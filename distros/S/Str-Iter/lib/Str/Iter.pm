package Str::Iter;

use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-11-10'; # DATE
our $DIST = 'Str-Iter'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(str_iter);

sub str_iter {
    my ($str,  $n) = @_;
    $n = 1 unless defined $n;

    my $pos = 0;
    sub {
        if ($pos < length($str)) {
            my $substr = substr($str, $pos, $n);
            $pos += $n;
            return $substr;
        } else {
            return undef; ## no critic: Subroutines::ProhibitExplicitReturnUndef
        }
    };
}

1;
# ABSTRACT: Generate a coderef iterator to iterate a string one (or more) character(s) at a time

__END__

=pod

=encoding UTF-8

=head1 NAME

Str::Iter - Generate a coderef iterator to iterate a string one (or more) character(s) at a time

=head1 VERSION

This document describes version 0.001 of Str::Iter (from Perl distribution Str-Iter), released on 2024-11-10.

=head1 SYNOPSIS

  use Str::Iter qw(str_iter);

  my $iter = str_iter("abc0123"); # iterate one character at a time
  while (defined(my $char = $iter->())) { ... } # a, b, c, 0, 1, 2, 3

  my $iter = str_iter("abc0123", 2); # iterate two characters at a time
  while (defined(my $substr = $iter->())) { ... } # ab, c0, 12, 3

=head1 DESCRIPTION

This module provides a simple iterator which is a coderef that you can call
repeatedly to get characters from a string. When the characters are exhausted,
the coderef will return undef. No class/object involved.

=for Pod::Coverage .+

=head1 FUNCTIONS

=head2 str_iter

Usage:

 ($str [ , $num_chars=1 ]) => coderef

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Str-Iter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Str-Iter>.

=head1 SEE ALSO

Other C<::Iter> modules e.g. L<Array::Iter>, L<Hash::Iter>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Str-Iter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
