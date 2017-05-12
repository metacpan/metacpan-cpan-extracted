package MsgPack::RPC::Message::Request;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: a MessagePack-RPC request
$MsgPack::RPC::Message::Request::VERSION = '1.0.1';

use strict;
use warnings;

use Moose;

use Promises qw/ deferred /;

extends 'MsgPack::RPC::Message';

has message_id => (
    is => 'ro',
);

has response => (
    is => 'ro',
    default => sub {
        my $self = shift;
        my $deferred = deferred;

        $deferred->then(
            sub{ $self->emitter->response($self->message_id,shift) },
            sub{ $self->emitter->response_error($self->message_id,shift) },
        );

        $deferred;
    },
    handles => {
        resp  => 'resolve',
        error => 'reject',
    }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MsgPack::RPC::Message::Request - a MessagePack-RPC request

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

    use MsgPack::RPC;

    my $rpc = MsgPack::RPC->new( io => '127.0.0.1:6543' );

    $rpc->emit( some_request => 'MsgPack::RPC::Message::Request', args => [ 1..5 ] );

=head1 DESCRIPTION

Sub-class of L<MsgPack::RPC::Message> representing an incoming request.

=head1 METHODS

=head2 new( args => $args, message_id => $id ) 

Accepts the same argument as L<MsgPack::RPC::Message>, plus C<message_id>,
the id of the request.

=head2 response

Returns a L<Promises::Deferred> that, once fulfilled, sends the response back with the provided arguments.

    $rpc->subscribe( something => sub {
        my $request = shift;
        $request->response->resolve('a-okay');
    });

=head2 resp($args)

Shortcut for

    $request->response->resolve($args)

=head2 error($args)

Shortcut for

    $request->response->reject($args)

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
