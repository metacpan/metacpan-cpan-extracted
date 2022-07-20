package Sah::Schema::str_or_re;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-06-05'; # DATE
our $DIST = 'Sah-Schemas-Str'; # DIST
our $VERSION = '0.004'; # VERSION

our $schema = [any => {
    summary => 'String or regex (if string is of the form `/.../`)',
    description => <<'_',

If string is of the form of `/.../`, then it will be parsed as a regex.
Otherwise, it's accepted as a plain string.

_
    of => [
        ['str'],
        ['re'],
    ],

    prefilters => ['Str::maybe_convert_to_re'],

    examples => [
        {value=>'', valid=>1},
        {value=>'a', valid=>1},
        {value=>{}, valid=>0, summary=>'Not a string'},

        {value=>'//', valid=>1, validated_value=>qr//},
        {value=>'/foo', valid=>1},
        {value=>'/foo.*/', valid=>1, validated_value=>qr/foo.*/},
        {value=>'/foo[/', valid=>0, summary=>'Invalid regex'},
    ],

}];

1;
# ABSTRACT: String or regex (if string is of the form `/.../`)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::str_or_re - String or regex (if string is of the form `/.../`)

=head1 VERSION

This document describes version 0.004 of Sah::Schema::str_or_re (from Perl distribution Sah-Schemas-Str), released on 2022-06-05.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("str_or_re*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("str_or_re*");
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
             schema => ['str_or_re*'],
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

 ""  # valid

 "a"  # valid

 {}  # INVALID (Not a string)

 "//"  # valid, becomes qr()

 "/foo"  # valid

 "/foo.*/"  # valid, becomes qr(foo.*)

 "/foo[/"  # INVALID (Invalid regex)

=head1 DESCRIPTION

If string is of the form of C</.../>, then it will be parsed as a regex.
Otherwise, it's accepted as a plain string.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Str>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Str>.

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

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Str>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
