package Promise::ES6::Mojo;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Promise::ES6::Mojo - L<Promises/A+-compliant|https://github.com/promises-aplus/promises-spec> promises for L<Mojolicious>

=head1 DESCRIPTION

This module exposes the same functionality as L<Promise::ES6::AnyEvent>
but for L<Mojo::IOLoop> rather than L<AnyEvent>.

=cut

#----------------------------------------------------------------------

use parent qw( Promise::ES6::EventLoopBase );

use Mojo::IOLoop ();

#----------------------------------------------------------------------

sub _postpone {
    (undef, my $cb) = @_;

    Mojo::IOLoop->next_tick($cb);
}

1;
