package Syntax::Infix::EqualityInsensitive;

use 5.038;
use strict;
use warnings;

use Infix::Custom ();

our $VERSION = '0.03';

require XSLoader;
XSLoader::load('Syntax::Infix::EqualityInsensitive', $VERSION);

sub import {
    Infix::Custom->import(
        op       => 'eqi',
        build_op => _eqi_build_op_addr(),
        prec     => 'rel',
    );
    Infix::Custom->import(
        op       => 'nei',
        build_op => _nei_build_op_addr(),
        prec     => 'rel',
    );
}

sub unimport {
    Infix::Custom->unimport('eqi');
    Infix::Custom->unimport('nei');
}

1;

__END__

=head1 NAME

Syntax::Infix::EqualityInsensitive - case-insensitive C<eqi> and C<nei> infix operators

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Syntax::Infix::EqualityInsensitive;

    if ($input eqi 'yes') { ... }        # true for 'YES', 'Yes', 'yes', ...
    if ($status nei 'OK') { ... }        # true unless case-insensitively 'ok'

    # correct Unicode case-folding
    use utf8;
    say 'match' if "Stra\x{df}e" eqi 'STRASSE';   # German sharp-s

=head1 DESCRIPTION

Installs two lexically-scoped infix operators for B<Unicode case-insensitive
string comparison>:

=over 4

=item C<$a eqi $b>

True if C<$a> and C<$b> are equal under Unicode case-folding (C<fc>).

=item C<$a nei $b>

True if C<$a> and C<$b> are B<not> equal under Unicode case-folding.

=back

Both operators sit at C<rel> precedence (peer of C<eq> and C<ne>) and are
non-associative.

=head2 Implementation

Both operands are upgraded to UTF-8 and compared with C<foldEQ_utf8> - the
same case-folding routine Perl uses for C</i> regex matching and the built-in
C<fc> function. This gives correct Unicode case-folding rather than the
ASCII-only C<lc>/C<tolower> approach.

Each operator lowers to a custom C<OP_CUSTOM> C<BINOP> via
L<Infix::Custom>'s C<build_op> escape hatch; there is no C<ENTERSUB> wrapper
at runtime.

=head2 Lexical scope

Active only inside the file or block that C<use>d the module.
C<no Syntax::Infix::EqualityInsensitive> removes both operators early.

=head2 Perl version

Requires Perl 5.38 or newer (the C<PL_infix_plugin> hook used by
L<Infix::Custom>).

=head1 SEE ALSO

L<Infix::Custom>, L<Syntax::Infix::Coalesce>, L<Syntax::Infix::OptionalChain>,
L<Syntax::Infix::ConditionalSplice>

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION C<< <email@lnation.org> >>.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
