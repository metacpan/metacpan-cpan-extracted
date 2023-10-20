package Org::ElementRole::Block;

use 5.010;
use Moo::Role;

sub is_block { 1 }

sub is_inline { 0 }

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-05'; # DATE
our $DIST = 'Org-Parser'; # DIST
our $VERSION = '0.560'; # VERSION

1;
# ABSTRACT: Role for block elements

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::ElementRole::Block - Role for block elements

=head1 VERSION

This document describes version 0.560 of Org::ElementRole::Block (from Perl distribution Org-Parser), released on 2023-08-05.

=head1 DESCRIPTION

=head1 REQUIRES

=head1 METHODS

=head2 is_block => bool (1)

=head2 is_inline => bool (0)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Org-Parser>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Org-Parser>.

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

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Org-Parser>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
