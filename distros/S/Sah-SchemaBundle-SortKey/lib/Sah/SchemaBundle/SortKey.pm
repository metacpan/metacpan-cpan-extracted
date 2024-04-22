package Sah::SchemaBundle::SortKey;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-03-07'; # DATE
our $DIST = 'Sah-SchemaBundle-SortKey'; # DIST
our $VERSION = '0.002'; # VERSION

1;
# ABSTRACT: Sah schemas related to SortKey

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::SchemaBundle::SortKey - Sah schemas related to SortKey

=head1 VERSION

This document describes version 0.002 of Sah::SchemaBundle::SortKey (from Perl distribution Sah-SchemaBundle-SortKey), released on 2024-03-07.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<perl::sortkey::modname|Sah::Schema::perl::sortkey::modname>

Perl SortKey::* module name without the prefix, e.g. NumE<sol>pattern_count.

Contains coercion rule so you can also input C<Foo-Bar>, C<Foo/Bar>, C<Foo/Bar.pm>
or even 'Foo.Bar' and it will be normalized into C<Foo::Bar>.


=item * L<perl::sortkey::modname_with_optional_args|Sah::Schema::perl::sortkey::modname_with_optional_args>

Perl SortKey::* module name without the prefix (e.g. Num::pattern_count) with optional arguments (e.g. Num::pattern_count,pattern,foo).

Perl SortKey::* module name without the prefix, with optional arguments which
will be used as import arguments, just like the C<-MMODULE=ARGS> shortcut that
C<perl> provides. Examples:

 Num::pattern_count
 Num::pattern_count=pattern,foo
 Num::pattern_count,pattern,foo

See also: C<perl::sortkey::modname>.


=item * L<perl::sortkey::modnames|Sah::Schema::perl::sortkey::modnames>

Array of Perl SortKey::* module names without the prefix, e.g. ["Num::length", "Num::pattern_count"].

Array of Perl SortKey::* module names, where each element is of
C<perl::sortkey::modname> schema, e.g. C<Num::length>, C<Num::pattern_count>.

Contains coercion rule that expands wildcard, so you can specify:

 Num::*

and it will be expanded to e.g.:

 ["Num::length", "Num::pattern_count"]

The wildcard syntax supports jokers (C<?>, C<*>, C<**>), brackets (C<[abc]>), and
braces (C<{one,two}>). See L<Module::List::Wildcard> for more details.


=item * L<perl::sortkey::modnames_with_optional_args|Sah::Schema::perl::sortkey::modnames_with_optional_args>

Array of Perl SortKey::* module names without the prefix, with optional args, e.g. ["Num::length", "Num::pattern_count=pattern,foo"].

Array of Perl SortKey::* module names without the prefix and with optional
args. Each element is of C<perl::sortkey::modname> schema, e.g. C<Num::length>,
C<Num::pattern_count>.

Contains coercion rule that expands wildcard, so you can specify:

 Num::*

and it will be expanded to e.g.:

 ["Num::length", "Num::pattern_count"]

The wildcard syntax supports jokers (C<?>, C<*>, C<**>), brackets (C<[abc]>), and
braces (C<{one,two}>). See L<Module::List::Wildcard> for more details.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-SchemaBundle-SortKey>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-SortKey>.

=head1 SEE ALSO

L<SortKey>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-SchemaBundle-SortKey>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
