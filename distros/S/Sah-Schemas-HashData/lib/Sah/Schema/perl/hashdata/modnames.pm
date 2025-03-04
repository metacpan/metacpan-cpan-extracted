package Sah::Schema::perl::hashdata::modnames;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-15'; # DATE
our $DIST = 'Sah-Schemas-HashData'; # DIST
our $VERSION = '0.001'; # VERSION

our $schema = [array => {
    summary => 'Array of Perl HashData::* module names without the prefix, e.g. ["Sample::DeNiro", "CPAN::AuthorName::ByPAUSEID"]',
    description => <<'_',

Array of Perl HashData::* module names, where each element is of
`perl::hashdata::modname` schema, e.g. `Sample::DeNiro`,
`CPAN::AuthorName::ByPAUSEID`.

Contains coercion rule that expands wildcard, so you can specify:

    CPAN::**

and it will be expanded to e.g.:

    ["CPAN::AuthorName::ByPAUSEID", "CPAN::Module::ByName"]

The wildcard syntax supports jokers (`?`, `*`, `**`), brackets (`[abc]`), and
braces (`{one,two}`). See <pm:Module::List::Wildcard> for more details.

_
    of => ["perl::hashdata::modname", {req=>1}, {}],

    'x.perl.coerce_rules' => [
        ['From_str_or_array::expand_perl_modname_wildcard', {ns_prefix=>'HashData'}],
    ],

    # provide a default completion which is from list of installed perl modules
    'x.element_completion' => ['perl_modname', {ns_prefix=>'HashData'}],

}];

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::perl::hashdata::modnames

=head1 VERSION

This document describes version 0.001 of Sah::Schema::perl::hashdata::modnames (from Perl distribution Sah-Schemas-HashData), released on 2024-01-15.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Sah-Schemas-HashData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Sah-Schemas-HashData>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Sah-Schemas-HashData>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
