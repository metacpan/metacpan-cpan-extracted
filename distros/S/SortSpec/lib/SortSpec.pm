## no critic: TestingAndDebugging::RequireUseStrict
package SortSpec;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-27'; # DATE
our $DIST = 'SortSpec'; # DIST
our $VERSION = '0.1.0'; # VERSION

1;
# ABSTRACT: Specification of sort specification

__END__

=pod

=encoding UTF-8

=head1 NAME

SortSpec - Specification of sort specification

=head1 SPECIFICATION VERSION

0.1

=head1 VERSION

This document describes version 0.1.0 of SortSpec (from Perl distribution SortSpec), released on 2024-01-27.

=head1 SYNOPSIS

Basic use with L<Sort::BySpec>:

 use Sort::BySpec qw(sort_by_spec);
 use SortSpec::Perl::CPAN::ChangesGroup::PERLANCAR; # sort specification of changes group, a la PERLANCAR

 my $sorter = sort_by_spec(spec => SortSpec::Perl::CPAN::ChangesGroup::PERLANCAR::get_spec());
 my @sorted = $sorter->(...);

Specifying arguments:

 use Sort::BySpec qw(sort_by_spec);
 use SortExample::Foo;
 my $sorter = sort_by_spec(spec => SortSpec::Foo::get_spec(arg1=>..., ));
 my @sorted = sorter->(...);

Specifying spec on the command-line (for other CLI's):

 % sort-by-spec -m Perl::CPAN::ChangesGroup::PERLANCAR ...
 % sort-by-spec -m Foo=arg1,val,arg2,val ...

=head1 DESCRIPTION

B<EXPERIMENTAL.>

C<SortSpec> is a namespace for modules that declare sort specifications. Sort
specifications are used with L<Sort::BySpec>.

=head2 Writing a SortSpec module

 package SortSpec::Foo;

 # required. must return a hash (DefHash)
 sub meta {
     return +{
         v => 1,
         summary => 'Sort specification related to Foo',
         args => {
             arg1 => {
                 schema => 'str*', # Sah schema
                 req => 1,
             },
         },
     };
 }

 sub get_spec {
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

L<SortExample>

=head2 Related modules

L<Sort::BySpec>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SortSpec>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SortSpec>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SortSpec>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
