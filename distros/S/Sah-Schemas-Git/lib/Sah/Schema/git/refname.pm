package Sah::Schema::git::refname;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-20'; # DATE
our $DIST = 'Sah-Schemas-Git'; # DIST
our $VERSION = '0.004'; # VERSION

use Regexp::Pattern::Git;

our $schema = [
    "str", {
        summary => "git reference name",
        match => $Regexp::Pattern::Git::RE{ref}{pat},

        examples => [
            {value=>'foo', valid=>0, summary=>'No slash'},
            {value=>'foo/bar', valid=>1},
            {value=>'.foo', valid=>0, summary=>'Starts with a dot'},
            {value=>'foo/.bar', valid=>0, summary=>'Starts with a dot'},
        ],
    },
    {},
];

1;

# ABSTRACT: git reference name

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::git::refname - git reference name

=head1 VERSION

This document describes version 0.004 of Sah::Schema::git::refname (from Perl distribution Sah-Schemas-Git), released on 2021-07-20.

=head1 SYNOPSIS

To check data against this schema (requires L<Data::Sah>):

 use Data::Sah qw(gen_validator);
 my $validator = gen_validator("git::refname*");
 say $validator->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create validator that returns nice error message string
 # and/or coerced value. Data::Sah can even create validator that targets other
 # language, like JavaScript. All from the same schema. See its documentation
 # for more details.

To validate function parameters against this schema (requires L<Params::Sah>):

 use Params::Sah qw(gen_validator);

 sub myfunc {
     my @args = @_;
     state $validator = gen_validator("git::refname*");
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
             schema => ['git::refname*'],
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

 "foo"  # INVALID (No slash)

 "foo/bar"  # valid

 ".foo"  # INVALID (Starts with a dot)

 "foo/.bar"  # INVALID (Starts with a dot)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-Git>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-Git>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-Git>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

The rules for a reference name is documented in the manual page of
L<git-check-ref-format> command,
L<https://git-scm.com/docs/git-check-ref-format>.

TODO: reorganize so we can display better error message

TODO: if --refsec-pattern is used, refname is allowed to have a single *, e.g.
foo/bar*/baz or foo/bar*baz but not foo/bar*/baz*

TODO: add normalize coercion rule to remove leading / and duplicate adjacent /.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
