package Sah::Schema::firefox::local_profile_name;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-04'; # DATE
our $DIST = 'Sah-Schemas-Firefox'; # DIST
our $VERSION = '0.002'; # VERSION

# TODO: allow selecting local Firefox installation

our $schema = ["firefox::profile_name" => {
    summary => 'Firefox profile name, must exist in local Firefox installation',
    prefilters => ['Firefox::check_profile_name_exists'],
    examples => [
        {
            value   => '',
            valid   => 0,
            test    => 0,
        },
        {
            summary => 'Assuming the default profile name exists in local Firefox installation',
            value   => 'default',
            valid   => 1,
            test    => 0,
        },
    ],
}, {}];

1;
# ABSTRACT: Firefox profile name, must exist in local Firefox installation

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::firefox::local_profile_name - Firefox profile name, must exist in local Firefox installation

=head1 VERSION

This document describes version 0.002 of Sah::Schema::firefox::local_profile_name (from Perl distribution Sah-Schemas-Firefox), released on 2020-06-04.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("firefox::local_profile_name*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("firefox::local_profile_name*");
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
             schema => ['firefox::local_profile_name*'],
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

 "default"  # valid

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Firefox>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Firefox>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Firefox>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
