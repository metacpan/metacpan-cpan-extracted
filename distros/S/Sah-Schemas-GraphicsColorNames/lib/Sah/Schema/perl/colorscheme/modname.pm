package Sah::Schema::perl::colorscheme::modname;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-03-20'; # DATE
our $DIST = 'Sah-Schemas-GraphicsColorNames'; # DIST
our $VERSION = '0.004'; # VERSION

use Sah::PSchema qw(get_schema);
use Sah::PSchema::perl::modname; # not detected yet

our $schema = get_schema(
    'perl::modname',
    {ns_prefix=>'Graphics::ColorNames'},
    {
        summary => 'Perl module name in the Graphics::ColorNames:: namespace without the namespace prefix, e.g. WWW or X',
        examples => [
            {value=>'', valid=>0},
            {value=>'WWW', valid=>1},
            {value=>'WWW::Foo', valid=>1, validated_value=>'WWW::Foo'},
            {value=>'WWW/Foo', valid=>1, validated_value=>'WWW::Foo'},
            {value=>'Foo Bar', valid=>0, summary=>'contains whitespace'},
        ],
    },
);

1;
# ABSTRACT: Perl module name in the Graphics::ColorNames:: namespace without the namespace prefix, e.g. WWW or X

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::colorscheme::modname - Perl module name in the Graphics::ColorNames:: namespace without the namespace prefix, e.g. WWW or X

=head1 VERSION

This document describes version 0.004 of Sah::Schema::perl::colorscheme::modname (from Perl distribution Sah-Schemas-GraphicsColorNames), released on 2021-03-20.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::colorscheme::modname*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("perl::colorscheme::modname*");
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
             schema => ['perl::colorscheme::modname*'],
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

 "WWW"  # valid

 "WWW::Foo"  # valid, becomes "WWW::Foo"

 "WWW/Foo"  # valid, becomes "WWW::Foo"

 "Foo Bar"  # INVALID (contains whitespace)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-GraphicsColorNames>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-GraphicsColorNames>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Sah-Schemas-GraphicsColorNames/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
