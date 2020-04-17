package Sah::Schema::hohoms;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-02'; # DATE
our $DIST = 'Sah-Schemas-Collection'; # DIST
our $VERSION = '0.004'; # VERSION

our $schema = [hash => {
    summary => 'Hash of (defined-)hash-of-maybe-strings',
    description => <<'_',

_
    of => ['homs', {req=>1}, {}],
    examples => [
        {data=>'a', valid=>0},
        {data=>[], valid=>0},
        {data=>{}, valid=>1},
        {data=>{k=>undef}, valid=>0},
        {data=>{k=>'a'}, valid=>0},
        {data=>{k=>[]}, valid=>0},
        {data=>{k=>{}}, valid=>1},
        {data=>{k=>{}, k2=>{k=>'a'}}, valid=>1},
        {data=>{k=>{}, k2=>{k=>[]}}, valid=>0},
        {data=>{k=>{}, k2=>{k=>{}}}, valid=>0},
        {data=>{k=>{}, k2=>{k=>undef}}, valid=>1},
    ],
}, {}];

1;
# ABSTRACT: Hash of (defined-)hash-of-maybe-strings

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::hohoms - Hash of (defined-)hash-of-maybe-strings

=head1 VERSION

This document describes version 0.004 of Sah::Schema::hohoms (from Perl distribution Sah-Schemas-Collection), released on 2020-03-02.

=head1 SYNOPSIS

Sample data:

 "a"  # INVALID

 []  # INVALID

 {}  # valid

 {k=>undef}  # INVALID

 {k=>"a"}  # INVALID

 {k=>[]}  # INVALID

 {k=>{}}  # valid

 {k=>{},k2=>{k=>"a"}}  # valid

 {k=>{},k2=>{k=>[]}}  # INVALID

 {k=>{},k2=>{k=>{}}}  # INVALID

 {k=>{},k2=>{k=>undef}}  # valid

=head1 DESCRIPTION

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

L<Sah::Schema::hohos> (hash of (defined-)hashes-of-(defined-)-strings).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
