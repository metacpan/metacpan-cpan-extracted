package Scalar::Util::Numeric::PP;

our $DATE = '2016-01-22'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                       isint
                       isnum
                       isnan
                       isinf
                       isneg
                       isfloat
               );

sub isint {
    local $_ = shift;
    return 0 unless defined;
    return 1 if /\A\s*[+-]?(?:0|[1-9][0-9]*)\s*\z/s;
    0;
}

sub isnan($) {
    local $_ = shift;
    return 0 unless defined;
    return 1 if /\A\s*[+-]?nan\s*\z/is;
    0;
}

sub isinf($) {
    local $_ = shift;
    return 0 unless defined;
    return 1 if /\A\s*[+-]?inf(?:inity)?\s*\z/is;
    0;
}

sub isneg($) {
    local $_ = shift;
    return 0 unless defined;
    return 1 if /\A\s*-/;
    0;
}

sub isnum($) {
    local $_ = shift;
    return 0 unless defined;
    return 1 if isint($_);
    return 1 if isfloat($_);
    0;
}

sub isfloat($) {
    local $_ = shift;
    return 0 unless defined;
    return 1 if /\A\s*[+-]?
                 (?: (?:0|[1-9][0-9]*)(\.[0-9]+)? | (\.[0-9]+) )
                 ([eE][+-]?[0-9]+)?\s*\z/sx && $1 || $2 || $3;
    return 1 if isnan($_) || isinf($_);
    0;
}

1;
# ABSTRACT: Pure-perl drop-in replacement/approximation of Scalar::Util::Numeric

__END__

=pod

=encoding UTF-8

=head1 NAME

Scalar::Util::Numeric::PP - Pure-perl drop-in replacement/approximation of Scalar::Util::Numeric

=head1 VERSION

This document describes version 0.04 of Scalar::Util::Numeric::PP (from Perl distribution Scalar-Util-Numeric-PP), released on 2016-01-22.

=head1 SYNOPSIS

=head1 DESCRIPTION

This module is written mainly for the convenience of L<Data::Sah>, as a drop-in
pure-perl replacement for the XS module L<Scalar::Util::Numeric>, in the case
when Data::Sah needs to generate code that uses PP modules instead of XS ones.

Not all functions from Scalar::Util::Numeric have been provided.

=head1 FUNCTIONS

=head2 isint

=head2 isfloat

=head2 isnum

=head2 isneg

=head2 isinf

=head2 isnan

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Scalar-Util-Numeric-PP>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Scalar-Util-Numeric-PP>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Scalar-Util-Numeric-PP>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah>

L<Scalar::Util::Numeric>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
