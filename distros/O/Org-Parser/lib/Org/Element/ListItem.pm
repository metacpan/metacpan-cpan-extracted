package Org::Element::ListItem;

our $DATE = '2020-12-30'; # DATE
our $VERSION = '0.554'; # VERSION

use 5.010;
use locale;
use Moo;
extends 'Org::Element';

has bullet => (is => 'rw');
has check_state => (is => 'rw');
has desc_term => (is => 'rw');

sub header_as_string {
    my ($self) = @_;
    join("",
         $self->parent->indent,
         $self->bullet, " ",
         defined($self->check_state) ? "[".$self->check_state."]" : "",
         defined($self->desc_term) ? $self->desc_term->as_string . " ::" : "",
     );
}

sub as_string {
    my ($self) = @_;
    $self->header_as_string . $self->children_as_string;
}

1;
# ABSTRACT: Represent Org list item

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::Element::ListItem - Represent Org list item

=head1 VERSION

This document describes version 0.554 of Org::Element::ListItem (from Perl distribution Org-Parser), released on 2020-12-30.

=head1 DESCRIPTION

Must have L<Org::Element::List> as parent.

Derived from L<Org::Element>.

=head1 ATTRIBUTES

=head2 bullet

=head2 check_state

undef, " ", "X" or "-".

=head2 desc_term

Description term (for description list).

=head1 METHODS

=for Pod::Coverage header_as_string as_string

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Org-Parser>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Org-Parser>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Org-Parser/issues>

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
