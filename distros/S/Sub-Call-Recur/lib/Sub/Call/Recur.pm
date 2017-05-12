package Sub::Call::Recur;

use strict;
use warnings;

require 5.008001;
use parent qw(Exporter DynaLoader);
use B::Hooks::OP::Check::EntersubForCV;

our $VERSION = '0.04';
$VERSION = eval $VERSION;

our @EXPORT = our @EXPORT_OK = qw(recur);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

__PACKAGE__->bootstrap($VERSION);

pop our @ISA;

# ex: set sw=4 et:

__PACKAGE__

__END__

=pod

=head1 NAME

Sub::Call::Recur - Self recursive tail call invocation.

=head1 SYNOPSIS

    sub fact {
        my ( $n, $accum ) = @_;

        $accum ||= 1;

        if ( $n == 0 ) {
            return $accum;
        } else {
            recur( $n - 1, $n * $accum );
        }
    }

=head1 DESCRIPTION

This module implements Clojure's C<recur> special form.

C<recur> is a tail call to the current function. It is a bit like assigning the
arguments to C<@_> and invoking a C<goto> to the first expression of the
subroutine.

It can be thought of as the C<redo> operator, but for subroutines instead of
loops.

This form allows functional style looping with constant stack space.

=head1 SEE ALSO

L<Sub::Call::Tail>

L<B::Hooks::OP::Check::EntersubForCV>

=head1 VERSION CONTROL

L<http://github.com/nothingmuch/Sub-Call-Recur>

=head1 AUTHOR

Yuval Kogman

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2009 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
