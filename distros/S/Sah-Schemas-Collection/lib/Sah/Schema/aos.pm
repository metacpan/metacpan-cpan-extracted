package Sah::Schema::aos;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-02'; # DATE
our $DIST = 'Sah-Schemas-Collection'; # DIST
our $VERSION = '0.004'; # VERSION

our $schema = [array => {
    summary => 'Array of (defined) strings',
    description => <<'_',

The elements (strings) of the array must be defined.

_
    of => ['str', {req=>1}, {}],
    examples => [
        {data=>'a', valid=>0},
        {data=>[], valid=>1},
        {data=>{}, valid=>0},
        {data=>['a'], valid=>1},
        {data=>[undef], valid=>0},
        {data=>['a', []], valid=>0},
        {data=>[['a']], valid=>0},
    ],
}, {}];

1;
# ABSTRACT: Array of (defined) strings

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::aos - Array of (defined) strings

=head1 VERSION

This document describes version 0.004 of Sah::Schema::aos (from Perl distribution Sah-Schemas-Collection), released on 2020-03-02.

=head1 SYNOPSIS

Sample data:

 "a"  # INVALID

 []  # valid

 {}  # INVALID

 ["a"]  # valid

 [undef]  # INVALID

 ["a",[]]  # INVALID

 [["a"]]  # INVALID

=head1 DESCRIPTION

The elements (strings) of the array must be defined.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Collection>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Collection>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Collection>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schema::aoms> (array of maybe-strings) where the elements of the array
are allowed to be undefs.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
