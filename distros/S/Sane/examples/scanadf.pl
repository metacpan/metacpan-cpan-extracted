#!/usr/bin/perl

use warnings;
use strict;
use Sane;
use Data::Dumper;
use Getopt::Long qw(:config no_ignore_case pass_through);
use File::Basename;
use IO::Handle;

#$Sane::DEBUG = 1;

my (%options, @window_val_user, @window_option, @window_val,
    @window, $device, $format, $devname, %option_number);
my $num_dev_options = 0;
my $verbose = 0;
my $help = 0;
my $test = 0;
my $batch_start_at = 1;
my $batch_count = -1;
my $batch_increment = 1;
my $buffer_size = (32 * 1024);	# default size
my $tl_x = 0;
my $tl_y = 0;
my $br_x = 0;
my $br_y = 0;
my $w_x = 0;
my $h_y = 0;
my $resolution_optind = -1;
my $resolution_value = 0;
my $prog_name = basename($0);
my $SANE_FRAME_TEXT = 10;
my $SANE_FRAME_JPEG = 11;
my $SANE_FRAME_G31D = 12;
my $SANE_FRAME_G32D = 13;
my $SANE_FRAME_G42D = 14;
my $no_overwrite = 0;
my $outputFile = "image-%04d";        # file name(format) to write output to
my $raw = SANE_FALSE;
my $scanScript;		# script to run at end of scan
my $startNum = 1, my $endNum = -1;                # start/end numbers of pages to scan
my @args = (\%options, 'd|device-name=s' => \$devname,
                       'L|list-devices',
                       'h|help' => \$help,
                       'v|verbose+' => \$verbose,
                       'N|no-overwrite' => \$no_overwrite,

                       'o|output-file:s' => \$outputFile,
                       's|start-count=i' => \$startNum,
                       'e|end-count=i' => \$endNum,
                       'r|raw' => \$raw);

sub sane_strframe {
 my $frame = shift;
 my %frame = (
  SANE_FRAME_GRAY => "gray",
  SANE_FRAME_RGB => "RGB",
  SANE_FRAME_RED => "red",
  SANE_FRAME_GREEN => "green",
  SANE_FRAME_BLUE => "blue",
  $SANE_FRAME_TEXT => "text",
  $SANE_FRAME_JPEG => "jpeg",
  $SANE_FRAME_G31D => "g31d",
  $SANE_FRAME_G32D => "g32d",
  $SANE_FRAME_G42D => "g42d",
 );
 if (defined $frame{$frame}) {
  return $frame{$frame};
 }
 else {
  return "unknown";
 }
}


sub sane_isbasicframe {
 my $frame = shift;
 return 
  $frame == SANE_FRAME_GRAY ||
  $frame == SANE_FRAME_RGB ||
  $frame == SANE_FRAME_RED ||
  $frame == SANE_FRAME_GREEN ||
  $frame == SANE_FRAME_BLUE
}


sub sighandler {
 my $signum = shift;

 if ($device) {
  print STDERR "$prog_name: stopping scanner...\n";
  $device->cancel;
 }
}


sub print_unit {
 my ($unit) = @_;

 if ($unit == SANE_UNIT_PIXEL) {
  print "pel";
 }
 elsif ($unit == SANE_UNIT_BIT) {
  print "bit";
 }
 elsif ($unit == SANE_UNIT_MM) {
  print "mm";
 }
 elsif ($unit == SANE_UNIT_DPI) {
  print "dpi";
 }
 elsif ($unit == SANE_UNIT_PERCENT) {
  print "%";
 }
 elsif ($unit == SANE_UNIT_MICROSECOND) {
  print "us";
 }
}


sub print_option {
 my ($device, $opt_num, $short_name) = @_;

 my $not_first = SANE_FALSE;
 my $maxwindow = 0;

 my $opt = $device->get_option_descriptor ($opt_num);

 if ($short_name) {
  printf "    -%s", $short_name;
 }
 else {
  printf "    --%s", $opt->{name};
 }

 if ($opt->{type} == SANE_TYPE_BOOL) {
  print "[=(";
  print "auto|" if ($opt->{cap} & SANE_CAP_AUTOMATIC);
  print "yes|no)]";
 }
 elsif ($opt->{type} != SANE_TYPE_BUTTON) {
  print ' ';
  if ($opt->{cap} & SANE_CAP_AUTOMATIC) {
   print "auto|";
   $not_first = SANE_TRUE;
  }
  if ($opt->{constraint_type} == SANE_CONSTRAINT_NONE) {
   if ($opt->{type} == SANE_TYPE_INT) {
    print "<int>";
   }
   elsif ($opt->{type} == SANE_TYPE_FIXED) {
    print "<float>";
   }
   elsif ($opt->{type} == SANE_TYPE_STRING) {
    print "<string>";
   }
   print ",..." if ($opt->{max_values} > 1);
  }
  elsif ($opt->{constraint_type} == SANE_CONSTRAINT_RANGE) {
   my $format = "%g..%g";
   $format = "%d..%d" if ($opt->{type} == SANE_TYPE_INT);
   if ($opt->{name} eq SANE_NAME_SCAN_BR_X) {
    $maxwindow = $opt->{constraint}{max} - $tl_x;
    printf $format, $opt->{constraint}{min}, $maxwindow;
   }
   elsif ($opt->{name} eq SANE_NAME_SCAN_BR_Y) {
    $maxwindow = $opt->{constraint}{max} - $tl_y;
    printf $format, $opt->{constraint}{min}, $maxwindow;
   }
   else {
    printf $format, $opt->{constraint}{min}, $opt->{constraint}{max};
   }
   print_unit ($opt->{unit});
   print ",..." if ($opt->{max_values} > 1);
   print " (in steps of $opt->{constraint}{quant})"
    if ($opt->{constraint}{quant});
  }
  elsif ($opt->{constraint_type} == SANE_CONSTRAINT_STRING_LIST
                      or $opt->{constraint_type} == SANE_CONSTRAINT_WORD_LIST) {
   for (my $i = 0; $i < @{$opt->{constraint}}; ++$i) {
    print '|' if ($i > 0);

    print $opt->{constraint}[$i];
   }
   if ($opt->{constraint_type} == SANE_CONSTRAINT_WORD_LIST) {
    print_unit ($opt->{unit});
    print ",..." if ($opt->{max_values} > 1);
   }
  }
 }
 if ($opt->{max_values} == 1) {
  # print current option value
  if (! ($opt->{cap} & SANE_CAP_INACTIVE)) {
   my $val = $device->get_option ($opt_num);
   print " [";
   if ($opt->{type} == SANE_TYPE_BOOL) {
    print ($val ? "yes" : "no");
   }
   elsif ($opt->{type} == SANE_TYPE_INT or $opt->{type} == SANE_TYPE_FIXED) {
    my $format = "%g";
    $format = "%d" if ($opt->{type} == SANE_TYPE_INT);
    if ($opt->{name} eq SANE_NAME_SCAN_TL_X) {
     $tl_x = $val;
     printf $format, $tl_x;
    }
    elsif ($opt->{name} eq SANE_NAME_SCAN_TL_Y) {
     $tl_y = $val;
     printf $format, $tl_y;
    }
    elsif ($opt->{name} eq SANE_NAME_SCAN_BR_X) {
     $br_x = $val;
     $w_x = $br_x - $tl_x;
     printf $format, $w_x;
    }
    elsif ($opt->{name} eq SANE_NAME_SCAN_BR_Y) {
     $br_y = $val;
     $h_y = $br_y - $tl_y;
     printf $format, $h_y;
    }
    else {
     printf $format, $val;
    }
   }
   elsif ($opt->{type} == SANE_TYPE_STRING) {
    print $val;
   }
   print ']';
  }
 }

 print " [inactive]" if ($opt->{cap} & SANE_CAP_INACTIVE);

 print "\n        ";

 if ($short_name eq 'x') {
  print "Width of scan-area.";
 }
 elsif ($short_name eq 'y') {
  print "Height of scan-area.";
 }
 else {
  my $column = 8;
  my $last_break = 0;
  my $start = 0;
  for (my $pos = 0; $pos < length($opt->{desc}); ++$pos) {
   ++$column;
   $last_break = $pos if (substr($opt->{desc}, $pos, 1) eq ' ');
   if ($column >= 79 and $last_break) {
    print substr($opt->{desc}, $start++, 1) while ($start < $last_break);
    $start = $last_break + 1;   # skip blank
    print "\n        ";
    $column = 8 + $pos - $start;
   }
  }
  print substr($opt->{desc}, $start++, 1) while ($start < length($opt->{desc}));
 }
 print "\n";
}


# A scalar has the following syntax:
#
#     V [ U ]
#
#   V is the value of the scalar.  It is either an integer or a
#   floating point number, depending on the option type.
#
#   U is an optional unit.  If not specified, the default unit is used.
#   The following table lists which units are supported depending on
#   what the option's default unit is:
#
#     Option's unit:	Allowed units:
#
#     SANE_UNIT_NONE:
#     SANE_UNIT_PIXEL:	pel
#     SANE_UNIT_BIT:	b (bit), B (byte)
#     SANE_UNIT_MM:	mm (millimeter), cm (centimeter), in or " (inches),
#     SANE_UNIT_DPI:	dpi
#     SANE_UNIT_PERCENT:	%
#     SANE_UNIT_MICROSECOND:	us

sub parse_scalar {
 my ($opt, $str) = @_;

 my ($v, $unit);
 if ($str =~ /^(\d*\.?\d*)(cm|mm|in|\"|b|B|dpi|%|us)?/) {
  $v = $1;
  $unit = $2;
  $unit = '' if not defined $unit;
 }
 else {
  print STDERR
             "$prog_name: option --$opt->{name}: bad option value (rest of option: $str)\n";
  exit (1);
 }

 if ($opt->{unit} == SANE_UNIT_BIT) {
  $v *= 8 if ($unit eq 'B');
 }
 elsif ($opt->{unit} == SANE_UNIT_MM) {
  if ($unit eq 'cm') {
   $v *= 10;
  }
  elsif ($unit eq 'in') {
   $v *= 25.4;
  }
 }
 return $v, substr($str, length($v) + length($unit), length($str));
}


# A vector has the following syntax:
#
#     [ '[' I ']' ] S { [','|'-'] [ '[' I ']' S }
#
#   The number in brackets (I), if present, determines the index of the
#   vector element to be set next.  If I is not present, the value of
#   last index used plus 1 is used.  The first index value used is 0
#   unless I is present.
#
#   S is a scalar value as defined by parse_scalar().
#
#   If two consecutive value specs are separated by a comma (,) their
#   values are set independently.  If they are separated by a dash (-),
#   they define the endpoints of a line and all vector values between
#   the two endpoints are set according to the value of the
#   interpolated line.  For example, [0]15-[255]15 defines a vector of
#   256 elements whose value is 15.  Similarly, [0]0-[255]255 defines a
#   vector of 256 elements whose value starts at 0 and increases to
#   255.

sub parse_vector {
 my ($opt, $str) = @_;

 my $index = -1;
 my $prev_value = 0;
 my $prev_index = 0;
 my $separator = '';
 my (@vector, $value);
 do {
  if ($str =~ /^\[/) {
   if ($str =~ /^\[(\d*\.?\d*)\]/) {
    $index = $1;
   }
   else {
    print STDERR
             "$prog_name: option --$opt->{name}: closing bracket missing "
                ."(rest of option: $str)\n";
    exit (1);
   }
  }
  else {
   ++$index;
  }

  if ($index < 0 or $index >= length($str)) {
   printf STDERR
             "$prog_name: option --$opt->{name}: index $index out of range [0..%d]\n",
               length($str);
   exit (1);
  }

  # read value
  ($value, $str) = parse_scalar ($opt, $str);

  if ($str ne '' and $str !~ /^[-,]/) {
   print STDERR
             "$prog_name: option --$opt->{name}: illegal separator (rest of option: $str)\n";
   exit (1);
  }

  # store value:
  $vector[$index] = $value;
  if ($separator eq '-') {
   # interpolate
   my $v = $prev_value;
   my $slope = ($value - $v) / ($index - $prev_index);

   for (my $i = $prev_index + 1; $i < $index; ++$i) {
    $v += $slope;
    $vector[$i] = $v;
   }
  }

  $prev_index = $index;
  $prev_value = $value;
  $separator = substr($str, 0, 1);
 }
 while ($separator eq ',' || $separator eq '-');

 if ($verbose > 2) {
  print STDERR "$prog_name: value for --$opt->{name} is: ";
  for (@vector) {
   print STDERR "$_ ";
  }
  print STDERR "\n";
 }
 
 return @vector;
}


sub fetch_options {
 my $device = shift;

# We got a device, find out how many options it has:
 $num_dev_options = $device->get_option(0);
 if ($Sane::STATUS != SANE_STATUS_GOOD) {
  print STDERR "$prog_name: unable to determine option count\n";
  exit (1);
 }

 for (my $i = 0; $i < $num_dev_options; ++$i) {
  my $opt = $device->get_option_descriptor ($i);

  next if (! ($opt->{cap} & SANE_CAP_SOFT_SELECT));

  $option_number{$opt->{name}} = $i;

  # Look for scan resolution
  $resolution_optind = $i
   if (($opt->{type} == SANE_TYPE_FIXED || $opt->{type} == SANE_TYPE_INT)
      and ($opt->{unit} == SANE_UNIT_DPI)
      and ($opt->{name} eq SANE_NAME_SCAN_RESOLUTION));

# Keep track of top-left corner options (if they exist at
# all) and replace the bottom-right corner options by a
# width/height option (if they exist at all).
  if (($opt->{type} == SANE_TYPE_FIXED || $opt->{type} == SANE_TYPE_INT)
      and ($opt->{unit} == SANE_UNIT_MM || $opt->{unit} == SANE_UNIT_PIXEL)) {
   if ($opt->{name} eq SANE_NAME_SCAN_TL_X) {
    $window[2] = $i;
    $opt->{name} = 'l';
   }
   elsif ($opt->{name} eq SANE_NAME_SCAN_TL_Y) {
    $window[3] = $i;
    $opt->{name} = 't';
   }
   elsif ($opt->{name} eq SANE_NAME_SCAN_BR_X) {
    $window[0] = $i;
    $opt->{name} = 'x';
    $window_option[0] = $opt;
    $window_option[0]->{title} = 'Scan width';
    $window_option[0]->{desc} = 'Width of scanning area.';
    $window_val[0] = $device->get_option ($i)
     if (!$window_val_user[0]);
   }
   elsif ($opt->{name} eq SANE_NAME_SCAN_BR_Y) {
    $window[1] = $i;
    $opt->{name} = 'y';
    $window_option[1] = $opt;
    $window_option[1]->{title} = 'Scan height';
    $window_option[1]->{desc} = 'Height of scanning area.';
    $window_val[1] = $device->get_option ($i)
     if (!$window_val_user[1]);
   }
  }

  if ($opt->{type} == SANE_TYPE_BOOL) {
   push @args, "$opt->{name}:s";
  }
  elsif ($opt->{type} == SANE_TYPE_BUTTON) {
   push @args, $opt->{name};
  }
  else {
   push @args, "$opt->{name}=s";
  }
 }

# Initialize width & height options based on backend default
# values for top-left x/y and bottom-right x/y:
 for (my $i = 0; $i < 2; ++$i) {
  if ($window[$i] and $window[$i + 2] and !$window_val_user[$i]) {
   my $pos = $device->get_option ($window[$i + 2]);
   $window_val[$i] = $window_val[$i] - $pos if (defined $pos);
  }
 }
}


sub set_option {
 my ($device, $optnum, $value) = @_;

 my $opt = $device->get_option_descriptor ($optnum);
 if ($opt and ($opt->{cap} & SANE_CAP_INACTIVE)) {
  print STDERR
             "$prog_name: ignored request to set inactive option $opt->{name}\n"
   if ($verbose > 0);
  return;
 }

 my $info = $device->set_option($optnum, $value);
 if ($Sane::STATUS != SANE_STATUS_GOOD) {
  print STDERR
            "$prog_name: setting of option --$opt->{name} failed ($Sane::STATUS)\n";
  exit (1);
 }

 if (($info & SANE_INFO_INEXACT) and $opt->{max_values} == 1) {
  my $orig = $value;
  $value = $device->get_option($optnum);
  if ($opt->{type} == SANE_TYPE_INT) {
   printf STDERR
     "$prog_name: rounded value of $opt->{name} from %d to %d\n", $orig, $value;
  }
  elsif ($opt->{type} == SANE_TYPE_FIXED) {
   printf STDERR
     "$prog_name: rounded value of $opt->{name} from %g to %g\n", $orig, $value;
  }
 }
 fetch_options ($device) if ($info & SANE_INFO_RELOAD_OPTIONS);
}


sub process_backend_option {
 my ($device, $optnum, $optarg) = @_;

 my $opt = $device->get_option_descriptor ($optnum);

 if ($opt and ($opt->{cap} & SANE_CAP_INACTIVE)) {
  print STDERR "$prog_name: attempted to set inactive option $opt->{name}\n";
  exit (1);
 }

 if (($opt->{cap} & SANE_CAP_AUTOMATIC) and $optarg and $optarg =~ /^auto$/i) {
  $device->set_auto($optnum);
  if ($Sane::STATUS != SANE_STATUS_GOOD) {
   printf STDERR "$prog_name: failed to set option --$opt->{name} to automatic ($Sane::STATUS)\n";
   exit (1);
  }
  return;
 }

 my $value;
 if ($opt->{type} == SANE_TYPE_BOOL) {
  $value = 1;                # no argument means option is set
  if ($optarg) {
   if ($optarg =~ /^yes$/i) {
    $value = 1;
   }
   elsif ($optarg =~ /^no$/i) {
    $value = 0;
   }
   else {
    printf STDERR "$prog_name: option --$opt->{name}: bad option value `$optarg'\n";
    exit (1);
   }
  }
 }
 elsif ($opt->{type} == SANE_TYPE_INT or $opt->{type} == SANE_TYPE_FIXED) {
  my @vector = parse_vector ($opt, $optarg);
  $value = \@vector;
 }
 elsif ($opt->{type} == SANE_TYPE_STRING) {
  $value = $optarg;
 }
 elsif ($opt->{type} == SANE_TYPE_BUTTON) {
  $value = 0;                # value doesn't matter
 }
 else {
  printf STDERR "$prog_name: duh, got unknown option type $opt->{type}\n";
  return;
 }
 set_option ($device, $optnum, $value);
}


sub write_pnm_header_to_file {
 my ($fh, $format, $width, $height, $depth) = @_;

# The netpbm-package does not define raw image data with maxval > 255.
# But writing maxval 65535 for 16bit data gives at least a chance
# to read the image.

 if ($format == SANE_FRAME_RED or $format == SANE_FRAME_GREEN or
                      $format == SANE_FRAME_BLUE or $format == SANE_FRAME_RGB) {
  printf $fh "P6\n# SANE data follows\n%d %d\n%d\n", $width, $height,
	      ($depth <= 8) ? 255 : 65535;
 }
 elsif ($format == SANE_FRAME_GRAY) {
  if ($depth == 1) {
   printf $fh "P4\n# SANE data follows\n%d %d\n", $width, $height;
  }
  else {
   printf $fh "P5\n# SANE data follows\n%d %d\n%d\n", $width, $height,
		($depth <= 8) ? 255 : 65535;
  }
 }
}


sub scan_it_raw {
 my ($fname, $raw, $script) = @_;

 my $first_frame = 1, my $offset = 0, my $must_buffer = 0;
 my $min = 0xff, my $max = 0;
 my (%image, $fp);

 my $parm;
 {do { # extra braces to get last to work.
  $device->start;
  if ($Sane::STATUS != SANE_STATUS_GOOD) {
   print STDERR "$prog_name: sane_start: $Sane::STATUS\n"
    if ($Sane::STATUS != SANE_STATUS_NO_DOCS);
   goto cleanup;
  }

  $parm = $device->get_parameters;
  if ($Sane::STATUS != SANE_STATUS_GOOD) {
   print STDERR "$prog_name: sane_get_parameters: $Sane::STATUS\n";
   goto cleanup;
  }

  open $fp, '>', $fname;
  if (!$fp) {
   print STDERR "Error opening output `$fname': $@\n";
   $Sane::_status = SANE_STATUS_IO_ERROR;
   goto cleanup;
  }

  if ($verbose) {
   if ($first_frame) {
    if (sane_isbasicframe($parm->{format})) {
     if ($parm->{lines} >= 0) {
      printf STDERR "$prog_name: scanning image of size %dx%d pixels at "
                ."%d bits/pixel\n",
                $parm->{pixels_per_line}, $parm->{lines},
                8 * $parm->{bytes_per_line} / $parm->{pixels_per_line};
     }
     else {
       printf STDERR "$prog_name: scanning image %d pixels wide and "
                ."variable height at %d bits/pixel\n",
                $parm->{pixels_per_line},
                8 * $parm->{bytes_per_line} / $parm->{pixels_per_line};
     }
    }
    else {
     printf STDERR "$prog_name: receiving %s frame "
			     ."bytes/line=%d, "
			     ."pixels/line=%d, "
			     ."lines=%d, "
			     ."depth=%d\n",
			     , sane_strframe($parm->{format}),
			     $parm->{bytes_per_line},
			     $parm->{pixels_per_line},
			     $parm->{lines},
			     $parm->{depth};
    }
   }

   printf STDERR "$prog_name: acquiring %s frame\n",
                                                 sane_strframe($parm->{format});
  }

  if ($first_frame) {
   if ($parm->{format} == SANE_FRAME_RED
       or $parm->{format} == SANE_FRAME_GREEN
       or $parm->{format} == SANE_FRAME_BLUE) {
    die unless ($parm->{depth} == 8);
    $must_buffer = 1;
    $offset = $parm->{format} - SANE_FRAME_RED;
   }
   elsif ($parm->{format} == SANE_FRAME_RGB) {
    die unless ($parm->{depth} == 8);
   }
   if ($parm->{format} == SANE_FRAME_RGB or $parm->{format} == SANE_FRAME_GRAY) {
    die unless (($parm->{depth} == 1) || ($parm->{depth} == 8));
    # if we're writing raw, we skip the header and never
    # have to buffer a single frame format.
    if ($raw == SANE_FALSE) {
     if ($parm->{lines} < 0) {
      $must_buffer = 1;
      $offset = 0;
     }
     else {
      write_pnm_header_to_file ($fp, $parm->{format}, 
                                $parm->{pixels_per_line},
                                $parm->{lines}, $parm->{depth});
     }
    }
   }
   elsif ($parm->{format} == $SANE_FRAME_TEXT
          or $parm->{format} == $SANE_FRAME_JPEG
          or $parm->{format} == $SANE_FRAME_G31D
          or $parm->{format} == $SANE_FRAME_G32D
          or $parm->{format} == $SANE_FRAME_G42D) {
    if (!$parm->{last_frame}) {
     $Sane::_status = SANE_STATUS_INVAL;
     printf STDERR "$prog_name: bad %s frame: must be last_frame\n",
              sane_strframe ($parm->{format});
     goto cleanup;
    }
   }

    # write them out without a header; don't buffer
   else {
    # Default action for unknown frametypes; write them out 
    # without a header; issue a warning in verbose mode.
    # Since we're not writing a header, there's no need to
    # buffer.
    printf STDERR "$prog_name: unknown frame format $parm->{format}\n"
     if ($verbose);
    if (!$parm->{last_frame}) {
     $Sane::_status = SANE_STATUS_INVAL;
     printf STDERR "$prog_name: bad %s frame: must be last_frame\n",
              sane_strframe ($parm->{format});
     goto cleanup;
    }
   }
  }
  else {
   die unless ($parm->{format} >= SANE_FRAME_RED
           && $parm->{format} <= SANE_FRAME_BLUE);
   $offset = $parm->{format} - SANE_FRAME_RED;
   $image{x} = $image{y} = 0;
  }

  while (1) {
   my ($buffer, $len) = $device->read ($buffer_size);
   if ($Sane::STATUS != SANE_STATUS_GOOD) {
    printf STDERR "$prog_name: min/max graylevel value = %d/%d\n", $min, $max
     if ($verbose && $parm->{depth} == 8);
    if ($Sane::STATUS != SANE_STATUS_EOF) {
     print STDERR "$prog_name: sane_read: $Sane::STATUS\n";
     return;
    }
    last;
   }

   if ($must_buffer) {
    # We're either scanning a multi-frame image or the
    # scanner doesn't know what the eventual image height
    # will be (common for hand-held scanners).  In either
    # case, we need to buffer all data before we can write
    # the image
    if ($parm->{format} == SANE_FRAME_RED
        or $parm->{format} == SANE_FRAME_GREEN
        or $parm->{format} == SANE_FRAME_BLUE) {
     for (my $i = 0; $i < $len; ++$i) {
      $image{data}[$offset + 3 * $i] = substr($buffer, $i, 1);
     }
     $offset += 3 * $len;
    }
    elsif ($parm->{format} == SANE_FRAME_RGB
           or $parm->{format} == SANE_FRAME_GRAY) {
     for (my $i = 0; $i < $len; ++$i) {
      $image{data}[$offset + $i] = substr($buffer, $i, 1);
     }
     $offset += $len;
    }
    else {
     # optional frametypes are never buffered
     printf STDERR "$prog_name: ERROR: trying to buffer %s frametype\n",
             sane_strframe($parm->{format});
    }
   }
   else {
    print $fp $buffer;
   }

   if ($verbose && $parm->{depth} == 8) {
    for (split(//, $buffer)) {
     my $c = ord;
     if ($c >= $max) {
      $max = $c;
     }
     elsif ($c < $min) {
      $min = $c;
     }
    }
   }

  }
  $first_frame = 0;
 }
 while (!$parm->{last_frame});}

 if ($must_buffer) {
  if ($parm->{lines} > 0) {
   $image{height} = $parm->{lines};
  }
  else {
   $image{height} = @{$image{data}}/$parm->{pixels_per_line};
   $image{height} /= 3 if ($parm->{format} == SANE_FRAME_RED
                         or $parm->{format} == SANE_FRAME_GREEN
                         or $parm->{format} == SANE_FRAME_BLUE);
  }
  if ($raw == SANE_FALSE) {
   # if we're writing raw, we skip the header
   write_pnm_header_to_file ($fp, $parm->{format}, $parm->{pixels_per_line},
                                                $image{height}, $parm->{depth});
  }
  for (@{$image{data}}) {print $fp $_;}
 }

 if ($fp) {
  close $fp;
  undef $fp;
 }

cleanup:
 close $fp if ($fp);
 return;
}


sub scan_docs {
 my ($start, $end, $no_overwrite, $raw, $outfmt, $script) = @_;

 $Sane::_status = SANE_STATUS_GOOD;
 my $scannedPages = 0;

 while ($end < 0 || $start <= $end) {
  #!!! buffer overflow; need protection
  my $fname = sprintf($outfmt, $start);

  # does the filename already exist?
  if ($no_overwrite and -r $fname) {
   $Sane::_status = SANE_STATUS_INVAL;
   print STDERR "Filename $fname already exists; will not overwrite\n";
  }
  
  # Scan the document
  scan_it_raw($fname, $raw, $script) if ($Sane::STATUS == SANE_STATUS_GOOD);

  # Any scan errors?
  if ($Sane::STATUS == SANE_STATUS_NO_DOCS) {
   # out of paper in the hopper; this is our normal exit
   $Sane::_status = SANE_STATUS_GOOD;
   last;
  }
  elsif ($Sane::STATUS == SANE_STATUS_EOF) {
   # done with this doc
   $Sane::_status = SANE_STATUS_GOOD;
   print STDERR "Scanned document $fname\n";
   $scannedPages++;
   $start++;
  }
  else {
   # unexpected error
   print STDERR "$Sane::STATUS\n";
   last;
  }
 }

 print STDERR "Scanned $scannedPages pages\n";

 return;
}

# There seems to be a bug in Getopt::Long 2.37 where l is treated as L whilst
# l is not in @args. Therefore the workaround is to rename l to m for the first
# scan and back to l for the second.
for (@ARGV) {
 $_ = '-m' if ($_ eq '-l');
 $_ = '-u' if ($_ eq '-t');
}
# make a first pass through the options with error printing and argument
# permutation disabled:
GetOptions (@args);

if (defined $options{L}) {
 my @device_list = Sane->get_devices;
 if ($Sane::STATUS != SANE_STATUS_GOOD) {
  print STDERR "$prog_name: sane_get_devices() failed: $Sane::STATUS\n";
  exit (1);
 }
 foreach (@device_list) {
  printf "device `%s' is a %s %s %s\n", $_->{name}, $_->{vendor},
                                         $_->{model}, $_->{type};
 }
 printf "\nNo scanners were identified. If you were expecting "
         ."something different,\ncheck that the scanner is plugged "
         ."in, turned on and detected by the\nsane-find-scanner tool "
         ."(if appropriate). Please read the documentation\nwhich came "
         ."with this software (README, FAQ, manpages).\n"
  if ($#device_list == -1);
 printf "default device is `%s'\n", $ENV{'SANE_DEFAULT_DEVICE'}
  if (defined($ENV{'SANE_DEFAULT_DEVICE'}));
 exit (0);
}

if (defined($options{V})) {
 printf "$prog_name (sane-backends) %s\n", Sane->get_version;
 exit (0);
}

if ($help) {
 print "Usage: $prog_name [OPTION]...\n
Start image acquisition on a scanner device and write image data to
output files.\n
   [ -d | --device-name <device> ]   use a given scanner device.
   [ -h | --help ]                   display this help message and exit.
   [ -L | --list-devices ]           show available scanner devices.
   [ -v | --verbose ]                give even more status messages.
   [ -V | --version ]                print version information.
   [ -N | --no-overwrite ]           don't overwrite existing files.\n
   [ -o | --output-file <name> ]     name of file to write image data
                                     (\%d replacement in output file name).
   [ -S | --scan-script <name> ]     name of script to run after every scan.
   [ --script-wait ]                 wait for scripts to finish before exit
   [ -s | --start-count <num> ]      page count of first scanned image.
   [ -e | --end-count <num> ]        last page number to scan.
   [ -r | --raw ]                    write raw image data to file.\n";
}

if (! $devname) {
# If no device name was specified explicitly,
# we open the first device we find (if any):
 my @device_list = Sane->get_devices;
 if ($Sane::STATUS != SANE_STATUS_GOOD) {
  print STDERR "$prog_name: sane_get_devices() failed: $Sane::STATUS\n";
  exit (1);
 }
 if ($#device_list == -1) {
  print STDERR "$prog_name: no SANE devices found\n";
  exit (1);
 }
 $devname = $device_list[0]{name};
}

$device = Sane::Device->open($devname);
if ($Sane::STATUS != SANE_STATUS_GOOD) {
 print STDERR "$prog_name: open of device $devname failed: $Sane::STATUS\n";
 if ($help) {
  undef $device;
 }
 else {
  exit (1);
 }
}

if (defined($device)) {
 fetch_options($device);
# re-enable error printing and arg permutation
 Getopt::Long::Configure('no_pass_through');
# There seems to be a bug in Getopt::Long 2.37 where l is treated as L whilst
# l is not in @args. Therefore the workaround is to rename l to m for the first
# scan and back to l for the second.
 for (@ARGV) {
  $_ = '-l' if ($_ eq '-m');
  $_ = '-t' if ($_ eq '-u');
 }
 my @ARGV_old = @ARGV;
 exit 1 if (! GetOptions (@args));
# As it isn't possible to get the argument order from Getopt::Long 2.37, do
# this myself
 for (@ARGV_old) {
  my $ch;
  if (/--(.*)/) {
   $ch = $1;
   my $i = index($ch, '=');
   $ch = substr($ch, 0, $i) if ($i > -1);
  }
  elsif (/-(.)/) {
   $ch = $1;
  }
  else {
   next;
  }
  if (defined $options{$ch}) {
   if ($ch eq 'x') {
    $window_val_user[0] = 1;
    ($window_val[0]) = parse_vector ($window_option[0], $options{x});
   }
   elsif ($ch eq 'y') {
    $window_val_user[1] = 1;
    ($window_val[1]) = parse_vector ($window_option[1], $options{y});
   }
   elsif ($ch eq 'l') { # tl-x
    process_backend_option ($device, $window[2], $options{l});
   }
   elsif ($ch eq 't') { # tl-y
    process_backend_option ($device, $window[3], $options{t});
   }
   else {
    process_backend_option ($device, $option_number{$ch}, $options{$ch});
   }
  }
 }

 for (my $index = 0; $index < 2; ++$index) {
  if ($window[$index] and defined($window_val[$index])) {
   my $val = $window_val[$index] - 1;
   if ($window[$index + 2]) {
    my $pos = $device->get_option ($window[$index + 2]);
    $val = $pos + $window_val[$index] if (defined $pos);
   }
   set_option ($device, $window[$index], $val);
  }
 }
 if ($help) {
  printf "\nOptions specific to device `%s':\n", $devname;

  for (my $i = 0; $i < $num_dev_options; ++$i) {
   my $short_name = '';

   my $opt = 0;
   for (my $j = 0; $j < 4; ++$j) {
    if ($i == $window[$j]) {
     $short_name = substr("xylt", $j, 1);
     $opt = $window_option[$j] if ($j < 2);
    }
   }
   $opt = $device->get_option_descriptor ($i) if (!$opt);

   printf "  %s:\n", $opt->{title} if ($opt->{type} == SANE_TYPE_GROUP);

   next if (! ($opt->{cap} & SANE_CAP_SOFT_SELECT));

   print_option ($device, $i, $short_name);
  }
  print "\n" if ($num_dev_options);
 }
}

if ($help) {
 printf "Type ``$prog_name --help -d DEVICE'' to get list of all options for DEVICE.\n\nList of available devices:";
 my @device_list = Sane->get_devices;
 if ($Sane::STATUS == SANE_STATUS_GOOD) {
  my $column = 80;

  foreach (@device_list) {
   if ($column + length ($_->{name}) + 1 >= 80) {
    printf "\n    ";
    $column = 4;
   }
   if ($column > 4) {
    print ' ';
    $column += 1;
   }
   print $_->{name};
   $column += length ($_->{name});
  }
 }
 print "\n";
 exit (0);
}

$SIG{HUP} = \&sighandler;
$SIG{INT} = \&sighandler;
$SIG{PIPE} = \&sighandler;
$SIG{TERM} = \&sighandler;

scan_docs ($startNum, $endNum, $no_overwrite, $raw, $outputFile, $scanScript);

exit $Sane::STATUS;

__END__

=head1 NAME

scanadf - acquire multiple images from a scanner equipped with an ADF

=head1 SYNOPSIS

B<scanadf>
B<[ -d | --device-name>
I<dev ]>
B<[ -h | --help ]>
B<[ -L | --list-devices ]>
B<[ -v | --verbose ]>
B<[ -V | --version ]>
B<[ -o | --output-file>
I<name ]>
B<[ -N | --no-overwrite ]>
B<[ -S | --scan-script>
I<name ]>
B<[ --script-wait ] >
B<[ -s | --start-count>
I<num ]>
B<[ -e | --end-count>
I<num ]>
B<[ -r | --raw ]>
I<[ device-specific-options ]>

=head1 DESCRIPTION

B<scanadf>
is a command-line interface to control image acquisition devices which
are capable of returning a series of images (e.g. a scanner with an
automatic document feeder (ADF)).  The device is controlled via
command-line options.  After command-line processing,
B<scanadf>
normally proceeds to acquire a series of images until the device returns
the
B<SANE_STATUS_NO_DOCS>
status code.  

The images are written to output files, specified by the
B<--output-file>
option.  These files are typically written in one of the PNM (portable aNyMaP) 
formats (PBM for black-and-white images, PGM for grayscale images, 
and PPM for color images).  Several optional frame formats (SANE_FRAME_JPEG, 
SANE_FRAME_G31D, SANE_FRAME_G32D, SANE_FRAME_G42D, and SANE_FRAME_TEXT)
are supported.  In each case, the data is written out to the output file
as-is without a header.  Unrecognized frame formats are handled in
the same way, although a warning message is printed in verbose mode.

Typically, the optional frame formats are used in conjunction with a scan 
script (specified by the 
B<--scanscript>
option) which is invoked for each acquired image.  The script is provided
with a series of environment variables which describe the parameters
and format of the image file.

B<scanadf>
accesses image acquisition devices through the SANE (Scanner Access
Now Easy) interface and can thus support any device for which there
exists a SANE backend (try "apropos sane\-" to get a list of available
backends).

=head1 OPTIONS

The
B<-d>
or
B<--device-name>
options must be followed by a SANE device-name.  A (partial) list of
available devices can be obtained with the
B<--list-devices>
option (see below).  If no device-name is specified explicitly,
B<scanadf>
will attempt to open the first available device.

The
B<-h>
or
B<--help>
options request help information.  The information is printed on
standard output and in this case, no attempt will be made to acquire
an image.

The
B<-L>
or
B<--list-devices>
option requests a (partial) list of devices that are available.  The
list is not complete since some devices may be available, but are not
listed in any of the configuration files (which are typically stored
in directory /usr/etc/sane.d).  This is particularly the case when
accessing scanners through the network.  If a device is not listed in
a configuration file, the only way to access it is by its full device
name.  You may need to consult your system administrator to find out
the names of such devices.

The
B<-v>
or
B<--verbose>
options increase the verbosity of the operation of
B<scanadf.>
The option may be specified repeatedly, each time increasing the verbosity
level.

The
B<-V>
or
B<--version>
option requests that
B<scanadf>
print the program and package name, as well as the version number of
the SANE distribution that it came with.

The
B<-o>
or
B<--output-file>
option specifies a format string used to generate the name of file to 
write the image data to.  You can use %d replacement in the output file
name; this will be replaced with the current page number.  The default
format string is image-%04d.

The
B<-N>
or
B<--no-overwrite>
option prevents
B<scanadf >
from overwriting existing image files. 

The
B<-S>
or
B<--scan-script>
option specifies the name of script to run after each scanned image
is acquired.  The script receives the name of the image output file
as its first and only command line argument.  Additionally the scan
script can reference the following environment variables to get 
information about the parameters of the image.

=over

=item B<SCAN_RES>

- the image resolution (in DPI)

=item B<SCAN_WIDTH>

- the image width (in pixels) 

=item B<SCAN_HEIGHT>

- the image height (in pixels)

=item B<SCAN_DEPTH>

- the image bit-depth (in bits)

=item B<SCAN_FORMAT>

- a string representing the image format (e.g. gray, g42d, text, etc)

=item B<SCAN_FORMAT_ID>

- the numeric image format identifier

=back

If the
B<--scipt-wait>
option is given, scanadf will wait until all scan-scripts have been finished before
exiting. That will be useful if scanadf is used in conjunction with tools to modify
the scanned images.

The
B<-s>
or
B<--start-count>
option specifies the page number of first scanned image.

The
B<-e>
or
B<--end-count>
option specifies the last page number to scan.  Using this option,
you can request a specific number of pages to be scanned, rather than
scanning until there are no more images available.

The
B<-r>
or
B<--raw>
option specifies that the raw image data be written to the output file
as-is without interpretation.  This disables the writing of the PNM
header for basic frame types.  This feature is usually used in 
conjunction with the
B<--scan-script>
option where the scan script uses the environment variables to
understand the format and parameters of the image and converts
the file to a more useful format.  NOTE: With support for the
optional frame types and the default handling of unrecognized
frametypes, this option becomes less and less useful.

As you might imagine, much of the power of
B<scanadf>
comes from the fact that it can control any SANE backend.  Thus, the
exact set of command-line options depends on the capabilities of the
selected device.  To see the options for a device named
I<dev ,>
invoke
B<scanadf>
via a command-line of the form:

=over

scanadf --help --device
I<dev>

=back

The documentation for the device-specific options printed by
B<--help>
is explained in the manual page for
B<scanimage.>

=head1 FILES

=over

=item I</usr/etc/sane.d>

This directory holds various configuration files.  For details, please
refer to the manual pages listed below.

=back

=head1 "SEE ALSO"

scanimage(1), xscanimage(1), sane(7)

=head1 AUTHOR

Transliterated from the C original by Jeffrey Ratcliffe.

=head1 BUGS

All the bugs of scanadf and much, much more.

This program relies on the backend to return the 
B<SANE_STATUS_NO_DOCS>
status code when the automatic document feeder is out of paper.  Use of
this program with backends that do not support ADFs (e.g. flatbed scanners) 
will likely result in repeated scans of the same document.  In this
case, it is essential to use the start-count and end-count to
control the number of images acquired.

Only a subset of the SANE backends support feeders and return
SANE_STATUS_NO_DOCS appropriately.  Backends which are known to
work at this time are:

=over

=item B<sane-bh>

- Bell+Howell Copiscan II series scanners.

=item B<sane-hp>

- Hewlett Packard scanners.  A patch to the sane-hp backend 
is necessary.  The --scantype=ADF option must be specified (earlier
versions of the backend used the --scan-from-adf option, instead).

=item B<sane-umax>

- UMAX scanners.  Support exists in build 12 and later.
The --source="Automatic Document Feeder" option must be specified.

=back
