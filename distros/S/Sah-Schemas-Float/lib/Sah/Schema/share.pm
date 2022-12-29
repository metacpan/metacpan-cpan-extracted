package Sah::Schema::share;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-22'; # DATE
our $DIST = 'Sah-Schemas-Float'; # DIST
our $VERSION = '0.012'; # VERSION

our $schema = ['float', {
    summary => 'A float between 0 and 1',
    min => 0,
    max => 1,
    description => <<'_',

Accepted in one of these forms:

    0.5      # a normal float between 0 and 1
    10       # a float between 1 (exclusive) and 100, interpreted as percent
    10%      # a percentage string, between 0% and 100%

Due to different interpretations, particularly "1" (some people might expect it
to mean "0.01" or "1%") use of this type is discouraged. Use
<pm:Sah::Schema::percent> instead.

_
    'x.perl.coerce_rules' => [
        'From_str::share',
    ],

    examples => [
        {value=>0, valid=>1, validated_value=>0},
        {value=>0.5, valid=>1, validated_value=>0.5},
        {value=>1, valid=>1, validated_value=>1},
        {value=>1.2, valid=>1, validated_value=>0.012},
        {value=>'1.2%', valid=>1, validated_value=>0.012},
        {value=>'102%', valid=>0},
    ],
}, {}];

1;
# ABSTRACT: A float between 0 and 1

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::share - A float between 0 and 1

=head1 VERSION

This document describes version 0.012 of Sah::Schema::share (from Perl distribution Sah-Schemas-Float), released on 2022-09-22.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 0  # valid, becomes 0

 0.5  # valid, becomes 0.5

 1  # valid, becomes 1

 1.2  # valid, becomes 0.012

 "1.2%"  # valid, becomes 0.012

 "102%"  # INVALID

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("share*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("share", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = 0;
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "102%";
 my $errmsg = $validator->($data); # => "Must be at most 1"

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("share", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = 0;
 my $res = $validator->($data); # => ["",0]
 
 # a sample invalid data
 $data = "102%";
 my $res = $validator->($data); # => ["Must be at most 1",1.02]

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
     state $validator = gen_validator("share*");
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
             schema => ['share*'],
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

Accepted in one of these forms:

 0.5      # a normal float between 0 and 1
 10       # a float between 1 (exclusive) and 100, interpreted as percent
 10%      # a percentage string, between 0% and 100%

Due to different interpretations, particularly "1" (some people might expect it
to mean "0.01" or "1%") use of this type is discouraged. Use
L<Sah::Schema::percent> instead.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Float>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Float>.

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
