package Sah::Schema::date::dow_nums;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-09'; # DATE
our $DIST = 'Sah-Schemas-Date'; # DIST
our $VERSION = '0.019'; # VERSION

our $schema = ['array' => {
    summary => 'Array of required date::dow_num (day-of-week, 1-7, 1=Monday, like DateTime, with coercions), e.g. [1,3,5]',
    of => ['date::dow_num', {req=>1}],
    'x.perl.coerce_rules' => ['From_str::comma_sep'],
    'x.completion' => ['date_dow_nums'],
    description => <<'_',

See also <pm:Sah::Schema::date::dow_num> which is the schema for the elements.

See also related schemas that coerce from other locales, e.g.
<pm:Sah::Schema::date::dow_nums::id> (Indonesian),
<pm:Sah::Schema::date::dow_num::en_or_id> (English/Indonesian), etc.

_
    examples => [
        {value=>'', valid=>1, validated_value=>[]},
        {value=>1, valid=>1, validated_value=>[1]},
        {value=>[1], valid=>1},
        {value=>[1,undef], valid=>0, summary=>'Contains undef'},
        {value=>[1,7], valid=>1},
        {value=>'1,7', valid=>1, validated_value=>[1,7]},
        {value=>["Mon","SunDAY"], valid=>1, validated_value=>[1,7]},
        {value=>'Mo,SU', valid=>1, validated_value=>[1,7]},
        {value=>[1,7,8], valid=>0, summary=>'Has number not in 1-7'},
        {value=>'1,7,8', valid=>0, summary=>'Has number not in 1-7'},
    ],
}];

1;

# ABSTRACT: Array of required date::dow_num (day-of-week, 1-7, 1=Monday, like DateTime, with coercions), e.g. [1,3,5]

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::date::dow_nums - Array of required date::dow_num (day-of-week, 1-7, 1=Monday, like DateTime, with coercions), e.g. [1,3,5]

=head1 VERSION

This document describes version 0.019 of Sah::Schema::date::dow_nums (from Perl distribution Sah-Schemas-Date), released on 2023-12-09.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # valid, becomes []

 1  # valid, becomes [1]

 [1]  # valid

 [1,undef]  # INVALID (Contains undef)

 [1,7]  # valid

 "1,7"  # valid, becomes [1,7]

 ["Mon","SunDAY"]  # valid, becomes [1,7]

 "Mo,SU"  # valid, becomes [1,7]

 [1,7,8]  # INVALID (Has number not in 1-7)

 "1,7,8"  # INVALID (Has number not in 1-7)

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("date::dow_nums*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("date::dow_nums", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "1,7";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = [1,7,8];
 my $errmsg = $validator->($data); # => "\@[2]: Must be at most 7"

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("date::dow_nums", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "1,7";
 my $res = $validator->($data); # => ["",[1,7]]
 
 # a sample invalid data
 $data = [1,7,8];
 my $res = $validator->($data); # => ["\@[2]: Must be at most 7",[1,7,8]]

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
     state $validator = gen_validator("date::dow_nums*");
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
             schema => ['date::dow_nums*'],
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

 % validate-with-sah '"date::dow_nums*"' '"data..."'

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
         sah2type('date::dow_nums*', name=>'DateDowNums')
     );
 }

 use My::Types qw(DateDowNums);
 DateDowNums->assert_valid($data);

=head1 DESCRIPTION

See also L<Sah::Schema::date::dow_num> which is the schema for the elements.

See also related schemas that coerce from other locales, e.g.
L<Sah::Schema::date::dow_nums::id> (Indonesian),
L<Sah::Schema::date::dow_num::en_or_id> (English/Indonesian), etc.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date>.

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

This software is copyright (c) 2023, 2022, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
