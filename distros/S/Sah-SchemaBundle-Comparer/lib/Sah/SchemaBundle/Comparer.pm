package Sah::SchemaBundle::Comparer;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-03-07'; # DATE
our $DIST = 'Sah-SchemaBundle-Comparer'; # DIST
our $VERSION = '0.002'; # VERSION

1;
# ABSTRACT: Sah schemas related to Comparer

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaBundle::Comparer - Sah schemas related to Comparer

=head1 VERSION

This document describes version 0.002 of Sah::SchemaBundle::Comparer (from Perl distribution Sah-SchemaBundle-Comparer), released on 2024-03-07.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<perl::comparer::modname|Sah::Schema::perl::comparer::modname>

Perl Comparer::* module name without the prefix, e.g. foo.

Contains coercion rule so you can also input C<Foo-Bar>, C<Foo/Bar>, C<Foo/Bar.pm>
or even 'Foo.Bar' and it will be normalized into C<Foo::Bar>.


=item * L<perl::comparer::modname_with_optional_args|Sah::Schema::perl::comparer::modname_with_optional_args>

Perl Comparer::* module name without the prefix (e.g. Foo::bar) with optional arguments (e.g. Foo::baz,qux,quux).

Perl Comparer::* module name without the prefix, with optional arguments which
will be used as import arguments, just like the C<-MMODULE=ARGS> shortcut that
C<perl> provides. Examples:

 Foo::bar
 Foo::baz=qux,quux
 Foo::baz,qux,quux

See also: C<perl::comparer::modname>.


=item * L<perl::comparer::modnames|Sah::Schema::perl::comparer::modnames>

Array of Perl Comparer::* module names without the prefix, e.g. ["Foo::bar", "Foo::baz"].

Array of Perl Comparer::* module names, where each element is of
C<perl::comparer::modname> schema, e.g. C<Foo::bar>, C<Foo::baz>.

Contains coercion rule that expands wildcard, so you can specify:

 Foo::*

and it will be expanded to e.g.:

 ["Foo::bar", "Foo::baz"]

The wildcard syntax supports jokers (C<?>, C<*>, C<**>), brackets (C<[abc]>), and
braces (C<{one,two}>). See L<Module::List::Wildcard> for more details.


=item * L<perl::comparer::modnames_with_optional_args|Sah::Schema::perl::comparer::modnames_with_optional_args>

Array of Perl Comparer::* module names without the prefix, with optional args, e.g. ["Foo::bar", "Foo::baz=qux,quux"].

Array of Perl Comparer::* module names without the prefix and with optional args.
Each element is of C<perl::comparer::modname_with_optional_args> schema, e.g.
C<Foo::bar>, C<Foo::baz=qux,quux>.

Contains coercion rule that expands wildcard, so you can specify:

 Foo::*

and it will be expanded to e.g.:

 ["Foo::bar", "Foo::baz"]

The wildcard syntax supports jokers (C<?>, C<*>, C<**>), brackets (C<[abc]>), and
braces (C<{one,two}>). See L<Module::List::Wildcard> for more details.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-Comparer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-SchemaBundle-Comparer>.

=head1 SEE ALSO

L<Comparer>

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-Comparer>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
