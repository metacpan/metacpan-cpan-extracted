## no critic (Modules::ProhibitAutomaticExportation)

package Term::ANSIColor::WithWin32;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-21'; # DATE
our $DIST = 'Term-ANSIColor-WithWin32'; # DIST
our $VERSION = '0.002'; # VERSION

use strict 'subs', 'vars';
use warnings;

if ($^O =~ /^(MSWin32)$/) { require Win32::Console::ANSI }

use Term::ANSIColor (); # XXX color() & colored() still imported?
no warnings 'redefine';

sub import {
    my $pkg = shift;
    Term::ANSIColor->export_to_level(1, @_);
}

1;
# ABSTRACT: Use Term::ANSIColor and load Win32::Console::ANSI on Windows

__END__

=pod

=encoding UTF-8

=head1 NAME

Term::ANSIColor::WithWin32 - Use Term::ANSIColor and load Win32::Console::ANSI on Windows

=head1 VERSION

This document describes version 0.002 of Term::ANSIColor::WithWin32 (from Perl distribution Term-ANSIColor-WithWin32), released on 2020-03-21.

=head1 SYNOPSIS

Use as you would L<Term::ANSIColor>.

=head1 DESCRIPTION

This module is a thin wrapper for L<Term::ANSIColor>. It loads
L<Win32::Console::ANSI> on Windows (an extra step needed to make ANSI escape
codes work). The rest is identical with Term::ANSIColor.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Term-ANSIColor-WithWin32>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Term-ANSIColor-WithWin32>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Term-ANSIColor-WithWin32>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Term::ANSIColor>

L<Win32::Console::ANSI>

L<Term::ANSIColor::Conditional> now also tries to load Win32::Console::ANSI on
Windows.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
