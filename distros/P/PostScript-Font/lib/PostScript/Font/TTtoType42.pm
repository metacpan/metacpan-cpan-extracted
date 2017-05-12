# RCS Status      : $Id: TTtoType42.pm,v 1.12 2007-10-11 11:47:17+02 jv Exp $
# Author          : Johan Vromans
# Created On      : Mon Dec 16 18:56:03 2002
# Last Modified By: Johan Vromans
# Last Modified On: Thu Oct 11 11:47:15 2007
# Update Count    : 196
# Status          : Released

################ Module Preamble ################

package PostScript::Font::TTtoType42;

use 5.006;

use strict;
use warnings;

our $VERSION = "0.04";

use base qw(Font::TTF::Font);

use constant CHUNK => 65534;

################ Public Methods ################

# my $f = new PostScript::Font::TTtoType42::("Arial.ttf");

sub new {
    my $class = shift;
    my $font = shift;
    my (%atts) = (verbose => 0, trace => 0, debug => 0,
		  @_);
    my $self = Font::TTF::Font->open($font);
    $self->{' verbose'} = $atts{verbose};
    $self->{' trace'}   = $atts{trace} || $self->{verbose};
    $self->{' debug'}   = $atts{debug} || $self->{trace};
    bless $self, $class;
}

# $f->write("Arial.t42");

sub write {
    my ($self, $file) = @_;

    CORE::open(my $fd, ">", $file) or die("$file: $!\n");
    print $fd (${$self->as_string});
    close($fd);
    $self;
}

# my $t42data = ${$f->as_string};

sub as_string {
    my ($self) = @_;

    # Read some tables.
    my $head = $self->{head}->read;
    my $name = $self->{name}->read;
    my $post = $self->{post}->read;

    # Version. Try to normalize to nnn.nnn.
    my $version = $self->_str(5);
    $version = sprintf("%07.3f", $1) if $version =~ /(\d+\.\d+)/;

    # Font bounding box.
    # Some fonts have dimensions that are 1000 times too small. Let's
    # do some auto-sensing.
    my $fix = 1;
    my $scale = do {
	my $u = $head->{unitsPerEm};
	sub {int($_[0] * $fix / $u)}
    };
    my @bb = map { $scale->($head->{$_}) } qw(xMin yMin xMax yMax);
    if ( !$bb[0] || !$bb[1] || !$bb[2] || !$bb[3] ) {
	$fix = 1000;
	@bb = map { $scale->($head->{$_}) } qw(xMin yMin xMax yMax);
    }

    # Glyph table.
    my $glyphs = $self->glyphs;

    # Start font information.
    my $ret = "%!PS-TrueTypeFont" .
              "-" . sprintf("%07.3f", $self->{head}{version}) .
              "-" . $version .
              "\n" .
              "%%Creator: " . __PACKAGE__ . " " . $VERSION .
	      " by Johan Vromans\n" .
	      "%%CreationDate: " . localtime(time) . "\n";

    $ret .= "11 dict begin\n";
    $self->_addstr(\$ret, "FontName", 6, 1);
    $ret .= "/FontType 42 def\n" .
            "/FontMatrix [1 0 0 1 0 0] def\n" .
	    "/FontBBox [@bb] def\n" .
	    "/PaintType 0 def\n" .
	    "/FontInfo 9 dict dup begin\n" .
	    "/version (" . _psstr($version) . ") readonly def\n";
    # $self->_addstr(\$ret, "Notice",     0);
    $self->_addstr(\$ret, "FullName",   4);
    $self->_addstr(\$ret, "FamilyName", 1);
    $self->_addstr(\$ret, "Weight",     2);
    $self->_addnum(\$ret, "ItalicAngle",        $post->{italicAngle});
    $self->_addbool(\$ret,"isFixedPitch",       $post->{isFixedPitch});
    $self->_addnum(\$ret, "UnderlinePosition",  $post->{underlinePosition});
    $self->_addnum(\$ret, "UnderlineThickness", $post->{underlineThickness});
    $ret .= "end readonly def\n" .
            "/Encoding StandardEncoding def\n";

    # CharStrings definitions.
    $glyphs = [ ".notdef" ] unless @$glyphs;
    $ret .= "/CharStrings " . scalar(@$glyphs) . " dict dup begin\n";
    my $i = 0;
    foreach ( @$glyphs ) {
	$ret .= "/$_ $i def\n";
	$i++;
    }
    $ret .= "end readonly def\n";

    # TrueType strings table.
    $ret .= "/sfnts[<\n";

    my @tables = ('cvt ', 'fpgm', 'glyf', 'head', 'hhea', 'hmtx', 'loca',
		  'maxp', 'prep');

    # Count the number of tables actually present.
    my $tables = 0;
    foreach my $t ( @tables ) {
	next unless $self->{$t};
	next unless $self->{$t}->{' LENGTH'};
	$tables++;
    }

    my $start = 12 + 16 * $tables;
    my $dir = _dirhdr($tables);
    my $fd = $self->{' INFILE'};

    # Create dir entries and calculate the new 'head' checksum.
    my $csum = 0xB4DED201;
    { use integer;
      foreach my $t ( @tables ) {
	next unless $self->{$t};
	my $off = $self->{$t}->{' OFFSET'};
	my $len = $self->{$t}->{' LENGTH'};
	my $sum = $self->{$t}->{' CSUM'};
	$dir .= sprintf("%s%08X%08X%08X\n",
			uc unpack("H8", $t), $sum, $start, $len);
	$csum += $sum + $sum + $start + $len;
	$start += $len;
	$start++ while $start % 4;
      }
      $csum &= 0xffffffff;
      $csum = 0xb1b0afba - $csum;
    }

    # Add dir info and prepare for the tables.
    $ret .= $dir;
    my $tally = length($dir) / 2;
    my $data = "";

    my $ship = sub {
	$data =~ s/(.{72})/$1\n/g;
	$ret .= $data . "\n00><\n";
	$data = "";
	$tally = 0;
    };

    foreach my $t ( @tables ) {
	next unless $self->{$t};
	my $len = $self->{$t}->{' LENGTH'};
	next unless $len;	# to make sure.

	printf STDERR ("$t: off = 0x%x, len = 0x%x, csum = 0x%x\n",
		       $self->{$t}->{' OFFSET'}, $len,
		       $self->{$t}->{' CSUM'}) if $self->{' trace'};

	# If the glyf table is bigger than a CHUNK, it must be split on 
	# a glyph boundary...
	if ( $t eq "glyf" && $len > CHUNK ) {
	    $self->_glyftbl(\$data, \$tally, $ship, $fd,
			    $self->{glyf}->{' OFFSET'}, $len,
			    $self->{loca}->{' OFFSET'},
			    $self->{loca}->{' LENGTH'});
	}
	else {
	    # Ship current sfnts string if this table does not fit.
	    if ( $tally + $len > CHUNK ) {
		$ship->();
	    }

	    # Read table, and convert to hex data.
	    my $off = $self->{$t}->{' OFFSET'};
	    sysseek($fd, $off, 0);
	    while ( $len > 0 ) {
		my $dat;
		my $l = $len >= 1024 ? 1024 : $len;
		sysread($fd, $dat, $l);
		if ( $t eq "head" ) {
		    # Move new checksum in.
		    substr($dat,8,4) = pack("N",$csum)
		}
		$len -= $l;
		$tally += $l;
		$l += $l;
		$data .= uc unpack("H$l", $dat);
	    }
	}

	# Pad to 4-byte boundary if necessary.
	if ( ($len = $self->{$t}->{' LENGTH'}) & 0x3 ) {
	    printf STDERR ("odd length 0x%x, adjusting...\n", $len)
	      if $self->{' debug'};
	    $len = 4 - ($len & 0x3);
	    $data .= "00" x $len;
	    $tally += $len;
	}
    }

    # Format and terminate pending sfnts string.
    $data =~ s/(.{72})/$1\n/g;
    $ret .= $data . "\n00>";

    # Finish font info.
    $ret .= "]def\n" .
	    "FontName currentdict end definefont pop\n";

    # Return ref to the info.
    \$ret;
}

# my @glyphs = @{$f->glyphs};
# Ordered set of glyphs, as they appear in the font.
sub glyphs {
    my $self = shift;
    $self->{glyphs} ||= $self->_getglyphs;
}

# my @glyphnames = @{$f->glyphnames};
# Sorted list of glyph names, no duplicates.
sub glyphnames {
    my $self = shift;
    return $self->{glyphnames} if exists $self->{glyphnames};
    my %glyphs = map { $_ => 1 } @{$self->glyphs};
    $self->{glyphnames} = [ sort keys %glyphs ];
}

# $f->write_afm("Arial.afm");
sub write_afm {
    my ($self, $file) = @_;
    CORE::open(my $fd, ">", $file) or die("$file: $!\n");
    print $fd (${$self->afm_as_string});
    close($fd);
    $self;
}

# my $afmdata = ${$f->afm_as_string};
sub afm_as_string {
    my ($self) = @_;

    # Read some tables.
    my $head = $self->{head}->read;
    my $hhea = $self->{'OS/2'}->read;
    my $name = $self->{name}->read;
    my $post = $self->{post}->read;

    # Version. Try to normalize to nnn.nnn.
    my $version = $self->_str(5);
    $version = sprintf("%07.3f", $1) if $version =~ /(\d+\.\d+)/;

    # Font bounding box.
    # Some fonts have dimensions that are 1000 times too small. Let's
    # do some auto-sensing.
    my $fix = 1;
    my $scale = do {
	my $u = $head->{unitsPerEm};
	sub {int($_[0] * $fix / $u)}
    };
    my @bb = map { $scale->($head->{$_}) } qw(xMin yMin xMax yMax);
    if ( !$bb[0] || !$bb[1] || !$bb[2] || !$bb[3] ) {
	$fix = 1000;
	@bb = map { $scale->($head->{$_}) } qw(xMin yMin xMax yMax);
    }

    # Glyph table.
    my $glyphs = $self->glyphs;

    # Start AFM information.
    my $ret = "StartFontMetrics 4.1\n";

    $ret .= "Comment Creator: " . __PACKAGE__ . " " . $VERSION .
	    " by Johan Vromans\n" .
	    "Comment Creation Date: " . localtime(time) . "\n" .
            "FontName "   . $self->_str(6) . "\n" .
            "FullName "   . $self->_str(4) . "\n" .
	    "FamilyName " . $self->_str(1) . "\n" .
	    "Weight "     . $self->_str(2) . "\n" .
	    sprintf("ItalicAngle %s\n" .
		    "IsFixedPitch %s\n" .
		    "FontBBox %d %d %d %d\n" .
		    "UnderlinePosition %d\n" .
		    "UnderlineThickness %d\n",
		    $post->{italicAngle},
		    $post->{isFixedPitch} ? "true" : "false",
		    @bb,
		    $post->{underlinePosition},
		    $post->{underlineThickness},
		   ) .
	    "Version $version\n" .
	    "Notice "     . _psstr($self->_str(0)) . "\n" .
	    "EncodingScheme AdobeStandardEncoding\n" .
	    "Ascender " . $scale->($hhea->{sTypoAscender}) . "\n" .
	    "Descender " . $scale->($hhea->{sTypoDescender}) . "\n";

    #### Encoding.

    # Build reverse encoding hash.
    my %enc;
    { require PostScript::StandardEncoding;
      my $enc = PostScript::StandardEncoding::->array;
      foreach my $i ( 0..scalar(@$enc)-1 ) {
	$enc{$enc->[$i]} = $i;
      }
    }

    #### Character Data

    { my @metrics = ("") x 256;
      my @xmetrics;
      my $loca = $self->{loca}->read;
      my $hmtx = $self->{hmtx}->read;
      my $width = $hmtx->{advance};
      my $space;
      my $nbspace;
      my $nglyphs = 0;

      $loca->glyphs_do
        ( sub { my ($glyph, $gix) = @_;
	        $glyph->read_dat;
		my $name = $glyphs->[$gix];
		return if $name eq ".notdef";
	        my $ix = $enc{$name};
		$ix = -1 unless defined($ix);
		my $ent = sprintf("C %d ; WX %d ; N %s ; B %d %d %d %d ;\n",
				  $ix,
				  $scale->($width->[$gix]),
				  $name,
				  map { $scale->($glyph->{$_}) }
				  qw(xMin yMin xMax yMax));
		if ( $ix >= 0 ) {
		    $metrics[$ix] = $ent;
		}
		else {
		    push(@xmetrics, $ent);
		}
		if ( $name eq "space" ) {
		    $space = $ent;
		}
		elsif ( $name =~ /^(nb|nonbreaking)space$/ ) {
		    $nbspace = $ent;
		}
		$nglyphs++;
	    } );

      # Add space and nbspace, if necessary;
      my $wspace;
      for ( qw(space nonbreakingspace) ) {
	  next if $_ eq "space" && $space;
	  next if $_ eq "nonbreakingspace" && $nbspace;

	  unless ( defined($wspace) ) {
	      my $spx = 0;
	      foreach ( @$glyphs ) {
		  last if $_ eq "space";
		  $spx++;
	      }
	      $wspace = $scale->($width->[$spx]);
	  }

	  my $ix = $enc{$_};
	  $ix = -1 unless defined($ix);
	  my $ent = "C $ix ; WX $wspace ; N $_ ; B 0 0 0 0 ;\n";
	  if ( $ix >= 0 ) {
	      $metrics[$ix] = $ent;
	  }
	  else {
	      push(@xmetrics, $ent);
	  }
	  $nglyphs++;
      }

      # Sort the unencoded glyphs.
      @xmetrics = map { $_->[1] }
	sort { $a->[0] cmp $b->[0] }
	  map { [ (split(' ', $_))[7], $_ ] } @xmetrics;

      $ret .= "StartCharMetrics $nglyphs\n" .
	join("", @metrics, @xmetrics);
    }

    $ret .= "EndCharMetrics\n\n";

    #### Kerning Data

    if ( $self->{kern} ) {
	$ret .= "StartKernData\n";
	### $ret .= "StartTrackKern\n";
	### $ret .= "EndTrackKern\n";

	my $kern = $self->{kern}->read;
	my $nkern = 0;

	# Gather the contents of all the kern tables in a single hash.
	my %k;
	foreach my $table ( @{$kern->{tables}} ) {
	    my $kerns = $table->{kern};
	    foreach my $left ( keys %$kerns ) {
		foreach my $right ( keys %{$kerns->{$left}} ) {
		    $k{$glyphs->[$left]}{$glyphs->[$right]} =
		      $scale->($kerns->{$left}{$right});
		    $nkern++;
		}
	    }
	}

	# Now print the hash, sorted.
	$ret .= "StartKernPairs $nkern\n";
	foreach my $left ( sort keys %k ) {
	    foreach my $right ( sort keys %{$k{$left}} ) {
		$ret .= "KPX $left $right " . $k{$left}{$right} . "\n";
	    }
	    $ret .= "\n";
	}
	$ret .= "EndKernPairs\n";
	$ret .= "EndKernData\n";
    }

    ### $ret .= "StartComposites\n";
    ### $ret .= "EndComposites\n";

    $ret .= "EndFontMetrics\n";

    \$ret;
}

# Font::TTF::Font uses cyclic structures, so we need this.
sub DESTROY {
    my $self = shift;
    $self->release;
}

################ Internal routines ################

# Create the directory header for the sfnts strings.
sub _dirhdr {
    my ($tables) = @_;
    my $searchrange = 1;
    my $entryselector = 0;

    while ( $searchrange <= $tables ) {
	$searchrange *= 2;
	$entryselector++;
    }
    $searchrange = 16 * ($searchrange/2);
    $entryselector--;
    my $rangeshift = 16 * $tables - $searchrange;

    sprintf("00010000%02hX%02hX%02hX%02hX%02hX%02hX%02hX%02hX\n",
	    $tables        >> 8, $tables        & 0xff,
	    $searchrange   >> 8, $searchrange   & 0xff,
	    $entryselector >> 8, $entryselector & 0xff,
	    $rangeshift    >> 8, $rangeshift    & 0xff);
}

# Fetch a PostScript string.
sub _str {
    my ($self, $idx) = @_;
    # [1] platform = 1 (Apple Unicode)
    # [0] encoding = 0 (default)
    # {0} language = 0 (default, English)
    $self->{name}{strings}[$idx][1][0]{0} || "";
}

# Generate the define code for a string, if it exists.
sub _addstr {
    my ($self, $ret, $tag, $idx, $name) = @_;
    my $t = $self->_str($idx);
    return unless $t ne "";
    if ( $name && $t =~ /^[-\w]+$/ ) {
	$$ret .= "/$tag /$t def\n";
    }
    else {
	$t = _psstr($t);
	$$ret .= "/$tag ($t) readonly def\n";
    }
}

# Escape PostScript characters.
sub _psstr {
    my ($str) = @_;
    $str =~ s/([\\()])/\\$1/g;
    $str =~ s/([\000-\037\177-\377])/sprintf("\\%03o",ord($1))/eg;
    $str;
}

# Generate the define code for a number, if it exists.
sub _addnum {
    my ($self, $ret, $tag, $val) = @_;
    return unless defined $val;
    $$ret .= "/$tag $val def\n";
}

# Generate the define code for a boolean, if it exists.
sub _addbool {
    my ($self, $ret, $tag, $val) = @_;
    return unless defined $val;
    $$ret .= "/$tag " .
      ( $val ? "true" : "false" ) . " def\n";
}

# Get the list of glyphs.
sub _getglyphs {
    my $self = shift;
    $self->{post}->read;
    $self->{glyphs} = $self->{post}{VAL};
    unless ( $self->{glyphs} ) {
	warn(__PACKAGE__ . ": No glyphs?\n");
	$self->{glyphs} = [];
    }
    $self->{glyphs};
}

# Generate the sfnts strings for the glyph table, splitting it on glyph
# boundaries.
sub _glyftbl {
    my ($self, $rd, $rt, $ship, $fd, $glyf_off, $glyf_len, $loca_off, $loca_len) = @_;

    # To split the glyph table we need to find an appropriate glyph
    # boudary. This requires processing the 'loca' table.

    my $loca = _read_tbl($fd, $loca_off, $loca_len);
    my $glyf = _read_tbl($fd, $glyf_off, $glyf_len);

    my $glyphs = $self->{maxp}->read->{numGlyphs};
    my $locfmt = $self->{head}->read->{indexToLocFormat};
    print STDERR ("glyphs = $glyphs, locfmt  = $locfmt\n") if $self->{' debug'};

    my $start = 0;
    my $off_old = 0;
    my $off;

    for ( my $i = 0; $i <= $glyphs; $i++ ) {
	if ( $locfmt ) {
	    $off = unpack("N", substr($$loca, $i*4, 4));
	}
	else {
	    $off = unpack("n", substr($$loca, $i*2, 2)) * 2;
	}
	if ( $$rt + $off - $start > CHUNK ) {
	    my $l = $off_old - $start;
	    $$rd .= uc unpack("H".($l+$l), substr($$glyf, $start, $l));
	    $start += $l;
	    $ship->();
	}
	$off_old = $off;
    }
    my $l = $glyf_len - $start;
    $$rd .= uc unpack("H".($l+$l), substr($$glyf, $start, $l));
    $$rt += $l;

    printf STDERR ("glyf ends: data = 0x%x, tally = 0x%x\n",
		   length($$rd), $$rt) if $self->{' debug'};
}

# Fetch (read) a complete table.
sub _read_tbl {
    my ($fd, $off, $len) = @_;
    sysseek($fd, $off, 0);
    my $data = "";
    while ( $len > 0 ) {
	my $l = sysread($fd, $data, $len, length($data));
	last if $l == $len;
	die("read: $!\n") if $l <= 0;
	$len -= $l;
    }
    \$data;
}

1;

__END__

=head1 NAME

PostScript::Font::TTtoType42 - Wrap a TrueType font into PostScript Type42

=head1 SYNOPSIS

    use PostScript::Font::TTtoType42;
    # Open a TrueType font.
    my $font = PostScript::Font::TTtoType42::->new("Arial.ttf");
    # Write a Type42 font.
    $font->write("Arial.t42");
    # Get the font data (scalar ref).
    my $ptr = $font->as_string;
    # Get the font glyph names (array ref).
    my $gref = $font->glyphnames;

=head1 DESCRIPTION

PostScript::Font::TTtoType42 is a subclass of Font::TTF::Font. It
knows how to wrap a TrueType font into PostScript Type42 format.

=head1 METHODS

=over

=item new(I<fontname> [ I<atts> ])

Opens the named TrueType font.

=item as_string

Returns the font data in Type42 format as reference to one single
string. Newlines are embedded for readability.

=item write(I<t42name>)

Writes the font data in Type42 format to the named file.

=item afm_as_string

Returns the font metrics in AFM format as a reference to a single
string. Newlines are embedded for readability.

=item write_afm(I<afmname>)

Writes the font metrics in AFM format to the named file.

=item glyphnames

Returns an array reference with the names of all the glyphs of the
font, sorted alphabetically.

=back

=head1 KNOWN BUGS

Certain TrueType fonts cause problems.
If you find one, let me know.

CID fonts are not yet supported.

=head1 SEE ALSO

=over 4

=item http://partners.adobe.com/asn/developer/PDFS/TN/5012.Type42_Spec.pdf

The specification of the Type 42 font format.

=item http://fonts.apple.com/TTRefMan/index.html

The True Type reference manual.

=item http://partners.adobe.com/asn/developer/PDFS/TN/5004.AFM_Spec.pdf

The specification of the Adobe font metrics file format.
=back

=head1 AUTHOR

Johan Vromans, Squirrel Consultancy <jvromans@squirrel.nl>

=head1 COPYRIGHT and DISCLAIMER

This program is Copyright 2002 by Squirrel Consultancy. All
rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either: a) the GNU General Public License as
published by the Free Software Foundation; either version 1, or (at
your option) any later version, or b) the "Artistic License" which
comes with Perl.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See either the
GNU General Public License or the Artistic License for more details.

=cut
