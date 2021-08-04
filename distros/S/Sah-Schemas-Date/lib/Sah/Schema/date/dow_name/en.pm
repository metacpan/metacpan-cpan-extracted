package Sah::Schema::date::dow_name::en;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-04'; # DATE
our $DIST = 'Sah-Schemas-Date'; # DIST
our $VERSION = '0.017'; # VERSION

our $schema = [cistr => {
    summary => 'Day-of-week name (abbreviated or full, in English)',
    in => [
        qw/su mo tu we th fr sa/,
        qw/sun mon tue wed thu fri sat/,
        qw/sunday monday tuesday wednesday thursday friday saturday/,
    ],
    description => <<'_',

See also: <pm:Sah::Schema::date::dow_num>.

See also related schemas for other locales, e.g.
<pm:Sah::Schema::date::dow_name::id> (Indonesian),
<pm:Sah::Schema::date::dow_name::en_or_id> (English/Indonesian), etc.

_
    examples => [
        {value=>'', valid=>0, summary=>'Empty string'},
        {value=>'su', valid=>1},
        {value=>'mOn', valid=>1},
        {value=>'TUESDAY', valid=>1},
        {value=>'foo', valid=>0, summary=>'Not a day-of-week name'},
    ],
}];

1;

# ABSTRACT: Day-of-week name (abbreviated or full, in English)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::date::dow_name::en - Day-of-week name (abbreviated or full, in English)

=head1 VERSION

This document describes version 0.017 of Sah::Schema::date::dow_name::en (from Perl distribution Sah-Schemas-Date), released on 2021-08-04.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID (Empty string)

 "su"  # valid

 "mOn"  # valid

 "TUESDAY"  # valid

 "foo"  # INVALID (Not a day-of-week name)

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("date::dow_name::en*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean value (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("date::dow_name::en", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = "TUESDAY";
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "";
 my $errmsg = $validator->($data); # => "Must be one of [\"su\",\"mo\",\"tu\",\"we\",\"th\",\"fr\",\"sa\",\"sun\",\"mon\",\"tue\",\"wed\",\"thu\",\"fri\",\"sat\",\"sunday\",\"monday\",\"tuesday\",\"wednesday\",\"thursday\",\"friday\",\"saturday\"]"

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("date::dow_name::en", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = "TUESDAY";
 my $res = $validator->($data); # => ["","TUESDAY"]
 
 # a sample invalid data
 $data = "";
 my $res = $validator->($data); # => ["Must be one of [\"su\",\"mo\",\"tu\",\"we\",\"th\",\"fr\",\"sa\",\"sun\",\"mon\",\"tue\",\"wed\",\"thu\",\"fri\",\"sat\",\"sunday\",\"monday\",\"tuesday\",\"wednesday\",\"thursday\",\"friday\",\"saturday\"]",""]

Data::Sah can also create validator that returns a hash of detaild error
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
     state $validator = gen_validator("date::dow_name::en*");
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
             schema => ['date::dow_name::en*'],
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

See also: L<Sah::Schema::date::dow_num>.

See also related schemas for other locales, e.g.
L<Sah::Schema::date::dow_name::id> (Indonesian),
L<Sah::Schema::date::dow_name::en_or_id> (English/Indonesian), etc.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
