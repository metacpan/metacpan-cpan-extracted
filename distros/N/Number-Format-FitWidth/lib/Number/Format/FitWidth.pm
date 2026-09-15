package Number::Format::FitWidth;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
use List::Util qw(max);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-06-26'; # DATE
our $DIST = 'Number-Format-FitWidth'; # DIST
our $VERSION = '0.002'; # VERSION

our @EXPORT_OK = qw(
                       format_fitwidth
               );

sub format_fitwidth {
    my $opts = ref($_[0]) eq 'HASH' ? {%{shift()}} : {};
    # use DD; dd $opts;

    return unless @_;
    my @nums = @_;

    my $width = length(($opts->{max} // max(@nums)) + 0);

    my $template = "%".($opts->{zero_prefix} ? "0" : "").$width."d";
    #print "D: template=<$template>\n";

    map { sprintf($template, $_) } @nums;
}

1;
# ABSTRACT: Pad all number(s) to the same width that will fit the widest number

__END__

=pod

=encoding UTF-8

=head1 NAME

Number::Format::FitWidth - Pad all number(s) to the same width that will fit the widest number

=head1 VERSION

This document describes version 0.002 of Number::Format::FitWidth (from Perl distribution Number-Format-FitWidth), released on 2026-06-26.

=head1 SYNOPSIS

 use Number::Format::FitWidth qw(format_fitwidth);

 format_fitwidth(1, 2, 10, 12);                     # => (" 1", " 2", "10", "12")
 format_fitwidth(1, 10, 100);                       # => ("  1", " 10", "100")

 # zero_prefix option
 format_fitwidth({zero_prefix=>1}, 1, 10, 100);     # => ("001", "010", "100")

 # max option
 format_fitwidth({max=>9999}, 1);                   # => ("   1")


 # TODO: decimals, negative number

 # TODO: thousands_sep option

 # TODO: decimal_point option

 # TODO: decimal_digits option

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 format_fitwidth

This is basically a glorified C<sprintf()> which will determine the width for
you. There are some conveniences (some not yet implemented) e.g. handling
decimal numbers, negative numbers, specifying maximum and minimum instead of
getting from the arguments, etc.

Usage:

 @formatted = format_fitwidth( [ \%opts, ] @numbers)

Options:

=over

=item * max

=item * zero_prefix

Boolean.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Number-Format-FitWidth>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Number-Format-FitWidth>.

=head1 SEE ALSO

Other C<Number::Format::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords perlancar

perlancar <perlancar@gmail.com>

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

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Number-Format-FitWidth>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
