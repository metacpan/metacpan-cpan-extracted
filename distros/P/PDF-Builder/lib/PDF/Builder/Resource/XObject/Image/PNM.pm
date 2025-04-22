package PDF::Builder::Resource::XObject::Image::PNM;

# For spec details, see man pages pam(5), pbm(5), pgm(5), pnm(5),  ppm(5)

use base 'PDF::Builder::Resource::XObject::Image';

use strict;
use warnings;

our $VERSION = '3.027'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

use IO::File;
use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;
use Scalar::Util qw(weaken);

# massively rewritten recently, so assuming nothing in PDF::API2 rewrite (2021)
# should make any functional difference

=head1 NAME

PDF::Builder::Resource::XObject::Image::PNM - Support routines for PNM (Portable aNy Map) image library

Inherits from L<PDF::Builder::Resource::XObject::Image>

=head2 METHODS

=head2 new

    $res = PDF::Builder::Resource::XObject::Image::PNM->new($pdf, $file, %opts)

=over

Options:

=over

=item 'name' => 'string'

This is the name you can give for the PNM image object. The default is Nxnnnn.

=item 'compress' => 1

This is the compression you can give for the PNM image object. Any value will
cause the use of I<Flate> compression, otherwise (C<compress> not given),
I<ASCIIHexDecode> is used.

=back

=back

Returns an image in the PDF. PNM types 1 (ASCII/plain bi-level/PBM), 
2 (ASCII/plain grayscale/PGM), 3 (ASCII/plain RGB/PPM), 
4 (binary/raw bi-level/PBM), 5 (binary/raw grayscale/PGM), and 
6 (binary/raw RGB/PPM) are supported.

For bi-level, only values 0/1 (white/black) are supported. For grayscale, the
maximum sample (full white) may be anything from 1 to 65535, with 0 being full
black. If the maximum sample value is 255 or smaller, one byte of raw binary
data per pixel, otherwise two bytes. For RGB, each sample (full-on of that
color) may be anything from 1 to 65535 (the same maximum for all three colors),
with 0 being full black. If the maximum sample value is 255 or smaller, three
bytes of raw binary data per pixel, otherwise six bytes.

Remember that you need to use Builder.pm's image_pnm method to use this
functionality.

=cut

# -------------------------------------------------------------------
sub new {
    my ($class, $pdf, $file, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-name'} && !defined $opts{'name'}) { $opts{'name'} = delete($opts{'-name'}); }
    if (defined $opts{'-compress'} && !defined $opts{'compress'}) { $opts{'compress'} = delete($opts{'-compress'}); }

    my ($name, $compress);
    if (exists $opts{'name'}) { $name = $opts{'name'}; }
    if (exists $opts{'compress'}) { $compress = $opts{'compress'}; }

    my $self;

    $class = ref($class) if ref($class);

    $self = $class->SUPER::new($pdf, $name || 'Nx'.pdfkey());
    $pdf->new_obj($self) unless $self->is_obj($pdf);

    $self->{' apipdf'} = $pdf;
    weaken $self->{' apipdf'};

    $self->read_pnm($pdf, $file);

    if (defined $compress) {
	$self->filters('FlateDecode');
    } else {
	$self->filters('ASCIIHexDecode');
    }

    return $self;
}

# -------------------------------------------------------------------
# READPPMHEADER
# taken from Image::PBMLib
# Copyright by Benjamin Elijah Griffin (28 Feb 2003)
# extensively modified by Phil M Perry, copyright 2020
#
sub readppmheader {
    # renamed to _read_header() in PDF::API2
    my ($gr, $buffer) = @_; # already-opened input file's filehandle
    my %info;
    $info{'error'} = undef;
    my ($width, $height, $max, $comment, $content);

    # extension: allow whitespace BEFORE the magic number (usually none)
    # read Px magic number 
    ($buffer, $comment) = eat_whitespace($gr, $buffer, 0);
    ($buffer, $content) = read_content($gr, $buffer);

    if (length($content) != 2) {
        $info{'error'} = 'Read error or EOF';
        return (\%info, $buffer);
    }

    if ($content =~ /^P([1-6])/) {
        $info{'type'} = $1;
        if ($info{'type'} > 3) {
            $info{'raw'} = 1;  # P4-6 is raw (binary)
        } else {
            $info{'raw'} = 0;  # P1-3 is plain (ASCII)
        }
    } else {
        $info{'error'} = 'Unrecognized magic number, not 1..6';
        return (\%info, $buffer);
    }

    if ($info{'type'} == 1 or $info{'type'} == 4) {
        $max = 1;
        $info{'bgp'} = 'b';
    } elsif ($info{'type'} == 2 or $info{'type'} == 5) {
        # need to read and validate 'max'
        $info{'bgp'} = 'g';
    } else {  # 3 or 6
        # need to read and validate 'max'
        $info{'bgp'} = 'p';
    }

    # expect width as unsigned integer > 0
    ($buffer, $comment) = eat_whitespace($gr, $buffer, 0);
    ($buffer, $content) = read_content($gr, $buffer);
    if (length($content) == 0) {
        $info{'error'} = 'Read error or EOF on width';
        return (\%info, $buffer);
    }
    if ($content =~ m/(^\d+)$/) {
	$width = $1;
    } else {
        $info{'error'} = 'Invalid width value '.$1;
        return (\%info, $buffer);
    }
    if ($width < 1) {
        $info{'error'} = 'Invalid width value '.$width;
        return (\%info, $buffer);
    }
	    
    # expect height as unsigned integer > 0
    ($buffer, $comment) = eat_whitespace($gr, $buffer, 0);
    ($buffer, $content) = read_content($gr, $buffer);
    if (length($content) == 0) {
        $info{'error'} = 'Read error or EOF on height';
        return (\%info, $buffer);
    }
    if ($content =~ m/(^\d+)$/) {
	$height = $1;
    } else {
        $info{'error'} = 'Invalid height value '.$1;
        return (\%info, $buffer);
    }
    if ($height < 1) {
        $info{'error'} = 'Invalid height value '.$height;
        return (\%info, $buffer);
    }
	    
    # expect max sample value as unsigned integer > 0 & < 65536
    # IF grayscale or pixmap (RGB). already set to 1 for bi-level
    if ($info{'bgp'} =~ m/^[gp]$/) {
        ($buffer, $comment) = eat_whitespace($gr, $buffer, 0);
        ($buffer, $content) = read_content($gr, $buffer);
        if (length($content) == 0) {
            $info{'error'} = 'Read error or EOF on max';
            return (\%info, $buffer);
        }
        if ($content =~ m/(^\d+)$/) {
	    $max = $1;
        } else {
            $info{'error'} = 'Invalid max value '.$1;
            return (\%info, $buffer);
        }
        if ($max < 1 || $max > 65535) {
            $info{'error'} = 'Invalid max value '.$max;
            return (\%info, $buffer);
        }
    }
	    
    $info{'width'}  = $width;
    $info{'height'} = $height;
    $info{'max'}    = $max;

    # for binary (raw) files, a single whitespace character should be seen.
    # for ASCII (plain) files, extend to allow arbitrary whitespace
    if ($info{'raw'}) {
	# The buffer should have a single ws char in it already, left over from
	# the previous content read. We don't want to read anything beyond that 
	# in case a byte value happens to be a valid whitespace character! If 
	# the file format is botched and there is additional whitespace, it 
	# will unfortunately be read as binary data.
	if ($buffer =~ m/^\s/) {
	    $buffer = substr($buffer, 1); # discard first character
	} else {
	    $info{'error'} = 'Expected single whitespace before raster data';
            return (\%info, $buffer);
	}
    } else {
	# As an extension, for plain (ASCII) format we allow arbitrary
	# whitespace (including comments) after the max value and before the
	# raster data, not just one whitespace.
        ($buffer, $comment) = eat_whitespace($gr, $buffer, 0);
    }

    return (\%info, $buffer);
} # end of readppmheader()

# -------------------------------------------------------------------
# eat and discard whitespace stream, but return any comment(s) found
# within the header, cannot have an EOF during whitespace read
sub eat_whitespace {
    my ($gr, $buffer, $qflag) = @_;
    # qflag = 0 if OK to read more from file (don't expect an EOF)
    #       = 1 eating ws at end of image, might hit EOF here

    my ($count, $buf, @comment);
    # first see if enough material is already in the buffer. if not, read some
    my $in_comment = 0; # not currently processing a comment, just ws.
    while (1) {
	# is buffer empty? if so, read some content
	if (length($buffer) == 0) {
	    $count = read($gr, $buffer, 50); # chunk of up to 50 bytes (could be 0)
	    if ($count == 0 && (!$qflag || $in_comment)) {
		# EOF or read error, is bad thing here
		print STDERR "EOF or read error reading whitespace.\n";
		return ($buffer, '');
	    }
	}
	# if buffer is still empty (qflag == 1), will exit cleanly

	if (!$in_comment) { $buffer =~ s/^\s+//; }
	# a bunch of whitespace may have been discarded. if buffer now starts
	# with a #, it is a comment to be read to EOL. otherwise we're done.
	if (length($buffer) > 0) {
	    # buffer still has stuff in it (starts with non-ws)
	    if ($buffer =~ m/^#/) {
		$in_comment = 1;
		# at start of comment. discard up through \n
		# (\n might not yet be in buffer!)
		# special case: #\n
		if      ($buffer =~ s/^#\n//) {
                    # special empty case
                    $in_comment = 0;
		} elsif ($buffer =~ s/^#\s*([^\n]*)\n//) {
		    push @comment, $1; # has been removed from buffer
		    $in_comment = 0;
                } else {
		    # haven't gotten to end of comment (\n) yet
		    $count = read($gr, $buf, 50);
		    if ($count == 0) { 
			# EOF or read error, is bad thing here
		        print STDERR "EOF or read error reading whitespace in pixel data\n";
		        return ($buffer, '');
		    }
                    $buffer .= $buf;
		    next;
                }
	    } else {
	        # non-whitespace, not #. content to be left in buffer
		$in_comment = 0;
		last;
	    }
	} else {
	    # empty buffer, need to read some more
	    if ($qflag && !$in_comment) { last; }
	    next;
	}
    } # while(1) until run out of whitespace

    my $comments = '';
    if (scalar(@comment) > 0) { $comments = join("\n", @comment); }
    return ($buffer, $comments);
} # end of eat_whitespace()

# -------------------------------------------------------------------
# eat a non-whitespace stream, returning the content up until whitespace
# should not see an EOF during this (at least one ws after this stream)
sub read_content {
    my ($gr, $buffer) = @_;

    my ($count, $content);
    $content = '';
    # first see if enough material is already in the buffer. if not, read some
    while (1) {
	# is buffer empty? if so, read some content
	if (length($buffer) == 0) {
	    $count = read($gr, $buffer, 50); # chunk of up to 50 bytes (could be 0)
	    if ($count == 0) {
		# EOF or read error, is bad thing here
		print STDERR "EOF or read error reading content in pixel data\n";
		return ($buffer, '');
	    }
	}

	# should always be non-ws content here
	$buffer =~ s/^([^\s]+)//;
	$content .= $1;  # has been removed from buffer (now possibly empty)
	# if buffer now empty (didn't see ws char), need to read more
	if (length($buffer) == 0) { next; }
	last;  # non-empty buffer means it starts with a ws char

	# this function is used for header fields and non-raw pixel data, so
	# we don't expect to have an EOF immediately after a data item (must
	# be a \n after it at the last data item).

    } # while(1) until run out of non-whitespace

    return ($buffer, $content);
} # end of read_content()

# -------------------------------------------------------------------
sub read_pnm {
    my $self = shift;
    my $pdf = shift;
    my $file = shift;

    my ($rc, $buf, $buf2, $s, $pix, $max);
    # $s is a scale factor for sample not full 8 or 16 bits.
    # it should scale the input to 0..255 or 0..65535, so final value
    # will be a full 8 or 16 bits per channel (bpc)
    my ($w,$h, $bpc, $cs, $img, @img) = (0,0, '', '', '');
    my ($info, $buffer, $content, $comment, $sample, $gr);
    my $inf;
    if (ref($file)) {
        $inf = $file;
    } else {
        open $inf, "<", $file or die "$!: $file";
    }
    binmode($inf,':raw');
    $inf->seek(0, 0);
    $buffer = ''; # initialize
    ($info, $buffer) = readppmheader($inf, $buffer);
    # info (hashref) fields:
    #   error     undef or an error description
    #   type      magic number 1-6
    #   raw       0 if plain/ASCII, 1 if raw/binary
    #   bgp       b=bi-level (1,4) g=grayscale (2,5), p=pixmap/RGB (3,6)
    #   width     width (row length/horizontal) in pixels
    #   height    height (row count/vertical) in pixels
    #   max       sample max value 1 for bi-level, 1-65535 for grayscale/RGB
    #   comments  comment line(s), if any (else '')
    if (defined $info->{'error'}) {
	print STDERR "Error reported during PNM file header read:\n".($info->{'error'}).".\n";
	return $self;
    }

    $w   = $info->{'width'};
    $h   = $info->{'height'};
    $max = $info->{'max'};

    my $bytes_per_sample = 1;
    if ($max > 255) { $bytes_per_sample = 2; }

    # ------------------------------
    if      ($info->{'type'} == 1) {
	# plain (ASCII) PBM bi-level, each pixel 0..1, ws between is optional
        
        $bpc = 1;  # one bit per channel/sample/pixel
	# pack 8 pixels (possibly with don't-care at end of row) to a byte
	my ($row, $col, $bits); # need to handle rows separately for d/c bits
	my $qflag;
	$content = '';
        for ($row = 0; $row < $h; $row++) {
	    $bits = '';
            for ($col = 0; $col < $w; $col++) {
	        # could be a single 0 or 1, or a whole bunch lumped together
		# in one or more groups
		# buffer has 0 or more entries. handle just one in this loop,
		# reading in new buffer if necessary
		if (length($content) == 0) {
                    $qflag = 0;
		    if ($row == $h-1 && $col == $w-1) { $qflag = 1; }
		    ($buffer, $comment) = eat_whitespace($inf, $buffer, $qflag);
		    ($buffer, $content) = read_content($inf, $buffer);
		    if (length($content) == 0) {
			print STDERR "Unexpected EOF or read error reading pixel data.\n";
			return $self;
		    }
		}
		$sample = substr($content, 0, 1);
		$content = substr($content, 1);
		if ($sample ne '0' && $sample ne '1') {
		    print STDERR "Invalid bit value '$sample' in pixel data.\n";
		    return $self;
		}
		$bits .= $sample;
		if (length($bits) == 8) {
		    $self->{' stream'} .= pack('B8', $bits);
		    $bits = '';
		}

            } # end of cols in row. partial $bits to finish?
	    if ($bits ne '') {
	        while (length($bits) < 8) {
	            $bits .= '0'; # don't care, but must be 0 or 1
		}
		$self->{' stream'} .= pack('B8', $bits);
	    }
        } # end of rows

        $cs = 'DeviceGray';  # at 1 bit per pixel
        $self->{'Decode'} = PDFArray(PDFNum(1), PDFNum(0));
	
    # ------------------------------
    } elsif ($info->{'type'} == 2) {
	# plain (ASCII) PGM grayscale, each pixel 0..max (1 or 2 bytes)
        
	# get scale factor $s to fully fill 8 or 16 bit sample (channel)
        if      ($max == 255 || $max == 65535) {
            $s = 0;  # flag: no scaling
        } elsif ($max > 255) {
            $s = 65535/$max;
        } else {
            $s = 255/$max;
        }
        $bpc = 8 * $bytes_per_sample;
	my $format = 'C';
	if ($bytes_per_sample == 2) { $format = 'S>'; }
	my $sample;

        for ($pix=($w*$h); $pix>0; $pix--) {
            ($buffer, $content) = read_content($inf, $buffer);
	    if (length($content) == 0) {
	        print STDERR "Unexpected EOF or read error reading pixel data.\n";
	        return $self;
	    }
            ($buffer, $comment) = eat_whitespace($inf, $buffer, $pix==1);

	    if ($content =~ m/^\d+$/) {
		if ($content > $max) {
		    print STDERR "Pixel data entry '$content' higher than $max. Value changed to $max.\n";
		    $content = $max;
		}
	    } else {
		print STDERR "Invalid pixel data entry '$content'.\n";
		return $self;
	    }
	    $sample = $content;

            if ($s > 0) {  
                # scaling needed
	        $sample = int($sample*$s + 0.5); # must not exceed 255/65535
            }
            $self->{' stream'} .= pack($format, $sample);
	} # loop through all pixels
        $cs = 'DeviceGray';
	
    # ------------------------------
    } elsif ($info->{'type'} == 3) {
	# plain (ASCII) PPM rgb, each pixel 0..max for R, G, B (1 or 2 bytes)
        
	# get scale factor $s to fully fill 8 or 16 bit sample (channel)
        if      ($max == 255 || $max == 65535) {
            $s = 0;  # flag: no scaling
        } elsif ($max > 255) {
            $s = 65535/$max;
        } else {
            $s = 255/$max;
        }
        $bpc = 8 * $bytes_per_sample;
	my $format = 'C';
	if ($bytes_per_sample == 2) { $format = 'S>'; }
	my ($sample, $rgb);

        for ($pix=($w*$h); $pix>0; $pix--) {
	    for ($rgb = 0; $rgb < 3; $rgb++) { # R, G, and B values
                ($buffer, $comment) = eat_whitespace($inf, $buffer, $pix==1);
                ($buffer, $content) = read_content($inf, $buffer);
	        if (length($content) == 0) {
	            print STDERR "Unexpected EOF or read error reading pixel data.\n";
	            return $self;
	        }

	        if ($content =~ m/^\d+$/) {
		    if ($content > $max) {
			# remember, $pix counts DOWN from w x h
		        print STDERR "Pixel $pix data entry '$content' higher than $max. Value changed to $max.\n";
		        $content = $max;
		    }
	        } else {
	  	    print STDERR "Invalid pixel data entry '$content'.\n";
	  	    return $self;
	        }
		$sample = $content;

                if ($s > 0) {  
                    # scaling needed
	            $sample = int($sample*$s + 0.5); # must not exceed 255/65535
                }
                $self->{' stream'} .= pack($format, $sample);
	    } # R G B loop
	} # loop through all pixels
        $cs = 'DeviceRGB';
	
    # ------------------------------
    } elsif ($info->{'type'} == 4) {
	# raw (binary) PBM bi-level, each pixel 0..1, row packed 8 pixel/byte
        $bpc = 1;  # one bit per channel/sample/pixel
	# round up for don't care bits at end of row
        my $bytes = int(($w+7)/8) * $h;
	$bytes -= length($buffer);  # some already read from file!
        $rc = read($inf, $buf2, $bytes);
	if ($rc != $bytes) {
	    print STDERR "Unexpected EOF or read error while reading PNM binary pixel data.\n";
	    return $self;
	}
	$self->{' stream'} = $buffer.$buf2;
        $cs = 'DeviceGray';  # at 1 bit per pixel
        $self->{'Decode'} = PDFArray(PDFNum(1), PDFNum(0));

    # ------------------------------
    } elsif ($info->{'type'} == 5) {
	# raw (binary) PGM grayscale, each pixel 0..max (1 or 2 bytes)
	
	# get scale factor $s to fully fill 8 or 16 bit sample (channel)
        if      ($max == 255 || $max == 65535) {
            $s = 0;  # flag: no scaling
        } elsif ($max > 255) {
            $s = 65535/$max;
        } else {
            $s = 255/$max;
        }
        $bpc = 8 * $bytes_per_sample;
	my $format = 'C';
	if ($bytes_per_sample == 2) { $format = 'S>'; }
	my ($buf, $sample);

        my $bytes = $w * $h * $bytes_per_sample;
	$bytes -= length($buffer);  # some already read from file!
        $rc = read($inf, $buf, $bytes);
	if ($rc != $bytes) {
	    print STDERR "Unexpected EOF or read error reading pixel data.\n";
	    return $self;
	}
	$buf = $buffer . $buf;
        if ($s > 0) {  
            # scaling needed
            for ($pix=($w*$h); $pix>0; $pix--) {
		$buf2 = substr($buf, 0, $bytes_per_sample);
		$buf  = substr($buf, $bytes_per_sample);
		$sample = unpack($format, $buf2);
	        $sample = int($sample*$s + 0.5); # must not exceed 255/65535
                $self->{' stream'} .= pack($format, $sample);
            }
        } else {
	    # no scaling needed
	    $self->{' stream'} = $buf;
        }
        $cs = 'DeviceGray';
	
    # ------------------------------
    } elsif ($info->{'type'} == 6) {
	# raw (binary) PPM rgb, each pixel 0..max for R, G, B (3 or 6 bytes)
	
	# get scale factor $s to fully fill 8 or 16 bit sample (channel)
        if      ($max == 255 || $max == 65535) {
            $s = 0;  # flag: no scaling
        } elsif ($max > 255) {
            $s = 65535/$max;
        } else {
            $s = 255/$max;
        }
        $bpc = 8 * $bytes_per_sample;
	my $format = 'C';
	if ($bytes_per_sample == 2) { $format = 'S>'; }
	my ($buf, $sample);

        my $bytes = $w * $h * $bytes_per_sample * 3;
	$bytes -= length($buffer);  # some already read from file!
        $rc = read($inf, $buf, $bytes);
	if ($rc != $bytes) {
	    print STDERR "Unexpected EOF or read error reading pixel data.\n";
	    return $self;
	}
	$buf = $buffer . $buf;
        if ($s > 0) {  
            # scaling needed
            for ($pix=($w*$h); $pix>0; $pix--) {
		# Red
		$buf2 = substr($buf, 0, $bytes_per_sample);
		$sample = unpack($format, $buf2);
	        $sample = int($sample*$s + 0.5); # must not exceed 255/65535
                $self->{' stream'} .= pack($format, $sample);
		# Green
		$buf2 = substr($buf, $bytes_per_sample, $bytes_per_sample);
		$sample = unpack($format, $buf2);
	        $sample = int($sample*$s + 0.5); # must not exceed 255/65535
                $self->{' stream'} .= pack($format, $sample);
		# Blue
		$buf2 = substr($buf, 2*$bytes_per_sample, $bytes_per_sample);
		$sample = unpack($format, $buf2);
	        $sample = int($sample*$s + 0.5); # must not exceed 255/65535
                $self->{' stream'} .= pack($format, $sample);

		$buf  = substr($buf, $bytes_per_sample*3);
            }
        } else {
	    # no scaling needed
	    $self->{' stream'} = $buf;
        }
        $cs = 'DeviceRGB';
    }
    close($inf);

    $self->width($w);
    $self->height($h);

    $self->bits_per_component($bpc);

    $self->filters('FlateDecode');

    $self->colorspace($cs);

    return $self;
} # end of read_pnm()

1;
