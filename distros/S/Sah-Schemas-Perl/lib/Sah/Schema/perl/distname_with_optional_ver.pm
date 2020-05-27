package Sah::Schema::perl::distname_with_optional_ver;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-21'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.032'; # VERSION

our $schema = [str => {
    summary => 'Perl distribution name (e.g. Foo-Bar) with optional version number suffix (e.g. Foo-Bar@0.001)',
    match => '\A[A-Za-z_][A-Za-z_0-9]*(-[A-Za-z_0-9]+)*(@[0-9][0-9A-Za-z]*(\\.[0-9A-Za-z_]+)*)?\z',
    'x.perl.coerce_rules' => [
        'From_str::normalize_perl_distname',
    ],

    # provide a default completion which is from list of installed perl distributions
    'x.completion' => 'perl_distname',

    description => <<'_',

For convenience (particularly in CLI with tab completion), you can input one of:

    Foo::Bar
    Foo/Bar
    Foo/Bar.pm
    Foo.Bar

and it will be coerced into Foo-Bar form.

_

    examples => [
        {value=>'', valid=>0},
        {value=>'Foo-Bar', valid=>1},
        {value=>'Foo-Bar@1', valid=>1},
        {value=>'Foo-Bar@1.0', valid=>1},
        {value=>'Foo::Bar@1.0.0', valid=>1, validated_value=>'Foo-Bar@1.0.0'},
        {value=>'Foo-Bar@0.5_001', valid=>1},
        {value=>'Foo::Bar@0.5_001', valid=>1, validated_value=>'Foo-Bar@0.5_001'},
        {value=>'Foo-Bar@a', valid=>0},
    ],

}, {}];

1;
# ABSTRACT: Perl distribution name (e.g. Foo-Bar) with optional version number suffix (e.g. Foo-Bar@0.001)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::distname_with_optional_ver - Perl distribution name (e.g. Foo-Bar) with optional version number suffix (e.g. Foo-Bar@0.001)

=head1 VERSION

This document describes version 0.032 of Sah::Schema::perl::distname_with_optional_ver (from Perl distribution Sah-Schemas-Perl), released on 2020-05-21.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::distname_with_optional_ver*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("perl::distname_with_optional_ver*");
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
             schema => ['perl::distname_with_optional_ver*'],
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

 ""  # INVALID

 "Foo-Bar"  # valid

 "Foo-Bar\@1"  # valid

 "Foo-Bar\@1.0"  # valid

 "Foo::Bar\@1.0.0"  # valid, becomes "Foo-Bar\@1.0.0"

 "Foo-Bar\@0.5_001"  # valid

 "Foo::Bar\@0.5_001"  # valid, becomes "Foo-Bar\@0.5_001"

 "Foo-Bar\@a"  # INVALID

=head1 DESCRIPTION

For convenience (particularly in CLI with tab completion), you can input one of:

 Foo::Bar
 Foo/Bar
 Foo/Bar.pm
 Foo.Bar

and it will be coerced into Foo-Bar form.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
