#!/usr/bin/perl
# list a font file's contents
# outputs ShowFont.<type>.<fontname>.pdf
# run without arguments to get help listing
# author: Phil M Perry

use strict;
use warnings;

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

use PDF::Builder;
use Encode;
use utf8;

# loaded encodings, and all possible encodings
my @list = Encode->encodings();
my @list_all = Encode->encodings(':all');

# default encodings to show if no -e given
my @encodings = qw(
  latin1
  latin2
  latin3
  latin4
  latin5
  latin6
  latin7
  latin8
  latin9
  latin10
  utf8
);

# minimum one arg (font name)
if ($#ARGV < 0) {
    usage();
    exit(1);
}

my $type = 'corefont';  # default for -t
my $fontfile = '';  # required (last argument)
my $fontname = '';  # derived from $fontfile
my @encode_list = @encodings; # optional list (-e)
my $from = 0;    # default start value for UTF-8 (-r)
my $to = 0x3FF;  # default end value for UTF-8 (-r)
my $extra = "ShowFont";
my $T1metrics = '';  # no default

my ($f, $i,$j, $page, $text, $grfx);
my $pdf = PDF::Builder->new(-compress => 'none');
my $title_font = $pdf->corefont('Helvetica');
my $grid_font = $pdf->corefont('Helvetica-Bold');

#my %infohash = $pdf->info(
#	'Creator' => "ShowFont.pl",
#	'Producer' => "PDF::Builder is the gr8st");

# go through argument list
foreach ($i=0; $i<scalar @ARGV; $i++) {
    if ($i == $#ARGV) {
        # last one, must be font name
	$fontfile = $ARGV[$i];
	# if not corefont, it is a file. extract fontname
	if ($type eq 'corefont') {
	    $fontname = $fontfile;
	} else {
	    $fontname = $fontfile;
            # strip off path
	    if ($fontfile =~ m#[/\\]([^/\\]+)$#) {
		$fontname = $1;  # strip off any path
	    }
            # strip off extension
	    $fontname =~ s#\.[a-z0-9_]+$##i;  # strip off .pfa or .pfb extension
	}
	last;
    }

    if (substr($ARGV[$i], 0, 2) eq '-t') {
	# type (corefont, truetype, type1)
	$f = substr($ARGV[$i], 2);
	if ($f eq '') {
	    # separate elements for flag and value
	    if ($i < $#ARGV-1) {
	        $type = $ARGV[++$i];
	    }
	} else {
	    $type = $f;
	}

    } elsif (substr($ARGV[$i], 0, 2) eq '-e') {
	# encodings list (default latinX and utf8) up until last arg or
	# -FLAG 
	$f = substr($ARGV[$i], 2);
	if ($f eq '') {
	    # separate elements for flag and first (or only) value
	    if ($i < $#ARGV-1) {
	        @encode_list = ($ARGV[++$i]);
	    }
	} else {
	    @encode_list = ($f);
	}
	# now any additional elements
	$i++;
	while ($i < $#ARGV && substr($ARGV[$i], 0, 1) ne '-') {
            push @encode_list, $ARGV[$i++];
	}
	$i--;  # went one too far...

    } elsif (substr($ARGV[$i], 0, 2) eq '-r') {
	# expect two decimal or hex values
	$f = substr($ARGV[$i], 2);
	if ($f eq '') {
	    # separate elements for flag and first value
	    if ($i < $#ARGV-2) {
	        $from = lc($ARGV[++$i]);
	        if (substr($from, 0, 2) eq '0x') { $from = hex($from); }
	    }
	} else {
	    # -r flag and 'from' value run together
	    $from = lc($f);
	    if (substr($from, 0, 2) eq '0x') { $from = hex($from); }
	}
	# 'to' value is always a separate element
	if ($i < $#ARGV-1) {
	    $to = lc($ARGV[++$i]);
	    if (substr($to, 0, 2) eq '0x') { $to = hex($to); }
	}

    } elsif (substr($ARGV[$i], 0, 2) eq '-x') {
	# "extra" to replace default "ShowFont"
	$f = substr($ARGV[$i], 2);
	if ($f eq '') {
	    # separate elements for flag and value
	    if ($i < $#ARGV-1) {
	        $extra = $ARGV[++$i];
	    }
	} else {
	    $extra = $f;
	}

    } elsif (substr($ARGV[$i], 0, 2) eq '-m') {
	# T1 metrics file
	$f = substr($ARGV[$i], 2);
	if ($f eq '') {
	    # separate elements for flag and value
	    if ($i < $#ARGV-1) {
	        $T1metrics = $ARGV[++$i];
	    }
	} else {
	    $T1metrics = $f;
	}

    } else { 
	# shouldn't get to here
	print "unknown flag or wrong number of arguments: $ARGV[$i]\n";
	exit(2);
    }
}

# add correct path for output file
my $outpath = $0;
  $outpath =~ s#[^\\/]+$##;

# see if all the settings look reasonable
if ($fontfile eq '' || substr($fontfile, 0, 1) eq '-') {
    print "missing or incorrect font file: $fontfile\n";
    exit(3);
}
if ($type ne 'corefont' && $type ne 'truetype' && $type ne 'type1') {
    print "incorrect font type: $type\n";
    exit(4);
}
if (!scalar @encode_list) {
    print "need at least one encoding\n";
    exit(5);
}
if ($from < 0 || $to < $from) {
    print "UTF-8 range $from to $to is invalid\n";
    exit(6);
}
if ($type eq 'type1' && $T1metrics eq '') {
    print "T1 metrics file path/name not given\n";
    exit(7);
}

print "font file: $fontfile\ntype: $type\nencode list: @encode_list\nfrom: $from to: $to (multibyte only)\n";
if ($T1metrics ne '') { print "T1 metrics file: $T1metrics\n"; }

# loop through encodings. for all but UTF-8, range is 00-FF on one page.
# for UTF-8, $from to $to, with max 256 entries per page (xxx00 through xxxFF)

foreach my $encode (@encode_list) {
    # xxx0 through xxxF across 30 wide
    my $x_offset = 10;
    my @x_list = ( 95, 125, 155, 185, 215, 245, 275, 305, 
	          335, 365, 395, 425, 455, 485, 515, 545);
    # xx0x through xxFx down
    my @y_list = (590, 565, 540, 515, 490, 465, 440, 415,
	          390, 365, 340, 315, 290, 265, 240, 215);
    my ($multibyte, $cur_font, @planes, $plane);
    my ($page_start, $page_end, $num_pages, $cur_page);

    if ($encode =~ m/^utf/i || $encode =~ m/^ucs/i) {
	if ($type ne 'truetype') { next; } # multibyte N/A for core, T1

	# multiple pages for multibyte encodings
	$multibyte = 1;
	# start is xxx00
	$page_start = int($from/256)*256 - 256;
	# end is xxxFF
	$page_end = int(($to+256)/256)*256 - 1 - 256;
	# number of pages that will be output
	$num_pages = ($page_end - $page_start + 1) / 256;
	
    } else {
	# one page for single byte encodings (may still be multiple planes)
	$multibyte = 0;
	$page_start = -256;
	$page_end = 255 - 256;
       #$page_start = 0;
       #$page_end = 255;
	$num_pages = 1;
    }
#print "encode=$encode, page_start=".($page_start+256).", page_end=".($page_end+256).", num_pages=$num_pages\n";

    if ($type eq 'corefont') {
        $cur_font = $pdf->corefont($fontname, -encode => $encode);
        @planes = ($cur_font, $cur_font->automap()); # 1 or more planes each 256

    } elsif ($type eq 'type1') {
	if ($T1metrics =~ m/\.afm$/i) {
	    $cur_font = $pdf->psfont($fontfile, -encode => $encode, 
		                     -afmfile => $T1metrics);
	} else {
	    $cur_font = $pdf->psfont($fontfile, -encode => $encode, 
		                     -pfmfile => $T1metrics);
	}
        @planes = ($cur_font, $cur_font->automap()); # 1 or more planes each 256

    } else {  # truetype/opentype
        $cur_font = $pdf->ttfont($fontfile, -encode => $encode);
	@planes = ($cur_font);  # automap() not available

    }
	
  for ($plane=0; $plane<scalar @planes; $plane++) {
    # for planes 1+, check if any characters in it
    if ($plane > 0) {
      my $flag = 0; # no character found yet
      foreach my $y (0..15) {
	foreach my $x (0..15) {
	  my $ci = $y*16 + $x; # 0..255 value
	  if ($ci==32 || $ci==33) { next; } # always something there
	  if (defined $planes[$plane]->uniByEnc($ci) && 
	              $planes[$plane]->uniByEnc($ci) > 0) {
	    $flag = 1;
	    last;
	  }
	}
	if ($flag) { last; }
      }
      if (!$flag) { next; } # no characters in this plane
    }

    for ($cur_page = 1; $cur_page <= $num_pages; $cur_page++) {
	my ($row, $col, $c_val, $c);

        newpage();  # create next page
	if ($multibyte || $plane == 0) {
	    $page_start += 256;
	    $page_end   += 256;
        }

        # page and grid headings
        $text->font($title_font, 25);
        $text->translate(36,700);
        $text->text("Font: $fontname ($type)");
        $text->font($title_font, 20);
        $text->translate(36,675);
	if ($num_pages > 1) {
            $text->text("Encoding: $encode (page $cur_page of $num_pages)");
	} else {
            $text->text("Encoding: $encode");
	}
	$text->translate(36, 650);
	$text->text("Plane ".($plane+1)." / ".($#planes+1));
        $text->font($grid_font, 20);
	# label columns
	for ($i=0; $i<16; $i++) {
            $text->translate($x_list[$i],$y_list[0]+25);
            $text->text(sprintf("_%1X", $i));
        }
	# label rows
	for ($j=0; $j<16; $j++) {
            $text->translate($x_list[0]-15,$y_list[$j]);
            $text->text_right(sprintf("%2X_", $page_start/16+$j));
        }

	# the characters themselves, right-justified at x_list + 20
       #$text->font($cur_font, 20);
        $text->font($planes[$plane], 20);
	for ($row = 0; $row < 16; $row++) {
	    for ($col = 0; $col < 16; $col++) {  
		$c_val = $page_start + (15-$row)*16 + $col;
		if ($c_val < $from || $c_val > $to) { next; }
	       #if ($c_val < 32) { next; } # control characters
	        if ($type eq 'corefont' && 
		    $planes[$plane]->wxMissingByEnc($c_val)) {
	            $grfx->fillcolor(1.0, 0.7, 0.7); # for missing width
		    $grfx->move($x_list[$col]+$x_offset, $y_list[15-$row]-2);
		    $grfx->line($x_list[$col]+$x_offset, $y_list[15-$row]+18);
		    $grfx->line($x_list[$col]+$x_offset+20, $y_list[15-$row]+18);
		    $grfx->line($x_list[$col]+$x_offset+20, $y_list[15-$row]-2);
		    $grfx->close();
		    $grfx->fill();
	            $grfx->fillcolor('black');
	        }
		# other font types get their widths from their files

		$text->translate($x_list[$col]+20, $y_list[15-$row]);
		# $c_val > x7F should be interpreted as either single byte
		# top half, or UTF-8 Latin-1 area
		$c = chr($c_val);
		if ($multibyte && $c_val >= 0x80 && $c_val <= 0xFF) {
		   # for some reason, 80..FF in UTF-8 isn't handled correctly
		   # perldoc.perl.org/functions/chr.html:
		   # Note that characters from 128 to 255 (inclusive) are by 
		   # default internally not encoded as UTF-8 for backward 
		   # compatibility reasons.
                   $c = Encode::decode('cp-1252', $c);
		}
		$text->text_right($c);
	    }
        }
    }
  }
}

if ($type eq 'corefont') { $type = 'core'; }
if ($type eq 'type1') { $type = 'T1'; }
if ($type eq 'truetype') { $type = 'TTF'; }
# can't use $encode here... no longer set
$pdf->saveas("$outpath$extra.$type.$fontname.pdf");
$pdf->end();

sub usage {

  my $message = <<"EOF";

Usage:

ShowFont [options] font-name

Options:
  
  -t type
    type = one of
     corefont (default)
     truetype 
     type1  (postscript)

  -e encoding
    encoding = one or more of 
     latin1 latin2 latin3 latin4 latin5 latin6 latin7 latin8 latin9 latin10
     utf8
    There are other encodings possible (see listing of Loaded and All encodings)
    and many aliases and alternate spellings for a given encoding. The list
    given here is the default if -e is not given.

    utf8 is ignored for corefont and type1

  -r from to
    This is for UTF-8 only, the start and end Unicode values to be listed,
      up to 256 per page (pages are xx00 through xxFF). The values may be 
      given in decimal or hex (leading 'x'). The default is 00 through 3FF.
    Single byte encodings are x00 - xFF even if -r is given.

  -x extra name info
    This, if given, replaces "ShowFonts" as the first name field in the file
      name. It should be characters legal for a file name.

  -m T1 metrics file name
    This is required for Type1 files. It must be either an .afm or .pfm
    file that supplies metrics for the .pfa or .pfb glyph file.

EOF
  print "\nLoaded encodings:\n";
   foreach (@list) { print $_."  "; }
  print "\n\nAll encodings:\n";
   foreach (@list_all) { print $_."  "; }
  print "\n$message";

  return;
}

sub newpage {
    $page = $pdf->page();
#print "=== newpage. page=$page\n";
    $page->mediabox('universal');
    $grfx = $page->gfx(); # define first, so bg fill is under char fg
    $text = $page->text();
#print "=== newpage. text=$text\n";
    return;
}
