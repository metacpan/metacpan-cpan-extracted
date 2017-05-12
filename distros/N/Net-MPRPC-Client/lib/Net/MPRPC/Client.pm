package Net::MPRPC::Client;
use strict;
use warnings;

our $VERSION = '0.02';

use IO::Select;
use IO::Socket::INET;

our $_HAVE_UNIX_SOCKET = 1;
eval q[use IO::Socket::INET; 1];
if ($@) { $_HAVE_UNIX_SOCKET = 0 }

use Try::Tiny;
use Carp;
use Data::MessagePack;

use constant MP_REQ_TYPE   => 0;
use constant MP_RES_ERROR  => 2;
use constant MP_RES_RESULT => 3;

sub new {
    my $class = shift;
    my $args  = @_ > 1 ? {@_} : $_[0];

    $args->{_id} = 0;
    $args->{timeout} ||= 30;
    $args->{_error} = q[];

    bless $args, $class;
}

sub connect {
    my $self = shift;
    my $args = @_ > 1 ? {@_} : $_[0];

    $self->disconnect if $self->{_sock};

    my $host = $args->{host} || $self->{host};
    my $port = $args->{post} || $self->{port};

    croak q[Required "host" parameter to connect] unless $host;
    croak q[Required "port" parameter to connect] unless $port;

    my $sock;
    try {
        if ($host eq 'unix/') {
            if (!$_HAVE_UNIX_SOCKET) {
                croak "This environment doesn't support UNIX socket";
            }

            $sock = IO::Socket::UNIX->new(
                Peer    => $port,
                Timeout => $self->{timeout},
            ) or die qq/Unable to connect unix socket "$port": $!/;
        }
        else {
            $sock = IO::Socket::INET->new(
                PeerAddr => $host,
                PeerPort => $port,
                Proto    => 'tcp',
                Timeout  => $self->{timeout},
            ) or die qq/Unable to connect "${host}:${port}": $!/;
        }

        $sock->autoflush(1);
        $self->{_sock} = $sock;
    } catch {
        $self->{_error} = $_;
    };

    return !!$self->{_sock};
}

sub disconnect {
    delete $_[0]->{_sock};
}

sub call {
    my ($self, $method, $param) = @_;

    $self->{_error} = q[];
    return unless $self->{_sock} or $self->connect;

    my $sock = $self->{_sock};
    my $req  = [
        MP_REQ_TYPE, ++$self->{_id},
        $method, $param,
    ];
    $sock->print(Data::MessagePack->pack($req));

    my $timeout = $sock->timeout;
    my $limit   = time + $timeout;
    my $buf     = q[];

    my $select = IO::Select->new or croak $!;
    $select->add($sock);

    my $unpacker = Data::MessagePack::Unpacker->new;
    my $nread    = 0;

    while ($limit >= time) {
        my @ready = $select->can_read( $limit - time )
            or last;

        croak q/Fatal error on select, $ready[0] isn't $sock/
            if $sock ne $ready[0];

        unless (my $l = $sock->sysread($buf, 512, length $buf)) {
            my $e = $!;
            $self->disconnect;
            croak qq/Error reading socket: $e/;
        }

        try {
            $nread = $unpacker->execute($buf, $nread);
        } catch {
            $self->{_error} = $_;
            $self->disconnect;
            $unpacker->reset;
        };
        return if $self->{_error};

        if ($unpacker->is_finished) {
            my $res = $unpacker->data;
            $unpacker->reset;

            unless ($res and ref $res eq 'ARRAY') {
                $self->{_error} = 'Invalid response from server';
                $self->disconnect;
                return;
            }

            if (my $error = $res->[MP_RES_ERROR]) {
                $self->{_error} = $error;
                return;
            }

            return $res->[MP_RES_RESULT];
        }
    }

    $self->disconnect;
    croak 'request timeout';
}

sub error {
    $_[0]->{_error};
}

1;

__END__

=for stopwords MessagePack RPC MessagePack-RPC Str hostname unix prefork

=head1 NAME

Net::MPRPC::Client - Synchronous MessagePack RPC client

=head1 SYNOPSIS

    use Net::MPRPC::Client;
    
    my $client = Net::MPRPC::Client->new(
        host => '127.0.0.1',
        port => 4423,
    );
    
    # or unix socket:
    my $client = Net::MPRPC::Client->new(
        host => 'unix/',
        port => '/tmp/mprpc.sock',
    );
    
    # call method "echo" with argument "foo bar"
    my $res = $client->call( echo => "foo bar" )
        or die $client->error;

=head1 DESCRIPTION

This module is a simple synchronous MessagePack-RPC client, designed to use in synchronous application (e.g. prefork server)
For asynchronous version of this module, take a look at L<AnyEvent::MPRPC::Client>.

=head1 METHODS

=head2 new(%parameters)

    my $client = Net::MPRPC::Client->new(
        host => '127.0.0.1',
        port => 4423,
    );
    
    # or unix socket:
    my $client = Net::MPRPC::Client->new(
        host => 'unix/',
        port => '/tmp/mprpc.sock',
    );

Create and return client object.
Available parameters are:

=over 4

=item * host => 'Str' (Required)

MessagePack-RPC server's hostname to connect.
If you want to use unix domain socket, this parameter should be "unix/".

=item * port => 'Int | Str' (Required)

MessagePack-RPC server's port or UNIX socket path to connect.

=item * timeout => 'Int'

Timeout (second) to connect. Default value is 30 seconds.

=back

=head2 call($method, $parameter)

    my $res = $client->call( echo => "foo bar" )
        or die $client->error;

Call RPC method and return result.

If remote server return some errors, this method return undef. You can get error message by C<error> method.
When something other error (network error or etc) occurred, this method throw exception.

=head2 error()

Return error messages. Return empty string when there's no error.

=head2 connect

=head2 disconnect

Connect to and disconnect from server. This method automatically called from C<call> method.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
