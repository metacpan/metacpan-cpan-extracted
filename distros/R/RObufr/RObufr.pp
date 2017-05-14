BEGIN {
$VERSION = '0.03';
}

pp_addpm({At => Top}, <<'EOD');
=head1 NAME 

RObufr - Perl interface to BUFR files for ground-based GNSS and Radio Occultation data

=head1 SYNOPSIS

  use RObufr;

  my $b = RObufr->new(EDITION   => $edition,
                       TIME      => $startTime,
                       LAT       => $lat,
                       LON       => $lon,
                       MSGPREFIX => $msgprefix,
                       GTSHDR    => $gtshdr);
  my $bufr = $b->bufr($values);                     
  
=head1 DESCRIPTION

  A perl BUFR encoding and decoding library
  specially tailored to writing radio occultation and ground-based GNSS BUFR files at UCAR

=head1 AUTHOR

Doug Hunt, dhunt(at)ucar.edu.

=head1 SEE ALSO

perl(1), PDL(1)

=cut

use PDL;
use TimeClass;
use Config;
use vars qw($missing);

$missing = -9999999;  # missing value.  This is translated to all ones in the BUFR files.


#/**----------------------------------------------------------------------
# @sub       new
#
# Create a new BUFR file object.  Receive optional data for used in
# BUFR sections 1-3
# 
# @parameter  $type -- Class of object (normally RObufr unless subclassed)
# @           @opts -- Pairs of options, including:
# @                    TIME    => time_in_gps_seconds
# @                    EDITION => bufr_edition_number (3 or 4)
# @                    NAME    => BUFR data name from gpsseq2.dat file (eg 'GPSRO2')
# @                    BUFRLIB => directory to find BUFR code table files
# @                    MSGPREFIX => Boolean:  1 = Add message prefix like NESDIS DDS likes
# @                    GTSHDR  => Boolean:  1=include GTS header and trailer
# @return     $obj  -- An object of the RObufr class.
# @exception  Can be raised
# ----------------------------------------------------------------------*/
sub new {
  my $type = shift;
  
  my $bufrlib = $Config{'installsitearch'}.'/bufr'; # default install location of BUFR library files

  # set defaults, allow input options to override
  my $self = {EDITION    => 3,
              COMPRESSED => 0,
              NOBS       => 1,
              BUFRLIB    => $bufrlib,
              MSGPREFIX  => 0,
              @_};

  bless $self, $type;

  return $self;
}


#/**----------------------------------------------------------------------
# @sub       encode
#
# Encode a BUFR file and return the data in a perl scalar.
# 
# @parameter  $values -- Data values to decode
# @return     $bufr   -- String filled with BUFR data
# @exception  Can be raised
# ----------------------------------------------------------------------*/
sub encode {
  my $self   = shift;
  my $values = shift;

  # Compute number of observations from $values
  $self->{NOBS} = (ref($values->[0]) eq 'ARRAY') ? scalar(@{$values->[0]}) : 1;
  if ($self->{NOBS} > 1) { $self->{COMPRESSED} = 1 }
  
  my $bufrlib = $self->{BUFRLIB};
  my $seqfile = (-s "./gpsseq2.dat") ? "./gpsseq2.dat" : "$bufrlib/gpsseq2.dat";
  die "Cannot find sequence file gpsseq2.dat (looked in . and $bufrlib)" unless (-s $seqfile);

  # Read in code tables
  my $tabled = read_table_d("$bufrlib/TABLED");
  my $tableb = read_table_b("$bufrlib/TABLEB");

  # Read in BUFR descriptors from sequence file
  my $desc = readDesc ($self->{NAME}, $seqfile);

  # Expand descriptors.  $expanded_desc = [{NAME => '', UNITS => '', SCALE => S, REF => R, WIDTH => W}]
  # These expanded descriptors include 'leaf' or bottom level descriptors and modifying (2) descriptors.
  # All compound (3) descriptors have been expanded.
  my $expanded_desc = expand_desc($desc, $tabled, $tableb);

  #
  ## Create all BUFR sections
  #
  $self->{SECTION0} = 'BUFR' . pack ("C4", 0, 0, 0, $self->{EDITION}); # leave 3 bytes null for total length
  $self->{SECTION1} = $self->write_section1;
  $self->{SECTION3} = write_section3 ($desc->[0], $self->{COMPRESSED}, $self->{NOBS});
  $self->{SECTION4} = write_section4 ($expanded_desc, $values);
  $self->{SECTION5} = '7777';
  $self->{MESSAGE}  = $self->{SECTION0} . $self->{SECTION1} . $self->{SECTION3} . $self->{SECTION4} . $self->{SECTION5};
  my $len = length($self->{MESSAGE});
  
  $self->{GTSHDR}   = $self->{GTSHDR} ? GTS_hdr($self->{LAT}, $self->{LON}, $self->{TIME}, $len, $self->{MSGPREFIX}) : '';
  $self->{GTSTRLR}  = $self->{GTSHDR} ? GTS_trailer() : '';
  
  # Add 3 bytes of overall message length to header
  my $bufr_length = substr(pack("N", $len), 1, 3);  # bottom 3 bytes
  substr ($self->{MESSAGE},  4, 3, $bufr_length);
  substr ($self->{SECTION0}, 4, 3, $bufr_length); # Update BUFR section 0 length as well

  return $self;

}


#/**----------------------------------------------------------------------
# @sub       getvalues
#
# Fetch the $values array structure from a BUFR object.  This structure
# looks like this:  $values = [[values from first field], [values from second field],...]
#              or:  $values = [single value from first field, single value from second field, ...]
# 
# @parameter  $self -- BUFR file to read
# @return     $values -- The object so called to get or print values can be chained.
# @exception  Can be raised
# ----------------------------------------------------------------------*/
sub getvalues {
  my $self = shift;

  die "No values structure set" if (!defined($self->{VALUES}));
  
  return $self->{VALUES};
}


#/**----------------------------------------------------------------------
# @sub       getbufr
#
# Fetch the BUFR message from a BUFR object.
# 
# @parameter  $self -- BUFR file to read
# @return     $bufr -- The BUFR file contents
# @exception  Can be raised
# ----------------------------------------------------------------------*/
sub getbufr {
  my $self = shift;

  die "No message set" if (!defined($self->{MESSAGE}));

  return $self->{GTSHDR} . $self->{MESSAGE} . $self->{GTSTRLR};  
}


#/**----------------------------------------------------------------------
# @sub       read
#
# Read in a BUFR file, extracting the values and storing them within the object.
# 
# @parameter  $file -- BUFR file to read
# @return     $self -- The object so called to get or print values can be chained.
# @exception  Can be raised
# ----------------------------------------------------------------------*/
sub read {
  my $self = shift;
  my $file = shift;

  my $bufrlib = $self->{BUFRLIB};
  my $seqfile = (-s "./gpsseq2.dat") ? "./gpsseq2.dat" : "$bufrlib/gpsseq2.dat";
  die "Cannot find sequence file gpsseq2.dat (looked in . and $bufrlib)" unless (-s $seqfile);

  # Read in code tables
  my $tabled = read_table_d("$bufrlib/TABLED");
  my $tableb = read_table_b("$bufrlib/TABLEB");

  $self->{BUFRTEXT} = do { local( @ARGV, $/ ) = $file; <> } ; # slurp!

  #
  ## Pull out the separate BUFR sections and lengths
  #
  my $ptr = CORE::index($self->{BUFRTEXT}, 'BUFR'); # Find start of BUFR file
  die "Cannot find BUFR section 0" if ($ptr < 0);
  
  $self->{SECTION0} = substr($self->{BUFRTEXT}, $ptr, 8);
  $ptr += 8;
  $self->{BUFR_LEN} = unpack ("N", "\x0" . substr($self->{SECTION0}, 4, 3));

  my $sec1_len = unpack ("N", "\x0" . substr($self->{BUFRTEXT}, $ptr, 3));
  $self->{SECTION1} = substr($self->{BUFRTEXT}, $ptr, $sec1_len);
  $ptr += $sec1_len;

  # Assume there is no section 2.
  
  my $sec3_len = unpack ("N", "\x0" . substr($self->{BUFRTEXT}, $ptr, 3));
  $self->{SECTION3} = substr($self->{BUFRTEXT}, $ptr, $sec3_len);
  $ptr += $sec3_len;

  my $sec4_len = unpack ("N", "\x0" . substr($self->{BUFRTEXT}, $ptr, 3));
  $self->{SECTION4} = substr($self->{BUFRTEXT}, $ptr, $sec4_len);
  $ptr += $sec4_len;

  $self->{SECTION5} = substr($self->{BUFRTEXT}, $ptr, 4);
  if ($self->{SECTION5} ne '7777') { die "Did not find correct section 5 (7777) at $ptr" }

  #
  ## Read in necessary values from section 1
  #
  $self->{NOBS}       = unpack "n", substr($self->{SECTION3}, 4, 2);
  $self->{COMPRESSED} = unpack ('C', substr($self->{SECTION3}, 6, 1)) & 0x40; # check flags byte, 0x40 = 'compressed'
  $self->{TOP_DESC}   = unpack_desc(unpack "n", substr($self->{SECTION3}, 7, 2)); # top level descriptor
  if ($self->{NOBS} > 1 && !$self->{COMPRESSED}) { die "Cannot handle multiple uncompressed observations" }

  # Expand descriptors.  $expanded_desc = [{NAME => '', UNITS => '', SCALE => S, REF => R, WIDTH => W}]
  # These expanded descriptors include 'leaf' or bottom level descriptors and modifying (2) descriptors.
  # All compound (3) descriptors have been expanded.
  $self->{EXPANDED_DESC} = expand_desc([$self->{TOP_DESC}], $tabled, $tableb);

  # Unpack section4 into either a single 1D @$values perl array (for a single obs) or
  # a list of lists:  @$values = ([obs1, ...], [obs2, ...], ...)
  $self->{VALUES} = $self->unpack_values;

  return $self;
  
}

#/**----------------------------------------------------------------------
# @sub       print
#
# Print out a text version of the descriptors and values
#
# @parameter  $self   -- RObufr object
# @return     $string -- String containing printout      
# @exception  Can be raised
# ----------------------------------------------------------------------*/
sub print {

  my $self = shift;

  return $self->{PRINTOUT};
  
} 

#/**----------------------------------------------------------------------
# @sub       unpack_values
#
# Given an expanded descriptor structure and a binary section 4 vector,
# return either a single 1D @$values perl array (for a single obs) or
# a list of lists:  @$values = ([obs1, ...], [obs2, ...], ...);
#
# @parameter  $self          -- RObufr object
# @return     $values        -- A ref to a list or list of lists of values
# @exception  Can be raised
# ----------------------------------------------------------------------*/
sub unpack_values {

  my $self          = shift;

  my $expanded_desc = $self->{EXPANDED_DESC};
  
  my $section4      = unpack ('B*', $self->{SECTION4});  # convert to long string of 0 and 1 characters!
  my @desc = @$expanded_desc; # copy input
  my $len = substr ($section4, 0, 4*8, ''); # chop off the section 4 length.

  my @values   = ();  # place to store values extracted
  my $printout = '';  # place to store printout of file with descriptions and values

  my $nobs = $self->{NOBS};

  # Used for modifying data width and scale as specified in 'modifying descriptors' (starting with 2)
  my $dw = 0; # delta width
  my $ds = 0; # delta scale

  while (1) {
    my $d = shift @desc;
    last if (!defined($d)); # we have run out of values...

    my ($f, $x, $y) = unpack "a a2 a3", $d->{ID}; # Unpack descriptor:  F XX YYY
    if ($f == 0) { # 0 = data descriptor
      my ($w, $s, $r) = @$d{'WIDTH', 'SCALE', 'REF'}; # Get the descriptor width, scale and reference value
      my ($name, $units) = @$d{'NAME', 'UNITS'};
      $printout .= sprintf "%-72s (%12s): ", $name, $units;

      # Apply modifications found in preceeding '2' descriptors
      $w += $dw;
      $s += $ds;
      my $cw;

      if ($nobs == 1) { # Single non-compressed observation

        if ($d->{UNITS} eq 'CCITT IA5') { # read a string
          my $value = join '', map { chr(unpack('C', pack("B*", substr ($section4, 0, 8, '')))) } (1..$w/8);
          push (@values, $value);
          $printout .= "$value ";
        } else { # read a scalar
          # pull off correct number of bits, scale and add reference value.
          my $bits  = substr ($section4, 0, $w, '');
          my $pad  = ('0' x (32-length($bits))); # left zero padding to 32 bits
          
          # all ones -> missing value
          my $value = ($bits =~ /^1+$/) ? $missing : (unpack ("N", pack ("B*", $pad.$bits)) + $r)/10**$s;
          push (@values, $value);
        }
        
      } else { # multiple compressed values

        if ($d->{UNITS} eq 'CCITT IA5') { # read a set of strings
        
          my $zeroes = substr ($section4, 0, $w, '');             # NULL chars for string length, discarded
          my $nchars = unpack ('C', pack ("B*", '00'.substr ($section4, 0, 6, ''))); # 6 bits of char length (up to 64 chars)

          # unpack each character of each string into a list of strings
          push (@values, [map { join ('', pack("B*", substr ($section4, 0, $w, ''))) } (1..$nobs)]);
          
        } else { # Normal case, numerical data

          my $min = unpack ("N", pack ("B*", ('0'x(32-$w)).substr ($section4, 0, $w, '')));  # w bits of minimum value
          $cw  = unpack ("C", pack ("B*", '00'.substr ($section4, 0, 6, '')));   # 6 bits of compressed width

          if ($cw == 0) { # All values are identical, so no deltas are stored

            if ($min == 2**$w-1) { # all values are the error value
              push (@values, [($missing) x $nobs]);
            } else {               # all values are the same, non-error value stored in $min
              my $vals = (zeroes($nobs) + $min + $r)/10**$s;
              push (@values, [$vals->list]);
            }

          } else { # Normal compression with non-zero deltas
          
            # Create a PDL of the compressed values.
            my $pad  = ('0' x (32-$cw)); # left zero padding to 32 bits
            my $vals = pdl (map { unpack ("N", pack ("B*", $pad.substr ($section4, 0, $cw, ''))) } (1..$nobs));
            $vals = $vals->setbadif($vals == 2**$cw-1); # check for all ones -> missing value
            $vals = (($vals + $min + $r)/10**$s); # Add to minimum then add reference value and apply scale
            $vals->inplace->setbadtoval($missing); # replace bad values with missing values (-9999999)
            push (@values, [$vals->list]); # convert to perl list and add to output list

          } # normal compression
        } # chars or numbers
      } # multiple compressed values

      #
      ## Now print out the values.  This is simple for single scalars, but more complex
      ## for multiple values
      #
      if ($nobs == 1) {
        $printout .= "$values[-1]\n";
      } elsif ($nobs > 1) {
        if ($d->{UNITS} ne 'CCITT IA5' && $cw == 0) { # All values are identical numbers
          my $v = $values[-1][0];
          $v =~ s/\x0//g; # get rid of nulls
          $printout .= "$v\n";
        } else { # multiple values, including multiple strings
          my @v   = map { unpack ('A*', $_) } @{$values[-1]}; # get rid of trailing nulls
          if ($d->{UNITS} eq 'CCITT IA5') { # strings
            my $len = length($v[0]);
            my $n_per_line = int(80/$len);
            my $n_lines    = int($nobs/$n_per_line);
            $printout .= "\n";
            for (my $i=0;$i<$n_lines;$i++) {
              $printout .= join ' ', splice (@v, 0, $n_per_line), "\n";
            }
            $printout .= join ' ', @v, "\n";
          } else { # numbers
            my $len = 16;
            my $n_per_line = int(80/$len);
            my $n_lines    = int($nobs/$n_per_line);
            $printout .= "\n";
            for (my $i=0;$i<$n_lines;$i++) {
              $printout .= join (' ', map { sprintf "%16.8g", $_ } splice (@v, 0, $n_per_line)) . "\n";
            }
            $printout   .= join (' ', map { sprintf "%16.8g", $_ } @v) . "\n";
          }
        }
      }
      
    } elsif ($f == 1) { # 1 = replication descriptor
    
      #
      ## Now count up all the steps to replicate and add them to a list.
      ## The count of steps to replicate is the current $x value and it includes only data descriptors.
      ## This count includes the current replication descriptor step and the
      ## 'replication factor' descriptor which follows.
      ## The number of times to duplicate these steps is the current value ($v) read in later.
      #
      my $rc = 0; # replication count
      my @steps_to_replicate = ();
      my $rep_desc = shift @desc if ($y == 0); # save the 'replication factor' descriptor if this is a delayed replication
      while (1) {
        my $step = shift @desc;
        push (@steps_to_replicate, $step);
        $rc++ if ($step->{ID} !~ /^1/);  # do not count nested replication descriptors...
        last if ($rc >= $x);
      }

      # Figure out the replication count.  If $y != 0, then y is the rep. count
      # Otherwise, pull the value from the encoded data based on the data description
      # stored above in $rep_desc.
      my $rep_count;

      if ($y == 0) {
        my ($w, $s, $r) = @$rep_desc{'WIDTH', 'SCALE', 'REF'}; # Get the descriptor width, scale and reference value

        # pull off correct number of bits, scale and add reference value.
        my $bits  = substr ($section4, 0, $w); # pull the bits off, but do not shorten section4
        my $pad  = ('0' x (32-length($bits))); # left zero padding to 32 bits
          
        # all ones -> missing value
        $rep_count = (unpack ("N", pack ("B*", $pad.$bits)) + $r)/10**$s;
      } else {
        $rep_count = $y;
      }          

      for (1..$rep_count) {
        unshift (@desc, @steps_to_replicate);
      }
      # put the replication count descriptor at the top of the list    
      unshift (@desc, $rep_desc) if ($y == 0);
      
    } else {

      # a modifying descriptor (starts with 2)
      if      ($x == 1) {
        $dw = ($y == 0) ? 0 : $dw + $y-128; # change of width
      } elsif ($x == 2) {
        $ds = ($y == 0) ? 0 : $ds + $y-128; # change of scale
      } else {
        die "Can only (currently) modify width or scale.  X = $x not yet supported."
      }
    }
  }

  $self->{PRINTOUT} = $printout;
  
  return (\@values);

}


#/**----------------------------------------------------------------------
# @sub       unpack_desc
# 
# Convert a two-byte coded descriptor into FXXYYY format.
# 
# @parameter  $desc -- Two-byte coded descriptor
# @return     $fxxyyy -- Decoded descriptor
# @exception  Can be raised
# ----------------------------------------------------------------------*/
sub unpack_desc {

  my $desc = shift;

  my $f = int($desc/16384);
  my $x = int(($desc-$f*16384)/256);
  my $y = int($desc-$f*16384-$x*256);

  return sprintf "%01d%02d%03d", $f, $x, $y;

}   


#/**----------------------------------------------------------------------
# @sub       readDesc
# 
# Function that reads a set of BUFR descriptors from the gpsseq.dat file
# 
# @parameter  $name -- The name of the desciptor sequence in gpsseq2.dat
# @           $file -- The full path of gpsseq2.dat
# @return     $desc -- An integer PDL of descriptors
# @exception  Can be raised
# ----------------------------------------------------------------------*/
sub readDesc {

  my $name = shift;
  my $file = shift;

  # magical slurp of data from $file
  my $text = do { local( @ARGV, $/ ) = $file ; <> } ;

  my ($desc) = ($text =~ m|\[$name\]\s*\d+ ([\d{6}\s*]+)|s);
  my @desc = split " ", $desc;

  # descriptors are 6 digits of the form FXXYYY.
  # Encode as desc[i] = (F * 64 + XX) * 256 + YYY
  #$desc = ( floor($desc/100000) * 64 + (floor($desc/1000) % 100) ) * 256 + ($desc % 1000);

  return \@desc;

}

#/**----------------------------------------------------------------------
# @sub       read_table_d
#
# Function that reads in the BUFR Table D file from UK MET and returns
# a perl structure:
#
# $tabled->{301045}[301011,004004,004005,201138,202131,004006,201000,202000,304030,304031];
#
# @parameter  $infile -- The name of the table D file
# @return     $tabled -- Structure as above
# @exception  Can be raised
# ----------------------------------------------------------------------*/
sub read_table_d {

  my $infile = shift;

  my %tabled = ();

  open my $fh, '<', $infile or die "Cannot open $infile";

  while (<$fh>) {
    chomp;
    next if (substr($_,0,1) ne '3'); # skip commentary lines that do not start with a compound descriptor
    my ($name, $n, @desc) = split /[ \?]+/;
    while ($n > @desc) { # look for more descriptors on continuation lines
      $_ = <$fh>;
      chomp;
      push (@desc, split /[ \?]+/);
    }
    $tabled{$name} = [@desc];
    @desc = ();
  }

  close $fh;

  return \%tabled;
}


#/**----------------------------------------------------------------------
# @sub       read_table_b
#
# Function that reads in the BUFR Table B file (which gives information
# on 'leaf' (bottom level) descriptors) from UK MET and returns
# a perl structure:
#
# $tableb->{027021}{NAME}  = 'IN DIRECTION OF 0 DEGREES LONGITUDE, DISTANCE FROM EARTH'S CENTR'
#                  {UNITS} = 'M'
#                  {SCALE} =  2
#                  {REF}   = -1073741824
#                  {WIDTH} =  31
#
# @parameter  $infile -- The name of the table B file
# @return     $tableb -- Structure as above
# @exception  Can be raised
# ----------------------------------------------------------------------*/
sub read_table_b {

  my $infile = shift;

  my %tableb = ();

  open my $fh, '<', $infile or die "Cannot open $infile";

  while (<$fh>) {
    chomp;
    next if (substr($_,0,1) ne '0'); # skip commentary lines that do not start with a bottom level descriptor
    my ($id, $name) = unpack ("a6 x a64", $_);
    chomp($_ = <$fh>);
    my ($units, $scale, $ref, $width) = unpack ("x a26 a2 a11 a3", $_);
    $units =~ s/^\s*(.*?)\s*$/$1/;  # get rid of leading and trailing spaces ('trim')
    $tableb{$id} = {NAME => $name, UNITS => $units, SCALE => $scale, REF => $ref, WIDTH => $width};
  }
  close $fh;

  return \%tableb;
}


#/**----------------------------------------------------------------------
# @sub       expand_desc
#
# Expand a list of high-level descriptors.
# The expanded descriptors only include 'leaf' or bottom level descriptors.
# All compound (3) descriptors should be expanded and all modifying (2) descriptors
# should be applied.
# Output is a list of expanded descriptors, either starting with '0', for
# a data descriptor:
# $expanded_desc = {ID    => 001041,
#                   NAME  => 'ABSOLUTE PLATFORM VELOCITY - FIRST COMPONENT (SEE NOTE 6)',
#                   UNITS => 'M S-1',
#                   SCALE => 5,
#                   REF   => -1073741824,
#                   WIDTH => 31}
# or '1', for a replication descriptor:  { ID => 116000 }
#
# @parameter  $desc -- A ref to a list of high level descriptors
# @           $table_d -- A table D structure, read using 'read_table_d'
# @           $table_b -- A table B structure, read using 'read_table_b'
# @return     $expanded_desc -- See description above
# @exception  Can be raised
# ----------------------------------------------------------------------*/
sub expand_desc {

  my $desc    = shift;
  my $table_d = shift;
  my $table_b = shift;

  my @e1 = @$desc;
  my @e2 = ();

  # First expand all compound descriptors (starting with 3) into
  # component simpler descriptors from TABLE D.
  while (1) {
    foreach my $d (@e1) {
      push (@e2, exists ($table_d->{$d}) ? @{$table_d->{$d}} : $d);
    }
    last if (!grep /3\d\d\d\d\d/, @e2); # check if there are any compound descriptors (starting with 3) left
    @e1 = @e2;
    @e2 = ();
  }

  # Now write out all descriptor information

  my @expanded_desc = ();
  foreach my $d (@e2) {
    my ($f, $x, $y) = unpack "a a2 a3", $d;
    if ($f == 0) { # low level descriptor (starting with 0)
      push (@expanded_desc, {ID    => $d,
                             WIDTH => $table_b->{$d}{WIDTH},
                             SCALE => $table_b->{$d}{SCALE},
                             REF   => $table_b->{$d}{REF},
                             NAME  => $table_b->{$d}{NAME},
                             UNITS => $table_b->{$d}{UNITS}});
    } else { # replication descriptor (starting with 1), or modifying descriptor (starting with 2)
      push (@expanded_desc, {ID => $d});
    }
  }

  return \@expanded_desc;
}


#/**----------------------------------------------------------------------
# @sub       write_section1
#
# Return section 1 of the BUFR message:
#
# @parameter  $edition       -- The BUFR edition number (3 or 4)
# @           $start_time    -- The start time of the occultation in GPS seconds
# @return     $section1      -- A binary string
# @exception  Can be raised
# ----------------------------------------------------------------------*/
sub write_section1 {

  my $self       = shift;
  my $edition    = $self->{EDITION};
  my $start_time = $self->{TIME};
  my $bufr_name  = $self->{NAME}; # 'GPSRO2' or 'GBGPS' so far...
  my $generating_center = $self->{GENERATING_CENTER} // 60;  # default to NCAR, can be set to 175 (UCAR)
  
  my @date       = TimeClass->new->set_gps($start_time)->get_utc;
  my @section1;

  # Data category (table A)
  my %name_to_data_category = (GPSRO2 => 3, # Vertical soundings (satellite)
                               GBGPS  => 0, # Surface data - land
                              );
                              
  # International data sub-category
  my %name_to_data_sub_category = (GPSRO2 => 50, # Radio Occultation sounding
                                   GBGPS  => 14, # Ground-based GNSS water vapour obs (GPSWV)
                                  );

  my $data_category = $name_to_data_category{$bufr_name}
     // die "No international data category found for $bufr_name";
  my $data_sub_category = $name_to_data_sub_category{$bufr_name}
     // die "No international data sub-category found for $bufr_name";
     
  if ($edition == 3) {

    @section1 = (18,  # length (18 bytes)
                 0,   # BUFR master table, 0 = Meteorology
                 0,   # generating sub-center
                 $generating_center, # generating center, 60 = NCAR or 175 = UCAR (proposed)
                 0,   # update sequence number
                 0,   # section 2 flag (0 = not present)
                 $data_category,
                 14,  # data sub-category (14 = GNSS)
                 12,  # version of master table
                 0,   # version of local table (0 = local table not used)
                 substr($date[0], 2, 2), # 2 digit year
                 @date[1..4],            # month, day, hour, minute
                 0,   # pad to even number of bytes
               );

    return substr(pack ("N", $section1[0]), 1, 3) . pack ("C15", @section1[1..15]);

  } else { # edition 4

    @section1 = (22,  # length (22 bytes)
                 0,   # BUFR master table, 0 = Meteorology
                 $generating_center, # generating center, 60 = NCAR or 175 = UCAR (proposed)
                 0,   # generating sub-center
                 0,   # update sequence number
                 0,   # section 2 flag (0 = not present)
                 $data_category,
                 $data_sub_category,
                 14,  # data sub-category (14 = GNSS)
                 12,  # version of master table
                 0,   # version of local table (0 = local table not used)
                 @date, # year, month, day, hour, minute, second
               );

    return substr(pack ("N", $section1[0]), 1, 3) . pack ("C n n C7 n C5", @section1[1..16]);

  }
}


#/**----------------------------------------------------------------------
# @sub       write_section3
#
# Return section 3 of the BUFR message:
#
# @parameter
# @return     $section3      -- A binary string
# @exception  Can be raised
# ----------------------------------------------------------------------*/
sub write_section3 {

  my ($desc, $is_compressed, $n_obs) = @_;
  my ($f, $x, $y) = unpack "a a2 a3", $desc; # Unpack descriptor:  F XX YYY
  my $desc_val = $f * 16384 + $x * 256 + $y;
  my $bits = 0x80 | (0x40 * $is_compressed); # bit 1 (most sig.) = 'observed'.  bit 2 (next sig.) = 'compressed'

  my @section3 = (10,        # length (10 bytes)
                  0,         # reserved
                  $n_obs,    # number of data sets (observations)
                  $bits,     # data flag: 1 = observed, X = uncompressed (bit order of flags reversed)
                  $desc_val, # eg 51738 = RO data descriptor:  3 10 026 (3 x 16384 + 10 x 256 + 026)
                  0,         # pad byte
                );

  return substr(pack ("N", $section3[0]), 1, 3) . pack ("C n C n C", @section3[1..5]);
}


#/**----------------------------------------------------------------------
# @sub       write_section4
#
# Given an expanded descriptor structure and an array of values, write out
# the BUFR data section (section 4).  For data descriptors (starting with 0)
# we just convert the current value from @values using the scale, reference
# value and width specified and add it to the bit sequence.
#
# For replication descriptors (starting with 1) we read in the repeat count from
# the @values array and duplicate the data descriptors accordingly.
#
# @parameter  $expanded_desc -- A ref to a list of expanded descriptors
# @           $values        -- A ref to a list of values to encode:
# @                             $values->[0] = [all values of first field]
# @                             $values->[1] = [all values of second field], ...
# @return     $section4      -- A bit sequence encoded into a binary string
# @exception  Can be raised
# ----------------------------------------------------------------------*/
sub write_section4 {

  my $expanded_desc = shift;
  my $values        = shift;

  my $section4 = '0' x 32; # save space for length to be written at end

  my $pow2 = 2**sequence(32); # powers of 2, 0 to 31

  # Decode the @$values list from a list of lists of raw values (numbers and strings)
  # to a list of lists of scaled numbers and padded strings
  my ($coded_values, $widths, $desc) = decode_values($expanded_desc, $values);

  #
  ## Now $coded_values = [[list of first field coded values],[list of second field coded values],...]
  ## $widths = [list of field widths]
  ## $desc   = [final expanded descriptors, all replications dealt with]
  #

  my $n_samples = (ref($coded_values->[0]) eq 'ARRAY') ? scalar(@{$coded_values->[0]}) : 1;

  # No compression, just write out the values
  if ($n_samples == 1) {

    foreach my $v (@$coded_values) {
      my $w = shift (@$widths);
      my $d = shift (@$desc);   
      my $encoded_value = ($v == $missing) ? sprintf '1' x $w
                        : ($w eq 'STRING') ? join ('', map { sprintf "%08b", ord($_) } split ('', $v))
                        :                    sprintf "%0${w}b", $v;

      # Catch nan/inf  D. Hunt 2012/11/28
      if ($v =~ /(inf|nan)/i) {
        print "NaN or Inf found for $d->{ID} in $w bits, setting to missing\n";
        $encoded_value = sprintf '1' x $w;
      }

      my $len = length($encoded_value);
      if ($len != $w) { die "Bit width $w does not match encoded variable width for v=$v)" }
      $section4 .= $encoded_value;
      # print "Encoded value $v \($d->{ID}\) as $encoded_value in $w bits.  Bit = ", length($section4), "\n"; # debug
    }

  } else {

    # Loop over all measurement types, compressing each one by minimum/delta packing
    for (my $i=0;$i<@$widths;$i++) {
      my $vals = $$coded_values[$i];
      my $w    = $$widths[$i];  # bit width
      my $d    = $$desc[$i];    # descriptor structure
      if ($w =~ /STRING/) {

        (my $str_width) = ($w =~ /STRING:(\d+)/);

        # First encode zeroes in string width, then the normal 6 bit width increment with
        # the number of characters in the string.
        $section4 .= ("0" x $str_width);
        $section4 .= sprintf ("%06b", $str_width/8);

        # loop over each string in the i'th position for the j'th measurement
        # and pack the strings themselves, encoded as zeroes and ones.
        foreach my $v (@$vals) {
          $section4 .= join ('', map { sprintf "%08b", ord($_) } split ('', $v));
        }
        
      } else { # Numeric fields subject to normal compression

        # Create a PDL of all measurements of this type
        my $pdl = pdl($vals);
        $pdl->inplace->setvaltobad($missing);
        my $min = $pdl->min;   # minimum value, not including missing values

        if (($pdl == $missing)->all) { # All values are missing
          $section4 .= sprintf ('1' x $w) .
                       sprintf ("%06b", 0);
        } elsif (($pdl - $pdl->min == 0)->all) {   # All values are identical
          $section4 .= sprintf ("%0${w}b", $min) .
                       sprintf ("%06b", 0);      
        } else { # Normal compression

          my $del = $pdl - $min; # difference between each non-missing value and the minimum
          
          # Find the number of bits necessary to store the differences in.
          my $cw = ($pow2 <= $del->max + 1)->minimum_ind;
          if ($cw > $w) {
             print "Warning: compressed width of $cw greater than nominal width $w for ID = $d->{ID}\n";
          }     
          $del->inplace->setbadtoval(2**$cw - 1);  # make missing values all ones in binary
          $section4 .= sprintf ("%0${w}b", $min) .
                       sprintf ("%06b", $cw) .
                       join ('', map { sprintf "%0${cw}b", $_ } $del->list);
        }
        
      } # compression of numbers, not strings
    } # loop over coded_values
  } # coded_values != 1

  my $tot_bits = length($section4);
  my $l = ceil($tot_bits/8);  # section 4 length in bytes
  $l += 1 if ($l % 2 == 1);   # round up to nearest half-word.  Section 4 must contain an even number of bytes

  my $padlen = $l*8 - $tot_bits;
  my $pad    = '0' x $padlen->sclr;

  # Fill in the length of the message in the first 3 bytes of section 4.
  substr($section4, 0, 24, sprintf "%024b", $l);

  # print "Encoded $tot_val values in $tot_bits bits.  Length of section4 = ", length($section4), "\n";

  # Return the binary string, packed from the string of 0 and 1 characters
  return pack ('B*', $section4.$pad);
}


#/**----------------------------------------------------------------------
# @sub       decode_values
#
# Given a perl list of values, and a set of data descriptors,
# convert these values to integers or strings and return them in a perl vector
# list structure with values and bit widths.
# This routine is called once for all observations.  It returns a list of lists
# of coded values (the scale and reference values applied):
#
# $coded_values = [[list of first field coded values],[list of second field coded values],...]
#
# The calling routine is responsible for bit-packing and compression.
#
# @parameter  $expanded_desc -- A ref to a list of expanded descriptors
# @           $values        -- A ref to a list of values to encode
# @return     $coded_values  -- The $values array coded by scale and offset and returned as integers (as above)
# @           $widths        -- The bit widths for the @$coded_values array
# @           $desc          -- The descriptors encoded
# @           $printout      -- Text output
# @exception  Can be raised
# ----------------------------------------------------------------------*/
sub decode_values {

  my $expanded_desc = shift;
  my $values        = shift;

  my @desc = @$expanded_desc; # copy input
  my @vals = @$values;        # copy input

  my @coded_values  = ();
  my @widths        = ();
  my @outdesc       = ();    
  
  my $tot_val  = 0;

  # Used for modifying data width and scale as specified in 'modifying descriptors' (starting with 2)
  my $dw = 0; # delta width
  my $ds = 0; # delta scale

  while (1) {
    my $d = shift @desc;
    last if (!defined($d)); # we have run out of values...

    my ($f, $x, $y) = unpack "a a2 a3", $d->{ID}; # Unpack descriptor:  F XX YYY
    if ($f == 0) { # 0 = data descriptor
      my ($w, $s, $r) = @$d{'WIDTH', 'SCALE', 'REF'}; # Get the descriptor width, scale and reference value
      
      # Apply modifications found in preceeding '2' descriptors
      $w += $dw;
      $s += $ds;

      my $v = shift @vals;  # pull a value or list of values from the list

      if (ref($v) eq 'ARRAY') { # a list of values to code

        foreach my $sv (@$v) {
          my $scaled_value  = ($d->{UNITS} eq 'CCITT IA5') ? $sv . ("\x0" x ($w/8 - length($sv)))  # pad to full width
                            : ($sv == $missing)            ? $missing
                            :                                floor((float($sv)->sclr * 10**$s - $r) + 0.5)->sclr; # round to integer
          push (@{$coded_values[$tot_val]}, $scaled_value);
          $printout .= "$sv ";
        }
      
      } else { # a single scalar value
      
        my $scaled_value  = ($d->{UNITS} eq 'CCITT IA5') ? $v . ("\x0" x ($w/8 - length($v)))  # pad to full width 
                          : ($v == $missing)             ? $missing
                          :                                floor((float($v)->sclr * 10**$s - $r) + 0.5)->sclr; # round to integer
                          
        $coded_values[$tot_val] = $scaled_value;
        # print "Recorded value $v \($d->{ID}\) as $scaled_value in $w bits. scale = $s, ref = $r\n"; # debug

      }

      $widths[$tot_val]       = ($d->{UNITS} eq 'CCITT IA5') ? "STRING:$w" : $w;
      $outdesc[$tot_val]      = $d;
      $tot_val++;
      
    } elsif ($f == 1) { # 1 = replication descriptor
    
      #
      ## Now count up all the steps to replicate and add them to a list.
      ## The count of steps to replicate is the current $x value and it includes only data descriptors.
      ## This count includes the current replication descriptor step and the
      ## 'replication factor' descriptor which follows.
      ## The number of times to duplicate these steps is the current value ($v) read in later.
      #
      my $rc = 0; # replication count
      my @steps_to_replicate = ();
      my $rep_desc = shift @desc if ($y == 0); # save the 'replication factor' descriptor if deferred replication
      while (1) {
        my $step = shift @desc;
        push (@steps_to_replicate, $step);
        $rc++ if ($step->{ID} !~ /^1/);  # do not count nested replication descriptors...
        last if ($rc >= $x);
      }

      #
      ## Get the repeat count from either:  $y (fixed repetition)
      ##                                    $vals[0] (delayed repetition, one single observation)
      ##                                    $vals[0][0] (delayed repetition, multiple observations)
      #
      my $rep_count;
      if ($y != 0) {
        $rep_count = $y;
      } elsif (ref($vals[0]) eq 'ARRAY') {
        $rep_count = $vals[0][0];
      } else {
        $rep_count = $vals[0];
      }
      
      # print "  Replication desc: $d->{ID}:  replicate $x values $rep_count times\n";
      for (1..$rep_count) {
        unshift (@desc, @steps_to_replicate);
      }
      # put the replication count descriptor at the top of the list    
      unshift (@desc, $rep_desc) if ($y == 0);
      
    } else {
    
      # a modifying descriptor (starts with 2)
      if      ($x == 1) {
        $dw = ($y == 0) ? 0 : $dw + $y-128; # change of width
      } elsif ($x == 2) {
        $ds = ($y == 0) ? 0 : $ds + $y-128; # change of scale
      } else {
        die "Can only (currently) modify width or scale.  X = $x not yet supported."
      }
    }
  }

  return (\@coded_values, \@widths, \@outdesc, $printout);

}


#/**----------------------------------------------------------------------
# @sub       GTS_hdr
#
# Function that returns a GTS header string based on the input occultation
# starting lat/lon and time.  The header is as follows (from the RO BUFR
# definition):
#
# The WMO 'Abbreviated Routing Header' allows GTS/RMDCN nodes
# to route messages (e.g. data in SYNOP, BUFR or GRIB code forms) in a
# table-driven way to defined destinations without knowing the
# message's data contents. Header and trailer sequences form a
# 'wrapper' around the message(s).
#
# The header is a set of characters from the International Alphabet
# No. 5 (CCITT-IA5 - equivalent to ASCII) and takes the form:
#
#        <SOH><CR><CR><LF>nnn<CR><CR><LF>T1T2A1A2ii<SP>cccc<SP>YYGGgg<CR><CR><LF>
#
# This is followed by the BUFR message ('BUFR' ... '7777') and finally the
# end-of-message trailer sequence:
#
#        <CR><CR><LF><ETX>
#
# The A2 element is a letter code identifying the regional location of
# the data (by hemisphere and quadrant) in the bulletin. For RO data,
# the appropriate letter is generated from the nominal latitude and
# longitude of the occultation event in the BUFR message. This can be
# used by routing nodes to filter bulletins by broad region without
# having to decode the BUFR.
#
# For most routing nodes, the date/time indicated by YYGGgg must be
# current or the data may be blocked or rejected. 'Current' is typically
# defined as not more than 24 hours old and not in the future by more
# than 10 minutes. For RO data, YYYGGgg will be that of the start of the
# occultation event.
#
# @parameter  $lat  -- Latitude of occ point.
# @           $lon  -- Longitude of occ point.
# @           $time -- Time of occ point in GPS seconds.
# @           $msglen -- length of message in bytes
# @           $msgprefix -- boolean:  1 = 'add message prefix like NESDIS DDS wants'
# @return     Binary GTS header stream.
# @exception  Can be raised
# ----------------------------------------------------------------------*/
sub GTS_hdr {

  my $lat  = shift;
  my $lon  = shift;
  my $time = shift;
  my $msglen = shift;
  my $msgprefix = shift;

  # special characters
  my ($soh, $cr, $lf, $sp) = map { pack 'C', $_ } (0x01, 0x0d, 0x0a, 0x20);

  my $header;

  if ($msgprefix) {
    $header = sprintf "####%03d%06d####$lf", 18, $msglen+24; # BUFR size plus header
  }
  else {
    $header = "$soh$cr$cr$lf";  # start of message
    $header .= '---';           # Place-holder for sequence number (000-999)
                                # The real sequence number is added as the files
                                # are FTPed to NESDIS (cronFtp.pl)
  }
  $header .= "$cr$cr$lf";

  $header .= "IUT";             # T1 = 'I' = Observations in binary code
                                # T2 = 'U' = Upper air
                                # A1 = 'T' = Satellite-derived sonde

  # Area code A-L (A2) for Longitude segments 0-90W, 90W-180, 180-90E, 90E-0
  # and for Latitude bands 90N-30N, 30N-30S, 30S-90S
  $lon += 360 if ($lon < 0);  # convert $lon from -180 to 180 deg. to 0-360 deg.
  my $lat_idx = 4 - int($lon / 90);
  $lat_idx = $lat_idx > 4 ? 4
           : $lat_idx < 1 ? 1
           : $lat_idx; # bound to 1-4

  if    ($lat < -30) {
    $lat_idx += 8;
  }
  elsif ($lat < 30 ) {
    $lat_idx += 4;
  }
  $header .= chr (64 + $lat_idx);  # A2 ('A' to 'L' according to lat/lon)

  $header .= '14';                 # ii (product type, 14 = radio occultation)
  $header .= "${sp}KWBC$sp";       # 'KWBC'  Washington USA


# YYGGgg Date/time of observation where:
# YY = Day of month (01-31),
#   GG = hour (00-23),
#     gg = minute (00-59).
  my ($yr, $mon, $day, $hr, $min) = TimeClass->new->set_gps($time)->get_ymdhms_gps;
  $header .= sprintf ("%02d%02d%02d", $day, $hr, $min);

  $header .= "$cr$cr$lf";

  return $header;

}

#/**----------------------------------------------------------------------
# @sub       GTS_trailer
#
# Function that returns a GTS trailer string.
# @parameter  none         
# @return     GPS trailer string
# @exception  Can be raised
# ----------------------------------------------------------------------*/
sub GTS_trailer {

  # GTS trailer   
  #         <ETX> 'End of Transmission' character:
  #               byte value = 3 decimal (03 hex)
  #          <CR> 'Carriage Return' character:
  #               byte value = 13 decimal (0D hex),
  #          <LF> 'Line Feed' character:
  #               byte value = 10 decimal (0A hex)
  return pack ('C4', 0x0d, 0x0d, 0x0a, 0x03);
}



EOD

pp_done();










