package Perinci::CLI;

our $DATE = '2015-09-03'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::CmdLine::Any -prefer_lite => 1;

sub import {
    my $class = shift;
    my $url = shift
        or die "Please specify URL as import argument to Perinci::CLI";
    Perinci::CmdLine::Any->new(url => $url)->run;
}

1;
# ABSTRACT: Run Perinci::CmdLine app as one-liner

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CLI - Run Perinci::CmdLine app as one-liner

=head1 VERSION

This document describes version 0.02 of Perinci::CLI (from Perl distribution Perinci-CLI), released on 2015-09-03.

=head1 SYNOPSIS

 % perl -MPerinci::CLI=/URL/To/Your/Function

which is a shortcut for:

 use Perinci::CmdLine::Any -prefer_lite=>1;
 Perinci::CmdLine::Any->new(url => '/URL/To/Your/Function')->run;

To specify options/arguments to your CLI:

 % perl -MPerinci::CLI=/URL/To/Your/Function -E1 -- --opt1 val arg

=head1 DESCRIPTION

=for Pod::Coverage ^(import)$

=head1 SEE ALSO

L<Perinci::CmdLine::Any>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CLI>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CLI>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CLI>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
