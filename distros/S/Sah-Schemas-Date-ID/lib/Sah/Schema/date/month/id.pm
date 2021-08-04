package Sah::Schema::date::month::id;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-04'; # DATE
our $DIST = 'Sah-Schemas-Date-ID'; # DIST
our $VERSION = '0.007'; # VERSION

our $schema = [cistr => {
    summary => 'Month number/name (abbreviated or full, in Indonesian)',
    in => [
        1..12,
        qw/jan feb mar apr mei jun jul agu sep okt nov des/,
        qw/januari februari maret april juni juli agustus september oktober november desember/,
    ],
    description => <<'_',

Note that name is not coerced to number; use
<pm:Sah::Schema::date::month_num::id> for that.

See also related schemas for other locales, e.g.
<pm:Sah::Schema::date::month::en> (English),
<pm:Sah::Schema::date::month::en_or_id> (English/Indonesian), etc.

_
    examples => [
        {value=>'', valid=>0, summary=>'Empty string'},
        {value=>'jan', valid=>1},
        {value=>'FEBRUARI', valid=>1},
        {value=>'march', valid=>0, summary=>'English'},
        {value=>0, valid=>0, summary=>'Not a name'},
        {value=>1, valid=>1},
        {value=>12, valid=>1},
        {value=>13, valid=>0, summary=>'Not a name'},
    ],
}];

1;

# ABSTRACT: Month number/name (abbreviated or full, in Indonesian)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::date::month::id - Month number/name (abbreviated or full, in Indonesian)

=head1 VERSION

This document describes version 0.007 of Sah::Schema::date::month::id (from Perl distribution Sah-Schemas-Date-ID), released on 2021-08-04.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # INVALID (Empty string)

 "jan"  # valid

 "FEBRUARI"  # valid

 "march"  # INVALID (English)

 0  # INVALID (Not a name)

 1  # valid

 12  # valid

 13  # INVALID (Not a name)

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("date::month::id*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean value (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("date::month::id", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = 12;
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = 0;
 my $errmsg = $validator->($data); # => "Must be one of [1,2,3,4,5,6,7,8,9,10,11,12,\"jan\",\"feb\",\"mar\",\"apr\",\"mei\",\"jun\",\"jul\",\"agu\",\"sep\",\"okt\",\"nov\",\"des\",\"januari\",\"februari\",\"maret\",\"april\",\"juni\",\"juli\",\"agustus\",\"september\",\"oktober\",\"november\",\"desember\"]"

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("date::month::id", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = 12;
 my $res = $validator->($data); # => ["",12]
 
 # a sample invalid data
 $data = 0;
 my $res = $validator->($data); # => ["Must be one of [1,2,3,4,5,6,7,8,9,10,11,12,\"jan\",\"feb\",\"mar\",\"apr\",\"mei\",\"jun\",\"jul\",\"agu\",\"sep\",\"okt\",\"nov\",\"des\",\"januari\",\"februari\",\"maret\",\"april\",\"juni\",\"juli\",\"agustus\",\"september\",\"oktober\",\"november\",\"desember\"]",0]

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
     state $validator = gen_validator("date::month::id*");
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
             schema => ['date::month::id*'],
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

Note that name is not coerced to number; use
L<Sah::Schema::date::month_num::id> for that.

See also related schemas for other locales, e.g.
L<Sah::Schema::date::month::en> (English),
L<Sah::Schema::date::month::en_or_id> (English/Indonesian), etc.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date-ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date-ID>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date-ID>

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
