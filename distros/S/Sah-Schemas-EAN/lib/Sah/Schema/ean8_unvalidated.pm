package Sah::Schema::ean8_unvalidated;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-27'; # DATE
our $DIST = 'Sah-Schemas-EAN'; # DIST
our $VERSION = '0.009'; # VERSION

our $schema = [str => {
    summary => 'EAN-8 number (e.g. 9638-5074), check digit not validated',
    description => <<'_',

Nondigits [^0-9] will be removed during coercion.

Length must be 8 digits.

This schema can be useful if you want to check EAN-8's check digit yourself.

_
    match => '\A[0-9]{8}\z',
    'prefilters' => ['Str::remove_nondigit'],

    examples => [
        {value=>'9638-5074', valid=>1, validated_value=>'96385074'},
        {value=>'12345678', valid=>1, summary=>'Invalid checkdigit still accepted'},
        {value=>'1234567', valid=>0, summary=>'Less than 8 digits'},
        {value=>'123456789', valid=>0, summary=>'More than 8 digits'},
    ],
}];

1;
# ABSTRACT: EAN-8 number (e.g. 9638-5074), check digit not validated

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::ean8_unvalidated - EAN-8 number (e.g. 9638-5074), check digit not validated

=head1 VERSION

This document describes version 0.009 of Sah::Schema::ean8_unvalidated (from Perl distribution Sah-Schemas-EAN), released on 2023-01-27.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 "9638-5074"  # valid, becomes 96385074

 12345678  # valid (Invalid checkdigit still accepted)

 1234567  # INVALID (Less than 8 digits)

 123456789  # INVALID (More than 8 digits)

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("ean8_unvalidated*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("ean8_unvalidated", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = 12345678;
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = 1234567;
 my $errmsg = $validator->($data); # => "Must match regex pattern \\A[0-9]{8}\\z"

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("ean8_unvalidated", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = 12345678;
 my $res = $validator->($data); # => ["",12345678]
 
 # a sample invalid data
 $data = 1234567;
 my $res = $validator->($data); # => ["Must match regex pattern \\A[0-9]{8}\\z",1234567]

Data::Sah can also create validator that returns a hash of detailed error
message. Data::Sah can even create validator that targets other language, like
JavaScript, from the same schema. Other things Data::Sah can do: show source
code for validator, generate a validator code with debug comments and/or log
statements, generate human text from schema. See its documentation for more
details.

=head2 Using with Params::Sah

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("ean8_unvalidated*");
     $validator->(\@args);
     ...
 }

=head2 Using with Perinci::CmdLine::Lite

To specify schema in L<Rinci> function metadata and use the metadata with
L<Perinci::CmdLine> (L<Perinci::CmdLine::Lite>) to create a CLI:

 # in lib/MyApp.pm
 package
   MyApp;
 our %SPEC;
 $SPEC{myfunc} = {
     v => 1.1,
     summary => 'Routine to do blah ...',
     args => {
         arg1 => {
             summary => 'The blah blah argument',
             schema => ['ean8_unvalidated*'],
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
 package
   main;
 use Perinci::CmdLine::Any;
 Perinci::CmdLine::Any->new(url=>'/MyApp/myfunc')->run;

 # in command-line
 % ./myapp.pl --help
 myapp - Routine to do blah ...
 ...

 % ./myapp.pl --version

 % ./myapp.pl --arg1 ...


=head2 Using with Type::Tiny

To create a type constraint and type library from a schema:

 package My::Types {
     use Type::Library -base;
     use Type::FromSah qw( sah2type );

     __PACKAGE__->add_type(
         sah2type('$sch_name*', name=>'Ean8Unvalidated')
     );
 }

 use My::Types qw(Ean8Unvalidated);
 Ean8Unvalidated->assert_valid($data);

=head1 DESCRIPTION

Nondigits [^0-9] will be removed during coercion.

Length must be 8 digits.

This schema can be useful if you want to check EAN-8's check digit yourself.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-EAN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-EAN>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-EAN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
