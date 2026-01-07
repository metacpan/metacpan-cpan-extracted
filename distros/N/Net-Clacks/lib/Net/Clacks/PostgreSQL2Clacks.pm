package Net::Clacks::PostgreSQL2Clacks;
#---AUTOPRAGMASTART---
use v5.36;
use strict;
use diagnostics;
use mro 'c3';
use English qw(-no_match_vars);
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = 34;
use autodie qw( close );
use Array::Contains;
use utf8;
use Encode qw(is_utf8 encode_utf8 decode_utf8);
use Data::Dumper;
use builtin qw[true false is_bool];
no warnings qw(experimental::builtin); ## no critic (TestingAndDebugging::ProhibitNoWarnings)
#---AUTOPRAGMAEND---

use Net::Clacks::Client;
use DBI;
use Time::HiRes qw(sleep);

sub new($class, %config) {
    my $self = bless \%config, $class;

    if(!defined($self->{clacks})) {
        croak("clacks config not defined");
    }

    my @requireds = qw(username password clientname);
    if(!defined($self->{clacks}->{socket})) {
        push @requireds, 'server';
        push @requireds, 'port';
    }

    foreach my $required (@requireds) {
        if(!defined($self->{clacks}->{$required})) {
            croak("clacks setting $required not defined");
        }
    }
    
    if(!defined($self->{clacks}->{caching})) {
        $self->{clacks}->{caching} = 0;
    }

    if(!defined($self->{postgres})) {
        croak("postgres config not defined");
    }

    foreach my $required (qw(url username password)) {
        if(!defined($self->{postgres}->{$required})) {
            croak("postgres setting $required not defined");
        }
    }

    my $clacks;

    if(defined($self->{clacks}->{socket})) {
        # Unix domain sockets
        $clacks = Net::Clacks::Client->newSocket($self->{clacks}->{socket}, $self->{clacks}->{username}, $self->{clacks}->{password}, $self->{clacks}->{clientname}, $self->{clacks}->{caching})
            or croak("Failed to connect to Clacks");
    } else {
        # TCP/IP connection
        $clacks = Net::Clacks::Client->new($self->{clacks}->{server}, $self->{clacks}->{port}, $self->{clacks}->{username}, $self->{clacks}->{password}, $self->{clacks}->{clientname}, $self->{clacks}->{caching})
            or croak("Failed to connect to Clacks");
    }

    my $dbh = DBI->connect($self->{postgres}->{url}, $self->{postgres}->{username}, $self->{postgres}->{password},
                               {
                                   AutoCommit => 0,
                                   RaiseError => 0,
                                   AutoInactiveDestroy => 1,
                               }) or croak($EVAL_ERROR);

    $self->{clacks} = $clacks;
    $self->{dbh} = $dbh;

    $self->{nextping} = time + 10;

    $self->{dbh}->do('LISTEN clacksmessage');
    $self->{dbh}->commit;

    return $self;
}

sub initFunctions($self) {

    my @stmts = $self->getStatements();

    # Create/update function on PostgreSQL side
    foreach my $stmt (@stmts) {
        if(!$self->{dbh}->do($stmt)) {
            croak($self->{dbh}->errstr);
        }
    }
    $self->{dbh}->commit;

    return;
}

sub run($self) {
    while(1) {
        my @lines = $self->runOnce();
        foreach my $line (@lines) {
            print STDERR $line, "\n";
        }
        sleep(0.1);
    }

    return;
}

sub runOnce($self) {
    if(!$self->{dbh}->ping) {
        croak("Database connection failed!");
    }
    my @lines;

    $self->{clacks}->doNetwork();

    if(time < $self->{nextping}) {
        $self->{clacks}->ping();
        $self->{nextping} = time + 10;
        $self->{clacks}->doNetwork();
    }


    while((my $message = $self->{clacks}->getNext())) {
        # We mostly do this to keep the inbuffer nice and empty.
        # Since we neither LISTEN nor expect any other message, we should be fine
        if($message->{type} eq 'serverinfo') {
            push @lines, "Connected to " . $message->{data};
        } elsif($message->{type} eq 'disconnect') {
            if($message->{data} eq 'timeout') {
                push @lines, "Connection timeout! If you use runOnce() instead of run(), make sure to call it at least every 10 seconds!";
            }
            push @lines, "Connection to server lost.";
        } elsif($message->{type} eq 'reconnected') {
            push @lines, "Reconnected to server.";
        } else {
            push @lines, "Clacks-Message: " . $message->{type} . " ignored.\n";
        }
    }


    while((my $notify = $self->{dbh}->pg_notifies)) {
        my ($nname, $npid, $npayload) = @{$notify};

        my ($command, $name, $value) = split/\§\§\§CLACKSDELIMETER\§\§\§/, $npayload;

        if(!defined($name)) {
            $name = '';
        }

        if(!defined($value)) {
            $value = '';
        }

        my $line = join(' ', $command, $name, $value);
        if($command eq 'NOTIFY') {
            $self->{clacks}->notify($name);
        } elsif($command eq 'SET') {
            $self->{clacks}->set($name, $value);
        } elsif($command eq 'STORE') {
            $self->{clacks}->store($name, $value);
        } elsif($command eq 'SETANDSTORE') {
            $self->{clacks}->setAndStore($name, $value);
        } elsif($command eq 'INCREMENT') {
            $self->{clacks}->increment($name, $value);
        } elsif($command eq 'DECREMENT') {
            $self->{clacks}->decrement($name, $value);
        } elsif($command eq 'REMOVE') {
            $self->{clacks}->remove($name);
        } else {
            $line = 'UNKNOWN COMMAND: ' . $line;
        }

        push @lines, $line;
        $self->{dbh}->commit;
        $self->{clacks}->doNetwork();
    }
    $self->{dbh}->commit;
    $self->{clacks}->doNetwork();

    return @lines;
}


sub DESTROY($self) {
    # Try to disconnect cleanly, but socket might already be DESTROYed, so catch any errors
    eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
        $self->{clacks}->disconnect();
        $self->{dbh}->disconnect();
    };

    return;
}

sub getStatements($self) {
    return (
        "CREATE OR REPLACE FUNCTION clacks_notify(clacksname text) RETURNS void AS \$\$
        BEGIN
           PERFORM pg_notify('clacksmessage', 'NOTIFY' || '§§§CLACKSDELIMETER§§§' || clacksname);
           RETURN;
        END
        \$\$ LANGUAGE plpgsql;",

        "CREATE OR REPLACE FUNCTION clacks_set(clacksname text, clacksvalue text) RETURNS void AS \$\$
        BEGIN
           PERFORM pg_notify('clacksmessage', 'SET' || '§§§CLACKSDELIMETER§§§' || clacksname || '§§§CLACKSDELIMETER§§§' || clacksvalue);
           RETURN;
        END
        \$\$ LANGUAGE plpgsql;",

        "CREATE OR REPLACE FUNCTION clacks_store(clacksname text, clacksvalue text) RETURNS void AS \$\$
        BEGIN
           PERFORM pg_notify('clacksmessage', 'STORE' || '§§§CLACKSDELIMETER§§§' || clacksname || '§§§CLACKSDELIMETER§§§' || clacksvalue);
           RETURN;
        END
        \$\$ LANGUAGE plpgsql;",

        "CREATE OR REPLACE FUNCTION clacks_setandstore(clacksname text, clacksvalue text) RETURNS void AS \$\$
        BEGIN
           PERFORM pg_notify('clacksmessage', 'SETANDSTORE' || '§§§CLACKSDELIMETER§§§' || clacksname || '§§§CLACKSDELIMETER§§§' || clacksvalue);
           RETURN;
        END
        \$\$ LANGUAGE plpgsql;",

        "CREATE OR REPLACE FUNCTION clacks_increment(clacksname text, clacksvalue text) RETURNS void AS \$\$
        BEGIN
           PERFORM pg_notify('clacksmessage', 'INCREMENT' || '§§§CLACKSDELIMETER§§§' || clacksname || '§§§CLACKSDELIMETER§§§' || clacksvalue);
           RETURN;
        END
        \$\$ LANGUAGE plpgsql;",

        "CREATE OR REPLACE FUNCTION clacks_decrement(clacksname text, clacksvalue text) RETURNS void AS \$\$
        BEGIN
           PERFORM pg_notify('clacksmessage', 'DECREMENT' || '§§§CLACKSDELIMETER§§§' || clacksname || '§§§CLACKSDELIMETER§§§' || clacksvalue);
           RETURN;
        END
        \$\$ LANGUAGE plpgsql;",

        "CREATE OR REPLACE FUNCTION clacks_remove(clacksname text) RETURNS void AS \$\$
        BEGIN
           PERFORM pg_notify('clacksmessage', 'REMOVE' || '§§§CLACKSDELIMETER§§§' || clacksname);
           RETURN;
        END
        \$\$ LANGUAGE plpgsql;",
    );
};


1;
__END__

=head1 NAME

Net::Clacks::PostgreSQL2Clacks - write-only support client for PostgreSQL messaging

=head1 SYNOPSIS

  use Net::Clacks::PostgreSQL2Clacks;

  # Create new instance.
  my $pgclacks = Net::Clacks::PostgreSQL2Clacks->new(
      clacks => {
          server => '127.0.0.1',
          port => '4988',
          username => 'exampleuser',
          password => 'unsafepassword',
          clientname => 'PostgreSQL 2 Clacks Bridge',
          caching => 0,
      },
      postgres => {
          url => 'dbi:Pg:dbname=TropicoDB;host=/var/run/postgresql;sslmode=disable',
          username => 'ElPresidente',
          password => 'WorldDomination',
      },
  );
  # If you want to use Clacks with Unix domain sockets (can be a lot faster!), replace "server" and "port" with "socket" and point it to server socket
  # e.g. socket => '/my/path/to/server.socket"

  # run the PostgreSQL "CREATE OR REPLACE FUNCTION" calls. This needs the proper PostgreSQL permissions.
  # Only needs to be run once per database and after that only if the UpgradeGuide calls for it.
  $pgclacks->initFunctions();


  # Use the in-build event loop (never returns)
  $pgclacks->run();

  # ... or use your own event loop
  while($keeprunning) {
      # do your stuff

      $pgclacks->runOnce();
  }



=head1 DESCRIPTION

This implements a simple "write-only" support client to allow sending clacks messages from PostgreSQL. This makes it easy (or
at least "easier") to implement database triggers that send clacks messages.

And example would be a price list for articles. Whenever articles get updated in the database, it can now trigger a clacks
message that requests all clients to reload the price data from the database. In some cases this can reduce server load, because
the clients now only have to listen for small network messages instead of constantly polling the database.

Another example would be a live counter. Say you implement a mail server that knows how to stuff mails into the database but
doesn't know how to "speak clacks". With the help of PostgreSQL2Clacks, you can now add a PostgreSQL trigger that calls clacks_increment(),
and every time new mail arrives, the live counter gets incremented.

Technically, this works by using the PostgreSQL inbuild LISTEN/NOTIFY functionality. This module provides a few extra PostgreSQL server side functions. The
database trigger calls these, the functions concatenate the message parts with some delimeters and send a PostgreSQL "NOTIFY" message. This client LISTENs for them,
un-concatenate the message parts and call the corresponding L<Net::Clacks::Client> function.

=head1 Perl functions

=head2 new

Create a new instance, see SYNOPSIS.

=head2 initFunctions

initFunctions() installs (and upgrades) the required PostgreSQL server side functions. Only needs to be run once per database instances. But make sure to
check the L<Net::Clacks::UpgradeGuide> when upgrading. It may require you to run initFunctions again.

This is designed this way so you can use the client without having to give it the "CREATE" privilege during normal running. This is only required for
installing and upgrading.

=head2 runOnce

Run the event loop once. Use this if you implement your own event loops in your application. Make sure to call it at least once every 10 seconds or so,
shorter intervals are better.

=head2 run

Just hand over everything to Net::Clacks::PostgreSQL2Clacks. Unless something goes horribly wrong, it will never return. Perfect for creating a small standalone
PostgreSQL to Clacks bridge.

=head2 getStatements

Technically an internal function which returns all the "CREATE" statements used in initFunctions(). If you don't want to give the client "CREATE" permissions,
you can use something like this to just list all the statements to run them by hand in your psql console:

  my @stmts = $pgclacks->getStatements();

  foreach my $stmt (@stmts) {
      print $stmt, "\n\n";
  }

You would still need a valid connection to clacks and the database, though, for the client.

=head2 DESTROY

This tries to close the connection cleanly but there is a good chance it wont succeed cleanly under certain circumstances,
especially on program exit. Blame the random order Perl calls DESTROY.

=head1 PostgreSQL functions

=head2 clacks_notify(clacksname TEXT)

NOTIFY via clacks that event "clacksname" has happened

=head2 clacks_set(clacksname TEXT, clacksvalue TEXT)

SET clacks real-time value "clacksname" to "clacksvalue"

=head2 clacks_store(clacksname TEXT, clacksvalue TEXT)

STORE clacks cache value "clacksname" with "clacksvalue"

=head2 clacks_setandstore(clacksname TEXT, clacksvalue TEXT)

Combines SET and STORE in one go

=head2 clacks_increment(clacksname TEXT, clacksvalue TEXT)

INCREMENT clacks cache value "clacksname" by "clacksvalue"

(yes, you send a TEXT, not a BIGINT or something similar.)

=head2 clacks_decrement(clacksname TEXT, clacksvalue TEXT)

DECREMENT clacks cache value "clacksname" by "clacksvalue"

(yes, you send a TEXT, not a BIGINT or something similar.)

=head2 clacks_remove(clacksname TEXT)

REMOVE clacks cache value "clacksname"

=head1 IMPORTANT NOTE

Please make sure and read the documentations for L<Net::Clacks> as it contains important information
pertaining to upgrades and general changes!

=head1 AUTHOR

Rene Schickbauer, E<lt>cavac@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2024 Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
