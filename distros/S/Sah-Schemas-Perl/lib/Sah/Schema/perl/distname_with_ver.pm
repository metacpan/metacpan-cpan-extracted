package Sah::Schema::perl::distname_with_ver;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-14'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.047'; # VERSION

our $schema = [str => {
    summary => 'Perl distribution name with version number suffix, e.g. Foo-Bar@0.001',
    match => '\A[A-Za-z_][A-Za-z_0-9]*(-[A-Za-z_0-9]+)*@[0-9][0-9A-Za-z]*(\\.[0-9A-Za-z_]+)*\z',
    'x.perl.coerce_rules' => [
        'From_str::normalize_perl_distname',
    ],

    # provide a default completion which is from list of installed perl distributions
    'x.completion' => 'perl_distname',


    description => <<'_',

For convenience (particularly in CLI with tab completion), you can input one of:

    Foo::Bar@1.23
    Foo/Bar@1.23
    Foo/Bar.pm@1.23
    Foo.Bar@1.23

and it will be coerced into Foo-Bar form.

_

    examples => [
        {value=>'', valid=>0},
        {value=>'Foo-Bar', valid=>0},
        {value=>'Foo::Bar', valid=>0},
        {value=>'Foo-Bar@1.0.0', valid=>1},
        {value=>'Foo::Bar@1.0.0', valid=>1, validated_value=>'Foo-Bar@1.0.0'},
        {value=>'Foo-Bar@0.5_001', valid=>1},
        {value=>'Foo::Bar@0.5_001', valid=>1, validated_value=>'Foo-Bar@0.5_001'},
        {value=>'Foo-Bar@a', valid=>0},
    ],

}];

1;
# ABSTRACT: Perl distribution name with version number suffix, e.g. Foo-Bar@0.001

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::distname_with_ver - Perl distribution name with version number suffix, e.g. Foo-Bar@0.001

=head1 VERSION

This document describes version 0.047 of Sah::Schema::perl::distname_with_ver (from Perl distribution Sah-Schemas-Perl), released on 2023-01-14.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID

 "Foo-Bar"  # INVALID

 "Foo::Bar"  # INVALID

 "Foo-Bar\@1.0.0"  # valid

 "Foo::Bar\@1.0.0"  # valid, becomes "Foo-Bar\@1.0.0"

 "Foo-Bar\@0.5_001"  # valid

 "Foo::Bar\@0.5_001"  # valid, becomes "Foo-Bar\@0.5_001"

 "Foo-Bar\@a"  # INVALID

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::distname_with_ver*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("perl::distname_with_ver", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "Foo::Bar\@0.5_001";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "Foo-Bar";
 my $errmsg = $validator->($data); # => "Must match regex pattern \\A[A-Za-z_][A-Za-z_0-9]*(-[A-Za-z_0-9]+)*\@[0-9][0-9A-Za-z]*(\\.[0-9A-Za-z_]+)*\\z"

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("perl::distname_with_ver", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "Foo::Bar\@0.5_001";
 my $res = $validator->($data); # => ["","Foo-Bar\@0.5_001"]
 
 # a sample invalid data
 $data = "Foo-Bar";
 my $res = $validator->($data); # => ["Must match regex pattern \\A[A-Za-z_][A-Za-z_0-9]*(-[A-Za-z_0-9]+)*\@[0-9][0-9A-Za-z]*(\\.[0-9A-Za-z_]+)*\\z","Foo-Bar"]

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
     state $validator = gen_validator("perl::distname_with_ver*");
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
             schema => ['perl::distname_with_ver*'],
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
         sah2type('$sch_name*', name=>'PerlDistnameWithVer')
     );
 }

 use My::Types qw(PerlDistnameWithVer);
 PerlDistnameWithVer->assert_valid($data);

=head1 DESCRIPTION

For convenience (particularly in CLI with tab completion), you can input one of:

 Foo::Bar@1.23
 Foo/Bar@1.23
 Foo/Bar.pm@1.23
 Foo.Bar@1.23

and it will be coerced into Foo-Bar form.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Perl>.

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
