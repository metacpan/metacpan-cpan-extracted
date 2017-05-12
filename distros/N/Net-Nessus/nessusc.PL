# -*- perl -*-

use strict;
use Config;

my $script = <<'END_OF_NESSUS_PL';
~startperl~
#
#
#   Net::Nessus - a set of Perl modules for working with the
#                 nessus program
#
#
#   The Net::Nessus package is
#
#	Copyright (C) 1998	Jochen Wiedmann
#               		Am Eisteich 9
#				72555 Metzingen
#				Germany
#
#				Phone: +49 7123 14887
#				Email: joe@ispsoft.de
#
#
#   All rights reserved.
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#
#   $Id: nessusc.PL,v 1.2 1999/01/31 14:03:17 joe Exp $
#
############################################################################

use strict;
require 5.004;
use Net::Nessus::Client();
use Getopt::Long ();
use Term::ReadKey ();


$| = 1;


############################################################################
#
#   Name:    Usage
#
#   Purpose: Print Usage message and exit with error status.
#
#   Inputs:  None
#
############################################################################

sub Usage {
    print <<USAGE;
$0 <action> --user=user --password=password [options]

Possible actions are:

  --target=<targethost>  Launch an attack against <targethost>.
  --plugins		 List the Nessus servers plugin list.
  --prefs		 List the Nessus servers preference list.
  --rules		 List the Nessus servers rules.

Possible options are:

  --host=<host>		 At startup the program connects to the Nessus server
  --port=<port>		 running at the machine <host>, port <port> as user
  --user=<user>          <user> with password <password>. The default host
  --password=<password>	 is localhost, port 1241, no defaults for user and
			 password are set, you must supply these values.
  --proto=<proto>	 Use NTP version <proto>; by default version 1.1
			 is used. This may change in the future, depending
			 on the Nessus releases.
  --verbose		 Run in verbose mode.

USAGE
    exit 1;
}


############################################################################
#
#   This is main()
#
############################################################################

package Net::Nessus::NessusC;

@Net::Nessus::NessusC::ISA = qw(Net::Nessus::Client);

sub new {
    my $proto = shift;
    my $o = shift;
    my $self = $proto->SUPER::new(@_);
    $self->{'verbose'} = $o->{'verbose'};
    $self;
}

sub Attack {
    my $self = shift;
    ($self->{'termWidth'}, $self->{'termHeight'}) =
	Term::ReadKey::GetTerminalSize(\*STDIN);
    $self->{'readMode'} = 5;
    Term::ReadKey::ReadMode(5, \*STDIN);
    my $messages = eval { $self->SUPER::Attack(@_) };
    $self->{'readMode'} = 0;
    Term::ReadKey::ReadMode(0, \*STDIN);
    die $@ if $@;
    $messages;
}

sub ShowSTATUS {
    my $self = shift; my $msg = shift;
    my $plugins_order = $self->{'plugins_order'};
    my $plugins = $self->Plugins();
    my $line;
    my $status = $msg->Status();
    if ($msg->Action() eq 'portscan') {
        $line = sprintf("Portscan %s: %s", $msg->Host(), $status);
    } else {
	if ($status =~ /(\d+)/) {
            $line = sprintf("Attack %s: $status %s", $msg->Host(),
        		    $plugins->[$plugins_order->[$1-1]]->{'summary'});
	}
    }

    my $termWidth;
    if (($termWidth = $self->{'termWidth'})  and
	(length($line) > $termWidth-2)) {
	$line = substr($line, 0, $termWidth-2);
    }
    if (defined($self->{'prevLine'})) {
	my $len = length($self->{'prevLine'}) - length($line);
	printf("%s%s\r", $line, ($len > 0) ? (" " x $len) : "");
    } else {
	printf("%s\r", $line);
    }
    $self->{'prevLine'} = $line;
}

sub DESTROY {
    my $self = shift;
    Term::ReadKey::ReadMode(0, \*STDIN) if ($self->{'readMode'});
}


package main;

{
    my $o = {
	'host' => '127.0.0.1',
	'port' => 1241,
        'proto' => '1.1',
        'help' => \&Usage
    };
    Getopt::Long::GetOptions($o, 'host=s', 'port=s', 'proto=s', 'user=s',
			     'password=s', 'target=s', 'plugins', 'prefs',
                             'rules', 'verbose', 'help');

    Usage() unless (defined($o->{'user'}) and defined($o->{'password'}));

    my $client = eval {
        Net::Nessus::NessusC->new($o,
				  'host' => $o->{'host'},
                                  'port' => $o->{'port'},
                                  'user' => $o->{'user'},
                                  'password' => $o->{'password'},
                                  'ntp_proto' => $o->{'proto'},
                                  'Timeout' => 300
                                  # ,'Dump_Log' => 'dump.log'
                                 );
    };
    unless ($client) {
        print STDERR ("Cannot connect to the Nessus server running at",
                      " $o->{'host'}, port $o->{'port'}:\n$@\n");
        exit 1;
    }

    my $done;
    if ($o->{'plugins'}) {
	print "\nPlugin list:\n\n";
        foreach my $plugin (@{$client->Plugins()}) {
	    foreach my $ref ( ['  Name: ', 'name'],
			      ['             Id: ', 'id'],
			      ['         Family: ', 'family'],
			      ['       Category: ', 'category'],
			      ['      Copyright: ', 'copyright'],
			      ['    Description: ', 'description']) {
		my $prefix = $ref->[0];
		foreach my $line (split(/;/, $plugin->{$ref->[1]})) {
		    print "$prefix$line\n";
		    $prefix = '     ';
		}
	    }
	    print "\n";
	}
	$done = 1;
    }
    if ($o->{'prefs'}) {
	print "\nPreference list:\n\n";
	while (my($var, $val) = each %{$client->Prefs()}) {
	    print "  $var = $val\n";
        }
	$done = 1;
    }
    if ($o->{'rules'}) {
        print "\nRule list:\n\n";
        foreach my $rule (@{$client->Rules()}) {
	    print "  $rule\n";
	}
        $done = 1;
    }
    if ($o->{'target'}) {
	my $plugin_list =
	    join(";",
		 map { $_->{'id'} } grep {$_->{'category'} ne 'denial'}
		 @{$client->Plugins()});
	my $msg = Net::Nessus::Message::PREFERENCES->new
	    ({'reverse_lookup' => 'no',
	      'host_expansion' => 'none',
	      'max_hosts' => 1,
	      'scan_level' => 'normal',
	      'plugin_set' => $plugin_list
	     });
	my $reply = eval { $client->Print($msg); $client->GetMsg() };
	if ($@) {
	    print STDERR "Failed to set preferences: $@\n";
	    exit 1;
	}

	my $errors = $reply->Prefs();
	if (%$errors) {
	    print STDERR "Could not set the following preferences:\n";
	    while (my($var, $val) = each %$errors) {
		print "  $var = $val\n";
	    }
	}

	my $messages = eval { $client->Attack($o->{'target'}) };
	if ($@) {
	    print STDERR "Failed to launch attack against $o->{'target'}:$@\n";
	    exit 1;
	}

	while (my($host_var, $host_messages) = each %$messages) {
	    print "\n\nReport for $host_var:\n\n";
	    foreach my $key ( sort { ($a eq 'general') ? 1 :
				      ($b eq 'general') ? -1 :
				       $a <=> $b } keys %$host_messages) {
	        my $port_hash = $host_messages->{$key};
	        if ($key eq 'general') {
		    print "\nGeneral problems detected:\n";
	        } else {
		    print "\nDetected port $key\n";
	        }
	        foreach my $hole (@{$port_hash->{'HOLE'}}) {
		    print "Detected hole: ", $hole->Description(), "\n";
		    print "               Scan-ID: ", $hole->ScanID(), "\n"
		        if defined($hole->ScanID());
	        }
	        foreach my $info (@{$port_hash->{'INFO'}}) {
		    print "Warning: ", $info->Description(), "\n";
		    print "               Scan-ID: ", $info->ScanID(), "\n"
		        if defined($info->ScanID());
		}
	    }
	}

	$done = 1;
    }

    Usage() unless $done;
}

=pod

=head1 NAME

  nessusc - A Nessus client written in Perl


=head1 SYNOPSIS

  Launch an attack:

    nessusc --target=thost --user=user --password=password
        [ --host=nhost --port=port --proto=1.1 ]

  Print the plugin list:

    nessusc --plugins --user=user --password=password
        [ --host=nhost --port=port --proto=1.1 ]

  Print the nessus servers preferences:

    nessusc --prefs --user=user --password=password
        [ --host=nhost --port=port --proto=1.1 ]

  Print the nessus servers rules:

    nessusc --rules --user=user --password=password
        [ --host=nhost --port=port --proto=1.1 ]


=head1 DESCRIPTON

The F<nessusc> script is a frontend for the I<Net::Nessus::Client> class,
for use from the command line or within shell scripts.

The scripts known options are:

=over 8

=item --host <nhost>

=item --user <user>

=item --password <password>

At startup the program will connect to the Nessus server running at machine
I<nhost> as I<user> with the given I<password>. The I<host> option defaults
to F<localhost>, no defaults are set for the other options: You must set
these.

Do not mismatch the I<host> option with I<target>!

=item --plugins

Print the plugin list.

=item --prefs

Print the list of preferences.

=item --rules

Print the list of rules.

=item --target <thost>

Launch an attack against the host F<thost>.

=back


=head1 AUTHOR AND COPYRIGHT

The Net::Nessus package is

  Copyright (C) 1998	Jochen Wiedmann
			Am Eisteich 9
			72555 Metzingen
			Germany

			Phone: +49 7123 14887
			Email: joe@ispsoft.de
  All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.


=head1 SEE ALSO

L<Net::Nessus::Client(3)>

=cut
END_OF_NESSUS_PL

$script =~ s/\~(\w+)\~/$Config::Config{$1}/eg;
die "Error while creating 'nessusc' file: $!"
    unless (open(FILE, ">nessusc")
	    and (print FILE $script)
	    and close(FILE));
