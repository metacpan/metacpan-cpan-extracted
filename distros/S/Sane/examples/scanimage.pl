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
    @window, $num_dev_options, $device, $format, $devname, %option_number);
my $verbose = 0;
my $help = 0;
my $test = 0;
my $batch = 0;
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
my $progress = 0;
my $batch_double = 0;
my $batch_prompt = 0;
my $dont_scan = 0;
my $prog_name = basename($0);
my @args = (\%options, 'd|device-name=s' => \$devname,
                       'L|list-devices',
                       'f|formatted-device-list=s',
                       'b|batch:s' => \$format,
                       'batch-start=i' => \$batch_start_at,
                       'batch-count=i' => \$batch_count,
                       'batch-increment=i' => \$batch_increment,
                       'batch-double' => \$batch_double,
                       'batch-prompt' => \$batch_prompt,
                       'p|progress' => \$progress,
                       'n|dont-scan' => \$dont_scan,
                       'T|test' => \$test,
                       'h|help' => \$help,
                       'v|verbose+' => \$verbose,
                       'B|buffer-size' => \$buffer_size,
                       'V|version');


sub sighandler {
 my $signum = shift;

 my $first_time = SANE_TRUE;

 if ($device) {
  print STDERR "$prog_name: received signal $signum\n";
  if ($first_time) {
   $first_time = SANE_FALSE;
   print STDERR "$prog_name: trying to stop scanner\n";
   $device->cancel;
  }
  else {
   print STDERR "$prog_name: aborting\n";
   _exit (0);
  }
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


sub write_pnm_header {
 my ($format, $width, $height, $depth) = @_;

# The netpbm-package does not define raw image data with maxval > 255.
# But writing maxval 65535 for 16bit data gives at least a chance
# to read the image.

 if ($format == SANE_FRAME_RED or $format == SANE_FRAME_GREEN or
                      $format == SANE_FRAME_BLUE or $format == SANE_FRAME_RGB) {
  printf "P6\n# SANE data follows\n%d %d\n%d\n", $width, $height,
	      ($depth <= 8) ? 255 : 65535;
 }
 else {
  if ($depth == 1) {
   printf "P4\n# SANE data follows\n%d %d\n", $width, $height;
  }
  else {
   printf "P5\n# SANE data follows\n%d %d\n%d\n", $width, $height,
		($depth <= 8) ? 255 : 65535;
  }
 }
}


sub scan_it {
 my $first_frame = 1;
 my $offset = 0;
 my $must_buffer = 0;
 my $min = 0xff;
 my $max = 0;
 my %image;
 my @format_name = (
   "gray", "RGB", "red", "green", "blue"
 );
 my $total_bytes = 0;
 my $hang_over = -1;

 my $parm;
 {do { # extra braces to get last to work.
  if (!$first_frame) {
   $device->start;
   if ($Sane::STATUS != SANE_STATUS_GOOD) {
    printf STDERR "$prog_name: sane_start: $Sane::STATUS\n";
    goto cleanup;
   }
  }

  $parm = $device->get_parameters;
  if ($Sane::STATUS != SANE_STATUS_GOOD) {
   printf STDERR "$prog_name: sane_get_parameters: $Sane::STATUS\n";
   goto cleanup;
  }

  if ($verbose) {
   if ($first_frame) {
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

   printf STDERR "$prog_name: acquiring %s frame\n",
    $parm->{format} <= SANE_FRAME_BLUE ? $format_name[$parm->{format}]:"Unknown";
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
    die unless (($parm->{depth} == 8) || ($parm->{depth} == 16));
   }
   if ($parm->{format} == SANE_FRAME_RGB or $parm->{format} == SANE_FRAME_GRAY) {
    die unless (($parm->{depth} == 1) || ($parm->{depth} == 8)
            || ($parm->{depth} == 16));
    if ($parm->{lines} < 0) {
     $must_buffer = 1;
     $offset = 0;
    }
    else {
#     if ($output_format == OUTPUT_TIFF) {
#       sanei_write_tiff_header ($parm->{format},
#                                $parm->{pixels_per_line}, $parm->{lines},
#                                $parm->{depth}, $resolution_value,
#                                icc_profile);
#     else {
       write_pnm_header ($parm->{format}, $parm->{pixels_per_line},
                         $parm->{lines}, $parm->{depth});
#      }
    }
   }
  }
  else {
   die unless ($parm->{format} >= SANE_FRAME_RED
           && $parm->{format} <= SANE_FRAME_BLUE);
   $offset = $parm->{format} - SANE_FRAME_RED;
   $image{x} = $image{y} = 0;
  }
  my $hundred_percent = $parm->{bytes_per_line} * $parm->{lines}
    * (($parm->{format} == SANE_FRAME_RGB || $parm->{format} == SANE_FRAME_GRAY) ? 1:3);

  while (1) {
   my ($buffer, $len) = $device->read ($buffer_size);
   $total_bytes += $len;
   my $progr = (($total_bytes * 100.) / $hundred_percent);
   $progr = 100. if ($progr > 100.);
   printf STDERR "Progress: %3.1f%%\r", $progr if ($progress);

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
   }
   else { # ! must_buffer
#    if (($output_format == OUTPUT_TIFF) || ($parm->{depth} != 16)) {
#     print $buffer;
#    }
#    else {
##if !defined(WORDS_BIGENDIAN)
#     my $start = 0;
#
#     # check if we have saved one byte from the last sane_read
#     if ($hang_over > -1) {
#      if ($len > 0) {
#       print $buffer;
#       $buffer = $hang_over.$buffer;
#       $hang_over = -1;
#       $start = 1;
#      }
#     }
#     # now do the byte-swapping
#     $buffer = reverse $buffer;
#
#     # check if we have an odd number of bytes
#     if ((($len - $start) % 2) != 0) {
#      $hang_over = substr($buffer, $len - 1, 1);
#      $len--;
#     }
##endif
     print $buffer;
#    }
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
#  if ($output_format == OUTPUT_TIFF) {
#   sanei_write_tiff_header ($parm->{format}, $parm->{pixels_per_line},
#                             $parm->{lines}, $parm->{depth}, $resolution_value,
#                             icc_profile);
#  }
#  else {
   write_pnm_header ($parm->{format}, $parm->{pixels_per_line}, $image{height}, $parm->{depth});
#  }
#  if (($output_format == OUTPUT_TIFF) || ($image{Bpp} == 1)
#      || ($image{Bpp} == 3)) {
#   print $image{data};
#  }
#  else { # $image{Bpp} == 2 or $image{Bpp} == 6 assumed
##if !defined(WORDS_BIGENDIAN)
#   for (my $i = 0; $i < $image{Bpp} * $image{height} * $image{width}; $i += 2) {
#    my $LSB = $image{data}[$i];
#    $image{data}[$i] = $image{data}[$i + 1];
#    $image{data}[$i + 1] = $LSB;
#   }
##endif
   for (@{$image{data}}) {print;}
#  }
 }

 # flush the output buffer
 STDOUT->flush;

cleanup:
 my $expected_bytes = $parm->{bytes_per_line} * $parm->{lines} *
   (($parm->{format} == SANE_FRAME_RGB
     || $parm->{format} == SANE_FRAME_GRAY) ? 1 : 3);
 $expected_bytes = 0 if ($parm->{lines} < 0);
 if ($total_bytes > $expected_bytes && $expected_bytes != 0) {
  printf STDERR
              "%s: WARNING: read more data than announced by backend "
              ."(%u/%u)\n", $prog_name, $total_bytes, $expected_bytes;
 }
 elsif ($verbose) {
  printf STDERR "%s: read %u bytes in total\n", $prog_name, $total_bytes;
 }
 return;
}


sub pass_fail {
 my ($max, $len, $buffer) = @_;

 if ($Sane::STATUS != SANE_STATUS_GOOD) {
  print STDERR "FAIL Error: $Sane::STATUS\n";
 }
 elsif ($len < length($buffer)) {
  printf STDERR "FAIL Cheat: %d bytes\n", length($buffer);
 }
 elsif ($len > $max) {
  printf STDERR "FAIL Overflow: %d bytes\n", $len;
 }
 elsif ($len == 0) {
  print STDERR "FAIL No data\n";
 }
 else {
  print STDERR "PASS\n";
 }
}


sub test_it {
 my %image;
 my @format_name = (
   "gray", "RGB", "red", "green", "blue"
 );

 $device->start;
 if ($Sane::STATUS != SANE_STATUS_GOOD) {
  print STDERR "$prog_name: sane_start: $Sane::STATUS\n";
  goto cleanup;
 }

 my $parm = $device->get_parameters;
 if ($Sane::STATUS != SANE_STATUS_GOOD) {
  print STDERR "$prog_name: sane_get_parameters: $Sane::STATUS\n";
  goto cleanup;
 }

 if ($parm->{lines} >= 0) {
  printf STDERR "$prog_name: scanning image of size %dx%d pixels at "
            ."%d bits/pixel\n", $parm->{pixels_per_line}, $parm->{lines},
            8 * $parm->{bytes_per_line} / $parm->{pixels_per_line};
 }
 else {
  printf STDERR "$prog_name: scanning image %d pixels wide and "
            ."variable height at %d bits/pixel\n",$parm->{pixels_per_line},
            8 * $parm->{bytes_per_line} / $parm->{pixels_per_line};
 }
 printf STDERR "$prog_name: acquiring %s frame, %d bits/sample\n",
          $parm->{format} <= SANE_FRAME_BLUE ? $format_name[$parm->{format}]:"Unknown",
          $parm->{depth};

 printf STDERR "$prog_name: reading one scanline, %d bytes...\t",
          $parm->{bytes_per_line};
 ($image{data}, my $len) = $device->read ($parm->{bytes_per_line});
 pass_fail ($parm->{bytes_per_line}, $len, $image{data});
 goto cleanup if ($Sane::STATUS != SANE_STATUS_GOOD);

 print STDERR "$prog_name: reading one byte...\t\t";
 ($image{data}, $len) = $device->read (1);
 pass_fail (1, $len, $image{data});
 goto cleanup if ($Sane::STATUS != SANE_STATUS_GOOD);

 my $i;
 for ($i = 2; $i < $parm->{bytes_per_line} * 2; $i *= 2) {
  printf STDERR "$prog_name: stepped read, %d bytes... \t", $i;
  ($image{data}, $len) = $device->read ($i);
  pass_fail ($i, $len, $image{data});
  goto cleanup if ($Sane::STATUS != SANE_STATUS_GOOD);
 }

 for ($i /= 2; $i > 2; $i /= 2) {
  printf STDERR "$prog_name: stepped read, %d bytes... \t", $i - 1;
  ($image{data}, $len) = $device->read ($i - 1);
  pass_fail ($i - 1, $len, $image{data});
  goto cleanup if ($Sane::STATUS != SANE_STATUS_GOOD);
 }

cleanup:
 $device->cancel;
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

if (defined($options{L}) or defined($options{f})) {
 my @device_list = Sane->get_devices;
 if ($Sane::STATUS != SANE_STATUS_GOOD) {
  print STDERR "$prog_name: sane_get_devices() failed: $Sane::STATUS\n";
  exit (1);
 }
 if (defined($options{L})) {
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
 }
 else {
  for (my $i = 0; $i < @device_list; $i++) {
   my $format = $options{f};
   $format =~ s/%d/$device_list[$i]->{name}/g;
   $format =~ s/%v/$device_list[$i]->{vendor}/g;
   $format =~ s/%m/$device_list[$i]->{model}/g;
   $format =~ s/%t/$device_list[$i]->{type}/g;
   $format =~ s/%i/$i/g;
   print $format;
  }
 }
 printf "default device is `%s'\n", $ENV{'SANE_DEFAULT_DEVICE'}
  if (defined($ENV{'SANE_DEFAULT_DEVICE'}));
 exit (0);
}

if (defined($options{V})) {
 printf "%s %s; backend version %d.%d.%d\n", $prog_name,
	  $Sane::VERSION, Sane->get_version;
 exit (0);
}

if ($help) {
 printf "Usage: %s [OPTION]...

Start image acquisition on a scanner device and write PNM image data to
standard output.

Parameters are separated by a blank from single-character options (e.g.
-d epson) and by a \"=\" from multi-character options (e.g. --device-name=epson).
-d, --device-name=DEVICE   use a given scanner device (e.g. hp:/dev/scanner)
    --format=pnm|tiff      file format of output file
-i, --icc-profile=PROFILE  include this ICC profile into TIFF file", $prog_name;
 printf "
-L, --list-devices         show available scanner devices
-f, --formatted-device-list=FORMAT similar to -L, but the FORMAT of the output
                           can be specified: %%d (device name), %%v (vendor),
                           %%m (model), %%t (type), and %%i (index number)
-b, --batch[=FORMAT]       working in batch mode, FORMAT is `out%%d.pnm' or
                           `out%%d.tif' by default depending on --format";
 printf "
    --batch-start=#        page number to start naming files with
    --batch-count=#        how many pages to scan in batch mode
    --batch-increment=#    increase number in filename by an amount of #
    --batch-double         increment page number by two for 2sided originals
                           being scanned in a single sided scanner
    --batch-prompt         ask for pressing a key before scanning a page
    --accept-md5-only      only accept authorization requests using md5";
 printf "
-p, --progress             print progress messages
-n, --dont-scan            only set options, don't actually scan
-T, --test                 test backend thoroughly
-h, --help                 display this help message and exit
-v, --verbose              give even more status messages
-B, --buffer-size          change default input buffersize
-V, --version              print version information\n";
}

if (! $devname) {
# If no device name was specified explicitly, we look at the
# environment variable SANE_DEFAULT_DEVICE.  If this variable
# is not set, we open the first device we find (if any):
 if (defined($ENV{'SANE_DEFAULT_DEVICE'})) {
  $devname = $ENV{'SANE_DEFAULT_DEVICE'};
 }
 else {
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
}

$device = Sane::Device->open($devname);
if ($Sane::STATUS != SANE_STATUS_GOOD) {
 print STDERR "$prog_name: open of device $devname failed: $Sane::STATUS\n";
 print STDERR "\nYou seem to have specified a UNIX device name, "
            ."or filename instead of selecting\nthe SANE scanner or "
            ."image acquisition device you want to use. As an example,\n"
            ."you might want \"epson:/dev/sg0\" or "
            ."\"hp:/dev/usbscanner0\". If any supported\ndevices are "
            ."installed in your system, you should be able to see a "
            ."list with\n\"$prog_name --list-devices\".\n"
  if ($devname =~ /^\//);
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

exit (0) if ($dont_scan);

$SIG{HUP} = \&sighandler;
$SIG{INT} = \&sighandler;
$SIG{PIPE} = \&sighandler;
$SIG{TERM} = \&sighandler;

$batch_increment = 2 if ($batch_double);
$batch = 1 if ($batch_count);

if ($test == 0) {
 my $n = $batch_start_at;
 $batch = 1 if (defined $format);

 if ($batch && (! defined($format) || $format eq '')) {
#  if ($output_format == OUTPUT_TIFF) {
#   $format = "out%d.tif";
#  }
#  else {
   $format = "out%d.pnm";
#  }
 }

 printf STDERR
            "Scanning %d pages, incrementing by %d, numbering from %d\n",
            $batch_count, $batch_increment, $batch_start_at if ($batch);

 {do { # extra braces to get last to work.
  my ($path, $fh);
  $path = sprintf $format, $n if ($batch);    # format is NULL unless batch mode

  if ($batch) {
   if ($batch_prompt) {
    printf STDERR "Place document no. %d on the scanner.\n", $n;
    printf STDERR "Press <RETURN> to continue.\n";
    printf STDERR "Press Ctrl + D to terminate.\n";

    if (! defined(<STDIN>)) {
     printf STDERR "Batch terminated, %d pages scanned\n",
              ($n - $batch_increment);
     last;    # get out of this loop
    }
   }
   printf STDERR "Scanning page %d\n", $n;
  }

  $device->start;
  if ($Sane::STATUS != SANE_STATUS_GOOD) {
   print STDERR "$prog_name: sane_start: $Sane::STATUS\n";
   last;
  }

  if ($batch && ! (open($fh, '>', $path) && STDOUT->fdopen($fh, '>'))) {
   print STDERR "cannot open $path\n";
   $device->cancel;
   exit SANE_STATUS_ACCESS_DENIED;
  }

  scan_it();
  if ($batch) {
   printf STDERR "Scanned page %d.", $n;
   printf STDERR " (scanner status = %d)\n", $Sane::STATUS;
  }

  if ($Sane::STATUS == SANE_STATUS_GOOD) {}
  elsif ($Sane::STATUS == SANE_STATUS_EOF) {
   $Sane::_status = SANE_STATUS_GOOD;
  }
  else {
   if ($batch) {
    close ($fh);
    unlink ($path);
   }
   last;
  }
  $n += $batch_increment;
 }
 while (($batch
         && ($batch_count == -1 || --$batch_count))
         && SANE_STATUS_GOOD == $Sane::STATUS);}

 $device->cancel;
}
else {
 $Sane::_status = test_it ();
}

exit $Sane::STATUS;

__END__

=head1 NAME

scanimage \- scan an image

=head1 SYNOPSIS

B<scanimage>
B<[ -d | --device-name>
I<dev ]>
B<[ --format>
I<format ]>
B<[ -i | --icc-profile>
I<profile ]>
B<[ -L | --list-devices ]>
B<[ -f | --formatted-device-list >
I<format ]>
B<[ --batch >
I<[= format ]]>
B<[ --batch-start>
I<start ]>
B<[ --batch-count>
I<count ]>
B<[ --batch-increment>
I<increment ]>
B<[ --batch-double ]>
B<[ --accept-md5-only ]>
B<[ -p | --progress ]>
B<[ -n | --dont-scan ]>
B<[ -T | --test ]>
B<[ -h | --help ]>
B<[ -v | --verbose ]>
B<[ -B | --buffersize ]>
B<[ -V | --version ]>
I<[ device-specific-options ]>

=head1 DESCRIPTION

B<scanimage>
is a command-line interface to control image acquisition devices such
as flatbed scanners or cameras.  The device is controlled via
command-line options.  After command-line processing,
B<scanimage>
normally proceeds to acquire an image.  The image data is written to
standard output in one of the PNM (portable aNyMaP) formats (PBM for
black-and-white images, PGM for grayscale images, and PPM for color
images) or in TIFF (black-and-white, grayscale or color).
B<scanimage>
accesses image acquisition devices through the
B<SANE>
(Scanner Access Now Easy) interface and can thus support any device for which
there exists a
B<SANE>
backend (try
B<apropos>
I<sane->
to get a list of available backends).

=head1 EXAMPLES

To get a list of devices:

  scanimage -L

To scan with default settings to the file image.pnm:

  scanimage >image.pnm

To scan 100x100 mm to the file image.tiff (-x and -y may not be available with
all devices):

  scanimage -x 100 -y 100 --format=tiff >image.tiff

To print all available options:

  scanimage -h

=head1 OPTIONS

Parameters are separated by a blank from single-character options (e.g.
-d epson) and by a "=" from multi-character options (e.g. --device-name=epson).

The
B<-d>
or
B<--device-name>
options must be followed by a
B<SANE>
device-name like 
I<` epson:/dev/sg0 '>
or 
I<` hp:/dev/usbscanner0 '.>
A (partial) list of available devices can be obtained with the
B<--list-devices>
option (see below).  If no device-name is specified explicitly,
B<scanimage>
reads a device-name from the environment variable
B<SANE_DEFAULT_DEVICE .>
If this variable is not set, 
B<scanimage>
will attempt to open the first available device.

The
B<--format >
I<format>
option selects how image data is written to standard output.
I<format>
can be
B<pnm>
or
B<tiff.>
If
B<--format>
is not used, PNM is written.

The
B<-i>
or
B<--icc-profile>
option is used to include an ICC profile into a TIFF file.

The
B<-L>
or
B<--list-devices>
option requests a (partial) list of devices that are available.  The
list is not complete since some devices may be available, but are not
listed in any of the configuration files (which are typically stored
in directory 
I</caehome/ra28145/etc/sane.d ).>
This is particularly the case when accessing scanners through the network.  If
a device is not listed in a configuration file, the only way to access it is
by its full device name.  You may need to consult your system administrator to
find out the names of such devices.

The
B<-f>
or
B<--formatted-device-list>
option works similar to
B<--list-devices ,>
but requires a format string.
B<scanimage>
replaces the placeholders
B<%d %v %m %t %i>
with the device name, vendor name, model name, scanner type and an index
number respectively. The command

=over

=item B<scanimage -f>
I<\*(lq scanner number %i device %d is a %t, model %m, produced by %v \*(rq>

=back

will produce something like:

=over

=item scanner number 0  device sharp:/dev/sg1 is  a  flatbed scanner, model JX250
SCSI, produced by SHARP

=back

The
B<--batch*>
options provide the features for scanning documents using document
feeders.  
B<--batch>
I<[ format ]>
is used to specify the format of the filename that each page will be written
to.  Each page is written out to a single file.  If
I<format>
is not specified, the default of out%d.pnm (or out%d.tif for --format tiff)
will be used.  
I<format>
is given as a printf style string with one integer parameter.
B<--batch-start>
I<start>
selects the page number to start naming files with. If this option is not
given, the counter will start at 0.
B<--batch-count>
I<count>
specifies the number of pages to attempt to scan.  If not given, 
scanimage will continue scanning until the scanner returns a state
other than OK.  Not all scanners with document feeders signal when the
ADF is empty, use this command to work around them.
With 
B<--batch-increment>
I<increment>
you can change the amount that the number in the filename is incremented
by.  Generally this is used when you are scanning double-sided documents
on a single-sided document feeder.  A specific command is provided to
aid this:
B<--batch-double>
will automatically set the increment to 2.
B<--batch-prompt>
will ask for pressing RETURN before scanning a page. This can be used for
scanning multiple pages without an automatic document feeder.

The
B<--accept-md5-only>
option only accepts user authorization requests that support MD5 security. The
B<SANE>
network daemon
B<( saned )>
is capable of doing such requests. See
B<saned (8).>

The
B<-p>
or
B<--progress>
option requests that
B<scanimage>
prints a progress counter. It shows how much image data of the current image has
already been received by
B<scanimage >
(in percent).

The
B<-n>
or
B<--dont-scan>
option requests that
B<scanimage>
only sets the options provided by the user but doesn't actually perform a
scan. This option can be used to e.g. turn off the scanner's lamp (if
supported by the backend).

The
B<-T>
or
B<--test>
option requests that
B<scanimage>
performs a few simple sanity tests to make sure the backend works as
defined by the
B<SANE>
API (in particular the
B<sane_read>
function is exercised by this test).

The
B<-h>
or
B<--help>
options request help information.  The information is printed on
standard output and in this case, no attempt will be made to acquire
an image.

The
B<-v>
or
B<--verbose>
options increase the verbosity of the operation of
B<scanimage.>
The option may be specified repeatedly, each time increasing the verbosity
level.

The
B<-B>
or
B<--buffersize>
option changes the input buffersize that
B<scanimage>
uses from default 32*1024 to 1024*1024 kbytes.

The
B<-V>
or
B<--version>
option requests that
B<scanimage>
prints the program and package name, the version number of
the
B<SANE>
distribution that it came with and the version of the backend that it
loads. Usually that's the dll backend. If more information about the version
numbers of the backends are necessary, the
B<DEBUG>
variable for the dll backend can be used. Example: SANE_DEBUG_DLL=3 scanimage
-L.

As you might imagine, much of the power of
B<scanimage>
comes from the fact that it can control any
B<SANE>
backend.  Thus, the exact set of command-line options depends on the
capabilities of the selected device.  To see the options for a device named
I<dev ,>
invoke
B<scanimage>
via a command-line of the form:

=over

=item B<scanimage --help --device-name>
I<dev>

=back

The documentation for the device-specific options printed by
B<--help>
is best explained with a few examples:

 -l 0..218mm [0]
    Top-left x position of scan area.

=over

=item The description above shows that option
B<-l>
expects an option value in the range from 0 to 218 mm.  The
value in square brackets indicates that the current option value is 0
mm. Most backends provide similar geometry options for top-left y position (-t),
width (-x) and height of scan-area (-y).

=back

 --brightness -100..100% [0]
    Controls the brightness of the acquired image.

=over

=item The description above shows that option
B<--brightness>
expects an option value in the range from -100 to 100 percent.  The
value in square brackets indicates that the current option value is 0
percent.

=back

 --default-enhancements
    Set default values for enhancement controls.

=over

=item The description above shows that option
B<--default-enhancements>
has no option value.  It should be thought of as having an immediate
effect at the point of the command-line at which it appears.  For
example, since this option resets the
B<--brightness>
option, the option-pair
B<--brightness 50 --default-enhancements>
would effectively be a no-op.

=back

 --mode Lineart|Gray|Color [Gray]
    Selects the scan mode (e.g., lineart or color).

=over

=item The description above shows that option
B<--mode>
accepts an argument that must be one of the strings
B<Lineart ,>
B<Gray ,>
or
B<Color .>
The value in the square bracket indicates that the option is currently
set to
B<Gray .>
For convenience, it is legal to abbreviate the string values as long as
they remain unique.  Also, the case of the spelling doesn't matter.  For
example, option setting
B<--mode col>
is identical to
B<"--mode Color" .>

=back

 --custom-gamma[=(yes|no)] [inactive]
    Determines whether a builtin or a custom gamma-table
    should be used.

=over

=item The description above shows that option
B<--custom-gamma>
expects either no option value, a "yes" string, or a "no" string.
Specifying the option with no value is equivalent to specifying "yes".
The value in square-brackets indicates that the option is not
currently active.  That is, attempting to set the option would result
in an error message.  The set of available options typically depends
on the settings of other options.  For example, the
B<--custom-gamma>
table might be active only when a grayscale or color scan-mode has
been requested.

=back

Note that the
B<--help>
option is processed only after all other options have been processed.
This makes it possible to see the option settings for a particular
mode by specifying the appropriate mode-options along
with the
B<--help>
option.  For example, the command-line:

B< scanimage --help --mode>
I<color>

would print the option settings that are in effect when the color-mode
is selected.

=back

 --gamma-table 0..255,...
    Gamma-correction table.  In color mode this option
    equally affects the red, green, and blue channels
    simultaneously (i.e., it is an intensity gamma table).

=over

=item The description above shows that option
B<--gamma-table>
expects zero or more values in the range 0 to 255.  For example, a
legal value for this option would be "3,4,5,6,7,8,9,10,11,12".  Since
it's cumbersome to specify long vectors in this form, the same can be
expressed by the abbreviated form "[0]3-[9]12".  What this means is
that the first vector element is set to 3, the 9-th element is set to
12 and the values in between are interpolated linearly.  Of course, it
is possible to specify multiple such linear segments.  For example,
"[0]3-[2]3-[6]7,[7]10-[9]6" is equivalent to "3,3,3,4,5,6,7,10,8,6".
The program
B<gamma4scanimage>
can be used to generate such gamma tables (see 
B<gamma4scanimage (1)>
for details).

=back

 --filename <string> [/tmp/input.ppm]
    The filename of the image to be loaded.

=over

=item The description above is an example of an option that takes an
arbitrary string value (which happens to be a filename).  Again,
the value in brackets show that the option is current set to the
filename 
B</tmp/input.ppm .>

=back

=head1 ENVIRONMENT

=over

=item B<SANE_DEFAULT_DEVICE>

The default device-name.

=back

=head1 FILES

=over

=item I</caehome/ra28145/etc/sane.d>

This directory holds various configuration files.  For details, please
refer to the manual pages listed below.

=item I<~/.sane/pass>

This file contains lines of the form

=item user:password:resource

scanimage uses this information to answer user authorization requests
automatically. The file must have 0600 permissions or stricter. You should
use this file in conjunction with the --accept-md5-only option to avoid
server-side attacks. The resource may contain any character but is limited
to 127 characters.

=back

=head1 "SEE ALSO"

B<sane (7),>
B<gamma4scanimage (1),>
B<xscanimage (1),>
B<xcam(1) ,>
B<xsane(1) ,>
B<scanadf (1),>
B<sane-dll (5),>
B<sane-net (5),>
B<sane-"backendname" (5)>

=head1 AUTHOR

Transliterated from the C original by Jeffrey Ratcliffe.

=head1 BUGS

All the bugs of scanimage and much, much more.
