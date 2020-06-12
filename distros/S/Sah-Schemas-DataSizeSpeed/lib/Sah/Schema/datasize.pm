package Sah::Schema::datasize;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-08'; # DATE
our $DIST = 'Sah-Schemas-DataSizeSpeed'; # DIST
our $VERSION = '0.009'; # VERSION

our $schema = ['float' => {
    summary => 'Data size',
    description => <<'_',

Float, in bytes.

Can be coerced from string that contains units, e.g.:

    2KB   -> 2048      (kilobyte, 1024-based)
    2mb   -> 2097152   (megabyte, 1024-based)
    1.5K  -> 1536      (kilobyte, 1024-based)
    1.6ki -> 1600      (kibibyte, 1000-based)

_
    min => 0,
    'x.perl.coerce_rules' => ['From_str::suffix_datasize'],

    examples => [
        {value=>'2KB', valid=>1, validated_value=>2*1024},
        {value=>'2 kb', valid=>1, validated_value=>2*1024},
        {value=>'2mb', valid=>1, validated_value=>2*1024*1024},
        {value=>'1.5K', valid=>1, validated_value=>1536},
        {value=>'1.6ki', valid=>1, validated_value=>1600},
        {value=>'1zzz', valid=>0},
    ],
}, {}];

1;

# ABSTRACT: Data size

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::datasize - Data size

=head1 VERSION

This document describes version 0.009 of Sah::Schema::datasize (from Perl distribution Sah-Schemas-DataSizeSpeed), released on 2020-03-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("datasize*");
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
             schema => ['datasize*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

Sample data:

 "2KB"  # valid, becomes 2048

 "2 kb"  # valid, becomes 2048

 "2mb"  # valid, becomes 2097152

 "1.5K"  # valid, becomes 1536

 "1.6ki"  # valid, becomes 1600

 "1zzz"  # INVALID

=head1 DESCRIPTION

Float, in bytes.

Can be coerced from string that contains units, e.g.:

 2KB   -> 2048      (kilobyte, 1024-based)
 2mb   -> 2097152   (megabyte, 1024-based)
 1.5K  -> 1536      (kilobyte, 1024-based)
 1.6ki -> 1600      (kibibyte, 1000-based)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-DataSizeSpeed>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-DataSizeSpeed>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-DataSizeSpeed>

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
