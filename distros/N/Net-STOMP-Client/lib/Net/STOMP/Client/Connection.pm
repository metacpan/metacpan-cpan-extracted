#+##############################################################################
#                                                                              #
# File: Net/STOMP/Client/Connection.pm                                         #
#                                                                              #
# Description: Connection support for Net::STOMP::Client                       #
#                                                                              #
#-##############################################################################

#
# module definition
#

package Net::STOMP::Client::Connection;
use strict;
use warnings;
our $VERSION  = "2.3";
our $REVISION = sprintf("%d.%02d", q$Revision: 2.6 $ =~ /(\d+)\.(\d+)/);

#
# used modules
#

use IO::Socket::INET qw();
use List::Util qw(shuffle);
use Net::STOMP::Client::Peer qw();
use No::Worries::Die qw(dief);
use No::Worries::File qw(file_read);
use No::Worries::Log qw(log_debug);
use Params::Validate qw(validate :types);
use Time::HiRes qw();

#+++############################################################################
#                                                                              #
# private helpers                                                              #
#                                                                              #
#---############################################################################

#
# convert a URI (with no options) to a peer object
#

sub _uri2peer ($) {
    my($uri) = @_;

    if ($uri =~ m{ ^ (tcp|ssl|stomp|stomp\+ssl)
                     \:\/\/ ([_a-z0-9\.\-]+) \: (\d+) \/? $ }ix) {
        return(Net::STOMP::Client::Peer->new(
            proto => $1,
            host  => $2,
            port  => $3,
        ));
    } else {
        dief("unexpected server uri: %s", $uri);
    }
}

#
# set the default connection options
#

sub _default_options ($) {
    my($option) = @_;

    $option->{randomize}  =  1;
    $option->{sleep}      =  0.01;
    $option->{max_sleep}  = 30;
    $option->{multiplier} =  2;
}

#
# parse an option string (we do not complain about unknown options)
#

sub _parse_options ($$) {
    my($option, $string) = @_;

    if ($string =~ /\b(backOffMultiplier=(\d+(\.\d+)?))\b/) {
        $option->{multiplier} = $2;
    }
    if ($string =~ /\b(useExponentialBackOff=false)\b/) {
        $option->{multiplier} = 0;
    }
    if ($string =~ /\b(randomize=false)\b/) {
        $option->{randomize} = 0;
    }
    if ($string =~ /\b(initialReconnectDelay=(\d+))\b/) {
        $option->{sleep} = $2 / 1000;
    }
    if ($string =~ /\b(maxReconnectDelay=(\d+))\b/) {
        $option->{max_sleep} = $2 / 1000;
    }
    if ($string =~ /\b(maxReconnectAttempts=(\d+))\b/) {
        $option->{max_attempt} = $2 + 1;
    }
}

#
# parse a connection URI
#
# supported URIs:
#  - tcp://foo:12
#  - file:/foo/bar
#  - ActiveMQ failover URIs
#

sub _parse_uri ($) {
    my($uri) = @_;
    my(@peers, %option, @list);

    while (1) {
        if ($uri =~ /^file:(.+)$/) {
            # list of URIs stored in a file, one per line
            @list = ();
            foreach my $line (split(/\n/, file_read($1))) {
                $line =~ s/\#.*//;
                $line =~ s/\s+//g;
                push(@list, $line) if length($line);
            }
            if (@list == 1) {
                # if only one, allow failover syntax for it
                $uri = shift(@list);
            } else {
                # otherwise, they must be simple URIs
                @peers = map(_uri2peer($_), @list);
                last;
            }
        } elsif ($uri =~ m{ ^ failover \: (?:\/\/)? \( ([_a-z0-9\.\-\:\/\,]+) \)
                            ( \? [_a-z0-9\.\=\-\&]+ ) ? $ }ix) {
            # failover with options
            _default_options(\%option);
            _parse_options(\%option, $2) if $2;
            @peers = map(_uri2peer($_), split(/,/, $1));
            last;
        } elsif ($uri =~ m{ ^ failover \: ([_a-z0-9\.\-\:\/\,]+) $ }ix) {
            # failover without options
            _default_options(\%option);
            @peers = map(_uri2peer($_), split(/,/, $1));
            last;
        } else {
            # otherwise this must be a simple URI
            @peers = (_uri2peer($uri));
            last;
        }
    }
    dief("empty server uri: %s", $uri) unless @peers;
    return(\@peers, \%option);
}

#
# attempt to connect to one peer (low level)
#

sub _attempt ($%) {
    my($peer, %sockopt) = @_;
    my($socket);

    # options sanity
    $sockopt{Proto} = "tcp"; # yes, even SSL is TCP...
    $sockopt{PeerAddr} = $peer->host();
    $sockopt{PeerPort} = $peer->port();
    # try to connect
    if ($peer->proto() =~ /\b(ssl)\b/) {
        # with SSL
        unless ($IO::Socket::SSL::VERSION) {
            eval { require IO::Socket::SSL };
            return(sprintf("cannot load IO::Socket::SSL: %s", $@)) if $@;
        }
        $socket = IO::Socket::SSL->new(%sockopt);
        return(sprintf("cannot SSL connect to %s:%d: %s", $peer->host(),
                       $peer->port(), IO::Socket::SSL::errstr()))
            unless $socket;
    } else {
        # with plain TCP
        $socket = IO::Socket::INET->new(%sockopt);
        return(sprintf("cannot connect to %s:%d: %s", $peer->host(),
                       $peer->port(), $!))
            unless $socket;
        return(sprintf("cannot binmode(socket): %s", $!))
            unless binmode($socket);
    }
    # so far so good...
    @{ $peer }[3] = $socket->peerhost();
    return($socket);
}

#
# try to connect to a list of peers (high level)
#

sub _try ($$$$) {
    my($peers, $peeropt, $sockopt, $debug) = @_;
    my(@list, $count, $result);

    dief("no peers given!") unless @{ $peers };
    $count = 0;
    while (1) {
        @list = $peeropt->{randomize} ? shuffle(@{ $peers }) : @{ $peers };
        foreach my $peer (@list) {
            $result = _attempt($peer, %{ $sockopt });
            if (ref($result)) {
                log_debug("connect to %s ok: %s", $peer->uri(), $peer->addr())
                    if $debug =~ /\b(connection|all)\b/;
                return($result, $peer);
            } else {
                log_debug("connect to %s failed: %s", $peer->uri(), $result)
                    if $debug =~ /\b(connection|all)\b/;
            }
            $count++;
            if (defined($peeropt->{max_attempt})) {
                last if $count >= $peeropt->{max_attempt};
            }
            if ($peeropt->{sleep}) {
                Time::HiRes::sleep($peeropt->{sleep});
                if ($peeropt->{multiplier}) {
                    $peeropt->{sleep} *= $peeropt->{multiplier};
                    if ($peeropt->{max_sleep} and
                        $peeropt->{sleep} > $peeropt->{max_sleep}) {
                        $peeropt->{sleep} = $peeropt->{max_sleep};
                        delete($peeropt->{multiplier});
                    }
                }
            }
        }
        if (defined($peeropt->{max_attempt})) {
            last if $count >= $peeropt->{max_attempt};
        }
        last unless keys(%{ $peeropt });
    }
    # in case of failure, we only report the last error message...
    dief($result);
}

#+++############################################################################
#                                                                              #
# public function                                                              #
#                                                                              #
#---############################################################################

my %new_options = (
    "host" => {
        optional => 1,
        type     => SCALAR,
        regex    => qr/^[a-z0-9\.\-]+$/,
    },
    "port" => {
        optional => 1,
        type     => SCALAR,
        regex    => qr/^\d+$/,
    },
    "uri" => {
        optional => 1,
        type     => SCALAR,
    },
    "sockopt" => {
        optional => 1,
        type     => HASHREF,
    },
    "debug" => {
        optional => 1,
        type     => UNDEF|SCALAR,
    },
);

sub new (@) {
    my(%option, $proto, $peers, $peeropt);

    %option = validate(@_, \%new_options);
    $option{sockopt} ||= {};
    $option{debug} ||= "";
    if (defined($option{uri})) {
        # by URI
        dief("unexpected server host: %s", $option{host})
            if defined($option{host});
        dief("unexpected server port: %s", $option{port})
            if defined($option{port});
        ($peers, $peeropt) = _parse_uri($option{uri});
    } else {
        # by host + port
        dief("missing server host") unless defined($option{host});
        dief("missing server port") unless defined($option{port});
        $proto = "tcp";
        $proto = "ssl" if grep(/^SSL_/, keys(%{ $option{sockopt} }));
        $peers = [
            Net::STOMP::Client::Peer->new(
                proto => $proto,
                host  => $option{host},
                port  => $option{port},
            ) ];
        $peeropt = {};
    }
    return(_try($peers, $peeropt, $option{sockopt}, $option{debug}));
}

1;

__END__

=head1 NAME

Net::STOMP::Client::Connection - Connection support for Net::STOMP::Client

=head1 DESCRIPTION

This module provides connection establishment support (plain TCP and SSL) as
well as URI handling.

It is used internally by L<Net::STOMP::Client> and should not be directly
used elsewhere.

=head1 FUNCTIONS

This module provides the following function (which is B<not> exported):

=over

=item new([OPTIONS])

attempt to establish a new connection to a STOMP server

=back

=head1 SSL

When creating an object with L<Net::STOMP::Client>'s new() method, if you
supply some socket options (via C<sockopts>) with a name starting with
C<SSL_> or if you supply a URI (via C<uri>) with a scheme containg C<ssl>
then L<IO::Socket::SSL> will be used to create the socket instead of
L<IO::Socket::INET> and the communication with the server will then go
through SSL.

Here are the most commonly used SSL socket options:

=over

=item SSL_ca_path

path to a directory containing several trusted certificates as separate
files as well as an index of the certificates

=item SSL_key_file

path of your RSA private key

=item SSL_cert_file

path of your certificate

=item SSL_passwd_cb

subroutine that should return the password required to decrypt your private
key

=back

For more information, see L<IO::Socket::SSL>.

=head1 FAILOVER

The C<uri> option of L<Net::STOMP::Client>'s new() method can be given a
complex URI indicating some kind of failover, for instance:
C<failover:(tcp://msg01:6163,tcp://msg02:6163)>.

The given URI must use the ActiveMQ failover syntax (see
L<http://activemq.apache.org/failover-transport-reference.html>) and only
some options are supported, namely: C<backOffMultiplier>,
C<initialReconnectDelay>, C<maxReconnectAttempts>, C<maxReconnectDelay>,
C<randomize> and C<useExponentialBackOff>.

When specified, these failover options will be used only inside the new()
method (so at the TCP connection level) and not elsewhere. If the broker
later fails during the STOMP interaction, it is up to the program author,
knowing the logic of his code, to perform the appropriate recovery actions
and eventually reconnect, using again the new() method.

=head1 SEE ALSO

L<IO::Socket::INET>,
L<IO::Socket::SSL>,
L<Net::STOMP::Client>.

=head1 AUTHOR

Lionel Cons L<http://cern.ch/lionel.cons>

Copyright (C) CERN 2010-2017
