package Sah::Schema::date::tz_offset_lax;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-12'; # DATE
our $DIST = 'Sah-Schemas-Date'; # DIST
our $VERSION = '0.018'; # VERSION

our $schema = ['date::tz_offset' => {
    summary => 'Timezone offset in seconds from UTC (any offset is allowed, coercible from string), e.g. 1 or 25200 e.g. UTC+7',
    'merge.delete.in' => [],
    min => -12*3600,
    max => +14*3600,
    description => <<'_',

This schema allows timezone offsets that are not known to exist, e.g. 1 second
(+00:00:01). If you only want ot allow timezone offsets that are known to exist,
see the `date::tz_offset` schema.

A coercion from these form of string is provided:

    UTC

    UTC-14 or UTC+12 or UTC+12:45 or UTC-00:25:21
    -14 or +12, -1400 or +12:00

A coercion from timezone name is also provided.

_
    examples => [
        {value=>'', valid=>0},
        {value=>'UTC', valid=>1, validated_value=>0},
        {value=>'3600', valid=>1, validated_value=>3600},
        {value=>'-43200', valid=>1, validated_value=>-43200},
        {value=>'-12', valid=>1, validated_value=>-12*3600},
        {value=>'-1200', valid=>1, validated_value=>-12*3600},
        {value=>'-12:00', valid=>1, validated_value=>-12*3600},
        {value=>'UTC-12', valid=>1, validated_value=>-12*3600},
        {value=>'UTC-1200', valid=>1, validated_value=>-12*3600},
        {value=>'UTC+12:45', valid=>1, validated_value=>+12.75*3600},
        {value=>'UTC-13', valid=>0},
        {value=>'UTC+12:01', valid=>1, validated_value=>+(12*3600+60)},
    ],
}];

1;

# ABSTRACT: Timezone offset in seconds from UTC (any offset is allowed, coercible from string), e.g. 1 or 25200 e.g. UTC+7

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::date::tz_offset_lax - Timezone offset in seconds from UTC (any offset is allowed, coercible from string), e.g. 1 or 25200 e.g. UTC+7

=head1 VERSION

This document describes version 0.018 of Sah::Schema::date::tz_offset_lax (from Perl distribution Sah-Schemas-Date), released on 2022-10-12.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID

 "UTC"  # valid, becomes 0

 3600  # valid, becomes 3600

 -43200  # valid, becomes -43200

 -12  # valid, becomes -43200

 -1200  # valid, becomes -43200

 "-12:00"  # valid, becomes -43200

 "UTC-12"  # valid, becomes -43200

 "UTC-1200"  # valid, becomes -43200

 "UTC+12:45"  # valid, becomes 45900

 "UTC-13"  # INVALID

 "UTC+12:01"  # valid, becomes 43260

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("date::tz_offset_lax*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("date::tz_offset_lax", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "UTC+12:01";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "";
 my $errmsg = $validator->($data); # => "Cannot be empty"

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("date::tz_offset_lax", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "UTC+12:01";
 my $res = $validator->($data); # => ["",43260]
 
 # a sample invalid data
 $data = "";
 my $res = $validator->($data); # => ["Cannot be empty",""]

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
     state $validator = gen_validator("date::tz_offset_lax*");
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
             schema => ['date::tz_offset_lax*'],
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
         sah2type('$sch_name*', name=>'DateTzOffsetLax')
     );
 }

 use My::Types qw(DateTzOffsetLax);
 DateTzOffsetLax->assert_valid($data);

=head1 DESCRIPTION

This schema allows timezone offsets that are not known to exist, e.g. 1 second
(+00:00:01). If you only want ot allow timezone offsets that are known to exist,
see the C<date::tz_offset> schema.

A coercion from these form of string is provided:

 UTC
 
 UTC-14 or UTC+12 or UTC+12:45 or UTC-00:25:21
 -14 or +12, -1400 or +12:00

A coercion from timezone name is also provided.

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

This software is copyright (c) 2022, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
