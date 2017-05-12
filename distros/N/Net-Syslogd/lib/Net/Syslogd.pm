package Net::Syslogd;

########################################################
# AUTHOR = Michael Vincent
# www.VinsWorld.com
########################################################

use strict;
use warnings;
use Socket qw(AF_INET);

my $AF_INET6 = eval { Socket::AF_INET6() };

our $VERSION = '0.16';
our @ISA;

my $HAVE_IO_Socket_IP = 0;
eval "use IO::Socket::IP -register";
if(!$@) {
    $HAVE_IO_Socket_IP = 1;
    push @ISA, "IO::Socket::IP"
} else {
    require IO::Socket::INET;
    push @ISA, "IO::Socket::INET";
}

########################################################
# Start Variables
########################################################
use constant SYSLOGD_DEFAULT_PORT => 514;
use constant SYSLOGD_RFC_SIZE     => 1024;  # RFC Limit
use constant SYSLOGD_REC_SIZE     => 2048;  # Recommended size
use constant SYSLOGD_MAX_SIZE     => 65467; # Actual limit (65535 - IP/UDP)

my @FACILITY = qw(kernel user mail system security internal printer news uucp clock security2 FTP NTP audit alert clock2 local0 local1 local2 local3 local4 local5 local6 local7);
my @SEVERITY = qw(Emergency Alert Critical Error Warning Notice Informational Debug);
our $LASTERROR;
########################################################
# End Variables
########################################################

########################################################
# Start Public Module
########################################################

sub new {
    my $self = shift;
    my $class = ref($self) || $self;

    # Default parameters
    my %params = (
        'Proto'     => 'udp',
        'LocalPort' => SYSLOGD_DEFAULT_PORT,
        'Timeout'   => 10,
        'Family'    => AF_INET
    );

    if (@_ == 1) {
        $LASTERROR = "Insufficient number of args - @_";
        return undef
    } else {
        my %cfg = @_;
        for (keys(%cfg)) {
            if (/^-?localport$/i) {
                $params{LocalPort} = $cfg{$_}
            } elsif (/^-?localaddr$/i) {
                $params{LocalAddr} = $cfg{$_}
            } elsif (/^-?family$/i) {
                 if ($cfg{$_} =~ /^(?:(?:(:?ip)?v?(?:4|6))|${\AF_INET}|$AF_INET6)$/) {
                    if ($cfg{$_} =~ /^(?:(?:(:?ip)?v?4)|${\AF_INET})$/) {
                        $params{Family} = AF_INET
                    } else {
                        if (!$HAVE_IO_Socket_IP) {
                            $LASTERROR = "IO::Socket::IP required for IPv6";
                            return undef
                        }
                        $params{Family} = $AF_INET6;
                        if ($^O ne 'MSWin32') {
                            $params{V6Only} = 1
                        }
                    }
                } else {
                    $LASTERROR = "Invalid family - $cfg{$_}";
                    return undef
                }
            } elsif (/^-?timeout$/i) {
                if ($cfg{$_} =~ /^\d+$/) {
                    $params{Timeout} = $cfg{$_}
                } else {
                    $LASTERROR = "Invalid timeout - $cfg{$_}";
                    return undef
                }
            # pass through
            } else {
                $params{$_} = $cfg{$_}
            }
        }
    }

    if (my $udpserver = $class->SUPER::new(%params)) {
        return bless {
                      %params,         # merge user parameters
                      '_UDPSERVER_' => $udpserver
                     }, $class
    } else {
        $LASTERROR = "Error opening socket for listener: $@";
        return undef
    }
}

sub get_message {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $message;

    foreach my $key (keys(%{$self})) {
        # everything but '_xxx_'
        $key =~ /^\_.+\_$/ and next;
        $message->{$key} = $self->{$key}
    }

    my $datagramsize = SYSLOGD_MAX_SIZE;
    if (@_ == 1) {
        $LASTERROR = "Insufficient number of args: @_";
        return undef
    } else {
        my %args = @_;
        for (keys(%args)) {
            # -maxsize
            if (/^-?(?:max)?size$/i) {
                if ($args{$_} =~ /^\d+$/) {
                    if (($args{$_} >= 1) && ($args{$_} <= SYSLOGD_MAX_SIZE)) {
                        $datagramsize = $args{$_}
                    }
                } elsif ($args{$_} =~ /^rfc$/i) {
                    $datagramsize = SYSLOGD_RFC_SIZE
                } elsif ($args{$_} =~ /^rec(?:ommend)?(?:ed)?$/i) {
                    $datagramsize = SYSLOGD_REC_SIZE
                } else {
                    $LASTERROR = "Not a valid size: $args{$_}";
                    return undef
                }
            # -timeout
            } elsif (/^-?timeout$/i) {
                if ($args{$_} =~ /^\d+$/) {
                    $message->{Timeout} = $args{$_}
                } else {
                    $LASTERROR = "Invalid timeout - $args{$_}";
                    return undef
                }
            }
        }
    }

    my $Timeout = $message->{Timeout};
    my $udpserver = $self->{_UDPSERVER_};
    my $datagram;

    if ($Timeout != 0) {
        # vars for IO select
        my ($rin, $rout, $ein, $eout) = ('', '', '', '');
        vec($rin, fileno($udpserver), 1) = 1;

        # check if a message is waiting
        if (! select($rout=$rin, undef, $eout=$ein, $Timeout)) {
            $LASTERROR = "Timed out waiting for datagram";
            return(0)
        }
    }

    # read the message
    if ($udpserver->recv($datagram, $datagramsize)) {

        $message->{_UDPSERVER_} = $udpserver;
        $message->{_MESSAGE_}{PeerPort} = $udpserver->SUPER::peerport;
        $message->{_MESSAGE_}{PeerAddr} = $udpserver->SUPER::peerhost;
        $message->{_MESSAGE_}{datagram} = $datagram;

        return bless $message, $class
    }

    $LASTERROR = sprintf "Socket RECV error: $!";
    return undef
}

sub process_message {
    my $self = shift;
    my $class = ref($self) || $self;

    ### Allow to be called as subroutine
    # Net::Syslogd->process_message($data)
    if (($self eq $class) && ($class eq __PACKAGE__)) {
        my %th;
        $self = \%th;
        ($self->{_MESSAGE_}{datagram}) = @_
    }
    # Net::Syslogd::process_message($data)
    if ($class ne __PACKAGE__) {
        my %th;
        $self = \%th;
        ($self->{_MESSAGE_}{datagram}) = $class;
        $class = __PACKAGE__
    }

    # Syslog RFC 3164 correct format:
    # <###>Mmm dd hh:mm:ss hostname tag msg
    #
    # NOTE:  This module parses the tag and msg as a single field called msg
    ######
    # Cisco:
    #   service timestamps log uptime
    # <189>82: 00:20:10: %SYS-5-CONFIG_I: Configured from console by cisco on vty0 (192.168.200.1)
    #   service timestamps log datetime
    # <189>83: *Oct 16 21:41:00: %SYS-5-CONFIG_I: Configured from console by cisco on vty0 (192.168.200.1)
    #   service timestamps log datetime msec
    # <189>88: *Oct 16 21:46:48.671: %SYS-5-CONFIG_I: Configured from console by cisco on vty0 (192.168.200.1)
    #   service timestamps log datetime year
    # <189>86: *Oct 16 2010 21:45:56: %SYS-5-CONFIG_I: Configured from console by cisco on vty0 (192.168.200.1)
    #   service timestamps log datetime show-timezone
    # <189>92: *Oct 16 21:49:30 UTC: %SYS-5-CONFIG_I: Configured from console by cisco on vty0 (192.168.200.1)
    #   service timestamps log datetime msec year
    # <189>90: *Oct 16 2010 21:47:50.439: %SYS-5-CONFIG_I: Configured from console by cisco on vty0 (192.168.200.1)
    #   service timestamps log datetime msec show-timezone
    # <189>93: *Oct 16 21:51:13.823 UTC: %SYS-5-CONFIG_I: Configured from console by cisco on vty0 (192.168.200.1)
    #   service timestamps log datetime year show-timezone
    # <189>94: *Oct 16 2010 21:51:49 UTC: %SYS-5-CONFIG_I: Configured from console by cisco on vty0 (192.168.200.1)
    #   service timestamps log datetime msec year show-timezone
    # <189>91: *Oct 16 2010 21:48:41.663 UTC: %SYS-5-CONFIG_I: Configured from console by cisco on vty0 (192.168.200.1)
    # IPv4 only
    # my $regex = '<(\d{1,3})>[\d{1,}: \*]*((?:[JFMASONDjfmasond]\w\w) {1,2}(?:\d+)(?: \d{4})* (?:\d{2}:\d{2}:\d{2}[\.\d{1,3}]*)(?: [A-Z]{1,3})*)?:*\s*(?:((?:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})|(?:[a-zA-Z0-9\-]+)) )?(.*)';
    # IPv6
    my $regex = '<(\d{1,3})>[\d{1,}: \*]*((?:[JFMASONDjfmasond]\w\w) {1,2}(?:\d+)(?: \d{4})? (?:\d{2}:\d{2}:\d{2}[\.\d{1,3}]*)(?: [A-Z]{1,3}:)?)?:?\s*(?:((?:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})|(?:[a-zA-Z0-9\-]+)|(?:(?:(?:[0-9A-Fa-f]{1,4}:){7}(?:[0-9A-Fa-f]{1,4}|:))|(?:(?:[0-9A-Fa-f]{1,4}:){6}(?::[0-9A-Fa-f]{1,4}|(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(?:(?:[0-9A-Fa-f]{1,4}:){5}(?:(?:(?::[0-9A-Fa-f]{1,4}){1,2})|:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(?:(?:[0-9A-Fa-f]{1,4}:){4}(?:(?:(?::[0-9A-Fa-f]{1,4}){1,3})|(?:(?::[0-9A-Fa-f]{1,4})?:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?:(?:[0-9A-Fa-f]{1,4}:){3}(?:(?:(?::[0-9A-Fa-f]{1,4}){1,4})|(?:(?::[0-9A-Fa-f]{1,4}){0,2}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?:(?:[0-9A-Fa-f]{1,4}:){2}(?:(?:(?::[0-9A-Fa-f]{1,4}){1,5})|(?:(?::[0-9A-Fa-f]{1,4}){0,3}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?:(?:[0-9A-Fa-f]{1,4}:){1}(?:(?:(?::[0-9A-Fa-f]{1,4}){1,6})|(?:(?::[0-9A-Fa-f]{1,4}){0,4}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(?::(?:(?:(?::[0-9A-Fa-f]{1,4}){1,7})|(?:(?::[0-9A-Fa-f]{1,4}){0,5}:(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(?:%.+)?) )?(.*)';

    # If more than 1 argument, parse the options
    if (@_ != 1) {
        my %args = @_;
        for (keys(%args)) {
            # -datagram
            if ((/^-?data(?:gram)?$/i) || (/^-?pdu$/i)) {
                $self->{_MESSAGE_}{datagram} = $args{$_}
            }
            # -regex
            if (/^-?regex$/i) {
                if ($args{$_} =~ /^rfc(?:3164)?$/i) {
                    # Strict RFC 3164
                    $regex = '<(\d{1,3})>((?:[JFMASONDjfmasond]\w\w) {1,2}(?:\d+)(?: \d{4})? (?:\d{2}:\d{2}:\d{2}))?:*\s*(?:((?:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})|(?:[a-zA-Z0-9\-]+)) )?(.*)'
                } else {
                    $regex = $args{$_};
                    # strip leading / if found
                    $regex =~ s/^\///;
                    # strip trailing / if found
                    $regex =~ s/\/$//
                }
            }
        }
    }

    my $Cregex = qr/$regex/;

    # Parse message
    $self->{_MESSAGE_}{datagram} =~ /$Cregex/;

    $self->{_MESSAGE_}{priority} = $1;
    $self->{_MESSAGE_}{time}     = $2 || 0;
    $self->{_MESSAGE_}{hostname} = $3 || 0;
    $self->{_MESSAGE_}{message}  = $4;
    $self->{_MESSAGE_}{severity} = $self->{_MESSAGE_}{priority} % 8;
    $self->{_MESSAGE_}{facility} = ($self->{_MESSAGE_}{priority} - $self->{_MESSAGE_}{severity}) / 8;

    $self->{_MESSAGE_}{hostname} =~ s/\s+//;
    $self->{_MESSAGE_}{time}     =~ s/:$//;

    return bless $self, $class
}

sub server {
    my $self = shift;
    return $self->{_UDPSERVER_}
}

sub datagram {
    my $self = shift;
    return $self->{_MESSAGE_}{datagram}
}

sub remoteaddr {
    my $self = shift;
    return $self->{_MESSAGE_}{PeerAddr}
}

sub remoteport {
    my $self = shift;
    return $self->{_MESSAGE_}{PeerPort}
}

sub priority {
    my $self = shift;
    return $self->{_MESSAGE_}{priority}
}

sub facility {
    my ($self, $arg) = @_;

    if (defined($arg) && ($arg >= 1)) {
        return $self->{_MESSAGE_}{facility}
    } else {
        return $FACILITY[$self->{_MESSAGE_}{facility}]
    }
}

sub severity {
    my ($self, $arg) = @_;

    if (defined($arg) && ($arg >= 1)) {
        return $self->{_MESSAGE_}{severity}
    } else {
        return $SEVERITY[$self->{_MESSAGE_}{severity}]
    }
}

sub time {
    my $self = shift;
    return $self->{_MESSAGE_}{time}
}

sub hostname {
    my $self = shift;
    return $self->{_MESSAGE_}{hostname}
}

sub message {
    my $self = shift;
    return $self->{_MESSAGE_}{message}
}

sub error {
    return $LASTERROR
}

########################################################
# End Public Module
########################################################

1;

__END__

########################################################
# Start POD
########################################################

=head1 NAME

Net::Syslogd - Perl implementation of Syslog Listener

=head1 SYNOPSIS

  use Net::Syslogd;

  my $syslogd = Net::Syslogd->new()
    or die "Error creating Syslogd listener: ", Net::Syslogd->error;

  while (1) {
      my $message = $syslogd->get_message();

      if (!defined($message)) {
          printf "$0: %s\n", Net::Syslogd->error;
          exit 1
      } elsif ($message == 0) {
          next
      }

      if (!defined($message->process_message())) {
          printf "$0: %s\n", Net::Syslogd->error
      } else {
          printf "%s\t%i\t%s\t%s\t%s\t%s\t%s\n",
                 $message->remoteaddr,
                 $message->remoteport,
                 $message->facility,
                 $message->severity,
                 $message->time,
                 $message->hostname,
                 $message->message
      }
  }

=head1 DESCRIPTION

Net::Syslogd is a class implementing a simple Syslog listener in Perl.
Net::Syslogd will accept messages on the default Syslog port (UDP 514)
and attempt to decode them according to RFC 3164.

=head1 METHODS

=head2 new() - create a new Net::Syslogd object

  my $syslogd = Net::Syslogd->new([OPTIONS]);

Create a new Net::Syslogd object with OPTIONS as optional parameters.
Valid options are:

  Option     Description                            Default
  ------     -----------                            -------
  -Family    Address family IPv4/IPv6                  IPv4
               Valid values for IPv4:
                 4, v4, ip4, ipv4, AF_INET (constant)
               Valid values for IPv6:
                 6, v6, ip6, ipv6, AF_INET6 (constant)
  -LocalAddr Interface to bind to                       any
  -LocalPort Port to bind server to                     514
  -timeout   Timeout in seconds for socket               10
             operations and to wait for request

B<NOTE>:  IPv6 requires IO::Socket::IP.  Failback is IO::Socket::INET 
and only IPv4 support.

Allows the following accessors to be called.

=head3 server() - return IO::Socket::IP object for server

  $syslogd->server();

Return B<IO::Socket::IP> object for the created server.
All B<IO::Socket::IP> accessors can then be called.

=head2 get_message() - listen for Syslog message

  my $message = $syslogd->get_message([OPTIONS]);

Listen for Syslog messages.  Timeout after default or user specified
timeout set in C<new> method and return '0'.  If message is received
before timeout, return is defined.  Return is not defined if error
encountered.

Valid options are:

  Option     Description                            Default
  ------     -----------                            -------
  -maxsize   Max size in bytes of acceptable          65467
             message.
             Value can be integer 1 <= # <= 65467.
             Keywords: 'RFC'         = 1024
                       'recommended' = 2048
  -timeout   Timeout in seconds to wait for              10
             request.  Overrides value set with
             new().

Allows the following accessors to be called.

=head3 remoteaddr() - return remote address from Syslog message

  $message->remoteaddr();

Return remote address value from a received (C<get_message()>)
Syslog message.  This is the address from the IP header on the UDP
datagram.

=head3 remoteport() - return remote port from Syslog message

  $message->remoteport();

Return remote port value from a received (C<get_message()>)
Syslog message.  This is the port from the IP header on the UDP
datagram.

=head3 datagram() - return datagram from Syslog message

  $message->datagram();

Return the raw datagram from a received (C<get_message()>)
Syslog message.

=head2 process_message() - process received Syslog message

  $message->process_message([OPTIONS]);

Process a received Syslog message according to RFC 3164 -
or as close as possible. RFC 3164 format is as follows:

  <###>Mmm dd hh:mm:ss hostname tag content
  |___||_____________| |______| |_________|
    |     Timestamp    Hostname   Message
    |
   Priority -> (facility and severity)

B<NOTE:>  This module parses the tag and content as a single field.

Called with one argument, interpreted as the datagram to process.
Valid options are:

  Option     Description                            Default
  ------     -----------                            -------
  -datagram  Datagram to process                    -Provided by
                                                     get_message()-
  -regex     Regular expression to parse received   -Provided in
             syslog message.                         this method-
             Keywords: 'RFC' = Strict RFC 3164
             Must include ()-matching:
               $1 = priority
               $2 = time
               $3 = hostname
               $4 = message

B<NOTE:>  This uses a regex that parses RFC 3164 compliant syslog
messages.  It will also recoginize Cisco syslog messages (not fully
RFC 3164 compliant) sent with 'timestamp' rather than 'uptime'.

This can also be called as a procedure if one is inclined to write
their own UDP listener instead of using C<get_message()>.  For example:

  $sock = IO::Socket::IP->new( blah blah blah );
  $sock->recv($datagram, 1500);
  # process datagram in $datagram variable
  $message = Net::Syslogd->process_message($datagram);

In either instantiation, allows the following accessors to be called.

=head3 priority() - return priority from Syslog message

  $message->priority();

Return priority value from a received and processed
(C<process_message()>) Syslog message.  This is the raw priority number
not decoded into facility and severity.

=head3 facility() - return facility from Syslog message

  $message->facility([1]);

Return facility value from a received and processed
(C<process_message()>) Syslog message.  This is the text representation
of the facility.  For the raw number, use the optional boolean argument.

=head3 severity() - return severity from Syslog message

  $message->severity([1]);

Return severity value from a received and processed
(C<process_message()>) Syslog message.  This is the text representation
of the severity.  For the raw number, use the optional boolean argument.

=head3 time() - return time from Syslog message

  $message->time();

Return time value from a received and processed
(C<process_message()>) Syslog message.

=head3 hostname() - return hostname from Syslog message

  $message->hostname();

Return hostname value from a received and processed
(C<process_message()>) Syslog message.

=head3 message() - return message from Syslog message

  $message->message();

Return message value from a received and processed
(C<process_message()>) Syslog message.  Note this is the tag B<and> msg
field from a properly formatted RFC 3164 Syslog message.

=head2 error() - return last error

  printf "Error: %s\n", Net::Syslogd->error;

Return last error.

=head1 EXPORT

None by default.

=head1 EXAMPLES

This distribution comes with several scripts (installed to the default
"bin" install directory) that not only demonstrate example uses but also
provide functional execution.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2010

L<http://www.VinsWorld.com>

All rights reserved

=cut
