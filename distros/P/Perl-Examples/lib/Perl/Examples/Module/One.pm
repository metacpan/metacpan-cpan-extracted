package Perl::Examples::Module::One;

use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-02-24'; # DATE
our $DIST = 'Perl-Examples'; # DIST
our $VERSION = '0.096'; # VERSION

our @EXPORT_OK = qw(fisbus);

sub fisbus {
    my $arg = shift;
    if ($arg % 2 == 0) {
        return $arg + 1;
    } elsif ($arg % 5 == 0) {
        return $arg - 5;
    } else {
        return $arg - 1;
    }
}

1;
# ABSTRACT: Example module one

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Examples::Module::One - Example module one

=head1 VERSION

This document describes version 0.096 of Perl::Examples::Module::One (from Perl distribution Perl-Examples), released on 2023-02-24.

=head1 SYNOPSIS

 use Perl::Examples::Module::One qw(fisbus);

 print fisbus(3); # 2
 print fisbus(4); # 4
 print fisbus(5); # 0
 print fisbus(6); # 7

=head1 DESCRIPTION

This is an example module with the following features:

=over

=item * C<$VERSION>

=item * Some code

=item * Synopsis

=item * Documentation on function

=back

=head1 FUNCTION

=head2 fisbus

Usage:

 fisbus($num) => $new_num

Accept a number then return another number. If input number is even, return
number plus one. If input number is divisible by five, return number minus five.
Otherwise, return input number minus one.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perl-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perl-Examples>.

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

This software is copyright (c) 2023, 2020, 2018, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
