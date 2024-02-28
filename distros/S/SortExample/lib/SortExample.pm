## no critic: TestingAndDebugging::RequireUseStrict
package SortExample;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-27'; # DATE
our $DIST = 'SortExample'; # DIST
our $VERSION = '0.1.1'; # VERSION

1;
# ABSTRACT: Sort examples

__END__

=pod

=encoding UTF-8

=head1 NAME

SortExample - Sort examples

=head1 SPECIFICATION VERSION

0.1

=head1 VERSION

This document describes version 0.1.1 of SortExample (from Perl distribution SortExample), released on 2024-01-27.

=head1 SYNOPSIS

Basic use with L<Sort::ByExample>:

 use Sort::ByExample qw(sbe);
 use SortExample::AHMS::Fruit::EN; # list of fruit by decreasing priority/popularity

 my @sorted = sbe(SortExample::AHMS::Fruit::EN::get_example(), "peach", "grape", "strawberry");
 # => ("strawberry", "grape", "peach");

Specifying arguments:

 use Sort::ByExample qw(sbe);
 use SortExample::Foo;
 my @sorted = sbe(SortExample::Foo::get_example(arg1=>..., ), ...);

Specifying example on the command-line (for other CLI's):

 % sort-by-example -m AHMS::Fruit::EN ...
 % sort-by-example -m Foo=arg1,val,arg2,val ...

=head1 DESCRIPTION

B<EXPERIMENTAL.>

C<SortExample> is a namespace for modules that declare sort examples. Sort
examples are used with L<Sort::ByExample>.

=head2 Writing a SortExample module

 package SortExample::Foo;

 # required. must return a hash (DefHash)
 sub meta {
     return +{
         v => 1,
         summary => 'Sort examples related to Foo',
         args => {
             arg1 => {
                 schema => 'str*', # Sah schema
                 req => 1,
             },
         },
     };
 }

 sub get_example {
     my %args = @_;
     ...
     return [...];
 }

 1;

=head2 Namespace organization

TODO.

=head2 SEE ALSO

=head2 Base specifications

L<DefHash>

L<Sah>

=head2 Related specifications

L<SortSpec>

=head2 Related modules

L<Sort::ByExample>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SortExample>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SortExample>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SortExample>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
