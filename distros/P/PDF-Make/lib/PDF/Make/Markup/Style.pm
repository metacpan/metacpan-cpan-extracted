package PDF::Make::Markup::Style;
use strict;
use warnings;

our $VERSION = '0.11';

# No logic lives here. The attribute table, every coercion and the inheritance
# rules are in src/pdfmake_markup_style.c, reached through xs/markup_style.xs;
# this file exists to name the package and carry its documentation. Anything
# that decides what an attribute means belongs in the C, where the renderer
# can read it without crossing back into the interpreter.
require PDF::Make;

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Markup::Style - attributes, values and inheritance for the markup

=head1 SYNOPSIS

    my $own    = PDF::Make::Markup::Style->attrs($node);
    my $style  = PDF::Make::Markup::Style->inherit($parent_style, $own);
    my $font   = PDF::Make::Markup::Style->font_args($style);

=head1 DESCRIPTION

One table describes every attribute: its type, whether children inherit it,
and which tags accept it. The validator, the resolver and the reference
documentation all read that table, so none of them can drift from the others.

=head2 Values

=over 4

=item * B<Lengths> are points. A bare number, or one with C<pt>; no other
unit exists, because the engine has no notion of one.

=item * B<Colours> are C<#rgb>, C<#rrggbb>, or one of a short list of names
(the HTML 4 sixteen, plus C<grey>). Everything normalises to C<#rrggbb>.

=item * B<Booleans> are C<1/0>, C<true/false>, C<yes/no> or C<on/off>.
Anything else is an error rather than a false.

=item * B<align> takes C<left>, C<center> (or C<centre>) and C<right>.

=back

=head2 Inheritance

C<size>, C<colour>, C<font>, C<bold>, C<italic>, C<line-height> and C<align>
pass down. Box properties - C<pad>, C<bg>, C<border>, C<weight>, C<width>,
C<height>, C<gap> - do not: a cell's padding is the cell's, not that of every
paragraph inside it.

=head2 Page size versus font size

C<size> always means font size. A page is set with C<page-size> on
C<< <doc> >> or C<< <page> >>, so that one attribute name never means two
things depending on where it appears.

=head1 SEE ALSO

L<PDF::Make::Markup::Parse>, L<PDF::Make::Markup::Build>

=cut
