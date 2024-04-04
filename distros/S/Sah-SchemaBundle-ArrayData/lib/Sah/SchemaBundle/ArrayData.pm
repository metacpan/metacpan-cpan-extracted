# no code
## no critic: TestingAndDebugging::RequireUseStrict
package Sah::SchemaBundle::ArrayData;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-16'; # DATE
our $DIST = 'Sah-SchemaBundle-ArrayData'; # DIST
our $VERSION = '0.005'; # VERSION

1;
# ABSTRACT: Sah schemas related to ArrayData

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaBundle::ArrayData - Sah schemas related to ArrayData

=head1 VERSION

This document describes version 0.005 of Sah::SchemaBundle::ArrayData (from Perl distribution Sah-SchemaBundle-ArrayData), released on 2024-02-16.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<perl::arraydata::modname|Sah::Schema::perl::arraydata::modname>

Perl ArrayData::* module name without the prefix, e.g. Lingua::Word::ID::KBBI.

Contains coercion rule so you can also input C<Foo-Bar>, C<Foo/Bar>, C<Foo/Bar.pm>
or even 'Foo.Bar' and it will be normalized into C<Foo::Bar>.


=item * L<perl::arraydata::modname_with_optional_args|Sah::Schema::perl::arraydata::modname_with_optional_args>

Perl ArrayData::* module name without the prefix (e.g. Lingua::Word::ID::KBBI) with optional args (e.g. Foo::Bar=arg1,arg2).

=item * L<perl::arraydata::modnames|Sah::Schema::perl::arraydata::modnames>

Array of Perl ArrayData::* module names without the prefix, e.g. ["Lingua::Word::ID::KBBI", "Number::Prime::First1000"].

Array of Perl ArrayData::* module names, where each element is of
C<perl::arraydata::modname> schema, e.g. C<Word::ID::KBBI>,
C<Number::Prime::First1000>.

Contains coercion rule that expands wildcard, so you can specify:

 Word::ID::*

and it will be expanded to e.g.:

 ["Word::ID::KBBI", "Word::ID::PERLANCAR"]

The wildcard syntax supports jokers (C<?>, C<*>, C<**>), brackets (C<[abc]>), and
braces (C<{one,two}>). See L<Module::List::Wildcard> for more details.


=item * L<perl::arraydata::modnames_with_optional_args|Sah::Schema::perl::arraydata::modnames_with_optional_args>

Array of Perl ArrayData::* module names without the prefix, with optional args, e.g. ["Lingua::Word::ID::KBBI", "WordList=wordlist,EN::Enable"].

Array of Perl ArrayData::* module names without the prefix and optional args.
Each element is of C<perl::arraydata::modname> schema, e.g.
C<Lingua::Word::ID::KBBI>, C<WordList=wordlist,EN::Enable>.

Contains coercion rule that expands wildcard, so you can specify:

 Lingua::Word::ID::*

and it will be expanded to e.g.:

 ["Lingua::Word::ID::KBBI", "Word::ID::PERLANCAR"]

The wildcard syntax supports jokers (C<?>, C<*>, C<**>), brackets (C<[abc]>), and
braces (C<{one,two}>). See L<Module::List::Wildcard> for more details.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-ArrayData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-ArrayData>.

=head1 SEE ALSO

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

L<ArrayData>

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

This software is copyright (c) 2024, 2022, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-ArrayData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
