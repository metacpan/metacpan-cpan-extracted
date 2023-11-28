package Org::ElementRole::Inline;

use 5.010;
use Moo::Role;

requires 'as_text';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-06'; # DATE
our $DIST = 'Org-Parser'; # DIST
our $VERSION = '0.561'; # VERSION

sub is_block { 0 }

sub is_inline { 1 }

sub children_as_text {
    my ($self) = @_;
    return "" unless $self->children;
    join "", map {$_->as_text} @{$self->children};
}

1;
# ABSTRACT: Role for inline elements

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::ElementRole::Inline - Role for inline elements

=head1 VERSION

This document describes version 0.561 of Org::ElementRole::Inline (from Perl distribution Org-Parser), released on 2023-11-06.

=head1 DESCRIPTION

This role is applied to elements that are "inline": elements that can occur
inside text and put as a child of L<Org::Element::Text>.

=head1 REQUIRES

=head2 as_text => str

Get the "rendered plaintext" representation of element. Most elements would
return the same result as C<as_string>, except for elements like
L<Org::Element::Link> which will return link description instead of the link
itself.

=head1 METHODS

=head2 is_block => bool (0)

=head2 is_inline => bool (1)

=head2 children_as_text => str

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
