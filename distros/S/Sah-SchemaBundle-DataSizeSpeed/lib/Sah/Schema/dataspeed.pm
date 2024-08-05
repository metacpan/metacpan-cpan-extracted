package Sah::Schema::dataspeed;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-08-03'; # DATE
our $DIST = 'Sah-SchemaBundle-DataSizeSpeed'; # DIST
our $VERSION = '0.010'; # VERSION

our $schema = ['float' => {
    summary => 'Data transfer speed',
    description => <<'MARKDOWN',

Float, in bytes/second.

Can be coerced from string that contains units, e.g.:

    1000kbps -> 128000 (kilobits per second, 1024-based)
    2.5 mbit -> 327680 (megabit per second, 1024-based)
    128KB/s  -> 131072 (kilobyte per second, 1024-based)

MARKDOWN
    min => 0,
    'x.perl.coerce_rules' => ['From_str::suffix_dataspeed'],

    examples => [
        {value=>'1000kbps', valid=>1, validated_value=>128000},
        {value=>'2.5 mbit', valid=>1, validated_value=>327680},
        {value=>'128KB/s' , valid=>1, validated_value=>131072},
        {value=>'128K/s'  , valid=>1, validated_value=>131072},
        {value=>'128K'    , valid=>1, validated_value=>131072},
        {value=>'1zzz'    , valid=>0},
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

This document describes version 0.010 of Sah::Schema::dataspeed (from Perl distribution Sah-SchemaBundle-DataSizeSpeed), released on 2024-08-03.

=head1 SAH SCHEMA DEFINITION

 [
   "float",
   { "min" => 0, "x.perl.coerce_rules" => ["From_str::suffix_dataspeed"] },
   {},
 ]

Base type: L<float|Data::Sah::Type::float>

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 "1000kbps"  # valid, becomes 128000

 "2.5 mbit"  # valid, becomes 327680

 "128KB/s"  # valid, becomes 131072

 "128K/s"  # valid, becomes 131072

 "128K"  # valid, becomes 131072

 "1zzz"  # INVALID

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("dataspeed*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("dataspeed", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "2.5 mbit";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "1zzz";
 my $errmsg = $validator->($data); # => "Not of type decimal number"

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("dataspeed", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "2.5 mbit";
 my $res = $validator->($data); # => ["",327680]
 
 # a sample invalid data
 $data = "1zzz";
 my $res = $validator->($data); # => ["Not of type decimal number","1zzz"]

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
     state $validator = gen_validator("dataspeed*");
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
             schema => ['dataspeed*'],
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

=head2 Using on the CLI with validate-with-sah

To validate some data on the CLI, you can use L<validate-with-sah> utility.
Specify the schema as the first argument (encoded in Perl syntax) and the data
to validate as the second argument (encoded in Perl syntax):

 % validate-with-sah '"dataspeed*"' '"data..."'

C<validate-with-sah> has several options for, e.g. validating multiple data,
showing the generated validator code (Perl/JavaScript/etc), or loading
schema/data from file. See its manpage for more details.


=head2 Using with Type::Tiny

To create a type constraint and type library from a schema (requires
L<Type::Tiny> as well as L<Type::FromSah>):

 package My::Types {
     use Type::Library -base;
     use Type::FromSah qw( sah2type );

     __PACKAGE__->add_type(
         sah2type('dataspeed*', name=>'Dataspeed')
     );
 }

 use My::Types qw(Dataspeed);
 Dataspeed->assert_valid($data);

=head1 DESCRIPTION

Float, in bytes/second.

Can be coerced from string that contains units, e.g.:

 1000kbps -> 128000 (kilobits per second, 1024-based)
 2.5 mbit -> 327680 (megabit per second, 1024-based)
 128KB/s  -> 131072 (kilobyte per second, 1024-based)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-DataSizeSpeed>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-DataSizeSpeed>.

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

This software is copyright (c) 2024, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-DataSizeSpeed>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
