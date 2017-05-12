# $Id$

local $PImage => Handle;

package Prima::IPA::Geometry {
    PImage mirror( PImage input, HV *profile);
    PImage rotate90( PImage input, Bool clockwise = true);
    PImage rotate180( PImage input);
    PImage shift_rotate( PImage img, HV *profile);
}

# profile for mirror:
#  type => how, where `how' is 1 for vertical and 2 for horizontal
# profile for shift_rotate:
#  where => how, where `how' is 1 for vertical and 2 for horizontal
#  size => integer - for how many pixels/scan lines
