package Perinci::Sub::Util::ResObj;

our $DATE = '2020-10-20'; # DATE
our $VERSION = '0.470'; # VERSION

use Carp;
use overload
    q("") => sub {
        my $res = shift; "ERROR $err->[0]: $err->[1]\n" . Carp::longmess();
    };

1;
# ABSTRACT: An object that represents enveloped response suitable for die()-ing

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Util::ResObj - An object that represents enveloped response suitable for die()-ing

=head1 VERSION

This document describes version 0.470 of Perinci::Sub::Util::ResObj (from Perl distribution Perinci-Sub-Util), released on 2020-10-20.

=head1 SYNOPSIS

Currently unused. See L<Perinci::Sub::Util>'s C<warn_err> and C<die_err>
instead.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Util>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Util>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Util>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
