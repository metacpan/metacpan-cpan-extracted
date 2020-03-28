package Sah::Schema::git::refname;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-27'; # DATE
our $DIST = 'Sah-Schemas-Git'; # DIST
our $VERSION = '0.003'; # VERSION

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

This document describes version 0.003 of Sah::Schema::git::refname (from Perl distribution Sah-Schemas-Git), released on 2020-03-27.

=head1 SYNOPSIS

Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 my $vdr = gen_validator("git::refname*");
 say $vdr->($data) ? "valid" : "INVALID!";

 # Data::Sah can also create a validator to return error message, coerced value,
 # even validators in other languages like JavaScript, from the same schema.
 # See its documentation for more details.

Using in L<Rinci> function metadata (to be used with L<Perinci::CmdLine>, etc):

 package MyApp;
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

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
