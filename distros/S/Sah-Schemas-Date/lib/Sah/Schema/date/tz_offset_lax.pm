package Sah::Schema::date::tz_offset_lax;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-08'; # DATE
our $DIST = 'Sah-Schemas-Date'; # DIST
our $VERSION = '0.013'; # VERSION

our $schema = ['date::tz_offset' => {
    summary => 'Timezone offset in seconds from UTC',
    'merge.delete.in' => [],
    min => -12*3600,
    max => +14*3600,
    description => <<'_',

This schema allows timezone offsets that are not known to exist, e.g. 1 second
(+00:00:01). If you only want ot allow timezone offsets that are known to exist,
see the `date::tz_offset` schema.

A coercion from these form of string is provided:

    UTC

    UTC-14 or UTC+12 or UTC+12:45 or UTC-00:25:21
    -14 or +12, -1400 or +12:00

A coercion from timezone name is also provided.

_
    examples => [
        {value=>'', valid=>0},
        {value=>'UTC', valid=>1, validated_value=>0},
        {value=>'3600', valid=>1, validated_value=>3600},
        {value=>'-43200', valid=>1, validated_value=>-43200},
        {value=>'-12', valid=>1, validated_value=>-12*3600},
        {value=>'-1200', valid=>1, validated_value=>-12*3600},
        {value=>'-12:00', valid=>1, validated_value=>-12*3600},
        {value=>'UTC-12', valid=>1, validated_value=>-12*3600},
        {value=>'UTC-1200', valid=>1, validated_value=>-12*3600},
        {value=>'UTC+12:45', valid=>1, validated_value=>+12.75*3600},
        {value=>'UTC-13', valid=>0},
        {value=>'UTC+12:01', valid=>1, validated_value=>+(12*3600+60)},
    ],
}, {}];

1;

# ABSTRACT: Timezone offset in seconds from UTC

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::date::tz_offset_lax - Timezone offset in seconds from UTC

=head1 VERSION

This document describes version 0.013 of Sah::Schema::date::tz_offset_lax (from Perl distribution Sah-Schemas-Date), released on 2020-03-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("date::tz_offset_lax*");
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
             schema => ['date::tz_offset_lax*'],
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

 "UTC"  # valid, becomes 0

 3600  # valid, becomes 3600

 -43200  # valid, becomes -43200

 -12  # valid, becomes -43200

 -1200  # valid, becomes -43200

 "-12:00"  # valid, becomes -43200

 "UTC-12"  # valid, becomes -43200

 "UTC-1200"  # valid, becomes -43200

 "UTC+12:45"  # valid, becomes 45900

 "UTC-13"  # INVALID

 "UTC+12:01"  # valid, becomes 43260

=head1 DESCRIPTION

This schema allows timezone offsets that are not known to exist, e.g. 1 second
(+00:00:01). If you only want ot allow timezone offsets that are known to exist,
see the C<date::tz_offset> schema.

A coercion from these form of string is provided:

 UTC
 
 UTC-14 or UTC+12 or UTC+12:45 or UTC-00:25:21
 -14 or +12, -1400 or +12:00

A coercion from timezone name is also provided.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date>

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
