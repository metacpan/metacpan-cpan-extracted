package Org::Element::List;

our $DATE = '2020-09-11'; # DATE
our $VERSION = '0.552'; # VERSION

use 5.010;
use locale;
use Moo;
extends 'Org::Element';

has indent => (is => 'rw');
has type => (is => 'rw');
has bullet_style => (is => 'rw');

sub items {
    my $self = shift;
    my @items;
    for (@{ $self->children }) {
        push @items, $_ if $_->isa('Org::Element::ListItem');
    }
    \@items;
}

1;
# ABSTRACT: Represent Org list

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::Element::List - Represent Org list

=head1 VERSION

This document describes version 0.552 of Org::Element::List (from Perl distribution Org-Parser), released on 2020-09-11.

=head1 DESCRIPTION

Must have L<Org::Element::ListItem> (or another ::List) as children.

Derived from L<Org::Element>.

=begin Pod::Coverage




=end Pod::Coverage

=head1 ATTRIBUTES

=head2 indent

Indent (e.g. " " x 2).

=head2 type

'U' for unordered list (-, +, * for bullets), 'D' for description list, 'O' for
ordered list (1., 2., 3., and so on).

=head2 bullet_style

E.g. '-', '*', '+'. For ordered list, currently just use '<N>.'

=head1 METHODS

=head2 $list->items() => ARRAY OF OBJECTS

Return the items, which are an arrayref of L<Org::Element::ListItem> objects.

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
