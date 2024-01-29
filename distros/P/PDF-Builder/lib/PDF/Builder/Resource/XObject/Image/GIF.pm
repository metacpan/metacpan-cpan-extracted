package PDF::Builder::Resource::XObject::Image::GIF;

use base 'PDF::Builder::Resource::XObject::Image';

use strict;
use warnings;

our $VERSION = '3.026'; # VERSION
our $LAST_UPDATE = '3.026'; # manually update whenever code is changed

use IO::File;
use PDF::Builder::Util;
use PDF::Builder::Basic::PDF::Utils;
use Scalar::Util qw(weaken);

=head1 NAME

PDF::Builder::Resource::XObject::Image::GIF - support routines for GIF image library. Inherits from L<PDF::Builder::Resource::XObject::Image>

=head2 History

GIF89a Specification: https://www.w3.org/Graphics/GIF/spec-gif89a.txt

A fairly thorough description of the GIF format may be found in 
L<http://giflib.sourceforge.net/whatsinagif/bits_and_bytes.html>.

Code originally from PDF::Create, PDF::Image::GIFImage - GIF image support
Author: Michael Gross <mdgrosse@sboxtugraz.at>

=head1 Supported Formats

GIF87a and GIF89a headers are supported. The Image block (x2C) is supported.

The Graphic Control Extension block (x21 + xF9) is supported for transparency 
control. Animation is not supported.

The Comment Extension block (x21 + xFE), Plain Text Extension block (x21 + x01),
and Application Extension block (x21 + xFF) are read, but ignored. Any other
block or Extension block will be flagged as an error.

If given, Local Color Tables are read and used, supposedly permitting more 
than 256 colors to be used overall in the image (despite the 8 bit color table
depth).

=head2 Options

=over

=item notrans

When defined and not 0, C<notrans> suppresses the use of transparency if such
is defined in the GIF file.

=item name => 'string'

This is the name you can give for the GIF image object. The default is Gxnnnn.

=item multi

When defined and not 0, C<multi> continues processing past the end of the 
first Image Block. The old behavior, which is now the default, is to stop 
processing at the end of the first Image Block.

=back

=cut

# modified for internal use. (c) 2004 fredo.
sub unInterlace {
    my $self = shift;

    my $data = $self->{' stream'};
    my $row;
    my @result;
    my $width = $self->width();
    my $height = $self->height();
    my $idx = 0;

    # Pass 1 - every 8th row, starting with row 0
    $row = 0;
    while ($row < $height) {
        $result[$row] = substr($data, $idx*$width, $width);
        $row += 8;
        $idx++;
    }

    # Pass 2 - every 8th row, starting with row 4
    $row = 4;
    while ($row < $height) {
        $result[$row] = substr($data, $idx*$width, $width);
        $row += 8;
        $idx++;
    }

    # Pass 3 - every 4th row, starting with row 2
    $row = 2;
    while ($row < $height) {
        $result[$row] = substr($data, $idx*$width, $width);
        $row += 4;
        $idx++;
    }

    # Pass 4 - every 2nd row, starting with row 1
    $row = 1;
    while ($row < $height) {
        $result[$row] = substr($data, $idx*$width, $width);
        $row += 2;
        $idx++;
    }

    return $self->{' stream'} = join('', @result);
}

sub deGIF {
    my ($ibits, $stream) = @_;

    my $bits = $ibits;
    my $resetcode = 1 << ($ibits-1);
    my $endcode = $resetcode+1;
    my $nextcode = $endcode+1;
    my $ptr = 0;
    my $maxptr = 8*length($stream);
    my $tag;
    my $out = '';
    my $outptr = 0;

 #   print STDERR "reset=$resetcode\nend=$endcode\nmax=$maxptr\n";

    my @d = map { chr($_) } (0 .. $resetcode-1);

    while ($ptr+$bits <= $maxptr) {
        $tag = 0;
        foreach my $off (reverse 0 .. $bits-1) {
            $tag <<= 1;
            $tag |= vec($stream, $ptr+$off, 1);
        }
    #    foreach my $off (0 .. $bits-1) {
    #        $tag <<= 1;
    #        $tag |= vec($stream, $ptr+$off, 1);
    #    }
    #    print STDERR "ptr=$ptr,tag=$tag,bits=$bits,next=$nextcode\n";
    #    print STDERR "tag too large\n" if($tag>$nextcode);
        $ptr += $bits;
        $bits++ if $nextcode == 1 << $bits and $bits < 12;
        if      ($tag == $resetcode) {
            $bits = $ibits;
            $nextcode = $endcode+1;
            next;
        } elsif ($tag == $endcode) {
            last;
        } elsif ($tag < $resetcode) {
            $d[$nextcode] = $d[$tag];
            $out .= $d[$nextcode];
            $nextcode++;
        } elsif ($tag > $endcode) {
            $d[$nextcode] = $d[$tag];
            $d[$nextcode] .= substr($d[$tag+1], 0, 1);
            $out .= $d[$nextcode];
            $nextcode++;
        }
    }
    return $out;
}

=head1 METHODS

=head2 new

     PDF::Builder::Resource::XObject::Image::GIF->new()

=over

Create an image object from a GIF input file.
Remember that this should be invoked via the Builder.pm method!

=back

=cut

sub new {
    my ($class, $pdf, $file, %opts) = @_;
    # copy dashed option names to preferred undashed names
    if (defined $opts{'-notrans'} && !defined $opts{'notrans'}) { $opts{'notrans'} = delete($opts{'-notrans'}); }
    if (defined $opts{'-name'} && !defined $opts{'name'}) { $opts{'name'} = delete($opts{'-name'}); }
    if (defined $opts{'-multi'} && !defined $opts{'multi'}) { $opts{'multi'} = delete($opts{'-multi'}); }
    if (defined $opts{'-compress'} && !defined $opts{'compress'}) { $opts{'compress'} = delete($opts{'-compress'}); }

    my ($name, $compress);
    if (exists $opts{'name'}) { $name = $opts{'name'}; }
   #if (exists $opts{'compress'}) { $compress = $opts{'compress'}; }

    my $self;

    my $interlaced = 0;

    $class = ref($class) if ref($class);

    $self = $class->SUPER::new($pdf, $name || 'Gx'.pdfkey());
    $pdf->new_obj($self) unless $self->is_obj($pdf);

    $self->{' apipdf'} = $pdf;
    weaken $self->{' apipdf'};

    my $fh = IO::File->new();
    if (ref($file)) {
        $fh = $file;
    } else {
        open $fh, "<", $file or die "$!: $file";
    }
    binmode $fh, ':raw';
    my $buf;
    $fh->seek(0, 0);

    # start reading in the GIF file
    #   GIF Header
    #     6 bytes "GIF87a" or "GIF89a"
    $fh->read($buf, 6); # signature
    unless ($buf =~ /^GIF[0-9][0-9][a-b]/) {
        # TBD b? is anything other than 87a and 89a valid?
	#     PDF::API2 allows a-z, not just a-b
        die "unknown image signature '$buf' -- not a GIF." 
    }

    #     4 bytes logical screen width and height (2 x 16 bit LSB first)
    #     1 byte flags, 1 byte background color index, 1 byte pixel aspect ratio
    $fh->read($buf, 7); # logical screen descriptor
    my($wg, $hg, $flags, $bgColorIndex, $aspect) = unpack('vvCCC', $buf);

    #       flags numbered left to right 0-7:
    #         bit 0 = 1 (x80) Global Color Table Flag (GCTF)
    #         bits 1-3 = color resolution
    #         bit 4 = 1 (x08) sort flag for Global Color Table
    #         bits 5-7 = size of Global Color Table 2**(n+1), $colSize
    if ($flags & 0x80) {  # GCTF is set?
        my $colSize = 2**(($flags & 0x7)+1);  # 2 - 256 entries
        my $dict = PDFDict();
        $pdf->new_obj($dict);
        $self->colorspace(PDFArray(PDFName('Indexed'), 
			  PDFName('DeviceRGB'), 
			  PDFNum($colSize-1), 
			  $dict));
        $fh->read($dict->{' stream'}, 3*$colSize); # Global Color Table
    }

    #   further content in file is blocks and trailer
    while (!$fh->eof()) {
        $fh->read($buf, 1); # 1 byte block tag (type)
        my $sep = unpack('C', $buf);

        if      ($sep == 0x2C) {
	    # x2C = image block (separator, equals ASCII comma ',')
            $fh->read($buf, 9); # image descriptor
	    #   image left (16 bits), image top (16 bits LSB first)
	    #   image width (16 bits), image height (16 bits LSB first)
	    #   flags (1 byte):
	    #     bit 0 = 1 (x80) Local Color Table Flag (LCTF)
	    #     bit 1 = 1 (x40) interlaced
	    #     bit 2 = 1 (x20) sort flag
	    #     bits 3-4 = reserved
	    #     bits 5-7 = size of Local Color Table 2**(n+1) if LCTF=1
            my ($left, $top, $w,$h, $flags) = unpack('vvvvC', $buf);

            $self->width($w||$wg);
            $self->height($h||$hg);
            $self->bits_per_component(8);

            if ($flags & 0x80) { # Local Color Table (LCTF = 1)
                my $colSize = 2**(($flags & 0x7)+1);
                my $dict = PDFDict();
                $pdf->new_obj($dict);
                $self->colorspace(PDFArray(PDFName('Indexed'), 
				           PDFName('DeviceRGB'), 
					   PDFNum($colSize-1), 
					   $dict));
                $fh->read($dict->{' stream'}, 3*$colSize); # Local Color Table
            }
            if ($flags & 0x40) { # need de-interlace
                $interlaced = 1;  # default to 0 earlier
            }

	    # LZW Minimum Code Size
            $fh->read($buf, 1); # image-lzw-start (should be 9).
            my ($sep) = unpack('C', $buf);

	    # read one or more blocks. first byte is length. 
	    # if 0, done (Block Terminator)
            $fh->read($buf, 1); # first chunk.
            my ($len) = unpack('C', $buf);
            my $stream = '';
            while ($len > 0) { # loop through blocks as long as non-0 length
                $fh->read($buf, $len);
                $stream .= $buf;
                $fh->read($buf, 1);
                $len = unpack('C', $buf);
            }
            $self->{' stream'} = deGIF($sep+1, $stream);
            $self->unInterlace() if $interlaced;
            # old (and current default) behavior is to quit processing at the
	    # end of the first Image Block. This means that any other blocks,
	    # including the Trailer, will not be processed.
	    if (!$opts{'multi'}) { last; }

        } elsif ($sep == 0x3b) {
	    # trailer (EOF) equals ASCII semicolon (;)
            last;

        } elsif ($sep == 0x21) {
            # Extension block (x21 + subtag) = ASCII '!'
            $fh->read($buf, 1); # tag.
            my $tag = unpack('C', $buf);

	    if ($tag == 0xF9) {
	        # xF9  graphic control extension block
                $fh->read($buf, 1); # len.  should be 04
                my $len = unpack('C', $buf);
                my $stream = '';
                while ($len > 0) {
                    $fh->read($buf, $len);
                    $stream .= $buf;
                    $fh->read($buf, 1);
                    $len = unpack('C', $buf);
                }
                my ($cFlags, $delay, $transIndex) = unpack('CvC', $stream);
                if (($cFlags & 0x01) && !$opts{'notrans'}) {
                    $self->{'Mask'} = PDFArray(PDFNum($transIndex), 
			                       PDFNum($transIndex));
                }

	    } elsif ($tag == 0xFE) {
	        # xFE  comment extension block
		#   read comment data block(s) until 0 length
		#   currently just discard comment ($stream)
                $fh->read($buf, 1); # len.
                my $len = unpack('C', $buf);
                my $stream = '';
                while ($len > 0) {
                    $fh->read($buf, $len);
                    $stream .= $buf;
                    $fh->read($buf, 1);
                    $len = unpack('C', $buf);
                }

	    } elsif ($tag == 0x01) {
	        # x01  plain text extension block
                $fh->read($buf, 13); # len.
                my ($blkSize,$tgL,$tgT,$tgW,$tgH,$ccW,$ccH,$tFci,$tBci) = 
		    unpack('CvvvvCCCC', $buf);

		#   read plain text data block(s) until 0 length
		#   currently just discard comment ($stream)
                $fh->read($buf, 1); # len.
                my $len = unpack('C', $buf);
                my $stream = '';
                while ($len > 0) {
                    $fh->read($buf, $len);
                    $stream .= $buf;
                    $fh->read($buf, 1);
                    $len = unpack('C', $buf);
                }

	    } elsif ($tag == 0xFF) {
	        # xFF  application extension block
                $fh->read($buf, 1);
                my $blkSize = unpack('C', $buf);
                $fh->read($buf, 8);
                my $appID = unpack('C8', $buf);

                $fh->read($buf, 1); # len.
                my $len = unpack('C', $buf);
                my $stream = '';
                while ($len > 0) {
                    $fh->read($buf, $len);
                    $stream .= $buf;
                    $fh->read($buf, 1);
                    $len = unpack('C', $buf);
                }

	    } else {
                print "unsupported extension block (".
		    sprintf("0x%02X",$tag).") ignored!\n";
	    }

        } else {
            # other extensions and blocks (ignored)
            print "unsupported extension or block (".
		    sprintf("0x%02X",$sep).") ignored.\n";

            $fh->read($buf, 1); # tag.
            my $tag = unpack('C', $buf);
            $fh->read($buf, 1); # tag.
            my $len = unpack('C', $buf);
            while ($len > 0) {
                $fh->read($buf, $len);
                $fh->read($buf, 1);
                $len = unpack('C', $buf);
            }
        }
    }
    $fh->close();

    $self->filters('FlateDecode');

    return $self;
}

1;
