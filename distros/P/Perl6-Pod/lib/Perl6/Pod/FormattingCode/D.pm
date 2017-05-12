#===============================================================================
#
#  DESCRIPTION:  definition formatting code
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================

package Perl6::Pod::FormattingCode::D;
use strict;
use warnings;
use Perl6::Pod::FormattingCode;
use base 'Perl6::Pod::FormattingCode';
our $VERSION = '0.01';

=pod

=head1 NAME

Perl6::Pod::FormattingCode::D - Definition

=head1 SYNOPSIS

    A D<formatting code|formatting codes;formatters> provides a way
    to add inline mark-up to a piece of text.

=head1 DESCRIPTION

The C<DE<lt>E<gt>> formatting code indicates that the contained text is a
B<definition>, introducing a term that the adjacent text
elucidates. It is the inline equivalent of a C<=defn> block.
For example:

    There ensued a terrible moment of D<coyotus interruptus>: a brief
    suspension of the effects of gravity, accompanied by a sudden
    to-the-camera realisation of imminent downwards acceleration.

A definition may be given synonyms, which are specified after a vertical bar
and separated by semicolons:

    A D<formatting code|formatting codes;formatters> provides a way
    to add inline mark-up to a piece of text.

A definition would typically be rendered in italics or C< E<lt>dfnE<gt>...E<lt>/dfnE<gt> >
tags and will often be used as a link target for subsequent instances of the
term (or any of its specified synonyms) within a hypertext.

=cut


=head2 to_xhtml

    D<photo|picture>

Render xhtml:

    <dfn>photo</dfn>
    
=cut

sub to_xhtml {
  my ( $self, $to ) = @_;
  $to->w->raw('<dfn>');
  $to->w->print($self->{term});
  $to->w->raw('</dfn>');
}

=head2 to_docbook

    D<photo|picture>

Render xml:

    photo
    
=cut

sub to_docbook {
  my ( $self, $to ) = @_;
  $to->w->print($self->{term})
}


1;
__END__

=head1 SEE ALSO

L<http://zag.ru/perl6-pod/S26.html>,
Perldoc Pod to HTML converter: L<http://zag.ru/perl6-pod/>,
Perl6::Pod::Lib

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut


