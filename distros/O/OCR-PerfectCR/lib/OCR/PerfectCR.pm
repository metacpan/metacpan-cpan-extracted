package OCR::PerfectCR;

# ABOVE the 'use strict' line!
$VERSION = 0.03;

use warnings;
use strict;
use IO::File;
use GD;
use Digest::MD5 'md5_hex';
use Graphics::ColorObject;
use Carp 'croak';

=head1 NAME

OCR::PerfectCR - Perfect OCR (if you have perfect input).

=head1 SYNOPSIS

    use OCR::PerfectCR;
    use GD;
    
    my $recognizer = OCR::PerfectCR->new;
    $recognizer->load_charmap_file("charmap");
    my $image = GD::Image->new("example.png") or die "Can't open example.png: $!";
    my $string = $recognizer->recognize($image);
    $recognizer->save_charmap_file("charmap");


=head1 DESCRIPTION

OCR::PerfectCR is a fast, highly accurate "optical" character recognition
engine requiring minimal training.  How does it manage this, despite
being written in pure perl?  By ignoring most of the problems.
OCR::PerfectCR requires that your input is in perfect shape -- that it
hasn't gone into the real world and been scanned, that each image
represent one line of text, and nothing else, and most difficultly,
that the font have a fairly wide spacing.  This makes it very useful
for converting image-based subtitle formats to text, and probably not
much else.  However, it is very good at doing that.

OCR::PerfectCR's knowledge about a particular font is encapsulated in a
"charmap" file, which maps md5 sums of the canonical representation
of a character (the first 32 characters of the line) to a string (the
34th and onwards chars, to newline).

Most methods will die on error, rather then trying to recover and return undef.

=cut

=head2 $recognizer->load_charmap_file("charmap")

Loads a charmap file into memory.

=cut

sub load_charmap_file {
  my $self = shift;
  my $filename = shift;
  
  # print "load_charmap_file($self, $filename);\n";
  
  my $charmapfile = IO::File->new("<".$filename) or 
    croak "Couldn't open $filename: $!";
  binmode($charmapfile, ':utf8');
  local $_;
  while (<$charmapfile>) {
    chomp;
    next if !$_ or $_ =~ m/^#/;
    my ($md5, $value);
    $md5 = substr($_, 0, 32, '');
    substr($_, 0, 1, '');
    $value = $_;
    $self->{charmap}{$md5}=$value;
  }
  
  return;
}

=head2 $recognizer->save_charmap_file("charmap")

Saves the charmap to a file.  Charmap files are always saved and
loaded in utf8.

=cut

sub save_charmap_file {
  my ($recognizer, $filename) = @_;
  # print "save_charmap_file($recognizer, $filename);\n";

  my $charmapfile = IO::File->new(">$filename") or 
    croak "Couldn't open $filename: $!";
  my %images = %{$recognizer->{charmap}};
  binmode($charmapfile, ':utf8');
  {
    no warnings 'uninitialized';
    for (sort {$images{$a} cmp $images{$b} or
                 $a  cmp $b} 
         keys %images) {
      my $v = $images{$_};
      $charmapfile->print("$_ $v\n");
    }
  }
}

=head2 $recognizer->recognize($image)  (recognise is an alias for this)

Takes the image (a GD::Image object), and tries to convert it into
text.  In list context, returns a list of hashrefs, each having a
C<str> key, whose value is the string in the charmap for that image.
There may also be a C<color> (note the spelling) key, with a value
between 0 and 360, representing the color of the text in degrees on
the color wheel, or C<undef> meaning grey.  The C<color> being missing
implies that there is nothing there but background -- that is, that
it's whitespace.  For non-whitespace characters, there is a key
C<md5>, which gives the md5 sum of the character in canonical form --
that is, it's charmap entry.  Other keys are purposefully not
documented -- if you find them useful, I<please> let me know by filing
an RT request.

Characters not in the charmap will have their str set to C<"\x{FFFD}"
eq "\N{REPLACEMENT CHARACTER}">, and will be added to the charmap.
They will also be saved as png files named I<md5>.png in the current
directory, so that they a human can look at them and ID them.


=cut

sub recognize {
  chopup(@_, \&charimage);
}
# To avoid an "only used once" warning.
*recognise = *recognize;
*recognise = *recognize;

=head2 OCR::PerfectCR->new();

Just a boring constructor.  No parameters.

=cut

sub new {
  return bless {}, shift;
}

=head1 BUGS

Please report bugs on L<http://rt.cpan.org/>.  If the bug /might possibly/ be because of your input file, please include it with the bug report.

=head1 AUTHOR & LICENSE

Copyright 2005 James Mastros, james@mastros.biz, JMASTROS, theorbtwo.  (Those are all the same person.)

May be used and copied under the same terms as C<perl> itself.

Thanks, castaway, for being you, and diotalevi for a detailed review.

=cut

### Internal functions below here.
sub charimage {
  my ($recognizer, $image, @bgrgb) = @_;
  
  # print "charimage($recognizer, $image)\n";
  ($image, my $this) = image_to_grey($image, @bgrgb);
  
  # printf "Got char image, size %d by %d\n", $image->getBounds;
  my $md5 = imagesum($image);
  $this->{md5} = $md5;
  if (!exists $recognizer->{charmap}{$md5}) {
    $recognizer->{charmap}{$md5} = "\x{FFFD}";
    # print  "md5: $md5\n";
    # print "First time!\n";
    
    my $file = IO::File->new(">$md5.png") or die "Couldn't create $md5.png: $!";
    binmode($file);
    $file->print($image->png);
  }
  
  #print "Known character: $images{$md5}\n";
  #print $images{$md5};
  $this->{str} = $recognizer->{charmap}{$md5};
  
  return $this;
}

my %rgb255_to_hsv;
sub RGB255_to_HSV {
  my ($r, $g, $b) = @_;
  my $rgb = $r * 0x10000 + $g*0x100 + $b;
  if (!exists $rgb255_to_hsv{$rgb}) {
    $rgb255_to_hsv{$rgb} = Graphics::ColorObject->new_RGB255(\@_, space=>'PAL')->as_HSV;
  }
  return @{$rgb255_to_hsv{$rgb}};
}

my %hsv_to_rgb255;
sub HSV_to_RGB255 {
  my ($h, $s, $v) = @_;
  my $hsv = "$h,$s,$v";
  if (!exists $hsv_to_rgb255{$hsv}) {
    $hsv_to_rgb255{$hsv} = Graphics::ColorObject->new_HSV(\@_, space=>'PAL')->as_RGB255;
  }
  return @{$hsv_to_rgb255{$hsv}};
}

sub image_to_grey {
  my ($colorimage, @bgrgb) = @_;
  my $totalweight = 0;
  my $totalcolor = 0;
  my $maxval = 0;

  my ($width, $height) = $colorimage->getBounds;
  my $bwimage = GD::Image->new($width, $height);
  my $black   = $bwimage->colorResolve(0, 0, 0);
  my $white   = $bwimage->colorResolve(255, 255, 255);

  # Squash to greyscale; figure out what the whitest pixel value is.
  foreach my $x (0..$width) {
    foreach my $y (0..$height) {
      my ($r, $g, $b) = $colorimage->rgb($colorimage->getPixel($x, $y));
      $r = abs($r - $bgrgb[0]);
      $g = abs($g - $bgrgb[1]);
      $b = abs($b - $bgrgb[1]);
      my ($h, $s, $v) = RGB255_to_HSV($r, $g, $b);
      $totalweight += $s;
      $totalcolor  += $h * $s;
      $maxval      = $v if $maxval < $v;
    }
  }

  # Adjust to put whitest value at 100%; squash to plain black and white.
  foreach my $x (0..$width) {
    foreach my $y (0..$height) {
      my ($r, $g, $b) = $colorimage->rgb($colorimage->getPixel($x, $y));
      $r = abs($r - $bgrgb[0]);
      $g = abs($g - $bgrgb[1]);
      $b = abs($b - $bgrgb[1]);
      my ($h, $s, $v) = RGB255_to_HSV($r, $g, $b);
      if ($v/$maxval > .5) {
        $bwimage->setPixel($x, $y, $white);
      } else {
        $bwimage->setPixel($x, $y, $black);
      }
    }
  }

  # print "Total color weight: ", $totalweight, "\n";
  # print "Average color: ", $totalcolor/$totalweight, "\n";
  my $avgcolor = sprintf("%.0f", $totalcolor/$totalweight);
  $avgcolor = undef if $totalweight < 1;

  return $bwimage, {color => $avgcolor, bgrgb=>\@bgrgb};
}

sub chopup {
  my ($recognizer, $inimage, $imagefunc) = @_;
  # print "chopup($recognizer, $inimage, $imagefunc);\n";
  my @string;
  
  my $bgcolor = $inimage->getPixel(0,0);
  my (@bgrgb) = $inimage->rgb($bgcolor);
  print "Background color at index $bgcolor [@bgrgb]\n";
  my ($width, $height) = $inimage->getBounds;
  
  my $mincol=0;
  while ($mincol <= $width) {
    my ($startcol, $endcol);
    print "Finding bounds starting at $mincol\n";

    # Find left and right char boundry.
    for my $col ($mincol .. $width-1) {
      # print "Column $col: ";
      my $hasnonbg=0;
      for my $row (0 .. $height-1) {
        if ($inimage->getPixel($col, $row) != $bgcolor) {
          $hasnonbg=1;
          last;
        }
      }
      # print "$hasnonbg\n";
      
      if (not defined $startcol) {
        if ($hasnonbg) {
          $startcol = $col;
        }
      } else {
        if (!$hasnonbg) {
          $endcol = $col;
          last;
        }
      }
    }
    
    if (not defined $endcol) {
      $endcol = $width-1;
    }

    if (not defined $startcol or
        $startcol >= $endcol) {
      # print "Couldn't find anything\n";
      last;
    }
    
    
    my ($startrow, $endrow);

    # Find top boundry
    for my $row (0..$height-1) {
      my $hasnonbg=0;
      for my $col ($startcol..$endcol) {
        if ($inimage->getPixel($col, $row) != $bgcolor) {
          $hasnonbg=1;
          last;
        }
      }
      if ($hasnonbg) {
        $startrow = $row;
        last;
      }
    }
    
    # Find bottom boundry.
    for my $row (reverse(0..$height-1)) {
      my $hasnonbg=0;
      for my $col ($startcol..$endcol) {
        if ($inimage->getPixel($col, $row) != $bgcolor) {
          $hasnonbg=1;
          last;
        }
      }
      if ($hasnonbg) {
        $endrow = $row;
        last;
      }
    }
    
    print "Character at ($startcol, $startrow)-($endcol, $endrow)\n";
    my $charimage = gdextract($inimage, $startcol, $startrow, $endcol, $endrow);
    my $this = $imagefunc->($recognizer, $charimage, @bgrgb);
    $this->{prespace} = $startcol - $mincol;
    $this->{startcol} = $startcol;
    # $this->{mincol} = $mincol;
    $this->{endcol} = $endcol;
    $this->{width} = $endcol - $startcol;
    $this->{chrwidth} = ($endcol - $startcol)/length($this->{str});
    push @string, $this;
    
    $mincol = $endcol;
  }
  
  # print "\n";
  
  #   for (1..$#string-1) {
  #     my $prev = $string[$_-1];
  #     my $this = $string[$_];
  
  #     print "Chars:      $prev->{str} -- $this->{str}\n";
  #     print "Charwidths: $prev->{chrwidth} -- $this->{chrwidth}\n";
  #     print "Prespace:     $this->{prespace}\n";
  #     print ("Metric: ", (($prev->{chrwidth}+$this->{chrwidth})/2)/$this->{prespace}, "\n");
  
  #   }

  # Insert spaces.
  @string = map {
    # The "6" here is mostly just a guess.
    # The ne '.' is just to fix up a common situation in the purticular
    # source I checked against the most.
    if ($_->{prespace} > $height/6 
        and $_->{str} ne '.') {
      ({str=>" ", fake=>1}, $_);
    } else {
      $_;
    }
  } @string;
  
  # print "Finished: ", join('', map { $_->{str} } @string), "\n";

  if (wantarray) {
    return @string;
  } else {
    return join "", map { $_->{str} } @string;
  }
}

# Just a silly helper
sub gdextract {
  my ($inimage, $x1, $y1, $x2, $y2) = @_;
  my $width  = $x2-$x1 + 1;
  my $height = $y2-$y1 + 1;

  my $outimage = GD::Image->new($width, $height);
  $outimage->copy($inimage, 0, 0, $x1, $y1, $width, $height);

  return $outimage;
}

# It appears that GD's ->png method doesn't always return exactly the
# same string for the same image -- it depends on the version of GD,
# or of libpng, or of libz, or... something.  I want charmap files to
# be portable, so I need a portable method, so we define our own.  It
# doesn't have to be small, just portable.
#
# Note to self: Everything should be packed N -- big-endian (network) u32.
sub imagesum {
  my ($img) = @_;
  my $str;
  my ($w, $h) = $img->getBounds;

  $str = pack('NN', $w, $h);
  for my $x (0..$w) {
    for my $y (0..$h) {
      $str .= pack('NNN', $img->rgb($img->getPixel($x, $y)));
    }
  }

  return md5_hex($str);
}

1;
