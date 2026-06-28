package PDF::Make::Extract::Word;
use strict;
use warnings;
use Object::Proto;

BEGIN {
    Object::Proto::define('PDF::Make::Extract::Word',
        'text:Str',
        'x0:Num',
        'y0:Num',
        'x1:Num',
        'y1:Num',
        'font_size:Num',
        'mcid',
        'tag',
    );
    Object::Proto::import_accessors('PDF::Make::Extract::Word');
}

sub bbox   { (x0($_[0]), y0($_[0]), x1($_[0]), y1($_[0])) }
sub width  { x1($_[0]) - x0($_[0]) }
sub height { y1($_[0]) - y0($_[0]) }

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Extract::Word - A word with position and font information

=head1 METHODS

=head2 text()

The word's text content (UTF-8).

=head2 x0, y0, x1, y1

Bounding box coordinates in PDF user space.

=head2 bbox()

Returns C<(x0, y0, x1, y1)> as a list.

=head2 width()

Width of the word bounding box.

=head2 height()

Height of the word bounding box.

=head2 font_size()

The font size used to render this word.

=head2 mcid()

For tagged PDFs, the marked-content identifier of the C<BDC/EMC> block that
contained this word's glyphs. C<undef> when the word is not inside a
marked-content block.

=head2 tag()

For tagged PDFs, the PDF structure role (e.g. C<H1>, C<P>, C<Figure>)
associated with this word via C</StructTreeRoot>. C<undef> when the word is
not tagged.

=head1 SEE ALSO

L<PDF::Make::Extract::Line>

=cut
