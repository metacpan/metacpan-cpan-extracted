package Software::Catalog;

use strict;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-17'; # DATE
our $DIST = 'Software-Catalog'; # DIST
our $VERSION = '1.0.8'; # VERSION

1;
# ABSTRACT: Software catalog

__END__

=pod

=encoding UTF-8

=head1 NAME

Software::Catalog - Software catalog

=head1 VERSION

This document describes version 1.0.8 of Software::Catalog (from Perl distribution Software-Catalog), released on 2024-07-17.

=head1 SYNOPSIS

=head1 DESCRIPTION

B<STATUS:> experimental.

L<Software::Catalog> is a specification for C<Software::Catalog::SW::*> modules.
Each C<Software::Catalog::SW::*> module describes a software (e.g.
L<firefox|Software::Catalog::SW::firefox>), including:

=over

=item * how to find out the latest version of the software

=item * where to download it

=item * possibly other information in the future

=back

=head1 FAQ

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Software-Catalog>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Software-Catalog>.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

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

This software is copyright (c) 2024, 2020, 2019, 2018, 2015, 2014, 2012 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Software-Catalog>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
