package Syntax::Infix::ConditionalSplice;

use 5.038;
use strict;
use warnings;

use Infix::Custom ();

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Syntax::Infix::ConditionalSplice', $VERSION);

sub import {
    Infix::Custom->import(
        op       => '?|',
        build_op => _build_op_addr(),
        prec     => 'assign',
    );
}

sub unimport {
    Infix::Custom->unimport('?|');
}

1;

__END__

=head1 NAME

Syntax::Infix::ConditionalSplice - a short-circuiting C<< ?| >> operator for conditional list elements

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Syntax::Infix::ConditionalSplice;

    my @cmd = (
        'prog',
        $verbose   ?| '--verbose',          # included only when $verbose
        $jobs > 1  ?| ('--jobs', $jobs),     # a whole sub-list, conditionally
        @files,
    );

    # equivalent, without the operator:
    my @cmd = (
        'prog',
        ($verbose  ? ('--verbose')       : ()),
        ($jobs > 1 ? ('--jobs', $jobs)   : ()),
        @files,
    );

=head1 DESCRIPTION

Installs a lexically scoped infix operator C<< ?| >> for B<conditionally
splicing elements into a list>. C<< COND ?| LIST >> evaluates to C<LIST> when
C<COND> is true and to the empty list C<()> otherwise -- it is exactly
C<< COND ? LIST : () >>, but reads as one quiet element in the middle of a list
instead of a parenthesised ternary with an easily-forgotten C<: ()> tail.

Two properties make it more than sugar a function could provide, and are the
reason it is built on L<Infix::Custom>'s C-level C<build_op> escape hatch:

=over 4

=item * B<It short-circuits.> C<LIST> is only evaluated when C<COND> is true, so
C<< $want ?| expensive() >> never calls C<expensive()> unless C<$want>. A
function call cannot do this -- its arguments are all evaluated first.

=item * B<It is context-aware.> In list context the true branch flattens its
list into the surrounding one; in scalar context C<< COND ?| LIST >> yields the
list's last value (or C<undef> when false), just like the ternary it mirrors.

=back

The entire implementation is one line of C -- a C<COND_EXPR> whose false branch
is the empty-list stub:

    return newCONDOP(0, lhs, rhs, newOP(OP_STUB, 0));

=head2 Precedence

C<< ?| >> binds at assignment precedence: tighter than comma (so
C<< $c ?| 'x' >> is a single list element) but looser than the comparison and
logical operators (so the condition can be written without parentheses, e.g.
C<< $n > 3 ?| '--big' >> or C<< $a && $b ?| $x >>). To make I<several>
elements conditional, parenthesise the right-hand side: C<< $c ?| ('a', 'b') >>.

=head2 Perl version

Requires perl 5.38 or newer (the C<PL_infix_plugin> hook L<Infix::Custom> builds
on); it does not install on older perls.

=head1 SEE ALSO

L<Infix::Custom>, L<Syntax::Infix::OptionalChain>

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
