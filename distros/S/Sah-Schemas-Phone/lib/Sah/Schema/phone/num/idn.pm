package Sah::Schema::phone::num::idn;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-23'; # DATE
our $DIST = 'Sah-Schemas-Phone'; # DIST
our $VERSION = '0.001'; # VERSION

our $schema = ["str" => {
    summary => 'Indonesian phone number, e.g. +628123456789',
    prefilters => [
        ['Regexp::replace' => {from_pat=>qr/\A0/, to_str=>'+62'}],
        'Phone::format',
    ],
    match => qr/\A\+62([0-9 ]{5,20})\z/i,

    description => <<'_',

This schema accepts Indonesian phone number e.g. +628123456789. If number does
not contain country code, it will be assumed to be '+62' (Indonesian calling
code). Some formatting characters like dashes and spaces are accepted, as long
as it passes <pm:Number::Phone> formatting. The number will be formatted using
international phone number formatting by the Number::Phone module, e.g. '+62 812
3456 789'.

_
    examples => [
        {value=>'', valid=>0},
        {value=>"08123456789", valid=>1, validated_value=>'+62 812 3456 789'},
        {value=>"+442087712924", valid=>0, summary=>'Not Indonesian number'},
        {value=>"+628123456789", valid=>1, validated_value=>'+62 812 3456 789'},
        {value=>"628123456789", valid=>1, validated_value=>'+62 812 3456 789'},
    ],

}];

1;
# ABSTRACT: Indonesian phone number, e.g. +628123456789

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::phone::num::idn - Indonesian phone number, e.g. +628123456789

=head1 VERSION

This document describes version 0.001 of Sah::Schema::phone::num::idn (from Perl distribution Sah-Schemas-Phone), released on 2022-09-23.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID

 "08123456789"  # valid, becomes "+62 812 3456 789"

 "+442087712924"  # INVALID (Not Indonesian number)

 "+628123456789"  # valid, becomes "+62 812 3456 789"

 628123456789  # valid, becomes "+62 812 3456 789"

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("phone::num::idn*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("phone::num::idn", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "+628123456789";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "+442087712924";
 my $errmsg = $validator->($data); # => "Must match regex pattern qr(\\A\\+62([0-9 ]{5,20})\\z)i"

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("phone::num::idn", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "+628123456789";
 my $res = $validator->($data); # => ["","+62 812 3456 789"]
 
 # a sample invalid data
 $data = "+442087712924";
 my $res = $validator->($data); # => ["Must match regex pattern qr(\\A\\+62([0-9 ]{5,20})\\z)i","+44 20 8771 2924"]

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
     state $validator = gen_validator("phone::num::idn*");
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
             schema => ['phone::num::idn*'],
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

This schema accepts Indonesian phone number e.g. +628123456789. If number does
not contain country code, it will be assumed to be '+62' (Indonesian calling
code). Some formatting characters like dashes and spaces are accepted, as long
as it passes L<Number::Phone> formatting. The number will be formatted using
international phone number formatting by the Number::Phone module, e.g. '+62 812
3456 789'.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Phone>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Phone>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Phone>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
