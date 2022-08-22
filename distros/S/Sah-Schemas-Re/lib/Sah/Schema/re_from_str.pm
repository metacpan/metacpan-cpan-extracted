package Sah::Schema::re_from_str;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-08-20'; # DATE
our $DIST = 'Sah-Schemas-Re'; # DIST
our $VERSION = '0.001'; # VERSION

our $schema = [
    re => {
        summary => 'Regexp object from string using Regexp::From::String\'s str_to_re()',
        description => <<'_',

This schema accepts Regexp object or string which will be coerced to Regexp object
using <pm:Regexp::From::String>'s `str_to_re()` function.

Basically, if string is of the form of `/.../` or `qr(...)`, then you could
specify metacharacters as if you are writing a literal regexp pattern in Perl.
Otherwise, your string will be `quotemeta()`-ed first then compiled to Regexp
object. This means in the second case you cannot specify metacharacters.

_

        prefilters => [ ['Re::re_from_str'=>{}] ],

        examples => [
        ],
    },
];

1;
# ABSTRACT: Regexp object from string

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::re_from_str - Regexp object from string

=head1 VERSION

This document describes version 0.001 of Sah::Schema::re_from_str (from Perl distribution Sah-Schemas-Re), released on 2022-08-20.

=for Pod::Coverage ^(.+)$

=head1 SYNOPSIS

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("re_from_str*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("re_from_str", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("re_from_str", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]

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
     state $validator = gen_validator("re_from_str*");
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
             schema => ['re_from_str*'],
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

This schema accepts Regexp object or string which will be coerced to Regexp object
using L<Regexp::From::String>'s C<str_to_re()> function.

Basically, if string is of the form of C</.../> or C<qr(...)>, then you could
specify metacharacters as if you are writing a literal regexp pattern in Perl.
Otherwise, your string will be C<quotemeta()>-ed first then compiled to Regexp
object. This means in the second case you cannot specify metacharacters.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Re>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Re>.

=head1 SEE ALSO

L<Sah::PSchema::re_from_str> a parameterized version of this schema.

L<Regexp::From::String>

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Re>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
