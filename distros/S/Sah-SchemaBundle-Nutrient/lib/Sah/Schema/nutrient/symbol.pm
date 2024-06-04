package Sah::Schema::nutrient::symbol;

use 5.010001;
use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-30'; # DATE
our $DIST = 'Sah-SchemaBundle-Nutrient'; # DIST
our $VERSION = '0.001'; # VERSION

our @rows;
# load and cache the table
{
    require TableData::Health::Nutrient;
    my $td = TableData::Health::Nutrient->new;
    @rows = $td->get_all_rows_hashref;
}

our $schema = [str => {
    summary => 'A known nutrient symbol, from TableData::Health::Nutrient',
    description => <<'MARKDOWN',

MARKDOWN
    in => [map {$_->{symbol}} @rows],
    'x.in.summaries' => [map {$_->{eng_name}} @rows],
    examples => [
        {value=>'', valid=>0, summary=>"Empty string"},
        {value=>'X', valid=>0, summary=>"Unknown nutrient"},
        {value=>'VD', valid=>1},
        {value=>'energy', valid=>0, summary=>'Case matters'},
    ],
}];

1;
# ABSTRACT: A known nutrient symbol, from TableData::Health::Nutrient

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::nutrient::symbol - A known nutrient symbol, from TableData::Health::Nutrient

=head1 VERSION

This document describes version 0.001 of Sah::Schema::nutrient::symbol (from Perl distribution Sah-SchemaBundle-Nutrient), released on 2024-05-30.

=head1 SAH SCHEMA DEFINITION

 [
   "str",
   {
     "in" => [
       "VA",
       "VD",
       "VE",
       "VK",
       "VB1",
       "VB2",
       "VB3",
       "VB5",
       "VB6",
       "VB9",
       "VB12",
       "VB7",
       "VB4",
       "VC",
       "Ca",
       "P",
       "Mg",
       "Fe",
       "I",
       "Zn",
       "Se",
       "Mn",
       "F",
       "Cr",
       "K",
       "Na",
       "Cl",
       "Cu",
       "Energy",
       "Protein",
       "Total_Fat",
       "Saturated_Fat",
       "Cholesterol",
       "Linoleic_Acid",
       "Alpha_Linoleic_Acid",
       "Carbohydrate",
       "Dietary_Fiber",
       "L_Carnitine",
       "Myo_Inositol",
     ],
     "x.in.summaries" => [
       "Vitamin A",
       "Vitamin D",
       "Vitamin E",
       "Vitamin K",
       "Vitamin B1",
       "Vitamin B2",
       "Vitamin B3",
       "Pantothenic acid",
       "Vitamin B6",
       "Folate",
       "Vitamin B12",
       "Biotin",
       "Choline",
       "Vitamin C",
       "Calcium",
       "Phosphorus",
       "Magnesium",
       "Iron",
       "Iodium",
       "Zinc",
       "Selenium",
       "Mangan",
       "Fluorine",
       "Chromium",
       "Potassium",
       "Sodium",
       "Chlorine",
       "Copper",
       "Energy",
       "Protein",
       "Total fat",
       "Saturated fat",
       "Cholesterol",
       "Linoleic acid",
       "\x{251}-linoleic acid",
       "Total carbohydrate",
       "Dietary fiber",
       "L-Carnitine",
       "Myo-Inositol",
     ],
   },
 ]

Base type: L<str|Data::Sah::Type::str>

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID (Empty string)

 "X"  # INVALID (Unknown nutrient)

 "VD"  # valid

 "energy"  # INVALID (Case matters)

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("nutrient::symbol*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("nutrient::symbol", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "VD";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "X";
 my $errmsg = $validator->($data); # => "Must be one of [\"VA\",\"VD\",\"VE\",\"VK\",\"VB1\",\"VB2\",\"VB3\",\"VB5\",\"VB6\",\"VB9\",\"VB12\",\"VB7\",\"VB4\",\"VC\",\"Ca\",\"P\",\"Mg\",\"Fe\",\"I\",\"Zn\",\"Se\",\"Mn\",\"F\",\"Cr\",\"K\",\"Na\",\"Cl\",\"Cu\",\"Energy\",\"Protein\",\"Total_Fat\",\"Saturated_Fat\",\"Cholesterol\",\"Linoleic_Acid\",\"Alpha_Linoleic_Acid\",\"Carbohydrate\",\"Dietary_Fiber\",\"L_Carnitine\",\"Myo_Inositol\"]"

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("nutrient::symbol", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "VD";
 my $res = $validator->($data); # => ["","VD"]
 
 # a sample invalid data
 $data = "X";
 my $res = $validator->($data); # => ["Must be one of [\"VA\",\"VD\",\"VE\",\"VK\",\"VB1\",\"VB2\",\"VB3\",\"VB5\",\"VB6\",\"VB9\",\"VB12\",\"VB7\",\"VB4\",\"VC\",\"Ca\",\"P\",\"Mg\",\"Fe\",\"I\",\"Zn\",\"Se\",\"Mn\",\"F\",\"Cr\",\"K\",\"Na\",\"Cl\",\"Cu\",\"Energy\",\"Protein\",\"Total_Fat\",\"Saturated_Fat\",\"Cholesterol\",\"Linoleic_Acid\",\"Alpha_Linoleic_Acid\",\"Carbohydrate\",\"Dietary_Fiber\",\"L_Carnitine\",\"Myo_Inositol\"]","X"]

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
     state $validator = gen_validator("nutrient::symbol*");
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
             schema => ['nutrient::symbol*'],
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

 % validate-with-sah '"nutrient::symbol*"' '"data..."'

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
         sah2type('nutrient::symbol*', name=>'NutrientSymbol')
     );
 }

 use My::Types qw(NutrientSymbol);
 NutrientSymbol->assert_valid($data);

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Nutrient>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Nutrient>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Nutrient>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
