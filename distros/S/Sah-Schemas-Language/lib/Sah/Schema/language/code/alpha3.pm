package Sah::Schema::language::code::alpha3;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-27'; # DATE
our $DIST = 'Sah-Schemas-Language'; # DIST
our $VERSION = '0.004'; # VERSION

use Locale::Codes::Language_Codes ();

my $codes = [sort (
    keys(%{ $Locale::Codes::Data{'language'}{'code2id'}{'alpha-3'} }),
)];
die "Can't extract language codes from Locale::Codes::Language_Codes"
    unless @$codes;

our $schema = [str => {
    summary => 'Language code (alpha-3)',
    description => <<'_',

Accept only current (not retired) codes. Only alpha-3 codes are accepted.

_
    match => '\A[a-z]{3}\z',
    in => $codes,
    'x.perl.coerce_rules' => ['From_str::to_lower'],

    examples => [
        {value=>"", valid=>0},
        {value=>"id", valid=>0, summary=>"Indonesian (2 letter, rejected)"},
        {value=>"IND", valid=>1, validated_value=>"ind", summary=>"Indonesian (3 letter)"},
        {value=>"qqq", valid=>0, summary=>"Unknown language code"},
    ],

}, {}];

1;
# ABSTRACT: Language code (alpha-3)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::language::code::alpha3 - Language code (alpha-3)

=head1 VERSION

This document describes version 0.004 of Sah::Schema::language::code::alpha3 (from Perl distribution Sah-Schemas-Language), released on 2020-05-27.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("language::code::alpha3*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("language::code::alpha3*");
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
             schema => ['language::code::alpha3*'],
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

 "id"  # INVALID (Indonesian (2 letter, rejected))

 "IND"  # valid, becomes "ind"

 "qqq"  # INVALID (Unknown language code)

=head1 DESCRIPTION

Accept only current (not retired) codes. Only alpha-3 codes are accepted.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Language>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Language>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Language>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schema::language::code::alpha2>

L<Sah::Schema::language::code>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
