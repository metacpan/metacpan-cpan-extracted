package Sah::Schema::perl::identifier::qualified_ascii;

use strict;
use utf8;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.048'; # VERSION

our $schema = [str => {
    summary => 'Qualified identifier in Perl, without "use utf8" in effect',
    description => <<'_',

_
    match => qr/\A[A-Za-z_][A-Za-z_0-9]*(?:::[A-Za-z_0-9]+)+\z/,
    max_len => 251, # total max length, with qualifier and all the '::', but without the sigil

    examples => [
        {value=>'', valid=>0, summary=>'Empty'},

        # ascii
        {value=>'foo', valid=>0, summary=>'Not qualified'},
        {value=>'foo::bar', valid=>1},
        {value=>"foo'bar", valid=>0, summary=>"This schema does not accept the old (soon-to-be-deprecated) namespace separator"},
        {value=>'_foo::bar', valid=>1},
        {value=>'0foo::bar', valid=>0, summary=>'Cannot start with a digit'},
        {value=>'foo::0', valid=>1, summary=>'Secondary+ parts are allowed to start with a digit (1)'},
        {value=>'foo::0bar', valid=>1, summary=>'Secondary+ parts are allowed to start with a digit (2)'},
        {value=>'foo0::bar', valid=>1},
        {value=>'foo::bar-baz', valid=>0, summary=>'Invalid character (dash)'},
        {value=>'$foo::bar', valid=>0, summary=>'Sigil not accepted'},

        # unicode
        {value=>'foo::bébé', valid=>0, summary=>'Non-latin letter not accepted'},
    ],

}];

1;
# ABSTRACT: Qualified identifier in Perl, without "use utf8" in effect

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::identifier::qualified_ascii - Qualified identifier in Perl, without "use utf8" in effect

=head1 VERSION

This document describes version 0.048 of Sah::Schema::perl::identifier::qualified_ascii (from Perl distribution Sah-Schemas-Perl), released on 2023-01-19.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID (Empty)

 "foo"  # INVALID (Not qualified)

 "foo::bar"  # valid

 "foo'bar"  # INVALID (This schema does not accept the old (soon-to-be-deprecated) namespace separator)

 "_foo::bar"  # valid

 "0foo::bar"  # INVALID (Cannot start with a digit)

 "foo::0"  # valid (Secondary+ parts are allowed to start with a digit (1))

 "foo::0bar"  # valid (Secondary+ parts are allowed to start with a digit (2))

 "foo0::bar"  # valid

 "foo::bar-baz"  # INVALID (Invalid character (dash))

 "\$foo::bar"  # INVALID (Sigil not accepted)

 "foo::b\xE9b\xE9"  # INVALID (Non-latin letter not accepted)

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::identifier::qualified_ascii*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("perl::identifier::qualified_ascii", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "foo0::bar";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "foo'bar";
 my $errmsg = $validator->($data); # => "Must match regex pattern qr(\\A[A-Za-z_][A-Za-z_0-9]*(?:::[A-Za-z_0-9]+)+\\z)"

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("perl::identifier::qualified_ascii", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "foo0::bar";
 my $res = $validator->($data); # => ["","foo0::bar"]
 
 # a sample invalid data
 $data = "foo'bar";
 my $res = $validator->($data); # => ["Must match regex pattern qr(\\A[A-Za-z_][A-Za-z_0-9]*(?:::[A-Za-z_0-9]+)+\\z)","foo'bar"]

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
     state $validator = gen_validator("perl::identifier::qualified_ascii*");
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
             schema => ['perl::identifier::qualified_ascii*'],
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
         sah2type('$sch_name*', name=>'PerlIdentifierQualifiedAscii')
     );
 }

 use My::Types qw(PerlIdentifierQualifiedAscii);
 PerlIdentifierQualifiedAscii->assert_valid($data);

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Perl>.

=head1 SEE ALSO

L<perldata>

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

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
