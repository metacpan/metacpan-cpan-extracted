package Sah::Schema::date::dow_name::id;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-08'; # DATE
our $DIST = 'Sah-Schemas-Date-ID'; # DIST
our $VERSION = '0.005'; # VERSION

our $schema = [cistr => {
    summary => 'Day-of-week name (abbreviated or full, in Indonesian)',
    in => [
        qw/mg sn sl rb km jm sb/,
        qw/min sen sel rab kam jum sab/,
        qw/minggu senin selasa rabu kamis jumat sabtu/,
    ],
    examples => [
        {value=>'', valid=>0},
        {value=>'mg', valid=>1},
        {value=>'min', valid=>1},
        {value=>'minggu', valid=>1},
        {value=>'sun', valid=>0, summary=>'English'},
        {value=>1, valid=>0},
    ],
}, {}];

1;

# ABSTRACT: Day-of-week name (abbreviated or full, in Indonesian)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::date::dow_name::id - Day-of-week name (abbreviated or full, in Indonesian)

=head1 VERSION

This document describes version 0.005 of Sah::Schema::date::dow_name::id (from Perl distribution Sah-Schemas-Date-ID), released on 2020-03-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("date::dow_name::id*");
 say $vdr->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create a validator to return error message, coerced value,
 # even validators in other languages like JavaScript, from the same schema.
 # See its documentation for more details.

Using in L<Rinci> function metadata (to be used with L<Perinci::CmdLine>, etc):

 package MyApp;
 our %SPEC;
 $SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['date::dow_name::id*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

Sample data:

 ""  # INVALID

 "mg"  # valid

 "min"  # valid

 "minggu"  # valid

 "sun"  # INVALID (English)

 1  # INVALID

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date-ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date-ID>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date-ID>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
