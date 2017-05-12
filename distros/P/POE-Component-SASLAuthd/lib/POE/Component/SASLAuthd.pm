package POE::Component::SASLAuthd;

use warnings;
use strict;

use Carp qw(carp croak);

use POE::Session;
use POE::Wheel::ReadWrite;
use POE::Filter::Line;

=head1 NAME

POE::Component::SASLAuthd - Implement the Cyrus SASL authdaemond daemon.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

The authdaemond provides authenticaiton services for various network services.
Cyrus IMAP server, Exim, Postfix and probably several other products support
authentication via the authdaemon interface.

A simple authentication daemon is provided below as an example:

    use strict;

    use POE::Session;
    use POE::Wheel::SocketFactory;
    use Socket;

    use POE::Component::SASLAuthd;

    POE::Session->create(
        inline_states => {
            _start => sub {
                my ($kernel, $heap) = @_[KERNEL, HEAP];

                my $sock = '/var/state/saslauthd/mux';

                unlink $sock if -e $sock;
                $heap->{'server'} = POE::Wheel::SocketFactory->new(
                    BindAddress => $sock,
                    SocketDomain => AF_UNIX,
                    SocketType => SOCK_STREAM,
                    SuccessEvent => 'handle_accept',
                    FailureEvent => 'handle_error',
                );
                chmod 0777, $sock;
            },
            _stop => sub { my ($kernel, $heap) = @_[KERNEL, HEAP];
                           warn "stop! ($heap->{'server'})\n" },
            handle_accept => sub {
                my ($kernel, $heap, $handle) = @_[KERNEL, HEAP, ARG0];

                POE::Component::SASLAuthd->spawn($handle, sub {
                    my $username = shift;
                    my $password = shift;
                    my $service = shift;
                    my $realm = shift;

                    return 0 if $password eq 'snakk';
                    return 1 if $username eq 'snik';
                    return 0;
                });
            },
            handle_error => sub {
                ### do something
            }
        }
    );

    POE::Kernel->run();

=head1 METHODS

=head2 spawn($socket, sub { ... })

This is a class method, invoked as

    POE::Component::SASLAuthd->spawn($handle, $code)

This method accepts two arguments - the first one is the socket handle that
cares the connection to the client, the second one is a code reference that
performs the authentication itself. The code is called with following arguments

    $username, $password, $service, $realm

The authentication will be allowed if the code returns true and denied
otherwise.

=cut

sub spawn {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    POE::Session->create(package_states => [$class, ['_start']], args => [@_]);
}


=head1 AUTHOR

Kirill Miazine, C<< <km@krot.org> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::SASLAuthd


You can also look for information at:


=head1 COPYRIGHT & LICENSE

Copyright 2008 Kirill Miazine, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    my ($handle, $auth_hook) = @_[ARG0, ARG1];

    $handle->blocking(1); # XXX Shall be made non-blocking at a later stage
    my $username = _sasl_string($handle);
    my $password = _sasl_string($handle);
    my $service = _sasl_string($handle);
    my $realm = _sasl_string($handle);

    return $auth_hook->($username, $password, $service, $realm) ?
        _sasl_allow($handle) :
        _sasl_deny($handle);
}

sub _sasl_string {
    my $buf;
    $_[0]->read($buf, 2);
    my $size = unpack('n', $buf);
    $_[0]->read($buf, $size);
    return unpack("A$size", $buf);
}

sub _sasl_allow {
    $_[0]->print(pack('nA3', 2, "OK\0"));
    $_[0]->close();
}

sub _sasl_deny {
    $_[0]->print(pack('nA3', 2, "NO\0"));
    $_[0]->close();
}

1; # End of POE::Component::SASLAuthd
