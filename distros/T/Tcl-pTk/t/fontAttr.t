# Test to see if the font attributes returned from a font object are really correct.
#  This is done by creating fonts, querying their attributies, and then creating a new font with those same
#   attributes. 
#  If the attributes are correct, then a label displayed with the original font and the new font should have the same
#   appearance.
#
#  This test was put in-place to check some code in Tcl::pTk::Font that works around a but in Tcl/tk (at least in
#    version (8.5.1-8.5.5) ), that reports incorrect font sizes for the "TkDefaultFont" and the 
#      "-*-helvetica-medium-r-*-*-12-*-*-*-*-*-*-*" ( and similar) fonts on Linux (Ubuntu 8.04 LTS)

use Tcl::pTk;
#use Tk;
#use Tk::Font;

use Test;

plan tests => 8;

my $TOP = MainWindow->new();

# List of font names to check. 
my @fontNames = (
        'Monospace 10', 
        "-*-helvetica-medium-r-*-*-12-*-*-*-*-*-*-*", # This font's size gets reported incorrectly without the fix in the Font Package
#        "-*-helvetica-medium-r-*-*-14-*-*-*-*-*-*-*", # This font's size gets reported incorrectly without the fix in the Font Package
        "TkDefaultFont",                              # This font's size gets reported incorrectly without the fix in the Font Package
        'Courier 10',
#       'Times 12',
# 'Mallige 12',
# 'Dingbats 12'
);

# Skip unix-style fonts on windows
my $win = $^O =~ /mswin/i;

foreach my $fontName(@fontNames){
        
        #print "---Font: $fontName -----\n";
        $TOP->Label(-text => "------Font: $fontName -------")->pack();
        
        
        $label1 = $TOP->Label(-text => "This text should be the same size for this font", -font => $fontName)->pack();
        my $font = $label1->cget(-font);
        # print "Label1'  font = '$font\n";
        my %attributes = $label1->cget(-font)->actual(); # Attributes using $font->actual
        my %attributes2= $TOP->fontActual($font);             # Attributes using $mw->fontActual
        
        my $size = $attributes{-size};
        my $scaling = $TOP->scaling;
        my $width = $font->measure('0');
        my $estWidth = $size/$scaling;
        my $ascent = $font->metrics(-ascent);
        my $descent = $font->metrics(-descent);
        #print "size = $size, scaling = $scaling, width = $width, estWidth = $estWidth\n";
        #print "     ascent = $ascent, decent = $descent\n";
        
        # Sanity check of size
        my $testFont = $TOP->Font(%attributes);
        my $testFont2 = $TOP->Font(%attributes2);
        my $widthTest1 = $testFont->measure('This is a test of font size');
        my $widthTest2 = $font->measure(    'This is a test of font size');
        my $widthTest3 = $testFont2->measure(    'This is a test of font size');
        $TOP->fontDelete($testFont);
        $TOP->fontDelete($testFont2);
        
        my $skip = $win && $fontName =~ /helvetica/i ? "Skip unix fontnames on windows" : 0;
        skip($skip, $widthTest1, $widthTest2, "Font->actual $fontName Attr Check");
        skip($skip, $widthTest2, $widthTest3, "\$widget->fontActual $fontName Attr Check");
        
        #print "Label1's Font Attributes = ".join(" ", %attributes)."\n";

        # $attributes{-size} = -$attributes{-size};
        my $clonedFont = $TOP->Font(%attributes);

        $TOP->Label(-text => "This text should be the same size for this font", -font => $clonedFont)->pack();
}

MainLoop if (@ARGV); # Pause if any args, (for debugging)
