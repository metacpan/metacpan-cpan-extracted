package Sah::Schema::array::int::monotonically_increasing;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-13'; # DATE
our $DIST = 'Sah-SchemaBundle-Array'; # DIST
our $VERSION = '0.004'; # VERSION

our $schema = [array => {
    summary => 'An array of integers with monotonically increasing elements',
    description => <<'_',

This is like the `array::num::monotonically_increasing` schema except elements
must be integers.

_
    of => ['int', {req=>1}],
    prefilters => ['Array::check_elems_numeric_monotonically_increasing'],
    examples => [
        {value=>{}, valid=>0, summary=>"Not an array"},
        {value=>[], valid=>1},
        {value=>[1, "a"], valid=>0, summary=>"Contains a non-numeric element"},
        {value=>[1, undef], valid=>0, summary=>"Contains an undefined element"},
        {value=>[1, 2, 2, 3], valid=>0, summary=>"Duplicate elements"},
        {value=>[1, 3, 2], valid=>0, summary=>"Not monotonically increasing"},
        {value=>[1, 2.9, 3], valid=>0, summary=>"Contains a non-integer element"},
        {value=>[1, 2, 3], valid=>1},
    ],
}];

1;
# ABSTRACT: An array of integers with monotonically increasing elements

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::array::int::monotonically_increasing - An array of integers with monotonically increasing elements

=head1 VERSION

This document describes version 0.004 of Sah::Schema::array::int::monotonically_increasing (from Perl distribution Sah-SchemaBundle-Array), released on 2024-02-13.

=head1 SAH SCHEMA DEFINITION

 [
   "array",
   {
     summary => "An array of integers with monotonically increasing elements",
     prefilters => ["Array::check_elems_numeric_monotonically_increasing"],
     of => ["int", { req => 1 }],
   },
 ]

Base type: L<array|Data::Sah::Type::array>

Used prefilters: L<Array::check_elems_numeric_monotonically_increasing|Data::Sah::Filter::perl::Array::check_elems_numeric_monotonically_increasing>

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 {}  # INVALID (Not an array)

 []  # valid

 [1,"a"]  # INVALID (Contains a non-numeric element)

 [1,undef]  # INVALID (Contains an undefined element)

 [1,2,2,3]  # INVALID (Duplicate elements)

 [1,3,2]  # INVALID (Not monotonically increasing)

 [1,2.9,3]  # INVALID (Contains a non-integer element)

 [1,2,3]  # valid

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("array::int::monotonically_increasing*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("array::int::monotonically_increasing", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = [1,2,3];
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = [1,"a"];
 my $errmsg = $validator->($data); # => "Elements not monotonically increasing (check element[1]) "

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("array::int::monotonically_increasing", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = [1,2,3];
 my $res = $validator->($data); # => ["",[1,2,3]]
 
 # a sample invalid data
 $data = [1,"a"];
 my $res = $validator->($data); # => ["Elements not monotonically increasing (check element[1]) ",[1,"a"]]

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
     state $validator = gen_validator("array::int::monotonically_increasing*");
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
             schema => ['array::int::monotonically_increasing*'],
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

 % validate-with-sah '"array::int::monotonically_increasing*"' '"data..."'

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
         sah2type('array::int::monotonically_increasing*', name=>'ArrayIntMonotonicallyIncreasing')
     );
 }

 use My::Types qw(ArrayIntMonotonicallyIncreasing);
 ArrayIntMonotonicallyIncreasing->assert_valid($data);

=head1 DESCRIPTION

This is like the C<array::num::monotonically_increasing> schema except elements
must be integers.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Array>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Array>.

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

This software is copyright (c) 2024, 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Array>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
