package Sah::Schema::date::tz_offset;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-09'; # DATE
our $DIST = 'Sah-Schemas-Date'; # DIST
our $VERSION = '0.019'; # VERSION

our @TZ_STRING_OFFSETS;
our @TZ_INT_OFFSETS;

BEGIN {

    # taken from Wikipedia page: https://en.wikipedia.org/wiki/UTC%2B14:00 on Feb 27, 2020
    @TZ_STRING_OFFSETS = qw(
    -12:00 -11:00 -10:30 -10:00 -09:30 -09:00 -08:30 -08:00 -07:00
    -06:00 -05:00 -04:30 -04:00 -03:30 -03:00 -02:30 -02:00 -01:00 -00:44 -00:25:21
    -00:00 +00:00 +00:20 +00:30 +01:00 +01:24 +01:30 +02:00 +02:30 +03:00 +03:30 +04:00 +04:30 +04:51 +05:00 +05:30 +05:40 +05:45
    +06:00 +06:30 +07:00 +07:20 +07:30 +08:00 +08:30 +08:45 +09:00 +09:30 +09:45 +10:00 +10:30 +11:00 +11:30
    +12:00 +12:45 +13:00 +13:45 +14:00
);

for (@TZ_STRING_OFFSETS) {
    /^([+-])(\d\d):(\d\d)(?::(\d\d))?$/
        or die "Unrecognized tz offset string: $_";
    push @TZ_INT_OFFSETS, ($1 eq '-' ? -1:1) * ($2*3600 + $3*60 + ($4 ? $4 : 0));
}

#use DD; dd \@TZ_INT_OFFSETS;

} # BEGIN

our $schema = [int => {
    summary => 'Timezone offset in seconds from UTC (only known offsets are allowd, coercible from string), e.g. 25200 or "+07:00"',
    in => \@TZ_INT_OFFSETS,
    description => <<'_',

Only timezone offsets that are known to exist are allowed. For example, 1 second
(+00:00:01) is not allowed. See `date::tz_offset_lax` for a more relaxed
validation.

A coercion from these form of string is provided:

    UTC

    UTC-14 or UTC+12 or UTC+12:45 or UTC-00:25:21
    -14 or +12, -1400 or +12:00

A coercion from timezone name is also provided.

_
    'x.perl.coerce_rules' => ['From_str::tz_offset_strings'],
    'x.completion' => sub {
        require Complete::TZ;
        require Complete::Util;

        my %args = @_;

        Complete::Util::combine_answers(
            Complete::TZ::complete_tz_offset(word => $args{word}),
            Complete::TZ::complete_tz_name(word => $args{word}),
        );
    },
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
        {value=>'UTC+12:01', valid=>0, summary=>'Unknown offset'},
    ],
}];

1;

# ABSTRACT: Timezone offset in seconds from UTC (only known offsets are allowd, coercible from string), e.g. 25200 or "+07:00"

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::date::tz_offset - Timezone offset in seconds from UTC (only known offsets are allowd, coercible from string), e.g. 25200 or "+07:00"

=head1 VERSION

This document describes version 0.019 of Sah::Schema::date::tz_offset (from Perl distribution Sah-Schemas-Date), released on 2023-12-09.

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

 "UTC+12:01"  # INVALID (Unknown offset)

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("date::tz_offset*");
 say $validator->($data) ? "valid" : "INVALID!";

The above validator returns a boolean result (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("date::tz_offset", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "-12:00";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "UTC-13";
 my $errmsg = $validator->($data); # => "Must be one of [-43200,-39600,-37800,-36000,-34200,-32400,-30600,-28800,-25200,-21600,-18000,-16200,-14400,-12600,-10800,-9000,-7200,-3600,-2640,-1521,0,0,1200,1800,3600,5040,5400,7200,9000,10800,12600,14400,16200,17460,18000,19800,20400,20700,21600,23400,25200,26400,27000,28800,30600,31500,32400,34200,35100,36000,37800,39600,41400,43200,45900,46800,49500,50400,-43200,-39600,-37800,-36000,-34200,-32400,-30600,-28800,-25200,-21600,-18000,-16200,-14400,-12600,-10800,-9000,-7200,-3600,-2640,-1521,0,0,1200,1800,3600,5040,5400,7200,9000,10800,12600,14400,16200,17460,18000,19800,20400,20700,21600,23400,25200,26400,27000,28800,30600,31500,32400,34200,35100,36000,37800,39600,41400,43200,45900,46800,49500,50400,-43200,-39600,-37800,-36000,-34200,-32400,-30600,-28800,-25200,-21600,-18000,-16200,-14400,-12600,-10800,-9000,-7200,-3600,-2640,-1521,0,0,1200,1800,3600,5040,5400,7200,9000,10800,12600,14400,16200,17460,18000,19800,20400,20700,21600,23400,25200,26400,27000,28800,30600,31500,32400,34200,35100,36000,37800,39600,41400,43200,45900,46800,49500,50400]"

Often a schema has coercion rule or default value rules, so after validation the
validated value will be different from the original. To return the validated
(set-as-default, coerced, prefiltered) value:

 my $validator = gen_validator("date::tz_offset", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "-12:00";
 my $res = $validator->($data); # => ["",-43200]
 
 # a sample invalid data
 $data = "UTC-13";
 my $res = $validator->($data); # => ["Must be one of [-43200,-39600,-37800,-36000,-34200,-32400,-30600,-28800,-25200,-21600,-18000,-16200,-14400,-12600,-10800,-9000,-7200,-3600,-2640,-1521,0,0,1200,1800,3600,5040,5400,7200,9000,10800,12600,14400,16200,17460,18000,19800,20400,20700,21600,23400,25200,26400,27000,28800,30600,31500,32400,34200,35100,36000,37800,39600,41400,43200,45900,46800,49500,50400,-43200,-39600,-37800,-36000,-34200,-32400,-30600,-28800,-25200,-21600,-18000,-16200,-14400,-12600,-10800,-9000,-7200,-3600,-2640,-1521,0,0,1200,1800,3600,5040,5400,7200,9000,10800,12600,14400,16200,17460,18000,19800,20400,20700,21600,23400,25200,26400,27000,28800,30600,31500,32400,34200,35100,36000,37800,39600,41400,43200,45900,46800,49500,50400,-43200,-39600,-37800,-36000,-34200,-32400,-30600,-28800,-25200,-21600,-18000,-16200,-14400,-12600,-10800,-9000,-7200,-3600,-2640,-1521,0,0,1200,1800,3600,5040,5400,7200,9000,10800,12600,14400,16200,17460,18000,19800,20400,20700,21600,23400,25200,26400,27000,28800,30600,31500,32400,34200,35100,36000,37800,39600,41400,43200,45900,46800,49500,50400]",-46800]

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
     state $validator = gen_validator("date::tz_offset*");
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
             schema => ['date::tz_offset*'],
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

 % validate-with-sah '"date::tz_offset*"' '"data..."'

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
         sah2type('date::tz_offset*', name=>'DateTzOffset')
     );
 }

 use My::Types qw(DateTzOffset);
 DateTzOffset->assert_valid($data);

=head1 DESCRIPTION

Only timezone offsets that are known to exist are allowed. For example, 1 second
(+00:00:01) is not allowed. See C<date::tz_offset_lax> for a more relaxed
validation.

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

This software is copyright (c) 2023, 2022, 2020, 2019 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
