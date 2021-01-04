package Org::Element::Text;

our $DATE = '2020-12-30'; # DATE
our $VERSION = '0.554'; # VERSION

use 5.010;
use locale;
use Moo;
extends 'Org::Element';
with 'Org::Element::Role';
with 'Org::Element::InlineRole';

has text => (is => 'rw');
has style => (is => 'rw');

our %mu2style = (''=>'', '*'=>'B', '_'=>'U', '/'=>'I',
                 '+'=>'S', '='=>'C', '~'=>'V');
our %style2mu = reverse(%mu2style);

sub as_string {
    my ($self) = @_;
    my $muchar = $style2mu{$self->style // ''} // '';

    join("",
         $muchar,
         $self->text // '', $self->children_as_string,
         $muchar);
}

sub as_text {
    my $self = shift;
    my $muchar = $style2mu{$self->style // ''} // '';

    join("",
         $muchar,
         $self->text // '', $self->children_as_text,
         $muchar);
}

1;
# ABSTRACT: Represent text

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::Element::Text - Represent text

=head1 VERSION

This document describes version 0.554 of Org::Element::Text (from Perl distribution Org-Parser), released on 2020-12-30.

=head1 DESCRIPTION

Derived from L<Org::Element>.

Org::Element::Text is an object that represents a piece of text. It has C<text>
and C<style> attributes. Simple text like C<Jakarta> or C<*Jakarta!*> will be
represented, respectively, as C<(text=Jakarta, style='')> and C<text=Jakarta!,
style=B> (for bold).

This object can also hold other inline (non-block) elements, e.g. links, radio
targets, timestamps, time ranges. They are all put in the C<children> attribute.

=for Pod::Coverage as_string

=head1 ATTRIBUTES

=head2 text => str

Plain text for this object I<only>. Note that if you want to get a plain text
representation for the whole text (including child elements), you'd want the
C<as_text> method.

=head2 style => str

''=normal, I=italic, B=bold, U=underline, S=strikethrough, V=verbatim,
C=code

=head1 METHODS

=head2 as_text => str

From L<Org::Element::InlineRole>.

=head2 as_string => str

From L<Org::Element>.

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
