package Sah::Schema::perl::modname_or_prefix;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-20'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.035'; # VERSION

our $schema = [str => {
    summary => 'Perl module name (e.g. Foo::Bar) or prefix (e.g. Foo::Bar::)',
    description => <<'_',

Contains coercion rule so inputing `Foo-Bar` or `Foo/Bar` will be normalized to
`Foo::Bar` while inputing `Foo-Bar-` or `Foo/Bar/` will be normalized to
`Foo::Bar::`

See also: `perl::modname` and `perl::modprefix`.

_
    match => '\A[A-Za-z_][A-Za-z_0-9]*(::[A-Za-z_0-9]+)*(?:::)?\z',

    'x.perl.coerce_rules' => [
        'From_str::normalize_perl_modname_or_prefix',
    ],

    # provide a default completion which is from list of installed perl modules
    'x.completion' => 'perl_modname_or_prefix',

    examples => [
        {value=>'', valid=>0},
        {value=>'Foo::Bar', valid=>1},
        {value=>'Foo::Bar::', valid=>1},
        {value=>'Foo/Bar', valid=>1, validated_value=>'Foo::Bar'},
        {value=>'Foo/Bar/', valid=>1, validated_value=>'Foo::Bar::'},
        {value=>'Foo-Bar', valid=>1, validated_value=>'Foo::Bar'},
        {value=>'Foo-Bar-', valid=>1, validated_value=>'Foo::Bar::'},
        {value=>'Foo|Bar', valid=>0},
    ],

}, {}];

1;
# ABSTRACT: Perl module name (e.g. Foo::Bar) or prefix (e.g. Foo::Bar::)

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::modname_or_prefix - Perl module name (e.g. Foo::Bar) or prefix (e.g. Foo::Bar::)

=head1 VERSION

This document describes version 0.035 of Sah::Schema::perl::modname_or_prefix (from Perl distribution Sah-Schemas-Perl), released on 2021-01-20.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::modname_or_prefix*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("perl::modname_or_prefix*");
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
             schema => ['perl::modname_or_prefix*'],
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

 "Foo::Bar"  # valid

 "Foo::Bar::"  # valid

 "Foo/Bar"  # valid, becomes "Foo::Bar"

 "Foo/Bar/"  # valid, becomes "Foo::Bar::"

 "Foo-Bar"  # valid, becomes "Foo::Bar"

 "Foo-Bar-"  # valid, becomes "Foo::Bar::"

 "Foo|Bar"  # INVALID

=head1 DESCRIPTION

Contains coercion rule so inputing C<Foo-Bar> or C<Foo/Bar> will be normalized to
C<Foo::Bar> while inputing C<Foo-Bar-> or C<Foo/Bar/> will be normalized to
C<Foo::Bar::>

See also: C<perl::modname> and C<perl::modprefix>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Sah-Schemas-Perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
