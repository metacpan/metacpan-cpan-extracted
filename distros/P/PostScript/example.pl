#!/usr/local/bin/perl -w

use strict;
use PostScript::TextBlock;

my $tb = new PostScript::TextBlock;

$tb->addText( text => "Hullaballo in Hoosick Falls.\n",
              font => 'CenturySchL-Ital',
              size => 24,
              leading => 100 
             );
$tb->addText( text => "by Charba Gaspee.\n",
              font => 'URWGothicL-Demi',
              size => 18,
              leading => 36 
             );

open I, "example.txt";
undef $/;
my $text = <I>;
$tb->addText( text => $text,
              font => 'URWGothicL-Demi',
              size => 14,
              leading => 24 
             );


open OUT, '>psoutput.ps';
my $pages = 1;
# create the first page
#
my ($code, $remainder) = $tb->Write(572, 752, 20, 772);
print OUT "%%Page:$pages\n";      # this is required by the Adobe 
                                  # Document Structuring Conventions
print OUT $code;
print OUT "showpage\n";

# Print the rest of the pages, if any
#
while ($remainder->numElements) {
    $pages++;
    print OUT "%%Page:$pages\n";
    ($code, $remainder) = $remainder->Write(572, 752, 20, 772);
    print OUT $code;
    print OUT "showpage\n";
}

