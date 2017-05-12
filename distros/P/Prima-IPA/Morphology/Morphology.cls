# $Id$
local $PImage => Handle;

package Prima::IPA::Morphology {
    PImage BWTransform(PImage img,HV *profile);
    PImage dilate( PImage IMi, HV *profile);
    PImage erode( PImage IMi, HV *profile);
    PImage algebraic_difference( PImage i1, PImage i2, HV *profile);
    PImage watershed( PImage IMi, HV *profile);
    PImage reconstruct( PImage I, PImage J, HV *profile);
    PImage thinning( PImage inp, HV *profile);
}

