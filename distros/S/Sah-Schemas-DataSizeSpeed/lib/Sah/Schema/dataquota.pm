package Sah::Schema::dataquota;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-08'; # DATE
our $DIST = 'Sah-Schemas-DataSizeSpeed'; # DIST
our $VERSION = '0.009'; # VERSION

use Sah::Schema::dataspeed;

our $schema = ['dataspeed' => {
    summary => 'Data transfer quota',

    examples => $Sah::Schema::dataspeed::schema->[1]{examples},
}, {}];

1;

# ABSTRACT: Data transfer quota

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::dataquota - Data transfer quota

=head1 VERSION

This document describes version 0.009 of Sah::Schema::dataquota (from Perl distribution Sah-Schemas-DataSizeSpeed), released on 2020-03-08.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("dataquota*");
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
             schema => ['dataquota*'],
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

An alias for L<Sah::Schema::datasize>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-DataSizeSpeed>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-DataSizeSpeed>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-DataSizeSpeed>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schema::datasize>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
