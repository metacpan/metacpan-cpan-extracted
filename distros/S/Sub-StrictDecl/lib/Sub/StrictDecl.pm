=head1 NAME

Sub::StrictDecl - detect undeclared subroutines in compilation

=head1 SYNOPSIS

	use Sub::StrictDecl;

	no Sub::StrictDecl;

=head1 DESCRIPTION

This module provides optional checking of subroutine existence at
compile time.  This checking detects mistyped subroutine names and
subroutines that the programmer forgot to import.  Traditionally Perl
does not detect these errors until runtime, so it is easy for errors to
lurk in rarely-executed or untested code.

Specifically, where checking is enabled, any reference to a specific
(compile-time-constant) package-based subroutine name is examined.  If the
named subroutine has never been declared then an error is signalled
at compile time.  This does not require that the subroutine be fully
defined: a forward declaration such as "C<sub foo;>" suffices to suppress
the error.  Imported subroutines qualify as declared.  References that
are checked include not only subroutine calls but also pure referencing
such as "C<\&foo>".

This checking is controlled by a lexically-scoped pragma.  It is
therefore applied only to code that explicitly wants the checking, and
it is possible to locally disable checking if necessary.  Checking might
need to be turned off for code that makes special arrangements to put
a subroutine in place at runtime, for example.

=cut

package Sub::StrictDecl;

{ use 5.006; }
use Lexical::SealRequireHints 0.008;
use warnings;
use strict;

our $VERSION = "0.005";

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head1 PACKAGE METHODS

=over

=item Sub::StrictDecl->import

Turns on subroutine declaration checking in the lexical environment that
is currently compiling.

=item Sub::StrictDecl->unimport

Turns off subroutine declaration checking in the lexical environment
that is currently compiling.

=back

=head1 SEE ALSO

L<Perl::Critic::StricterSubs>,
L<strict>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2011 PhotoBox Ltd

Copyright (C) 2011, 2015, 2017 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
