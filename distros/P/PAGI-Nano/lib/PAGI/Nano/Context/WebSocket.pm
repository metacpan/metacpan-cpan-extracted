package PAGI::Nano::Context::WebSocket;
$PAGI::Nano::Context::WebSocket::VERSION = '0.001000';
use strict;
use warnings;
use parent -norequire, 'PAGI::Context::WebSocket', 'PAGI::Nano::Context';
use PAGI::Context;             # base declares @ISA but does not load it
use PAGI::Context::WebSocket;
use PAGI::Nano::Context;       # the shared mixin (uri_for)

# The WebSocket context Nano vends: a genuine PAGI::Context::WebSocket (so
# $c->websocket and the rest of the WS API work) plus the shared Nano behavior,
# notably $c->uri_for for building links from WS handlers. Blessed directly so
# the base factory's scope-type resolution does not down-cast us.

sub new {
    my ($class, $scope, $receive, $send) = @_;
    return bless {
        scope   => $scope,
        receive => $receive,
        send    => $send,
    }, $class;
}

1;

=encoding utf8

=head1 NAME

PAGI::Nano::Context::WebSocket - The WebSocket context vended by PAGI::Nano

=head1 DESCRIPTION

A subclass of L<PAGI::Context::WebSocket> (so C<< $c->websocket >> and the full
WebSocket API are available) that also mixes in L<PAGI::Nano::Context>, giving
WebSocket handlers C<< $c->uri_for >> for link generation.

=head1 SEE ALSO

L<PAGI::Nano>, L<PAGI::Nano::Context>, L<PAGI::Context::WebSocket>.

=head1 AUTHOR

John Napiorkowski C<< <jjnapiork@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2026, John Napiorkowski. This library is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
