package Sah::Schema::bencher::participant;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-23'; # DATE
our $DIST = 'Sah-Schemas-Bencher'; # DIST
our $VERSION = '1.054.1'; # VERSION

our $schema = ['defhash', {
    summary => 'A benchmark participant',
    'merge.add.keys' => {
        defhash_v => ['int', {req=>1, is=>1}],
        v => ['int', {req=>1, is=>1}],

        module => ['perl::modname', {req=>1}],
        modules => ['perl::modnames', {req=>1}],
        helper_modules => ['perl::modnames', {req=>1}],

        function => ['str', {req=>1}], # XXX: funcname
        fcall_template => ['str', {req=>1}], # XXX: funcname
        code_template => ['str', {req=>1}], # XXX: funcname
        code => ['str', {req=>1}], # XXX: funcname
        cmdline => ['str_or_aos1', {req=>1}],
        cmdline_template => ['str_or_aos1', {req=>1}],
        perl_cmdline => ['str_or_aos1', {req=>1}],
        perl_cmdline_template => ['str_or_aos1', {req=>1}],

        result_is_list => ['bool', {req=>1, default=>0}],
        include_by_default => ['bool', {req=>1, default=>1}],
    },
    'keys.restrict' => 1,

    # TODO: function depends on module

    # TODO: either module+function or fcall_template or code_template or code or
    # or cmdline or cmdline_template or perl_cmdline or perl_cmdline_template

}];

1;
# ABSTRACT: A benchmark participant

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::bencher::participant - A benchmark participant

=head1 VERSION

This document describes version 1.054.1 of Sah::Schema::bencher::participant (from Perl distribution Sah-Schemas-Bencher), released on 2021-07-23.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("bencher::participant*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("bencher::participant*");
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
             schema => ['bencher::participant*'],
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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Bencher>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Bencher>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Bencher>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
