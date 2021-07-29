package Sah::Schema::perl::modname;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-20'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.038'; # VERSION

use Regexp::Pattern::Perl::Module ();

our $schema = [str => {
    summary => 'Perl module name, e.g. Foo::Bar',
    description => <<'_',

This is a schema you can use when you want to accept a Perl module name. It
offers basic checking of syntax as well as a couple of conveniences. First, it
offers completion from list of locally installed Perl modules. Second, it
contains coercion rule so you can also input `Foo-Bar`, `Foo/Bar`, `Foo/Bar.pm`
or even 'Foo.Bar' and it will be normalized into `Foo::Bar`.

To see this schema in action on the CLI, you can try e.g. the `pmless` script
from <pm:App::PMUtils> and activate its tab completion (see its manpage for more
details). Then on the CLI try typing:

    % pmless M/<tab>
    % pmless dzp/<tab>
    % pmless Module/List/Wildcard
    % pmless Module::List::Wildcard

Note that this schema does not check that the Perl module exists or is installed
locally. To check that, use the `perl::modname::installed` schema. And there's
also a `perl::modname::not_installed` schema.

_
    match => '\\A(?:' . $Regexp::Pattern::Perl::Module::RE{perl_modname}{pat} . ')\\z',

    'prefilters' => [
        'Perl::normalize_perl_modname',
    ],

    # provide a default completion which is from list of installed perl modules
    'x.completion' => 'perl_modname',

    examples => [
        {value=>'', valid=>0},
        {value=>'Foo::Bar', valid=>1},
        {value=>'Foo-Bar', valid=>1, validated_value=>'Foo::Bar'},
        {value=>'Foo/Bar', valid=>1, validated_value=>'Foo::Bar'},
        {value=>'Foo/Bar.pm', valid=>1, validated_value=>'Foo::Bar'},
        {value=>'Foo.Bar', valid=>1, validated_value=>'Foo::Bar'},
        {value=>'Foo|Bar', valid=>0},
    ],

}];

1;
# ABSTRACT: Perl module name, e.g. Foo::Bar

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::modname - Perl module name, e.g. Foo::Bar

=head1 VERSION

This document describes version 0.038 of Sah::Schema::perl::modname (from Perl distribution Sah-Schemas-Perl), released on 2021-07-20.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::modname*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("perl::modname*");
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
             schema => ['perl::modname*'],
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

 "Foo::Bar"  # valid

 "Foo-Bar"  # valid, becomes "Foo::Bar"

 "Foo/Bar"  # valid, becomes "Foo::Bar"

 "Foo/Bar.pm"  # valid, becomes "Foo::Bar"

 "Foo.Bar"  # valid, becomes "Foo::Bar"

 "Foo|Bar"  # INVALID

=head1 DESCRIPTION

This is a schema you can use when you want to accept a Perl module name. It
offers basic checking of syntax as well as a couple of conveniences. First, it
offers completion from list of locally installed Perl modules. Second, it
contains coercion rule so you can also input C<Foo-Bar>, C<Foo/Bar>, C<Foo/Bar.pm>
or even 'Foo.Bar' and it will be normalized into C<Foo::Bar>.

To see this schema in action on the CLI, you can try e.g. the C<pmless> script
from L<App::PMUtils> and activate its tab completion (see its manpage for more
details). Then on the CLI try typing:

 % pmless M/<tab>
 % pmless dzp/<tab>
 % pmless Module/List/Wildcard
 % pmless Module::List::Wildcard

Note that this schema does not check that the Perl module exists or is installed
locally. To check that, use the C<perl::modname::installed> schema. And there's
also a C<perl::modname::not_installed> schema.

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

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
