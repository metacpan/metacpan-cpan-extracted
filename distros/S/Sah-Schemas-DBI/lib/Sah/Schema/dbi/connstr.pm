package Sah::Schema::dbi::connstr;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-19'; # DATE
our $DIST = 'Sah-Schemas-DBI'; # DIST
our $VERSION = '0.005'; # VERSION

our $schema = [str => {
    summary => 'DBI connection string',
    description => <<'_',


_
    match => '\Adbi:\w+:.+\z',
    'x.completion' => ['dbi_connstr'],
    examples => [
        {value=>'', valid=>0},
        {value=>'dbi:SQLite:dbname=foo', valid=>1},
        {value=>'DBI:SQLite:dbname=foo', valid=>0},
        {value=>'dbi:Foo', valid=>0},
        {value=>'dbi:Foo:bar=baz', valid=>1},
    ],
}, {}];

1;
# ABSTRACT: DBI connection string

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::dbi::connstr - DBI connection string

=head1 VERSION

This document describes version 0.005 of Sah::Schema::dbi::connstr (from Perl distribution Sah-Schemas-DBI), released on 2021-07-19.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("dbi::connstr*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("dbi::connstr*");
     $validator->(\@args);
     ...
 }

To specify schema in L<Rinci> function metadata and use the metadata with
L<Perinci::CmdLine> to create a CLI:

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
             schema => ['dbi::connstr*'],
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
 Perinci::CmdLine::Any->new(url=>'MyApp::myfunc')->run;

 # in command-line
 % ./myapp.pl --help
 myapp - Routine to do blah ...
 ...

 % ./myapp.pl --version

 % ./myapp.pl --arg1 ...

Sample data:

 ""  # INVALID

 "dbi:SQLite:dbname=foo"  # valid

 "DBI:SQLite:dbname=foo"  # INVALID

 "dbi:Foo"  # INVALID

 "dbi:Foo:bar=baz"  # valid

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-DBI>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-DBI>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-DBI>

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
