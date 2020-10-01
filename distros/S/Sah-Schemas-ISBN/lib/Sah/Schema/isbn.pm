package Sah::Schema::isbn;

# AUTHOR
our $DATE = '2020-05-27'; # DATE
our $DIST = 'Sah-Schemas-ISBN'; # DIST
our $VERSION = '0.008'; # VERSION

our $schema = [str => {
    summary => 'ISBN 10 or ISBN 13 number',
    description => <<'_',

Nondigits [^0-9Xx] will be removed during coercion.

Checksum digit must be valid.

_
    match => '\A(?:[0-9]{13}|[0-9]{9}[0-9Xx])\z',
    'x.perl.coerce_rules' => ['From_str::to_isbn'],

    examples => [
        {value=>'', valid=>0},
        {value=>'0-545-01022-5', valid=>1, validated_value=>'0545010225'},
        {value=>'978-1-56619-909-4', valid=>1, validated_value=>'9781566199094'},
        {value=>'978-1-56619-909-5', valid=>0, summary=>'Fail check digit'},
        {value=>'978-1-56619-909-45', valid=>0, summary=>'Too long'},
    ],

}, {}];

1;
# ABSTRACT: ISBN 10 or ISBN 13 number

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::isbn - ISBN 10 or ISBN 13 number

=head1 VERSION

This document describes version 0.008 of Sah::Schema::isbn (from Perl distribution Sah-Schemas-ISBN), released on 2020-05-27.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("isbn*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("isbn*");
     $validator->(\@args);
     ...
 }

To specify schema in L<Rinci> function metadata and use the metadata with
L<Perinci::CmdLine> to create a CLI:

 # in lib/MyApp.pm
 package MyApp;
 our %SPEC;
 $SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['isbn*'],
         },
         ...
     },
 };
 sub myfunc {
     my %args = @_;
     ...
 }
 1;

 # in myapp.pl
 package main;
 use Perinci::CmdLine::Any;
 Perinci::CmdLine::Any->new(url=>'MyApp::myfunc')->run;

 # in command-line
 % ./myapp.pl --help
 myapp - Routine to do blah ...
 ...

 % ./myapp.pl --version

 % ./myapp.pl --arg1 ...

Sample data:

 ""  # INVALID

 "0-545-01022-5"  # valid, becomes "0545010225"

 "978-1-56619-909-4"  # valid, becomes 9781566199094

 "978-1-56619-909-5"  # INVALID (Fail check digit)

 "978-1-56619-909-45"  # INVALID (Too long)

=head1 DESCRIPTION

Nondigits [^0-9Xx] will be removed during coercion.

Checksum digit must be valid.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-ISBN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-ISBN>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-ISBN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
