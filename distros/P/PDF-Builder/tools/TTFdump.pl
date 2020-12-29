#!/usr/bin/perl

# given a .TTF file on the command line, dump its glyph list and widths
#   in PDF::Builder::Resource::Fonts::CoreFonts::[facename].pm format
# All the glyphs and their widths are given in widths.[fontname] by glyph
#   name. e.g., for core font timesroman, file might be .../times.ttf
# Replace the corresponding glyphs width table in [facename.pm] with the
#   updated one created here.

# "combining" forms are usually 0 width. For example, to create your own
# n+~ (if Times lacked it):
#
#  use strict;
#  use warnings;
#  use PDF::Builder;
#  
#  my $pdf = PDF::Builder->new(-compress => 'none');
#  my $font = $pdf->ttfont('/Windows/Fonts/times.ttf');
#  
#  my $page = $pdf->page();
#  my $text = $page->text();
#  
#  $text->font($font, 25);
#  $text->translate(100,600);
#  
#  # n + ~ created manually
#  $text->text("Pin\x{0303}on nuts come from a pine tree.");
#  
#  $pdf->saveas('combo.pdf');

use strict;
use warnings;

use lib qw{ ../lib };
use File::Basename;
use PDF::Builder;
use PDF::Builder::Util;
use Unicode::UCD 'charinfo';

my ($pdf);

# loop through command line list of font file names
die "Need one or more TTF file names on command line!\n" if !scalar(@ARGV);

foreach my $fn (@ARGV) {
    if (!-r $fn) {
        print "$fn cannot be read. Skipping...\n\n";
        next;
    }

    my $myName = basename($fn);
    $myName =~ s/\.[to]tf$//i;  # remove .ttf/.otf (any case)
    open my $FH, ">", "widths.$myName" or die "can't open output file widths.$myName\n";
    print $FH "# source: $fn\n";

    $pdf = PDF::Builder->new();
    my $font = $pdf->ttfont($fn);

    my $u = $font->underlineposition();
    print $FH "# font underline position = $u\n";

    my @cids = (0 .. $font->glyphNum()-1);
    print $FH "# CIDs 0 .. $#cids to be output\n";
    # warning: apparently not all fonts have fontbbox
    my @fbbx = $font->fontbbox();
    print $FH "# fontbbox = (@fbbx)\n";
    my $missingwidth = $font->missingwidth();
   #print $FH "# missingwidth = $missingwidth\n";
    # TBD other settings from $font to be added later

    # CId list is simply 0..number of glyphs in font-1
    my %wxList;
    while (scalar @cids>0) {
                my $xo = shift(@cids);  # 0, 1, 2,...

                my $name = $font->glyphByCId($xo);
                if (!defined $name || $name eq '') {
                    $name="No Name!";
		    next;
                }

                my $wx = $font->wxByCId($xo);   # actual width of character
		#print "G+$xo width=$wx, ";
		$wxList{$name} = $wx;

		## information about the character
		#	if (defined $font->uniByCId($xo)) {
		#    printf('U+%04X ', $font->uniByCId($xo));
		#} else {
		#    printf('U+???? ');
		#}

		#print "name='$name' ";

		#my $ci = charinfo($font->uniByCId($xo) || 0);
		#if (defined $ci->{'name'}) {
		#    print " desc. $ci->{'name'} ";
		#}

		#print "\n";
    } # loop through cids of font
    
    # now have list of widths for all glyphs in font (including those without
    # a Unicode point). output sorted by name into widths.[filename]

    my @keys = sort keys %wxList;

    print $FH "    'wx' => { # HORIZ. WIDTH TABLE\n";
    foreach my $glyphName (@keys) {
	print $FH "        '$glyphName'       => $wxList{$glyphName},\n";
    }
    print $FH "    },\n";

    close $FH;

} # loop through a font name. go to next command line name.

exit;

__END__

