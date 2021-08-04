package Sah::Schema::date::month_nums::id;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-04'; # DATE
our $DIST = 'Sah-Schemas-Date-ID'; # DIST
our $VERSION = '0.007'; # VERSION

our $schema = ['array' => {
    summary => 'Array of required month numbers, coercible from Indonesian full/abbreviated month names',
    of => ['date::month_num::id', {req=>1}],
    'x.perl.coerce_rules' => ['From_str::comma_sep'],
    description => <<'_',

See also related schemas for other locales, e.g.
<pm:Sah::Schema::date::month_nums> (English),
<pm:Sah::Schema::date::month_nums::en_or_id> (English/Indonesian), etc.

_
    examples => [
        {value=>'', valid=>1, validated_value=>[]},
        {value=>'jan', valid=>1, validated_value=>[1]},
        {value=>'AGU', valid=>1, validated_value=>[8]},
        {value=>'aug', valid=>0},
        {value=>0, valid=>0, summary=>'Has number not in 1-12'},
        {value=>[1,undef], valid=>0, summary=>'Has undef'},
        {value=>"1,agu", valid=>1, validated_value=>[1,8]},
        {value=>"1,foo", valid=>0, summary=>'Has unknown month name'},
        {value=>[1,"agu"], valid=>1, validated_value=>[1,8]},
        {value=>"1,12", valid=>1, validated_value=>[1,12]},
        {value=>"1,12,13", valid=>0, summary=>'Has number not in 1-12'},
        {value=>[1,12,13], valid=>0, summary=>'Has number not in 1-12'},
    ],
}];

1;

# ABSTRACT: Array of required month numbers, coercible from Indonesian full/abbreviated month names

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::date::month_nums::id - Array of required month numbers, coercible from Indonesian full/abbreviated month names

=head1 VERSION

This document describes version 0.007 of Sah::Schema::date::month_nums::id (from Perl distribution Sah-Schemas-Date-ID), released on 2021-08-04.

=head1 SYNOPSIS

=head2 Sample data and validation results against this schema

 ""  # valid, becomes []

 "jan"  # valid, becomes [1]

 "AGU"  # valid, becomes [8]

 "aug"  # INVALID

 0  # INVALID (Has number not in 1-12)

 [1,undef]  # INVALID (Has undef)

 "1,agu"  # valid, becomes [1,8]

 "1,foo"  # INVALID (Has unknown month name)

 [1,"agu"]  # valid, becomes [1,8]

 "1,12"  # valid, becomes [1,12]

 "1,12,13"  # INVALID (Has number not in 1-12)

 [1,12,13]  # INVALID (Has number not in 1-12)

=head2 Using with Data::Sah

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("date::month_nums::id*");
 say $validator->($data) ? "valid" : "INVALID!";

The above schema returns a boolean value (true if data is valid, false if
otherwise). To return an error message string instead (empty string if data is
valid, a non-empty error message otherwise):

 my $validator = gen_validator("date::month_nums::id", {return_type=>'str_errmsg'});
 my $errmsg = $validator->($data);
 
 # a sample valid data
 $data = [1,"agu"];
 my $errmsg = $validator->($data); # => ""
 
 # a sample invalid data
 $data = "aug";
 my $errmsg = $validator->($data); # => "\@[0]: Not of type integer"

Often a schema has coercion rule or default value, so after validation the
validated value is different. To return the validated (set-as-default, coerced,
prefiltered) value:

 my $validator = gen_validator("date::month_nums::id", {return_type=>'str_errmsg+val'});
 my $res = $validator->($data); # [$errmsg, $validated_val]
 
 # a sample valid data
 $data = [1,8];
 my $res = $validator->($data); # => ["",[1,8]]
 
 # a sample invalid data
 $data = "aug";
 my $res = $validator->($data); # => ["\@[0]: Not of type integer",["aug"]]

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
     state $validator = gen_validator("date::month_nums::id*");
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
             schema => ['date::month_nums::id*'],
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

Like the L<date::month_nums|Sah::Schema::date::month_nums> except the elements
are L<date::month_num::id|Sah::Schema::date::month_num::id> instead of
L<date::month_num|Sah::Schema::date::month_num>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Date-ID>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Date-ID>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Date-ID>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schema::date::month_nums>

L<Sah::Schema::date::month_nums::en_or_id>

L<Sah::Schema::date::month_num::id>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
