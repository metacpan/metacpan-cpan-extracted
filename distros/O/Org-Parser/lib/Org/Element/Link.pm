package Org::Element::Link;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.54'; # VERSION

use 5.010;
use locale;
use Moo;
extends 'Org::Element';
with 'Org::Element::Role';
with 'Org::Element::InlineRole';

has link => (is => 'rw');
has description => (is => 'rw');
has from_radio_target => (is => 'rw');

sub as_string {
    my ($self) = @_;
    return $self->_str if defined $self->_str;
    join("",
         "[",
         "[", $self->link, "]",
         (defined($self->description) && length($self->description) ?
              ("[", $self->description->as_string, "]") : ()),
         "]");
}

sub as_text {
    my $self = shift;
    my $desc = $self->description;
    defined($desc) ? $desc->as_text : $self->link;
}

1;
# ABSTRACT: Represent Org hyperlink

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::Element::Link - Represent Org hyperlink

=head1 VERSION

This document describes version 0.54 of Org::Element::Link (from Perl distribution Org-Parser), released on 2017-07-10.

=head1 DESCRIPTION

Derived from L<Org::Element>.

=head1 as_string => str

From L<Org::Element>.

=head2 as_text => str

From L<Org::Element::InlineRole>.

=head1 ATTRIBUTES

=head2 link => STR

=head2 description => OBJ

=head2 from_radio_target => BOOL

=head1 METHODS

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

This software is copyright (c) 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
