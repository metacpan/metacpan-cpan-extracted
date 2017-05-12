# $Id$
local $PImage => Handle;
local @TwoImages
{
   PImage magnitude;
   PImage direction;
}

package Prima::IPA::Local {
   PImage crispening(PImage input);
   PImage sobel(PImage input,HV *profile);
   PImage GEF(PImage input,HV *profile);
   PImage SDEF(PImage input,HV *profile);
   PImage deriche(PImage input, HV *profile);
   PImage filter3x3(PImage input,HV *profile);
   PImage median(PImage input,HV *profile);
   PImage unionFind(PImage input,HV *profile);
   PImage hysteresis(PImage input, HV*profile);
   PImage gaussian( int size, double sigma);
   PImage laplacian( int size, double sigma);
   TwoImages gradients(PImage input);
   PImage canny( PImage input, HV*profile);
   PImage nms( PImage input, HV*profile);
   PImage scale( PImage input, HV*profile);
   PImage ridge( PImage input, HV*profile);
   PImage convolution( PImage input, PImage kernel);
   PImage zerocross( PImage input, HV * profile);
}

