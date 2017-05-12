# $Id$
local $PImage => Handle;
local @Histogram int[ 256];

package Prima::IPA::Misc {
    SV * split_channels( PImage input, char * mode = "rgb");
    PImage combine_channels( SV * input, char * mode = "rgb");
    Histogram * histogram( PImage input);
}

