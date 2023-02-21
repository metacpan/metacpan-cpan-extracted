# -*- mode: perl; -*-
#
# Class for keeping track of Gnumeric style regions.
#
# Documentation below "__END__".
#
# [created.  -- rgr, 6-Feb-23.]
#

package Spreadsheet::Gnumeric::StyleRegion;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.2';

use parent qw(Spreadsheet::Gnumeric::Base);

# define instance accessors.
BEGIN {
    no strict 'refs';
    Spreadsheet::Gnumeric::StyleRegion->define_instance_accessors
	(qw(start_col start_row end_col end_row style_attributes));
}

1;

__END__

=head1 Spreadsheet::Gnumeric::StyleRegion

Helper class for storing style information extracted from a Gnumeric
spreadsheet.  The style information is already mostly converted in the
C<style_attributes> slot, and the other slots record which cells the
styles pertain to.  According to the file format documentation, the
regions describe disjoint rectangles that cover the entire
spreadsheet, and in practice extend far beyond the region that is
actually in use.

See the C<Spreadsheet::ReadGnumeric> class for further information.

=head2 Accessors and methods

=head3 end_col

Returns or sets the maximum column (zero based).

=head3 end_row

Returns or sets the maximum row (zero based).

=head3 start_col

Returns or sets the minimim column (zero based).

=head3 start_row

Returns or sets the minimim row (zero based).

=head3 style_attributes

Contains a hashref of attributes extracted from the C<< <Style> >> and
C<< <Font> >> element XML attributes.  These are mapped from the
original Gnumeric attribute names to hash key names compatible with
C<Spreadsheet::Read> according to the following table:

       Gnumeric         Spreadsheet::Read
       =============    =================
       Back             bgcolor
       Bold             bold   
       Fore             fgcolor
       Format           format 
       HAlign           halign 
       Hidden           hidden 
       Indent           indent
       Italic           italic
       Locked           locked
       PatternColor     pattern_color
       Rotation         rotation
       Script           script
       Shade            shade
       ShrinkToFit      shrink_to_fit
       Unit             size
       StrikeThrough    strike_through
       Underline        uline
       VAlign           valign
       WrapText         wrap

The values for the three names that end in "Color" may be converted
according to the C<convert_colors> flag of
C<Spreadsheet::ReadGnumeric>.  The values with "_" in the
C<Spreadsheet::Read> names don't actually have a C<Spreadsheet::Read>
equivalent (which probably means they don't have an Excel equivalent).

=cut
