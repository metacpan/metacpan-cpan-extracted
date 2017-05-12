# $Id: BlogCloud.pm 1783 2005-01-09 05:44:52Z btrott $

package POE::Component::BlogCloud;
use strict;

use POE qw( Component::Client::TCP );
use XML::SAX::ParserFactory;
use POE::Component::BlogCloud::SAXHandler;
use POE::Component::BlogCloud::Update;

use constant DEFAULT_HOST => 'ping.blo.gs';
use constant DEFAULT_PORT => 9999;

our $VERSION = '0.01';

sub spawn {
    my $class = shift;
    my %param = @_;
    $param{ReceivedUpdate}
        or return $class->error("ReceivedUpdate not supplied");
    my $alias = $param{Alias} || 'cloud';

    ## Create the TCP client.
    POE::Component::Client::TCP->new(
        RemoteAddress => $param{RemoteAddress} || DEFAULT_HOST,
        RemotePort    => $param{RemotePort} || DEFAULT_PORT,
        Alias         => "poco_${alias}_tcp_client",
        Started       => \&start,
        ServerInput   => \&server_input,
        $param{AutoReconnect} ? (ServerError => \&server_error) : (),
        InlineStates  => {
            got_update => sub { $param{ReceivedUpdate}->(@_) },
        },
    );
}

sub start {
    my($kernel, $heap, $cb) = @_[ KERNEL, HEAP, ARG0 ];
    my $h = POE::Component::BlogCloud::SAXHandler->new;
    $h->{kernel} = $kernel;
    $heap->{parser} = XML::SAX::ParserFactory->parser( Handler => $h );
}

sub server_input {
    my($heap, $input) = @_[ HEAP, ARG0 ];
    return unless $input;
    $heap->{parser}->parse_string($input);
}

sub server_error {
    my($kernel, $heap) = @_[ KERNEL, HEAP ];
    print STDERR "Got an error... reconnecting in 60 seconds.\n";
    ## Automatic reconnect after 60 seconds.
    $kernel->delay( reconnect => 60 );
}

1;
__END__

=head1 NAME

POE::Component::BlogCloud - Client interface to blo.gs streaming cloud server

=head1 SYNOPSIS

    use POE qw( Component::BlogCloud );
    POE::Component::BlogCloud->spawn(
        ReceivedUpdate => sub {
            my($update) = $_[ ARG0 ];
            ## $update is a POE::Component::BlogCloud::Update object.
        },
    );

=head1 DESCRIPTION

I<POE::Component::BlogCloud> is a client interface to the I<blo.gs>
streaming cloud server, described at I<http://blo.gs/cloud.php>. It's
built using the L<POE> framework for Perl, allowing you to build an
event-based application that receives weblog updates, then acts upon them.

=head1 USAGE

=head2 POE::Component::BlogCloud->spawn( %arg )

=over 4

=item * ReceivedUpdate

The callback to execute when an update from the streaming server is
received. ARG0 contains a I<POE::Component::BlogCloud::Update> that
represents the update information.

This argument is required.

=item * AutoReconnect

If the client is disconnected from the streaming server because of an error,
it can be told to automatically try to reconnect by setting I<AutoReconnect>
to C<1>.

This argument is optional, and if not specified defaults to C<0>, meaning
that the client will not automatically reconnect.

=item * RemoteAddress

The address of the streaming server to connect to.

This argument is optional, and if not specified defaults to C<ping.blo.gs>.

=item * RemotePort

The port where the streaming server is running.

This argument is optional, and if not specified defaults to C<9999>.

=back

=head1 CAVEATS

The specification for the streaming server indicates that gzip compression
will be turned on at some point, at which point an update to this module
will be needed.

In addition, the blo.gs server does sometimes seem to get "stuck" and stop
sending updates, which will be indicated by the client hanging waiting
for an update. There's not much that can be done about this from the client
side.

=head1 LICENSE

I<POE::Component::BlogCloud> is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, I<POE::Component::BlogCloud> is
Copyright 2005 Benjamin Trott, ben+cpan@stupidfool.org. All rights reserved.

=cut
