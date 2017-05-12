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
#
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

require Carp;


package Net::Nessus::Message;

# We are a subclass of Net::Cmd.
$Net::Nessus::Message::VERSION = '0.04';


=pod

=head1 NAME

    Net::Nessus::Message - An implementation of Nessus Messages.


=head1 SYNOPSIS

    # Read a message from a socket
    my $msg = Net::Nessus::Message->new('socket' => $sock,
                                        'sender' => 'SERVER');


=head1 DESCRIPTION

The Nessus client and server communicate with each other by
sending and receiving messages. The message format is described in
the files F<ntp_white_paper.txt> (Protocol version 1.0),
F<ntp_white_paper_11.txt> (Protocol version 1.1) and
F<ntp_extensions.txt> in the Nessus distribution. 
Messages consist of field lists, the fields being separated by the 
string ' <|> ' (including the spaces, not including the quotes). 
The first and the last lines are the words I<SERVER> or I<CLIENT>, 
depending on who's sending a message.

However, there are not only single line messages: Some messages, in
particular the plugin and rule lists or the nessus preference lists
contain multiple lines.

The Net::Nessus::Message class is abstract: Constructors never return
instances of this class, but instances of subclasses. For example,
if the server is sending a list of plugins, then an instance of
Net::Nessus::Message::PLUGIN_LIST is returned.


=head1 METHOD INTERFACE

=head2 Reading a message from a socket

  my $msg = Net::Nessus::Message->new(%attr);

(Class Method) This method is reading a message from a socket,
given by the I<socket> attribute of the hash array %attr.
The message is expected to be introduced and terminated by either
B<SERVER> or B<CLIENT>, a specific sender is forced by setting the
attribute I<sender>, both are accepted otherwise. Likewise you may
force a specific message type by setting the attribute I<type>.

Example:

  my $msg = Net::Nessus::Message->new('socket' => $sock,
                                      'sender' => 'SERVER',
                                      'type' => 'PLUGIN_LIST');

=head2 Creating a message by supplying attributes

While the socket constructor is good for reading messages, you need
another constructor for writing messages. The main difference is that
you call the appropriate classes constructor this time and not a
generic constroctur, unlike above.

Example:

  my $msg = Net::Nessus::Message::PREFERENCES->new(\%attr);

=cut


sub new {
    my $self = shift; my %attr = @_;
    my @timeout;
    @timeout = ('Timeout' => $attr{'timeout'}) if defined($attr{'timeout'});
    my $sock = $attr{'socket'};
    if (!$sock  and  ref($self)) {
	$sock = $self->{'socket'};
    }
    die "Missing socket definition" unless $sock;
    my $line = $sock->getline(@timeout);
    die "Missing NTP message" unless defined($line);
    $line =~ s/\015?\012$//; # Remove CRLF
    my @fields = split(/ \<\|\> /, $line);
    my $sender = shift @fields;
    if (!defined($sender)  or
	($sender ne 'CLIENT'  and  $sender ne 'SERVER')) {
	die "Bad user name or password" if $line =~ /bad\s+login/i;
	die "Unknown message sender, expected 'SERVER' or 'CLIENT'";
    }
    my $type = shift @fields;
    if (!@fields) {
	$type =~ s/\s+\<\|\>$//;
    }
    die "Unknown message type" unless defined($type);
    die "Wrong message type, expected $attr{'type'}, received $type"
	if defined($attr{'type'}) and $attr{'type'} ne $type;

    my $class = (ref($self) or $self);
    $class =~ s/^\b(Client|Server)\b/Message/;
    $class .= "::$type";
    $class->new($sock, $sender, $type, \@fields);
}


package Net::Nessus::Message::SingleLine;

@Net::Nessus::Message::SingleLine::ISA = qw(Net::Nessus::Message);

sub new {
    my $class = shift;
    my $self;
    if (@_ == 1) {
	$self = shift;
    } else {
	my($sock, $sender, $type, $fields) = @_;
	my $terminator = pop @$fields;
	die "Invalid message terminator "
	    . (defined($terminator) ? $terminator : "'undef'")
		unless defined($terminator) and $terminator eq $sender;
	$self = $fields;
    }
    bless($self, (ref($class) or $class));
    $self;
}

sub print {
    my($self, $sender, $socket, $fields) = @_;
    $fields ||= $self;
    my $class = ref($self);
    $class =~ s/.*\:\://;
    die ("Error while writing message: " . $socket->error())
	unless $socket->print(join(" <|> ", $sender, $class, @$fields, $sender)
			      . "\n");
}


package Net::Nessus::Message::MultiLine;

@Net::Nessus::Message::MultiLine::ISA = qw(Net::Nessus::Message);

sub new {
    my $class = shift;
    my $self;
    if (@_ == 1) {
	$self = { 'lines' => shift };
    } else {
	my($sock, $sender, $type, $fields) = @_;
	my @lines;
	while (defined(my $line = $sock->getline())) {
	    $line =~ s/\015?\012$//; # Remove CRLF
	    if ($line =~ /^\<\|\>\s+$sender$/) {
		$self = { 'lines' => \@lines,
			  'fields' => $fields };
		last;
	    }
	    push(@lines, [split(/ \<\|\> /, $line)]);
	}
	die "Unexpected end of multiline message"
	    unless $self;
    }
    bless $self, (ref($class) or $class);
    $self;
}

sub print {
    my($self, $sender, $socket, $lines) = @_;
    $lines ||= $self->{'lines'};
    my $success = 1;
    my $class = ref($self);
    $class =~ s/.*\:\://;
    if ($socket->print("$sender <|> $class <|>")) {
	foreach my $line (@$lines) {
	    if (!$socket->print("$line")) {
		$success = 0;
		last;
	    }
	}
    } else {
	$success = 0;
    }
    $success &&= $socket->print("<|> $sender");
    die ("Error while writing message: " . $socket->error())
	unless $success;
}

=pod

=head2 Available messages are:

=head3 PLUGIN_LIST

  $msg = Net::Nessus::Message::PLUGIN_LIST(\@plugins);
  $msg->print($sender, $socket);

Plugin lists are sent by the server as soon as the client connects
The client may present the list to the user and let him select the
plugins being called. The message has a single method

  $msg->Plugins();

that returns an array ref of hash refs, each of them having the
attributes I<id>, I<name>, I<category>, I<copyright>, I<description>
I<summary> and I<family>.

=cut

package Net::Nessus::Message::PLUGIN_LIST;

@Net::Nessus::Message::PLUGIN_LIST::ISA = qw(Net::Nessus::Message::MultiLine);

sub new {
    my $proto = shift;
    my $self = $proto->SUPER::new(@_);
    if (@_ > 1) {
	my $lines = $self->{'lines'};
	for (my $i = 0;  $i < @$lines; $i++) {
	    my $line = $lines->[$i];
	    $lines->[$i] = { 'id' => $line->[0],
			     'name' => $line->[1],
			     'category' => $line->[2],
			     'copyright' => $line->[3],
			     'description' => $line->[4],
			     'summary' => $line->[5],
			     'family' => $line->[6],
			   };
	}
    }
    $self;
}
sub print {
    my $self = shift;
    $self->SUPER::print(@_, [map {join(" <|> ",
				       $_->{'id'},
				       $_->{'name'},
				       $_->{'category'},
				       $_->{'copyright'},
				       $_->{'description'},
				       $_->{'summary'},
				       $_->{'family'}
				      ) } @{$self->{'lines'}}])
}
sub Plugins { shift->{'lines'} }


=pod

=head3 PREFERENCES, PREFERENCES_ERRORS

  my $msg = Net::Nessus::Message::PREFERENCES->new(\%attr);
  my $msg = Net::Nessus::Message::PREFERENCES_ERRORS->new(\%attr);

Similar to the PLUGIN_LIST, the PREFERENCES are sent to the client if he
has connected. The client may reply with another list of own preferences.
Its method

  $msg->Prefs();

returns the preferences hash ref. The PREFERENCES message is available
beginning with protocol version 1.1 and obsoletes the old NEW_ATTACK
message in favour of the shorter version.

If the client has sent a PREFERENCES message, the server will respond
a PREFERENCES_ERROR message. This is almost the same, except that only
those values appear that had illegal values in the PREFERENCES message.
The values in the reply will be the servers default values.

=cut


package Net::Nessus::Message::PREFERENCES;

@Net::Nessus::Message::PREFERENCES::ISA = qw(Net::Nessus::Message::MultiLine);

sub new {
    my $proto = shift;
    my $self = $proto->SUPER::new(@_);
    if (@_ == 1) {
	$self->{'prefs'} = delete $self->{'lines'};
    } else {
	my %prefs;
	my $lines = $self->{'lines'};
	for (my $i = 0;  $i < @$lines; $i++) {
	    my $line = $lines->[$i];
	    $prefs{$line->[0]} = $line->[1];
	}
	$self->{'prefs'} = \%prefs;
    }
    $self
}
sub print {
    my $self = shift;
    my $lines = [];
    while (my($var, $val) = each %{$self->{'prefs'}}) {
	push(@$lines, "$var <|> $val");
    }
    $self->SUPER::print(@_, $lines);
}
sub Prefs { shift->{'prefs'} }


package Net::Nessus::Message::PREFERENCES_ERRORS;

@Net::Nessus::Message::PREFERENCES_ERRORS::ISA =
    qw(Net::Nessus::Message::PREFERENCES);

=pod

=head3 RULES

  $msg = Net::Nessus::Message::RULES(\@rules);

This is the third message sent to the client upon connect. Its only
method is

  $msg->Rules();

returning an array ref of rules, each rule consisting of a single
string.

=cut

package Net::Nessus::Message::RULES;

@Net::Nessus::Message::RULES::ISA = qw(Net::Nessus::Message::MultiLine);

sub new {
    my $class = shift; my $self = $class->SUPER::new(@_);
    my $lines = $self->{'lines'};
    for (my $i = 0;  $i < @$lines;  $i++) {
	if (ref($lines->[$i]) eq 'ARRAY') {
	    $lines->[$i] = $lines->[$i]->[0];
	}
    }
    $self;
}

sub Rules { shift->{'lines'} }


=pod

=head3 INFO, HOLE

  $msg = Net::Nessus::Message::HOLE->new
      ([$host, $port, $description, $service, $proto]);

The HOLE and INFO messages are used by the server for reporting security
problems. INFO messages are considered warnings, HOLE messages are expected
to be more serious. You may use the following methods for retrieving more
info:

  $msg->Host();
  $msg->Port();
  $msg->Description();
  $msg->Service();
  $msg->Proto();
  $msg->ScanID();

The methods I<Service> and I<Description> are valid as of NTP 1.1 only,
they return B<undef> in NTP 1.0. The I<Proto> and I<Port> methods may
return B<undef> even with NTP 1.1, in which case the I<Service> method
returns "general". Thus the I<Service> method is used best to distinguish
between NTP 1.0 and 1.1. The method I<ScanID>, available with our
proposed NTP 1.2 enhancements returns the scans ID, as presented in the
plugin list.

=cut

package Net::Nessus::Message::HOLE;

@Net::Nessus::Message::HOLE::ISA = qw(Net::Nessus::Message::SingleLine);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my ($host, $port, $description, $service, $proto, $scan_id);
    $host = shift @$self;
    if (@$self == 1) {
	# NTP 1.0
	$description = shift @$self;
	die "Cannot parse hole or info description: $description"
	    unless $description =~ /(.*?):(.*)/;
	$port = $1;
	$description = $2;
    } else {
	$service = shift @$self;
	$description = shift @$self;
	$scan_id = shift @$self;
	if ($service =~ /^\s*general\/(.*?)\s*$/) {
	    $service = $1;
	    $port = 0;
	    $proto = $2;
	} elsif ($service =~ /\s*(.*?)\s*\((\d+)\/(\S+)\)/) {
	    $service = $1;
	    $port = $2;
	    $proto = $3;
	} else {
	    die "Cannot parse hole or info service: $service";
	}
    }
    $description =~ s/\;/\n/g;
    @$self = ($host, $port, $description, $service, $proto, $scan_id);
    $self;
}
sub print {
    my $self = shift;
    my $host = $self->Host();
    my $port = $self->Port();
    my $description = $self->Description();
    $description =~ s/\n/;/sg;
    if (defined(my $service = $self->Service())) {
	if (defined($port)) {
	    my $proto = $self->Proto();
	    $self->SUPER::print(@_, [$host, "$service ($port/$proto)",
				     $description]);
	} else {
	    $self->SUPER::print(@_, [$host, $service, $description]);
	}
    } else {
	$self->SUPER::print(@_, [$host, "$port:$description"]);
    }
}
sub Host { shift->[0] }
sub Port { shift->[1] }
sub Description { shift->[2] }
sub Service { shift->[3] }
sub Proto { shift->[4] }
sub ScanID { shift->[5] }


package Net::Nessus::Message::INFO;

@Net::Nessus::Message::INFO::ISA = qw(Net::Nessus::Message::HOLE);


=pod

=head3 PORT

  $msg = Net::Nessus::Message::PORT->new([$host, $port]);

The PORT message is sent, if the server finds an open port without known
security problems. Thus the methods are similar to the HOLE and INFO
messages, except that a I<Description> method is missing.

  $msg->Host();
  $msg->Port();

=cut

package Net::Nessus::Message::PORT;

@Net::Nessus::Message::PORT::ISA = qw(Net::Nessus::Message::SingleLine);

sub Host { shift->[0] }
sub Port { shift->[1] }


=pod

=head3 ERROR

The ERROR message is used by the Nessus server to report problems.
Its attributes are:    

  $msg->ErrMsg

=cut

package Net::Nessus::Message::ERROR;

@Net::Nessus::Message::ERROR::ISA = qw(Net::Nessus::Message::SingleLine);

sub ErrMsg { shift->[0] }

=pod

=head3 NEW_ATTACK

  # NTP 1.0
  $msg = Net::Nessus::Message::NEW_ATTACI->new
      ([$host, $pluginlist, $maxhosts, $recursive, $portrange]);
  # NTP 1.1
  $msg = Net::Nessus::Message::NEW_ATTACI->new([$host]);

NEW_ATTACK messages are sent by the client for launching new scans.
Its attributes are:

  $msg->Host();
  $msg->PluginList();
  $msg->MaxHosts();
  $msg->Recursive();
  $msg->PortRange();

Except for the I<Host> method, these are valid with NTP 1.0 only.
They return the value B<undef> in later versions.

=cut

package Net::Nessus::Message::NEW_ATTACK;

@Net::Nessus::Message::NEW_ATTACK::ISA = qw(Net::Nessus::Message::SingleLine);

sub new {
    my $proto = shift;
    my $self = $proto->SUPER::new(@_);
    if (@$self == 1) {
	# NTP 1.1
	my $host = shift @$self;
	@$self = (undef, undef, undef, undef, $host);
    }
    $self;
}

sub print {
    my($self, $sender, $socket, $fields) = @_;
    $fields ||= $self;
    $self->SUPER::print($sender, $socket,
			defined($fields->[0]) ? $fields : [$fields->[4]]);
}

sub PluginList { split(/;/, shift->[0]) };
sub MaxHosts { shift->[1] }
sub Recursive { shift->[2] }
sub PortRange { shift->[3] }
sub Host { shift->[4] }


=pod

=head3 STAT

  $msg = Net::Nessus::Message::STAT->new([$host, $port]);

The STAT message is sent by the server as an indicator for the port scanning
status. Its attributes are:

  $msg->Host();
  $msg->Port();

As of NTP 1.1, this message is obsoleted by the STATUS message.

=cut

package Net::Nessus::Message::STAT;

@Net::Nessus::Message::STAT::ISA = qw(Net::Nessus::Message::PORT);


=pod

=head3 STOP_ATTACK

  $msg = Net::Nessus::Message::STOP_ATTACK->new([$host]);

The STOP_ATTACK message is sent by the client. It forces the server to
stop attacking the given host:

  $msg->Host();

=cut

package Net::Nessus::Message::STOP_ATTACK;

@Net::Nessus::Message::STOP_ATTACK::ISA = qw(Net::Nessus::Message::SingleLine);

sub Host { shift->[0] }


=pod

=head3 PLUGINS_ORDER

  $msg = Net::Nessus::Message::PLUGINS_ORDER->new([$plugins]);

This message is sent by the server before he starts scanning. It will
contain the same list of plugins that the client requested with the
NEW_ATTACK message (NTP 1.0) or the PREFERENCES message (NTP 1.1), but
in the order they will be executed. The message has a method

  $msg->Plugins();

which returns an array of plugin ID's.

=cut

package Net::Nessus::Message::PLUGINS_ORDER;

@Net::Nessus::Message::PLUGINS_ORDER::ISA =
    qw(Net::Nessus::Message::SingleLine);

sub Plugins { split(/;/, shift->[0]) }


=pod

=head3 STATUS

  $msg = Net::Nessus::Message::STATUS->new([$host, $action, $status]);

This message is sent from an NTP 1.1 server as a progress indicator.
It's attributes are:

  $msg->Host();
  $msg->Action();
  $msg->Status();

where the I<Host> method returns a host being scanned, the I<Action>
method returns either B<portscan> or B<attack> and the I<Status>
method returns a string in the form "23/80" to indicate that 23 of

80 actions have been executed.

=cut

package Net::Nessus::Message::STATUS;

@Net::Nessus::Message::STATUS::ISA = qw(Net::Nessus::Message::SingleLine);

sub Host { shift->[0] }
sub Action { shift->[1] }
sub Status { shift->[2] }


=pod

=head3 STOP_WHOLE_TEST

  $msg = Net::Nessus::Message::STOP_WHOLE_TEST->new([]);

This message, available with NTP 1.1 only, can be used to stop the
whole test, unlike the STOP_ATTACK message which is stopping a single
host only.

The message has no attributes, thus no methods for fetching attributes
are available.

=cut

package Net::Nessus::Message::STOP_WHOLE_TEST;

@Net::Nessus::Message::STOP_WHOLE_TEST::ISA =
    qw(Net::Nessus::Message::SingleLine);


=pod

=head3 FINISHED

This message is sent by the server if the preference ntp_opt_show_end has 
been specified

=cut

package Net::Nessus::Message::FINISHED;
                                                                                
@Net::Nessus::Message::FINISHED::ISA = qw(Net::Nessus::Message::SingleLine);
                                                                                
sub Host { shift->[0] }

=pod

=head3 BYE

  $msg = Net::Nessus::Message::BYE->new([]);

This message is sent by the server to indicate that a scan is done.


=cut

package Net::Nessus::Message::BYE;

@Net::Nessus::Message::BYE::ISA = qw(Net::Nessus::Message::SingleLine);


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

