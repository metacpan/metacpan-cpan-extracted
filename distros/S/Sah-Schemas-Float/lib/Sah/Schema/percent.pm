package Sah::Schema::percent;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-22'; # DATE
our $DIST = 'Sah-Schemas-Float'; # DIST
our $VERSION = '0.012'; # VERSION

our $schema = ['float', {
    summary => 'A float',
    description => <<'_',

This type is basically `float`, with `str_as_percent` coerce rule. So the
percent sign is optional, but the number is always interpreted as percent, e.g.
"1" is interpreted as 1% (0.01).

In general, instead of using this schema, I recommend just using the `float`
type (which by default includes coercion rule to convert from percent notation
e.g. '1%' -> 0.01). Use this schema if your argument really needs to be
expressed in percents.

_
    'x.perl.coerce_rules' => [
        'From_str::as_percent',
    ],

    examples => [
        {value=>0, valid=>1, validated_value=>0},
        {value=>0.5, valid=>1, validated_value=>0.005},
        {value=>5, valid=>1, validated_value=>0.05},
        {value=>'5%', valid=>1, validated_value=>0.05},
    ],
}, {}];

1;
# ABSTRACT: A float

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::percent - A float

=head1 VERSION

This document describes version 0.012 of Sah::Schema::percent (from Perl distribution Sah-Schemas-Float), released on 2022-09-22.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 0  # valid, becomes 0

 0.5  # valid, becomes 0.005

 5  # valid, becomes 0.05

 "5%"  # valid, becomes 0.05

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("percent*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("percent", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = 0.5;
 my $errmsg = $validator->($data); # => ""

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("percent", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = 0.5;
 my $res = $validator->($data); # => ["",0.005]

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
     state $validator = gen_validator("percent*");
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
             schema => ['percent*'],
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

This type is basically C<float>, with C<str_as_percent> coerce rule. So the
percent sign is optional, but the number is always interpreted as percent, e.g.
"1" is interpreted as 1% (0.01).

In general, instead of using this schema, I recommend just using the C<float>
type (which by default includes coercion rule to convert from percent notation
e.g. '1%' -> 0.01). Use this schema if your argument really needs to be
expressed in percents.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Float>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Float>.

=head1 SEE ALSO

L<Sah::Schema::percent_str>

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

This software is copyright (c) 2022, 2020, 2019, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Float>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
