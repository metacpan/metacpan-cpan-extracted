package Sah::Schema::unix::groupname;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-16'; # DATE
our $DIST = 'Sah-Schemas-Unix'; # DIST
our $VERSION = '0.013'; # VERSION

our $schema = [str => {
    summary => 'Unix group name',
    description => <<'_',

The checking follows POSIX rules: does not begin with a hyphen and only contains
[A-Za-z0-9._-].

The above rule allows integers like 1234, which can be confused with GID, so
this schema disallows pure integers.

The maximum length is 32 following libc6's limit.

_
    min_len => 1,
    max_len => 32,
    match => qr/(?=\A[A-Za-z0-9._][A-Za-z0-9._-]{0,31}\z)(?=.*[A-Za-z._-])/,

    examples => [
        {value=>'', valid=>0},
        {value=>'foo', valid=>1},
        {value=>'-andy', valid=>0},
        {value=>'1234', valid=>0},
        {value=>'andy2', valid=>1},
        {value=>'an dy', valid=>0},
        {value=>'an.dy', valid=>1},
        {value=>'a' x 33, value=>0, summary=>'Too long'},
    ],

}, {}];

1;
# ABSTRACT: Unix group name

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::unix::groupname - Unix group name

=head1 VERSION

This document describes version 0.013 of Sah::Schema::unix::groupname (from Perl distribution Sah-Schemas-Unix), released on 2020-10-16.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("unix::groupname*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("unix::groupname*");
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
             schema => ['unix::groupname*'],
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

 "foo"  # valid

 "-andy"  # INVALID

 1234  # INVALID

 "andy2"  # valid

 "an dy"  # INVALID

 "an.dy"  # valid

 0  # INVALID (Too long)

=head1 DESCRIPTION

The checking follows POSIX rules: does not begin with a hyphen and only contains
[A-Za-z0-9._-].

The above rule allows integers like 1234, which can be confused with GID, so
this schema disallows pure integers.

The maximum length is 32 following libc6's limit.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Unix>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Unix>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Unix>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
