package Sah::Schema::date::month_num::id;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-08'; # DATE
our $DIST = 'Sah-Schemas-Date-ID'; # DIST
our $VERSION = '0.005'; # VERSION

our $schema = [int => {
    summary => 'Month number',
    min => 1,
    max => 12,
    'x.perl.coerce_rules' => ['From_str::convert_id_month_name_to_num'],
    examples => [
        {value=>'', valid=>0},
        {value=>'jan', valid=>1, validated_value=>1},
        {value=>'AGU', valid=>1, validated_value=>8},
        {value=>'aug', valid=>0},
        {value=>0, valid=>0},
        {value=>1, valid=>1},
        {value=>12, valid=>1},
        {value=>13, valid=>0},
    ],
}, {}];

1;

# ABSTRACT: Month number

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::date::month_num::id - Month number

=head1 VERSION

This document describes version 0.005 of Sah::Schema::date::month_num::id (from Perl distribution Sah-Schemas-Date-ID), released on 2020-03-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("date::month_num::id*");
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
             schema => ['date::month_num::id*'],
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

 "jan"  # valid, becomes 1

 "AGU"  # valid, becomes 8

 "aug"  # INVALID

 0  # INVALID

 1  # valid

 12  # valid

 13  # INVALID

=head1 DESCRIPTION

Like the L<date::month_num|Sah::Schema::date::month_num> schema, except with
coercion rule to convert Indonesian month name to number.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date-ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date-ID>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date-ID>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schema::date::month_num>

L<Sah::Schema::date::month_num::en_or_id>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
