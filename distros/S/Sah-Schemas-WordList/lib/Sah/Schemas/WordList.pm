package Sah::Schemas::WordList;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-01-19'; # DATE
our $DIST = 'Sah-Schemas-WordList'; # DIST
our $VERSION = '0.005'; # VERSION

1;
# ABSTRACT: Sah schemas related to WordList

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schemas::WordList - Sah schemas related to WordList

=head1 VERSION

This document describes version 0.005 of Sah::Schemas::WordList (from Perl distribution Sah-Schemas-WordList), released on 2023-01-19.

=head1 SAH SCHEMAS

The following schemas are included in this distribution:

=over

=item * L<perl::wordlist::modname|Sah::Schema::perl::wordlist::modname>

Perl WordList::* module name without the prefix, e.g. EN::Enable.

Contains coercion rule so you can also input C<Foo-Bar>, C<Foo/Bar>, C<Foo/Bar.pm>
or even 'Foo.Bar' and it will be normalized into C<Foo::Bar>.


=item * L<perl::wordlist::modname_with_optional_args|Sah::Schema::perl::wordlist::modname_with_optional_args>

Perl WordList::* module name without the prefix (e.g. EN::Enable) with optional arguments (e.g. MetaSyntactic::Any=theme,dangdut).

Perl WordList::* module name without the prefix, with optional arguments which
will be used as import arguments, just like the C<-MMODULE=ARGS> shortcut that
C<perl> provides. Examples:

 EN::Enable
 MetaSyntactic::Any=theme,dangdut

See also: C<perl::wordlist::modname>.


=item * L<perl::wordlist::modnames|Sah::Schema::perl::wordlist::modnames>

Array of Perl WordList::* module names without the prefix, e.g. ["EN::Enable", "EN::BIP39"].

Array of Perl WordList::* module names, where each element is of
C<perl::wordlist::modname> schema, e.g. C<EN::Enable>, C<EN::BIP39>.

Contains coercion rule that expands wildcard, so you can specify:

 EN::*

and it will be expanded to e.g.:

 ["EN::Enable", "EN::BIP39"]

The wildcard syntax supports jokers (C<?>, C<*>, C<**>), brackets (C<[abc]>), and
braces (C<{one,two}>). See L<Module::List::Wildcard> for more details.


=item * L<perl::wordlist::modnames_with_optional_args|Sah::Schema::perl::wordlist::modnames_with_optional_args>

Array of Perl WordList::* module names without the prefix, with optional args, e.g. ["EN::Enable", "MetaSyntactic::Any=theme,dangdut"].

Array of Perl WordList::* module names without the prefix and with optional
args. Each element is of C<perl::modname> schema, e.g. C<EN::Enable>,
C<MetaSyntactic::Any=theme,dangdut>.

Contains coercion rule that expands wildcard, so you can specify:

 ID::*

and it will be expanded to e.g.:

 ["ID::KBBI", "ID::PERLANCAR"]

The wildcard syntax supports jokers (C<?>, C<*>, C<**>), brackets (C<[abc]>), and
braces (C<{one,two}>). See L<Module::List::Wildcard> for more details.


=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-WordList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-WordList>.

=head1 SEE ALSO

L<Sah> - schema specification

L<Data::Sah> - Perl implementation of Sah

L<WordList>

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

This software is copyright (c) 2023, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-WordList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
