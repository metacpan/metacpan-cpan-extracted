package Sah::Schema::dataspeed;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-03'; # DATE
our $DIST = 'Sah-Schemas-DataSizeSpeed'; # DIST
our $VERSION = '0.006'; # VERSION

our $schema = ['float' => {
    summary => 'Data transfer speed',
    description => <<'_',

Float, in bytes/second.

Can be coerced from string that contains units, e.g.:

    1000kbps -> 128000 (kilobits per second, 1024-based)
    2.5 mbit -> 327680 (megabit per second, 1024-based)
    128KB/s  -> 131072 (kilobyte per second, 1024-based)

_
    min => 0,
    'x.perl.coerce_rules' => ['From_str::suffix_dataspeed'],
    examples => [
        {data=>'1000kbps', valid=>1, res=>128000},
        {data=>'2.5 mbit', valid=>1, res=>327680},
        {data=>'128KB/s' , valid=>1, res=>131072},
        {data=>'128K/s'  , valid=>1, res=>131072},
        {data=>'128K'    , valid=>1, res=>131072},
        {data=>'1zzz'    , valid=>0},
    ],
}, {}];

1;

# ABSTRACT: Data transfer speed

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::dataspeed - Data transfer speed

=head1 VERSION

This document describes version 0.006 of Sah::Schema::dataspeed (from Perl distribution Sah-Schemas-DataSizeSpeed), released on 2020-03-03.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("dataspeed*");
 say $vdr->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create a validator to return error message, coerced value,
 # even validators in other languages like JavaScript, from the same schema.
 # See its documentation for more details.

Using in L<Rinci> function metadata (to be used in L<Perinci::CmdLine>, etc):

 package MyApp;
 our %SPEC;
 $SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['dataspeed*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }

Sample data:

 "1000kbps"  # valid, becomes 128000

 "2.5 mbit"  # valid, becomes 327680

 "128KB/s"  # valid, becomes 131072

 "128K/s"  # valid, becomes 131072

 "128K"  # valid, becomes 131072

 "1zzz"  # INVALID

=head1 DESCRIPTION

Float, in bytes/second.

Can be coerced from string that contains units, e.g.:

 1000kbps -> 128000 (kilobits per second, 1024-based)
 2.5 mbit -> 327680 (megabit per second, 1024-based)
 128KB/s  -> 131072 (kilobyte per second, 1024-based)

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
