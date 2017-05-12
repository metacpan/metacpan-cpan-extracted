# $Id$
local $PImage => Handle;

package Prima::IPA::Point {
    PImage combine(HV *profile);
    PImage threshold(PImage input,HV *profile);
    PImage gamma(PImage input,HV *profile);
    PImage remap(PImage input,HV *profile);
    PImage subtract(PImage input1,PImage input2,HV *profile);
    PImage mask( PImage msk, HV *profile);
    PImage average( SV *list);
    PImage ab( PImage in, double mul, double add);
    PImage exp( PImage in);
    PImage log( PImage in);
}

