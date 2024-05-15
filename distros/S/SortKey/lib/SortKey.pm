## no critic: TestingAndDebugging::RequireUseStrict
package SortKey;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-05-15'; # DATE
our $DIST = 'SortKey'; # DIST
our $VERSION = '0.2.0'; # VERSION

1;
# ABSTRACT: Reusable sort key generators

__END__

=pod

=encoding UTF-8

=head1 NAME

SortKey - Reusable sort key generators

=head1 SPECIFICATION VERSION

0.1

=head1 VERSION

This document describes version 0.2.0 of SortKey (from Perl distribution SortKey), released on 2024-05-15.

=head1 SYNOPSIS

Basic use with C<sort()>:

 use SortKey::Num::length;
 my $by_length = SortKey::Num::length::gen_keygen;

 my @sorted = sort { $by_length->($a) <=> $by_length->($b) } "food", "foo", "foolish";
 # => ('foo', 'food', 'foolish')

Basic use with C<Sort::Key>:

 use Sort::Key qw(nkeysort);
 use SortKey::Num::length;
 my $by_length = SortKey::Num::length::gen_keygen;

 # use & prefix to get around prototype restriction
 my @sorted = &nkeysort($by_length, "food", "foo", "foolish");
 # => ('foo', 'food', 'foolish')

Specifying arguments:

 use Sort::Key qw(nkeysort);
 use SortKey::Num::pattern_count;
 my $by_pattern_count = Sort::Key::Num::pattern_count::gen_keygen(pattern => qr/foo/);
 my @sorted = &nkeysort($by_pattern_count, ...);

Specifying comparer on the command-line (for other CLI's):

 % customsort -k length ...
 % customsort -c pattern_count=pattern,foo ...

=head1 DESCRIPTION

B<EXPERIMENTAL. SPEC MIGHT STILL CHANGE.>

=head1 Glossary

A B<sort key generator> is a subroutine that accepts an item and converts it to
a string/numeric key. The key then can be compared using the standard C<< <=> >>
or C<cmp> operator.

A B<SortKey::*> module is a module that can return a sort key generator.

=head2 Writing a SortKey module

 package SorKey::Num::pattern_count;

 # required. must return a hash (DefHash)
 sub meta {
     return +{
         v => 1,
         summary => 'Number of occurrences of a pattern, as sort key',
         args => {
             pattern => {
                 schema => 're_from_str*', # Sah schema
                 req => 1,
             },
         },
     };
 }

 sub gen_keygen {
     my %args = @_;

     ...
     return sub {

         # since one of the main usages is with Sort::Key, and Sort::Key does
         # not pass the argument to @_ but sets $_. So a sort key generator
         # subroutine must check if argument is passed and if not then use $_ as
         # the argument.
         my $arg = @_ ? $_[0] : $_;

         # convert $arg to key
         ...
     };
 }

 1;

=head2 Namespace organization

C<SortKey::Num::*> are for modules that return a numeric key generator. Other
subnamespaces are for modules that return a string key.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/SortKey>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-SortKey>.

=head1 SEE ALSO

=head2 Base specifications

L<DefHash>

L<Sah>

=head2 Related specifications

L<Sorter>

L<Comparer>

=head2 Previous incarnation

L<Sort::Sub>

C<Sorter>, C<SortKey>, and C<Comparer> are meant to eventually supersede
Sort::Sub. The main improvement over Sort::Sub is the split into three kinds of
subroutines:

=over

=item 1. sorter

A subroutine that accepts a list of items to sort.

C<Sorter::*> modules are meant to generate sorters.

=item 2. sort key generator

A subroutine that converts an item to a string/numeric key suitable for simple
comparison using C<eq> or C<==> during sorting.

C<SortKey::*> modules are meant to generate sort key generators.

=item 3. comparer

A subroutine that compares two items. Can be used in C<sort()> as custom sort
block.

C<Comparer::*> modules are meant to generate comparers.

Perl's C<sort()>, as mentioned above, allows us to specify a comparer, but
oftentimes it's more efficient to sort by key using key generator, where the
keys are often cached. And sometimes due to preprocessing and/or postprocessing
it's more suitable to use the more generic sorter interface.

=back

Aside from the above, C<SortKey> also makes Sort::Sub's special arguments
C<reverse> and C<is_ci> become ordinary arguments, because they are not always
applicable in all situation, especially C<is_ci>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=SortKey>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
