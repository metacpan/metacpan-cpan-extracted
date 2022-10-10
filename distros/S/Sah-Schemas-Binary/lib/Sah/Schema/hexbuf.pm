package Sah::Schema::hexbuf;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-24'; # DATE
our $DIST = 'Sah-Schemas-Binary'; # DIST
our $VERSION = '0.006'; # VERSION

our $schema = [str => {
    summary => 'Binary data encoded in hexdigits',
    match => qr/\A([0-9A-fa-f][0-9A-fa-f])*\z/,

    prefilters => ['Str::remove_whitespace'],

    description => <<'_',

Note that this schema does not decode the hex encoding for you.

_

    examples => [
        {value=>'', valid=>1},
        {value=>'f', valid=>0, summary=>'Odd number of digits'},
        {value=>'fafafa', valid=>1},
        {value=>'FAFAFA', valid=>1, summary=>'Uppercase digits are allowed, not coerced to lowercase'},
        {value=>'fa fa  fa', valid=>1, summary=>'Whitespaces allowed, will be removed', validated_value=>'fafafa'},
        {value=>'fafafg', valid=>0},
    ],
}, {}];

1;

# ABSTRACT: Binary data encoded in hexdigits

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::hexbuf - Binary data encoded in hexdigits

=head1 VERSION

This document describes version 0.006 of Sah::Schema::hexbuf (from Perl distribution Sah-Schemas-Binary), released on 2022-07-24.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # valid

 "f"  # INVALID (Odd number of digits)

 "fafafa"  # valid

 "FAFAFA"  # valid (Uppercase digits are allowed, not coerced to lowercase)

 "fa fa  fa"  # valid (Whitespaces allowed, will be removed), becomes "fafafa"

 "fafafg"  # INVALID

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("hexbuf*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("hexbuf", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "fafafg";
 my $errmsg = $validator->($data); # => "Must match regex pattern qr(\\A([0-9A-fa-f][0-9A-fa-f])*\\z)"

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("hexbuf", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "";
 my $res = $validator->($data); # => ["",""]
 
 # a sample invalid data
 $data = "fafafg";
 my $res = $validator->($data); # => ["Must match regex pattern qr(\\A([0-9A-fa-f][0-9A-fa-f])*\\z)","fafafg"]

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
     state $validator = gen_validator("hexbuf*");
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
             schema => ['hexbuf*'],
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

=head1 DESCRIPTION

Note that this schema does not decode the hex encoding for you.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Binary>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Binary>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Binary>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
