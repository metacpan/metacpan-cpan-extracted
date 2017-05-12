# -*- perl -*-
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
#       Copyright (C) 2004      Tiago Stock
#                               Email: tstock@tiago.com 
#
#   All rights reserved.
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#
#
############################################################################

require 5.004;
use strict;

require Net::Telnet;
require Carp;
require Net::Nessus::Message;


package Net::Nessus::Client;

# We are a subclass of Net::Cmd.
$Net::Nessus::Client::VERSION = '0.09';


=pod

=head1 NAME

    Net::Nessus::Client - A Nessus client module

=head1 SYNOPSIS

    # Connect to the Nessus Server
    require Net::Nessus::Client;
    my $client = Net::Nessus::Client->new('host' => 'localhost',
					  'port' => '1241',
					  'user' => 'joe',
					  'password' => 'my_password');

=head1 DESCRIPTION

The Nessus program is a Client/Server application offering a framework for
lots of security related scanners, so-called plugins. The idea is not to
create a separate scanner for any possible security hole, but to reimplement
only the most important parts and let the Nessus Server (nessusd) do the
most part of the work.

Clients are typically available as GUI applications, for example based on
the GTK (nessus), Java or Win32 applications. This module is another
Nessus client written in Perl, but without GUI.

You start using the module by opening a connection to a Nessus Server:
This will create a Nessus client object for you. This object offers
methods that you can later use, for example retrieving the list of
available plugins, start a scan, set preferences and so on.


=head1 METHOD INTERFACE

=head2 Creating a client object

  require Net::Nessus::Client;
  my $client = Net::Nessus::Client->new(%attr);

(Class Method) The new method is the client constructor. It receives
a set of attributes that are required for opening the connection, for
example

A Perl exception is thrown in case of trouble.

=over 8

=item host

=item port

Host name (or IP address) and port number of the Nessus servers machine.
The defaults are I<localhost> and I<1241>, as accepted by the IO::Socket
modules I<new> constructor. You may as well use other attributes of this
constructor, for example I<Timeout>. L<IO::Socket>.

=item user

=item password

User name and password to use for logging into the Nessus server. There
are no defaults, you must set these attributes.

=item ntp_proto

An optional version of the NTP protocol to run. Defaults to the highest
available number, 1.1 as of this writing.

=back

Example: Log into the Nessus server running at machine "gate.company.com",
port 2367 as user "joe" with password "what_password" and NTP version
1.0:

  require Net::Nessus::Client;
  my $client = Net::Nessus::Client->new('host' => 'gate.company.com',
                                        'port' => 2367,
                                        'user' => 'joe',
                                        'password' => 'what_password',
                                        'ntp_proto' => '1.0');

=cut


sub new {
    my $class = shift;
    my %attr = @_;

    my $host = $attr{'host'} or Carp::croak("Missing Nessus host");
    my $port = $attr{'port'} || 1241;
    my $proto = $attr{'ntp_proto'} || '1.1';
    my $user = $attr{'user'} or Carp::croak("Missing user name");
    my $pass = $attr{'password'} or Carp::croak("Missing password");
    my $sock = $attr{'socket'} =
	Net::Telnet->new('Binmode' => 1,
			 'Host' => $host,
			 'Port' => $port,
			 'Dump_Log' => $attr{'Dump_Log'},
			 'Input_Log' => $attr{'Input_Log'},
			 'Output_Log' => $attr{'Output_Log'},
			 'Telnetmode' => 0,
			 'Timeout' => ($attr{'Timeout'} || 300))
	    or Carp::croak("Cannot connect: $!");

    $sock->print("< NTP/$proto >")
	or Carp::croak("Error while writing proto: $!");
    my $line = $sock->getline();
    die "Error while requesting NTP proto $proto: $!" unless defined($line);
    die "Protocol $proto not supported: $line"
	unless ($line =~ /\<\s+NTP\/$proto\s+\>/);
    $sock->waitfor('Match' => '/[Uu]ser\s+:\s*/');
    $sock->print($user);
    $sock->waitfor('Match' => '/[Pp]assword\s+:\s*/');
    $sock->print($pass);
    my $self = \%attr;
    bless($self, (ref($class) or $class));
    $self->{'plugins'} = $self->GetMsg('PLUGIN_LIST');
    if ($proto >= 1.1) {
	$self->{'prefs'} = $self->GetMsg('PREFERENCES');
	$self->{'rules'} = $self->GetMsg('RULES');
    }
    $self;
}


=pod

=head2 Reading the plugin list

  my $plugins = $self->Plugins();
  my $prefs = $self->Prefs();
  my $rules = $self->Rules();

(Instance Methods) Read the plugin list, the current preferences or the
list of rules. The plugin list is an array of hash refs, each hash ref
with attributes I<id>, I<category> and so on. The prefs are a single
hash ref of name/value pairs and the rules are an array ref of strings.

When talking to an NTP/1.0 server, the Prefs() and Rules() methods
will return undef.

Examples:

  my $plugins = $self->Plugins();
  print("The first plugins ID is ", $plugins->[0]->{'id'}, "\n");
  print("The second plugins description is ",
        $plugins->[1]->{'description'}, "\n");
  my $prefs = $self->Prefs();
  print "\nThe current prefs are:\n";
  while (my($var, $val) = each %$prefs) {
    print "  $var = $val\n";
  }
  my $rules = $self->Rules();
  print "\nThe current rules are:\n";
  foreach my $rule (@$rules) {
    print "  $rule\n";
  }

=cut

sub Plugins { shift->{'plugins'}->Plugins() }
sub Prefs { my $prefs = shift->{'prefs'}; $prefs ? $prefs->Prefs() : undef }
sub Rules { my $rules = shift->{'rules'}; $rules ? $rules->Rules() : undef }


=pod

=head2 Sending a message to the server

  $client->Print($msg);

(Instance Method) The print method is used for sending a previously
created message to the server. Depending on the message type you
should continue calling the I<GetMsg> method.

Example:

  my $rules = ['n:*.fr;', 'y:*.my.de;'];
  my $msg = Net::Nessus::Message::Rules($rules);
  $client->print($msg);

=cut

sub Print {
    my $self = shift; my $msg = shift;
    $msg->print('CLIENT', $self->{'socket'})
}

=pod

=head2 Reading a message from the server

  $msg = $client->GetMsg($type, $timeout);

(Instance method) The I<GetMsg> method is reading a message from the server.
If the argument $type is undef, then any message is accepted, otherwise
any message other message type is treated as an error. Valid message
types are PLUGIN_LIST, PREFERENCES and so on.

If the argument $timeout is given, then an error will be triggered, if
the server is not sending any message for that much seconds. If no
timeout is given, then the default timeout will be used.

=cut

sub GetMsg {
    my $self = shift; my $type = shift; my $timeout = shift;
    Net::Nessus::Message->new('sender' => 'SERVER',
			      'type' => $type,
			      'socket' => $self->{'socket'},
			      'timeout' => $timeout);
}


=head2 Launching an attack

  my $messages = $client->Attack(@hosts);
  $client->ShowSTATUS($msg);
  $client->ShowPORT($msg);
  $client->ShowHOLE($msg);
  $client->ShowINFO($msg);
  $client->ShowPLUGINS_ORDER($msg);
  $client->ShowBYE($msg);
  $client->ShowERROR($msg);

(Instance Methods) An attack can be launched by calling the clients
I<Attack> method. While the attack is running, the Nessus server will
send PLUGINS_ORDER, STATUS, PORT, HOLE and INFO messages and finally
a BYE message. If the client receives such a message, he will call
the corresponding Show method, for example I<ShowPLUGINS_ORDER> or
I<ShowPORT>.

The default implementations of these messages will create a hash ref.
The hash refs keys are port numbers, a special key being the word
B<general>. The hash refs values are hash refs again, the keys being
the words PORT, HOLE and INFO. The values are array refs of corresponding
messages. That is, you find all security holes (if any) of the targets
FTP port as follows:

  my @ftp_holes = @{$messages->{'21'}->{'PORT'}};

Finally the hosts are used to build a top hash ref, the values being
as described above for the respective host.

=cut

sub ShowPLUGINS_ORDER {
    my $self = shift; my $msg = shift;
    $self->{'plugins_order'} = [ $msg->Plugins() ];
}

sub ShowSTATUS { }

sub ShowPORT {
    my $self = shift; my $msg = shift; my $array = shift || 'PORT';
    my $port = $msg->Port() || 'general';
    my $host = $msg->Host();
    if ($port =~ /\S+\s+\((\d+)\/\S+\)/) {
	$port = $1;
    }
    my $messages = $self->{'messages'};
    $messages->{$host}->{$port} = { 'PORT' => [], 'INFO' => [], 'HOLE' => [] }
	unless exists($messages->{$host}->{$port});
    push(@{$messages->{$host}->{$port}->{$array}}, $msg);
}

sub ShowINFO {
    my $self = shift; my $msg = shift;
    $self->Net::Nessus::Client::ShowPORT($msg, 'INFO');
}

sub ShowHOLE {
    my $self = shift; my $msg = shift;
    $self->Net::Nessus::Client::ShowPORT($msg, 'HOLE');
}

sub ShowBYE { }

sub ShowERROR { }

sub ShowFINISHED { }

sub Attack {
    my $self = shift; my @hosts = @_;
    $self->{'messages'} = {};
    $self->{'plugins_order'} = undef;
    my $msg = Net::Nessus::Message::NEW_ATTACK->new([join(",", @hosts)]);
    $self->Print($msg);
    while ($msg = $self->GetMsg()) {
	my $class = ref($msg);
	$class =~ s/.*\:\://;
	my $method = "Show$class";
	$self->$method($msg);
	last if $class eq 'BYE';
    }
    $self->{'messages'};
}


1; # Let "require Net::Nessus::Client return a TRUE value

__END__

=pod

=head1 AUTHOR AND COPYRIGHT

The Net::Nessus package is

  Copyright (C) 1998	Jochen Wiedmann
			Am Eisteich 9
			72555 Metzingen
			Germany

			Phone: +49 7123 14887
			Email: joe@ispsoft.de

  Copyright (C) 2004    Tiago Stock
                        Email: tstock@tiago.com

  All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.


=head1 SEE ALSO

L<Net::Nessus::Client(3)>

=cut
