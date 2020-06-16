package Sah::Schema::perl::filename;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-16'; # DATE
our $DIST = 'Sah-Schemas-Perl'; # DIST
our $VERSION = '0.033'; # VERSION

our $schema = [str => {
    summary => 'Filename of Perl script/module/POD, e.g. /path/Foo/Bar.pm',
    description => <<'_',

Use this schema if you want to accept a filesystem path containing Perl script,
module, or POD. The value of this schema is in the convenience of CLI
completion, as well as coercion from script or module name.

String containing filename of a Perl script or module or POD. For convenience,
when value is in the form of:

    Foo
    Foo.pm
    Foo.pod
    Foo::Bar
    Foo/Bar
    Foo/Bar.pm
    Foo/Bar.pod

and a matching .pod or .pm file is found in `@INC`, then it will be coerced
(converted) into the path of that .pod/.pm file, e.g.:

    /home/ujang/perl5/perlbrew/perls/perl-5.24.0/lib/site_perl/5.24.0/Foo/Bar.pm
    lib/Foo/Bar.pod

To prevent such coercion, you can use prefixing path, e.g.:

    ./Foo::Bar
    ../Foo/Bar
    /path/to/Foo/Bar

This schema comes with convenience completion too.

_
    'x.perl.coerce_rules' => [
        'From_str::convert_perl_pm_or_pod_to_path',
    ],
    'x.completion' => sub {
        require Complete::File;
        require Complete::Module;
        require Complete::Util;

        my %args = @_;
        my $word = $args{word};

        my @answers;
        push @answers, Complete::File::complete_file(word => $word);
        if ($word =~ m!\A\w*((?:::|/)\w+)*\z!) {
            push @answers, Complete::Module::complete_module(word => $word);
        }

        Complete::Util::combine_answers(@answers);
    },

}, {}];

1;
# ABSTRACT: Filename of Perl script/module/POD, e.g. /path/Foo/Bar.pm

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::filename - Filename of Perl script/module/POD, e.g. /path/Foo/Bar.pm

=head1 VERSION

This document describes version 0.033 of Sah::Schema::perl::filename (from Perl distribution Sah-Schemas-Perl), released on 2020-06-16.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("perl::filename*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("perl::filename*");
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
             schema => ['perl::filename*'],
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

=head1 DESCRIPTION

Use this schema if you want to accept a filesystem path containing Perl script,
module, or POD. The value of this schema is in the convenience of CLI
completion, as well as coercion from script or module name.

String containing filename of a Perl script or module or POD. For convenience,
when value is in the form of:

 Foo
 Foo.pm
 Foo.pod
 Foo::Bar
 Foo/Bar
 Foo/Bar.pm
 Foo/Bar.pod

and a matching .pod or .pm file is found in C<@INC>, then it will be coerced
(converted) into the path of that .pod/.pm file, e.g.:

 /home/ujang/perl5/perlbrew/perls/perl-5.24.0/lib/site_perl/5.24.0/Foo/Bar.pm
 lib/Foo/Bar.pod

To prevent such coercion, you can use prefixing path, e.g.:

 ./Foo::Bar
 ../Foo/Bar
 /path/to/Foo/Bar

This schema comes with convenience completion too.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Perl>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Perl>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Perl>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sah::Schema::perl::pm_filename>

L<Sah::Schema::perl::pod_or_pm_filename>

L<Sah::Schema::perl::pod_filename>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
