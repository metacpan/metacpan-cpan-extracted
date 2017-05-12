
package Redirx::Client;

use 5.006;
use fields qw(socket host port timeout debug);
use strict;
use warnings;
use IO::Socket ();

our $VERSION = '0.01';

use constant DEFAULT_HOST    => 'redirx.com';
use constant DEFAULT_PORT    => 5313;
use constant DEFAULT_TIMEOUT => 5;

use constant CMD_PING        => 'PING';
use constant RES_PONG        => 'PONG';

use constant STATUS_ERROR    => 'ERROR';
use constant STATUS_OK       => 'OK';

sub new {
    my $self = shift;
    my $args = shift;

    $self = fields::new($self) unless ref $self;
    $self->{socket}  = undef;
    $self->{host}    = DEFAULT_HOST;
    $self->{port}    = DEFAULT_PORT;
    $self->{timeout} = DEFAULT_TIMEOUT;

    $self->connect($args);

    return $self;
}

sub connect {
    my $self = shift;
    my $args = shift;

    if (! $self->ping()) {
        if ($args) {
            $self->{host}     = $args->{Host}    if $args->{Host};
            $self->{port}     = $args->{Port}    if $args->{Port};
            $self->{timeout}  = $args->{Timeout} if $args->{Timeout};
            $self->{debug}    = $args->{Debug};
        }

        # open the persistent connection
        my $serverUrl =
            sprintf("redirx://%s:%s", $self->{host}, $self->{port});

        eval {
            $self->_debug("Connecting to: $serverUrl");
            $self->{socket} =
                IO::Socket::INET->new(PeerHost => $self->{host},
                                      PeerPort => $self->{port},
                                      Timeout  => $self->{timeout});
        };
        if ($@) {
            die "Unable to connect to $serverUrl: $@\n";
        }
        if (! $self->{socket}) {
            die "No response from $serverUrl\n";
        }

        # negotiate the protocol
        my $proto = $self->_getline();
        $self->_debug("Received protocol: $proto");
        unless ($proto =~ /^REDIRXD V\d+.\d+$/) {
            die "Bad protocol: $proto\n";
        }
    }

    return 1;
}

sub ping {
    my $self = shift;

    if ($self->_connected()) {
        # send PING
        $self->_debug(sprintf("Sending cmd: %s", CMD_PING));
        $self->_print(CMD_PING);

        # receive PONG
        my $res = $self->_getline();
        $self->_debug("Received response: $res");
        return $res eq RES_PONG;
    }

    return undef;
}

sub storeUrl {
    my $self = shift;
    my $url = shift or
        die "No url to store\n";

    $self->connect();

    # send URL
    $self->_debug("Sending URL $url");
    $self->_print($url);

    # receive response
    my $res = $self->_getline();
    my ($status, $msg) = split /\s+/, $res;
    $self->_debug("Received response: $status: $msg");
    if ($status eq STATUS_ERROR) {
        die "Error: $msg\n";
    }
    elsif ($status ne STATUS_OK) {
        die "Bad response: status: $res";
    }

    return $msg; # this is the redirx url
}

sub _connected {
    my $self = shift;

    return $self->{socket} && $self->{socket}->connected();
}

sub _debug {
    my $self = shift;
    my $str = shift or
        return undef;

    warn "$str\n" if $self->{debug};
}

sub _getline {
    my $self = shift;

    $self->{socket} or
        die "Can't read from closed connection\n";
    my $line = $self->{socket}->getline();
    chomp $line;

    return $line;
}

sub _print {
    my $self = shift;
    my $line = shift or
        die "No line to print\n";

    $self->{socket} or
        die "Can't print to closed connection\n";
    $self->{socket}->print("$line\n");
}

1;
__END__

=head1 NAME

Redirx::Client - Client API for the redirx protocol

=head1 SYNOPSIS

  use Redirx::Client;

=head1 DESCRIPTION

This module provides a client API for the redirx protocol. It is
descended from the original I<RedirxClient> module written by Aaron
Gowatch.

=head1 AUTHOR

Brian Moseley E<lt>bcm-nospam@maz.org<gt>

=head1 SEE ALSO

L<perl>.

=cut
