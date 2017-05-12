package SQL::Easy;
{
  $SQL::Easy::VERSION = '2.0.0';
}

# ABSTRACT: extremely easy access to sql data



use strict;
use warnings;

use DBI;
use Carp;



sub new {
    my ($class, @params) = @_;

    if (ref $params[0] eq 'HASH') {
        croak "Incorrect usage of SQL::Easy->new()."
            . " Since version 2.0.0 SQL::Easy->new() need to recieve hash, not hashref."
            ;
    }
    my %params = @params;

    my $self  = {};

    $self->{dbh} = $params{dbh};
    $self->{connection_check_threshold} = $params{connection_check_threshold} || 30;
    $self->{count} = 0;

    unless ($self->{dbh}) {
        $self->{settings} = {
            db         => $params{database},
            user       => $params{user},
            password   => $params{password},
            host       => $params{host} || '127.0.0.1',
            port       => $params{port} || 3306,
        };

        $self->{dbh} = _get_connection($self->{settings});
    };

    $self->{last_connection_check} = time;

    if (defined $params{debug}) {
        croak "Incorrect usage of SQL::Easy->new()."
            . " Since version 2.0.0 SQL::Easy has no 'debug' parameter in new()."
            ;
    }

    my $cb_before_execute = delete $params{cb_before_execute};
    if (defined $cb_before_execute) {
        croak "cb_before_execute should be coderef"
            if ref($cb_before_execute) ne 'CODE';
        $self->{_cb_before_execute} = $cb_before_execute;
    }

    bless($self, $class);
    return $self;
}


sub get_dbh {
    my ($self) = @_;

    $self->_reconnect_if_needed();

    return $self->{dbh};
}


sub get_one {
    my ($self, $sql, @bind_variables) = @_;

    $self->_reconnect_if_needed();

    my $sth = $self->{dbh}->prepare($sql);
    $self->_run_cb_before_execute($sql, @bind_variables);
    $sth->execute(@bind_variables) or croak $self->{dbh}->errstr;

    my @row = $sth->fetchrow_array;

    return $row[0];
}


sub get_row {
    my ($self, $sql, @bind_variables) = @_;

    $self->_reconnect_if_needed();

    my $sth = $self->{dbh}->prepare($sql);
    $self->_run_cb_before_execute($sql, @bind_variables);
    $sth->execute(@bind_variables) or croak $self->{dbh}->errstr;

    my @row = $sth->fetchrow_array;

    return @row;
}


sub get_col {
    my ($self, $sql, @bind_variables) = @_;
    my @return;

    $self->_reconnect_if_needed();

    my $sth = $self->{dbh}->prepare($sql);
    $self->_run_cb_before_execute($sql, @bind_variables);
    $sth->execute(@bind_variables) or croak $self->{dbh}->errstr;

    while (my @row = $sth->fetchrow_array) {
        push @return, $row[0];
    }

    return @return;
}


sub get_data {
    my ($self, $sql, @bind_variables) = @_;
    my @return;

    $self->_reconnect_if_needed();

    my $sth = $self->{dbh}->prepare($sql);
    $self->_run_cb_before_execute($sql, @bind_variables);
    $sth->execute(@bind_variables) or croak $self->{dbh}->errstr;

    my @cols = @{$sth->{NAME}};

    my @row;
    my $line_counter = 0;
    my $col_counter = 0;

    while (@row = $sth->fetchrow_array) {
        $col_counter = 0;
        foreach(@cols) {
            $return[$line_counter]{$_} = ($row[$col_counter]);
            $col_counter++;
        }
        $line_counter++;
    }

    return \@return;
}


sub get_tsv_data {
    my ($self, $sql, @bind_variables) = @_;
    my $return;

    $self->_reconnect_if_needed();

    my $sth = $self->{dbh}->prepare($sql);
    $self->_run_cb_before_execute($sql, @bind_variables);
    $sth->execute(@bind_variables) or croak $self->{dbh}->errstr;

    $return .= join ("\t", @{$sth->{NAME}}) . "\n";

    while (my @row = $sth->fetchrow_array) {
        foreach (@row) {
            $_ = '' unless defined;
        }
        $return .= join ("\t", @row) . "\n";
    }

    return $return;
}


sub insert {
    my ($self, $sql, @bind_variables) = @_;

    $self->_reconnect_if_needed();

    my $sth = $self->{dbh}->prepare($sql);
    $self->_run_cb_before_execute($sql, @bind_variables);
    $sth->execute(@bind_variables) or croak $self->{dbh}->errstr;

    return $sth->{mysql_insertid};
}


sub execute {
    my ($self, $sql, @bind_variables) = @_;

    $self->_reconnect_if_needed();

    my $sth = $self->{dbh}->prepare($sql);
    $self->_run_cb_before_execute($sql, @bind_variables);
    $sth->execute(@bind_variables) or croak $self->{dbh}->errstr;

    return 1;
}


sub _run_cb_before_execute {
    my ($self, $sql, @bind_variables) = @_;

    if (defined $self->{_cb_before_execute}) {
        $self->{_cb_before_execute}->(
            sql => $sql,
            bind_variables => \@bind_variables,
        );
    }

    return '';
}


sub _reconnect_if_needed {
    my ($self) = @_;

    if (time - $self->{last_connection_check} > $self->{connection_check_threshold}) {
        if (_check_connection($self->{dbh})) {
            $self->{last_connection_check} = time;
        } else {
            $self->{dbh}= _get_connection($self->{settings});
        }
    }

}


sub _get_connection {
    my ($self) = @_;

    my $dsn = "DBI:mysql:database=" . $self->{db}
        . ";host=" . $self->{host}
        . ";port=" . $self->{port};

    my $dbh = DBI->connect(
        $dsn,
        $self->{user},
        $self->{password},
        {
            PrintError => 0,
            RaiseError => 1,
            mysql_auto_reconnect => 0,
            mysql_enable_utf8 => 1,
        },
    ) or croak "Can't connect to database. Error: " . $DBI::errstr . " . Stopped";

    return $dbh;
}


sub _check_connection {
    my $dbh = shift;
    return unless $dbh;
    if (my $result = $dbh->ping) {
        if (int($result)) {
            # DB driver itself claims all is OK, trust it:
            return 1;
        } else {
            # It was "0 but true", meaning the default DBI ping implementation
            # Implement our own basic check, by performing a real simple
            # query.
            my $ok;
            eval {
                $ok = $dbh->do('select 1');
            };
            return $ok;
        }
    } else {
        return;
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::Easy - extremely easy access to sql data

=head1 VERSION

version 2.0.0

=head1 SYNOPSIS

Let image we have db 'blog' with one table:

    CREATE TABLE `posts` (
      `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
      `dt` datetime NOT NULL,
      `title` VARCHAR(255) NOT NULL,
      PRIMARY KEY (`ID`)
    ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

    insert INTO `posts` (`dt`, `title`) values
      ('1', '2010-07-14 18:30:31', 'Hello, World!'),
      ('2', '2010-08-02 17:13:35', 'use perl or die')
    ;

Then we we can do some things with SQL::Easy

    use SQL::Easy;

    my $se = SQL::Easy->new(
        database => 'blog',
        user     => 'user',
        password => 'secret',
        host     => '127.0.0.1',           # default '127.0.0.1'
        port     => 3306,                  # default 3306
        connection_check_threshold => 30,  # default 30
    );

    # get scalar
    my $posts_count = $se->get_one('select count(id) from posts');

    # get list
    my ($dt, $title) = $se->get_row(
        'select dt, title from posts where id = ?',
        1,
    );

    # get arrayref
    my $posts = $se->get_data(
        'select dt_post, title from posts order by id',
    );
    # We will get
    #    [
    #        {
    #            'dt_post' => '2010-07-14 18:30:31',
    #            'title' => 'Hello, World!'
    #        },
    #        {
    #            'dt_post' => '2010-08-02 17:13:35',
    #            'title' => 'use perl or die'
    #        }
    #    ];

    my $post_id = $se->insert(
        'insert into images ( dt_post, title ) values ( now(), ? )',
        'My new idea',
    );
    # $post_id is the id of the new row in table

    # Sometimes you don't need the any return value (when you delete or update
    # rows), you only need to execute some sql. You can do it by
    $se->execute(
        'update posts set title = ? where id = ?',
        'JAPH',
        2,
    );

If it passed more than 'connection_check_threshold' seconds between requests
the module will check that db connection is alive and reconnect if it went
away.

=head1 DESCRIPTION

On cpan there are a lot of ORMs. The problem is that sometimes ORM are too
complex. You don't need ORM in a simple script with couple requests. ORM is
sometimes difficult to use, you need to learn its syntax. From the other hand
you already knows SQL language.

SQL::Easy give you easy access to data stored in databases using well known
SQL language.

SQL::Easy version numbers uses Semantic Versioning standart.
Please visit L<http://semver.org/> to find out all about this great thing.

=head1 METHODS

=head2 new

B<Get:> 1) $class 2) $params - hashref with constraction information

B<Return:> 1) object

    my $se = SQL::Easy->new(
        database => 'blog',
        user     => 'user',
        password => 'secret',
        host     => '127.0.0.1',           # default '127.0.0.1'
        port     => 3306,                  # default 3306
        connection_check_threshold => 30,  # default 30
    );

Or, if you already have dbh:

    my $se2 = SQL::Easy->new(
        dbh => $dbh,
    );

For example, if you are woring with Dancer::Plugin::Database you can use this
command to create SQL::Easy object:

    my $se3 = SQL::Easy->new(
        dbh => database(),
    );

This is one special parameter `cb_before_execute`. It should recieve callback.
This callback is run just before the sql is executed. The callback recieves
hash with keys 'sql' and 'bind_variables' that contains the values. The return
value of this callback is returned.

    my $se4 = SQL::Easy->new(
        ...
        cb_before_execute => sub {
            my (%params) = @_;

            my $sql = delete $params{sql};
            my $bind_variables = delete $params{bind_variables};

            print $sql . "\n";
            print join("\n", @{$bind_variables}) . "\n";

            return '';
        }
    );

=head2 get_dbh

B<Get:> 1) $self

B<Return:> 1) $ with dbi handler

=head2 get_one

B<Get:> 1) $self 2) $sql 3) @bind_variables

B<Return:> 1) $ with the first value of request result

=head2 get_row

B<Get:> 1) $self 2) $sql 3) @bind_variables

B<Return:> 1) @ with first row in result table

=head2 get_col

B<Get:> 1) $self 2) $sql 3) @bind_variables

B<Return:> 1) @ with first column in result table

=head2 get_data

B<Get:> 1) $self 2) $sql 3) @bind_variables

B<Return:> 1) $ with array of hashes with the result of the query

Sample usage:

    my $a = $se->get_data('select * from t1');

    print scalar @{$a};         # quantity of returned rows
    print $a->[0]{filename};    # element 'filename' in the first row

    for(my $i = 0; $i <= $#{$a}; $i++) {
        print $a->[$i]{filename}, "\n";
    }

=head2 get_tsv_data

B<Get:> 1) $self 2) $sql 3) @bind_variables

B<Return:> 1) $ with tab separated db data

Sample usage:

    print $se->get_tsv_data(
        'select dt_post, title from posts order by id limit 2',
    );

It will output the text below (with the tabs as separators).

    dt_post title
    2010-07-14 18:30:31     Hello, World!
    2010-08-02 17:13:35     use perl or die

=head2 insert

B<Get:> 1) $self 2) $sql 3) @bind_variables

B<Return:> 1) $ with id of inserted record

Sub executes sql with bind variables and returns id of inseted record

=head2 execute

B<Get:> 1) $self 2) $sql 3) @bind_variables

B<Return:> -

Sub just executes sql that it recieves and returns nothing interesting

=begin comment _run_cb_before_execute

B<Get:> 1) $self 2) $sql 3) @bind_variables

B<Return:> -

=end comment

=begin comment _reconnect_if_needed

B<Get:> 1) $self

B<Return:> -

Method checks if last request to db was more than
$self->{connection_check_threshold} seconds ago. If it was, then method
updates stored dbh.

=end comment

=begin comment _get_connection

B<Get:> 1) $self

B<Return:> -

Gets hashref with connection parameters and returns db

=end comment

=begin comment _check_connection

B<Get:> 1) $dbh

B<Return:> -

Check the connection is alive.

Based on sub with the same name created by David Precious in
Dancer::Plugin::Database.

=end comment

=head1 CONTRIBUTORS

=over 4

=item * Igor Sverdlov

=back

=head1 SOURCE CODE

The source code for this module is hosted on GitHub
L<https://github.com/bessarabov/SQL-Easy>

=head1 BUGS

Please report any bugs or feature requests in GitHub Issues
L<https://github.com/bessarabov/SQL-Easy>

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
