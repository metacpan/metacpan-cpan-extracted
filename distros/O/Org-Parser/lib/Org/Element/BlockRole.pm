package Org::Element::BlockRole;

our $DATE = '2020-09-11'; # DATE
our $VERSION = '0.552'; # VERSION

use 5.010;
use Moo::Role;

sub is_block { 1 }

sub is_inline { 0 }

1;
# ABSTRACT: Role for block elements

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::Element::BlockRole - Role for block elements

=head1 VERSION

This document describes version 0.552 of Org::Element::BlockRole (from Perl distribution Org-Parser), released on 2020-09-11.

=head1 DESCRIPTION

=head1 REQUIRES

=head1 METHODS

=head2 is_block => bool (1)

=head2 is_inline => bool (0)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Org-Parser>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Org-Parser>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Org-Parser>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
