package Parse::Lnk;

# Based on the contents of the document:
# http://www.i2s-lab.com/Papers/The_Windows_Shortcut_File_Format.pdf

use 5.006;
use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.10';

=pod

=encoding latin1

=head1 NAME

Parse::Lnk - A cross-platform, depencency free, Windows shortcut (.lnk) meta data parser.

=head1 VERSION

Version 0.10

=cut

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parse_lnk resolve_lnk);

our $map = { # Tag names made up based on the docs
  flag => {
    0 => {
      0 => 'NO SHELLIDLIST',
      1 => 'HAS SHELLIDLIST',
    },
    1 => {
      0 => 'NOT POINT TO FILE/DIR',
      1 => 'POINTS TO FILE/DIR',
    },
    2 => {
      0 => 'NO DESCRIPTION',
      1 => 'HAS DESCRIPTION',
    },
    3 => {
      0 => 'NO RELATIVE PATH STRING',
      1 => 'HAS RELATIVE PATH STRING',
    },
    4 => {
      0 => 'NO WORKING DIRECTORY',
      1 => 'HAS WORKING DIRECTORY',
    },
    5 => {
      0 => 'NO CMD LINE ARGS',
      1 => 'HAS CMD LINE ARGS',
    },
    6 => {
      0 => 'NO CUSTOM ICON',
      1 => 'HAS CUSTOM ICON',
    },
  },
  file => {
    0 => 'READ ONLY TARGET',
    1 => 'HIDDEN TARGET',
    2 => 'SYSTEM FILE TARGET',
    3 => 'VOLUME LABEL TARGET (not possible)',
    4 => 'DIRECTORY TARGET',
    5 => 'ARCHIVE',
    6 => 'NTFS EFS',
    7 => 'NORMAL TARGET',
    8 => 'TEMP. TARGET',
    9 => 'SPARSE TARGET',
    10 => 'REPARSE POINT DATA TARGET',
    11 => 'COMPRESSED TARGET',
    12 => 'TARGET OFFLINE',
  },
  show_wnd => {
    0 => 'SW_HIDE',
    1 => 'SW_NORMAL',
    2 => 'SW_SHOWMINIMIZED',
    3 => 'SW_SHOWMAXIMIZED',
    4 => 'SW_SHOWNOACTIVE',
    5 => 'SW_SHOW',
    6 => 'SW_MINIMIZE',
    7 => 'SW_SHOWMINNOACTIVE',
    8 => 'SW_SHOWNA',
    9 => 'SW_RESTORE',
    10 => 'SW_SHOWDEFAULT',
  },
  vol_type => {
    0 => 'Unknown',
    1 => 'No root directory',
    2 => 'Removable (Floppy, Zip, USB, etc.)',
    3 => 'Fixed (Hard Disk)',
    4 => 'Remote (Network Drive)',
    5 => 'CD-ROM',
    6 => 'RAM Drive',
  },
};

sub resolve_lnk {
  my $filename = shift;
  my $l = __PACKAGE__->new (
    filename => $filename,
    resolve  => 1,
  );
  $l->_parse;
  $l->{base_path};
}

sub parse_lnk {
  my $filename = shift;
  my $l = __PACKAGE__->new (
    filename => $filename,
  );
  $l->_parse;
  return if $l->{error};
  $l;
}

sub new {
  my $class = shift;
  if (@_ and @_ % 2) {
    croak "This method expects (name => value) arguments. Odd number of arguments received";
  }
  my $self = {
    @_,
  };
  bless $self, $class;
}

sub from {
  my $self = shift;
  my $filename = shift;
  $self = $self->new (
    filename => $filename,
  ) unless ref $self;
  $self->_parse;
  return if $self->{error};
  $self;
}

sub parse {
  my $self = shift;
  my $filename = shift;
  $self = $self->new (
    filename => $filename,
  ) unless ref $self;
  $self->_parse;
  return if $self->{error};
  $self;
}

sub _reset {
  my $self = shift;
  return unless ref $self;
  for my $k (keys %$self) {
    delete $self->{$k};
  }
  $self;
}

sub _parse {
  my $self = shift;
  my $filename = $self->{filename};
  my $resolve = $self->{resolve};
  $self->_reset;
  if (not defined $filename) {
    $self->{error} = 'A filename is required';
    return;
  }
  if (not -f $filename) {
    $self->{error} = "Not a file";
    return;
  }
  if (open my $in, '<', $filename) {
    binmode $in;
    $self->{_fh} = $in;
  } else {
    # We set error before croak, in case this call is being eval'ed
    $self->{error} = "Can't open file '$filename' for reading";
    croak $self->{error};
  }
  
  my $header = $self->_read_unpack(0, 1);
  if ($header ne '4c') {
    $self->{error} = 'Invalid Lnk file header';
    close $self->{_fh};
    delete $self->{_fh};
    return;
  }
  
  $self->{guid} = $self->_read_unpack(4, 16);
  
  my $flags = $self->_read_unpack_bin(20, 1);
  my $flag_cnt = 0;
  my @flag_bits = (0, 0, 0, 0, 0, 0, 0, 0);
  while ($flag_cnt < 7) {
    my $flag_bit = substr $flags, $flag_cnt, 1;
    push @{$self->{flags}}, $map->{flag}->{$flag_cnt}->{$flag_bit};
    if ($flag_bit eq '1') {
      if ($flag_cnt >= 0 and $flag_cnt <= 6) {
        $flag_bits[$flag_cnt] = 1;
      }
    }
    $flag_cnt++;
  }
  
  # File Attributes 4bytes@18h = 24d
  # Only a non-zero if "Flag bit 1" above is set to 1
  #
  if ($flag_bits[1] == 1) {
    my $file_attrib = $self->_read_unpack_bin(24, 2);
    my $file_att_cnt = 0;
    while ($file_att_cnt < 13) {
      my $file_bit = substr $file_attrib, $file_att_cnt, 1;
      push @{$self->{attributes}}, $map->{file}->{$file_att_cnt} if $file_bit;
      $file_att_cnt++;
    }
  }

  # Create time 8bytes @ 1ch = 28
  my $ctime = $self->_read_unpack(28, 8);
  $ctime = Parse::Windows::Shortcut::Bigint::bighex($self->_reverse_hex($ctime));
  $ctime = $self->_MStime_to_unix($ctime);
  $self->{create_time} = $ctime;
  
  # Access time 8 bytes@ 0x24 = 36D
  my $atime = $self->_read_unpack(36, 8);
  $atime = Parse::Windows::Shortcut::Bigint::bighex($self->_reverse_hex($atime));
  $atime = $self->_MStime_to_unix($atime);
  $self->{last_accessed_time} = $atime;

  # Mod Time8b @ 0x2C = 44D
  my $mtime = $self->_read_unpack(44, 8);
  $mtime = Parse::Windows::Shortcut::Bigint::bighex($self->_reverse_hex($mtime));
  $mtime = $self->_MStime_to_unix($mtime);
  $self->{modified_time} = $mtime;

  # Target File length starts @ 34h = 52d
  my $f_len = $self->_read_unpack(52, 4);
  $f_len = hex $self->_reverse_hex($f_len);
  $self->{target_length} = $f_len;
  
  # Icon File info starts @ 38h = 56d
  my $ico_num = $self->_read_unpack(56, 4);
  $ico_num = hex $ico_num;
  $self->{icon_index} = $ico_num;
  
  # ShowWnd val to pass to target
  # Starts @3Ch = 60d 
  my $show_wnd = $self->_read_unpack(60, 1);
  $show_wnd = hex $show_wnd;
  $self->{show_wnd} = $show_wnd;
  $self->{show_wnd_flag} = $map->{show_wnd}->{$show_wnd};
  
  # Hot key
  # Starts @40h = 64d 
  my $hot_key = $self->_read_unpack(64, 4);
  $hot_key = hex $hot_key;
  $self->{hot_key} = $hot_key;
  
  # ItemID List
  # Read size of item ID list
  my $i_len = $self->_read_unpack(76, 2);
  $i_len = hex $self->_reverse_hex($i_len);
  # skip to end of list
  my $end_of_list = (78 + $i_len);

  # FileInfo structure
  #
  my $struc_start = $end_of_list;
  my $first_off_off = ($struc_start + 4);
  my $vol_flags_off = ($struc_start + 8);
  my $local_vol_off = ($struc_start + 12);
  my $base_path_off = ($struc_start + 16);
  my $net_vol_off = ($struc_start + 20);
  my $rem_path_off = ($struc_start + 24);

  # Structure length
  my $struc_len = $self->_read_unpack($struc_start, 4);
  $struc_len = hex $self->_reverse_hex($struc_len);
  my $struc_end = $struc_start + $struc_len;

  # First offset after struct - Should be 1C under normal circumstances
  my $first_off = $self->_read_unpack($first_off_off, 1);

  # File location flags
  my $vol_flags = $self->_read_unpack_bin($vol_flags_off, 1);
  $vol_flags = substr $vol_flags, 0, 2;
  my @vol_bits = (0, 0);
  if ($vol_flags =~ /10/) {
    $self->{target_type} = 'local';
    $vol_bits[0] = 1;
    $vol_bits[1] = 0;
  }
  # Haven't found this case yet...
  if ($vol_flags =~ /01/) {
    $self->{target_type} = 'network';
    $vol_bits[0] = 0;
    $vol_bits[1] = 1;
  }
  # But this one I did:
  if ($vol_flags =~ /11/) {
    $self->{target_type} = 'network';
    $vol_bits[0] = 1;
    $vol_bits[1] = 1;
  }
  
  # Local volume table
  # Random garbage if bit0 is clear in volume flags
  if ($vol_bits[0] == 1 and $vol_bits[1] == 0) {
    # This is the offset of the local volume table within the 
    #File Info Location Structure
    my $loc_vol_tab_off = $self->_read_unpack($local_vol_off, 4); 
    $loc_vol_tab_off = hex $self->_reverse_hex($loc_vol_tab_off);

    # This is the asolute start location of the local volume table
    my $loc_vol_tab_start = $loc_vol_tab_off + $struc_start;

    # This is the length of the local volume table
    my $local_vol_len = $self->_read_unpack(($loc_vol_tab_off + $struc_start), 4);
    $local_vol_len = hex $self->_reverse_hex($local_vol_len);

    # We now have enough info to
    # Calculate the end of the local volume table.
    my $local_vol_tab_end = $loc_vol_tab_start + $local_vol_len;

    # This is the volume type
    my $curr_tab_offset = $loc_vol_tab_off + $struc_start + 4;
    my $vol_type = $self->_read_unpack($curr_tab_offset, 4);
    $vol_type = hex $self->_reverse_hex($vol_type);
    $self->{volume_type} = $map->{vol_type}->{$vol_type};

    # Volume Serial Number
    $curr_tab_offset = $loc_vol_tab_off + $struc_start + 8;
    my $vol_serial = $self->_read_unpack($curr_tab_offset, 4);
    $vol_serial = $self->_reverse_hex($vol_serial);
    $self->{volume_serial} = $vol_serial;

    # Get the location, and length of the volume label 
    # we should really read the vol_label_loc from offset Ch 
    my $vol_label_loc = $loc_vol_tab_off + $struc_start + 16;
    my $vol_label_len = $local_vol_tab_end - $vol_label_loc;
    my $vol_label = $self->_read_unpack_ascii($vol_label_loc, $vol_label_len);
    $self->{volume_label} = $vol_label;

    # This is the offset of the base path info within the
    # File Info structure
    # Random Garbage when bit0 is clear in volume flags
    my $base_path_off = $self->_read_unpack($base_path_off, 4);
    $base_path_off = hex $self->_reverse_hex($base_path_off);
    $base_path_off = $struc_start + $base_path_off;

    # Read base path data upto NULL term 
    my $bp_data = $self->_read_null_term($base_path_off);
    $self->{base_path} = $bp_data;
    if ($resolve) {
      close $self->{_fh};
      delete $self->{_fh};
      return $self;
    }
  }

  # Network Volume Table
  if ($vol_bits[0] == 0 and $vol_bits[1] == 1) {
    $net_vol_off = hex $self->_reverse_hex($self->_read_unpack($net_vol_off, 4));
    $net_vol_off = $struc_start + $net_vol_off;
    my $net_vol_len = $self->_read_unpack($net_vol_off, 4);
    $net_vol_len = hex $self->_reverse_hex($net_vol_len);

    # Network Share Name
    my $net_share_name_off = $net_vol_off + 8;
    my $net_share_name_loc = hex $self->_reverse_hex($self->_read_unpack($net_share_name_off, 4));
    if ($net_share_name_loc ne "20") {
      close delete $self->{_fh};
      $self->{error} = 'Error: NSN ofset should always be 14h';
      close $self->{_fh};
      delete $self->{_fh};
      return $self;
    }
    $net_share_name_loc = $net_vol_off + $net_share_name_loc;
    my $net_share_name = $self->_read_null_term($net_share_name_loc);
    $self->{base_path} = $net_share_name;
    if ($resolve) {
      close $self->{_fh};
      delete $self->{_fh};
      return $self;
    }

    # Mapped Network Drive Info
    my $net_share_mdrive = $net_vol_off + 12;
    $net_share_mdrive = $self->_read_unpack($net_share_mdrive, 4);
    $net_share_mdrive = hex $self->_reverse_hex($net_share_mdrive);
    if ($net_share_mdrive ne "0") {
      $net_share_mdrive = $net_vol_off + $net_share_mdrive;
      $net_share_mdrive = $self->_read_null_term($net_share_mdrive);
      $self->{mapped_drive} = $net_share_mdrive;
    }
  }

  if ($vol_bits[0] == 1 and $vol_bits[1] == 1) {
    # Finding the location, as I'm not sure this is always 104
    for my $i (1..10000) {
      my $n = 4 * $i;
      my $l = $self->_read_unpack($n, 4);
      $l = hex $self->_reverse_hex($l);
      my $net_share_name_off = $n + 8;
      my $net_share_name_loc = hex $self->_reverse_hex($self->_read_unpack($net_share_name_off, 4));
      if ($net_share_name_loc ne "20") {
        next;
      }
      $net_vol_off = $n;
      last;
    }
    
    my $net_vol_len = $self->_read_unpack($net_vol_off, 4);
    $net_vol_len = hex $self->_reverse_hex($net_vol_len);

    # Network Share Name
    my $net_share_name_off = $net_vol_off + 8;
    my $net_share_name_loc = hex $self->_reverse_hex($self->_read_unpack($net_share_name_off, 4));
    if ($net_share_name_loc ne "20") {
      close delete $self->{_fh};
      $self->{error} = 'Error: NSN ofset should always be 14h';
      close $self->{_fh};
      delete $self->{_fh};
      return $self;
    }
    $net_share_name_loc = $net_vol_off + $net_share_name_loc;
    my $net_share_name = $self->_read_null_term($net_share_name_loc);
    $self->{base_path} = $net_share_name;
    if ($resolve) {
      close $self->{_fh};
      delete $self->{_fh};
      return $self;
    }

    # Mapped Network Drive Info
    my $net_share_mdrive = $net_vol_off + 12;
    $net_share_mdrive = $self->_read_unpack($net_share_mdrive, 4);
    $net_share_mdrive = hex $self->_reverse_hex($net_share_mdrive);
    if ($net_share_mdrive ne "0") {
      $net_share_mdrive = $net_vol_off + $net_share_mdrive;
      $net_share_mdrive = $self->_read_null_term($net_share_mdrive);
      $self->{mapped_drive} = $net_share_mdrive;
    }
  }

  #Remaining Path
  $rem_path_off = $self->_read_unpack($rem_path_off, 4);
  $rem_path_off = hex $self->_reverse_hex($rem_path_off);
  $rem_path_off = $struc_start + $rem_path_off;
  my $rem_data = $self->_read_null_term($rem_path_off);
  $self->{remaining_path} = $rem_data;

  # The next starting location is the end of the structure
  my $next_loc = $struc_end;
  my $addnl_text;

  # Description String
  # present if bit2 is set in header flags.
  if ($flag_bits[2] eq "1") {
    ($addnl_text, $next_loc) = $self->_add_info($next_loc);
    $self->{description} = $addnl_text;
    $next_loc = $next_loc + 1;
  }

  # Relative Path
  if ($flag_bits[3] eq "1") {
    ($addnl_text, $next_loc) = $self->_add_info($next_loc);
    $self->{relative_path} = $addnl_text;
    $next_loc = $next_loc + 1;
  }
  # Working Dir
  if ($flag_bits[4] eq "1") {
    ($addnl_text, $next_loc) = $self->_add_info($next_loc);
    ($self->{working_directory} = $addnl_text) =~ s/\x00//g;
    $next_loc = $next_loc + 1;
  }
  # CMD Line
  if ($flag_bits[5] eq "1") {
    ($addnl_text, $next_loc) = $self->_add_info($next_loc);
    $self->{command_line} = $addnl_text;
    $next_loc = $next_loc + 1;
  }
  #Icon filename
  ($addnl_text, $next_loc) = $self->_add_info($next_loc);
  if ($flag_bits[6] eq "1") {
    $self->{icon_filename} = $addnl_text;
  }
  close delete $self->{_fh};
  $self;
}

sub _add_info {
  my $self = shift;
  my ($tmp_start_loc) = shift;
  my $tmp_len = 2 * hex $self->_reverse_hex($self->_read_unpack($tmp_start_loc, 1));
  $tmp_start_loc++;
  if ($tmp_len ne "0") {
    my $tmp_string = $self->_read_unpack_ascii($tmp_start_loc, $tmp_len);
    my $now_loc = tell;
    return ($tmp_string, $now_loc);
  } else {
    my $now_loc = tell;
    my $tmp_string = 'Null';
    return ($tmp_string, $now_loc);
  }
}

sub _read_unpack {
  my $self = shift;
  my ($loc, $bites) = @_;
  my $tmp_data;
  seek ($self->{_fh}, $loc, 0) or croak "Can't seek to $loc";
  read $self->{_fh}, $tmp_data, $bites;
  $tmp_data = unpack 'H*', $tmp_data;
  return $tmp_data; 
}

sub _read_unpack_ascii {
  my $self = shift;
  my ($loc, $bites) = @_;
  my $tmp_data;
  seek ($self->{_fh}, $loc, 0) or croak "Can't seek to $loc\n";
  read $self->{_fh}, $tmp_data, $bites;
  $tmp_data = unpack 'A*', $tmp_data;
  return $tmp_data; 
}

sub _read_unpack_bin {
  my $self = shift;
  my ($loc, $bites) = @_;
  my $tmp_data;
  seek ($self->{_fh}, $loc, 0) or croak "Can't seek to $loc\n";
  read $self->{_fh}, $tmp_data, $bites;
  $tmp_data = unpack 'b*', $tmp_data;
  return $tmp_data;
}

sub _MStime_to_unix {
  my $self = shift;
  my $mstime_dec = shift;
  # The number of seconds between Unix/FILETIME epochs
  my $MSConversion = '11644473600';
  # Convert 100ms increments to Seconds.
  $mstime_dec *= .0000001;
  # Add difference in epochs
  $mstime_dec -= $MSConversion;
  sprintf '%0.3f', $mstime_dec;
}

sub _reverse_hex {
  my $self = shift;
  my $HEXDATE = shift;
  my @bytearry;
  my $byte_cnt = 0;
  my $max_byte_cnt = length($HEXDATE) < 16 ? int(length($HEXDATE) / 2) : 8;
  my $byte_offset = 0;
  while ($byte_cnt < $max_byte_cnt) {
    my $tmp_str = substr $HEXDATE, $byte_offset, 2;
    push @bytearry, $tmp_str;
    $byte_cnt++;
    $byte_offset += 2;
  }
  return join '', reverse @bytearry;
}

sub _read_null_term {
  my $self = shift;
  my $loc = shift;
  # Save old record seperator
  my $old_rs = $/;
  # Set new seperator to NULL term.
  $/ = "\0";
  seek ($self->{_fh}, $loc, 0) or die "Can't seek to $loc\n";
  my $fh = $self->{_fh};
  my $term_data = <$fh>;
  chomp $term_data if $term_data;
  # Reset 
  $/ = $old_rs;
  return $term_data;
}

{
  package Parse::Windows::Shortcut::Bigint;
  require Math::BigInt;
  require bigint;

  sub bighex {
    my $v = shift;
    my $h = bigint::hex $v;
    $h.'';
  }
}


=head1 SYNOPSIS

This module reads Win32 shortcuts (*.lnk files) to obtain the meta data in them.

Its goal is to be able to resolve the path they point to (along with other data),
from any platform/OS, without the need for extra dependencies.

Some examples of usage:

    use Parse::Lnk;

    my $data = Parse::Lnk->from($filename);
    
    # $data is now a hashref if the file was parsed successfully.
    # undef if not.
    
    ##########
    # Or ... #
    ##########
    
    use Parse::Lnk qw(parse_lnk);
    
    my $data = parse_lnk $filename;
    
    # $data is now a hashref if the file was parsed successfully.
    # undef if not.
    
    ##########
    # Or ... #
    ##########
    
    use Parse::Lnk qw(resolve_lnk);
    
    my $path = resolve_lnk $filename;
    
    # $path is now a string with the path the lnk file points to.
    # undef if the lnk file was not parsed successfully.
    
    ###############################################################
    # Or, if you want a little more information/control on errors #
    ###############################################################
    
    use Parse::Lnk;
    
    my $lnk = Parse::Lnk->new;
    
    $lnk->parse($filename) or die $lnk->{error};
    
    # Or:
    
    $lnk->parse($filename);
    
    if ($lnk->{error}) {
        # ... do your own error handling;
    }
    



=head1 EXPORT

Nothing is exported by default. You can explicitly import this functions:

=head2 parse_lnk($filename)

This will return a Parse::Lnk instance, which is a hashref. The keys in that
hashref depend on the data that was parsed from the .lnk file.

It will return C<undef> on error.

    use Parse::Lnk qw(parse_lnk);
    
    my $lnk = parse_lnk $filename;
    
    if ($lnk) {
        print "$filename points to path $lnk->{base_path}\n";
        
        my $create_date = localtime $lnk->{create_time};
        print "$filename was created on $create_date";
    } else {
        print "Could not parse $filename";
    }

=head2 resolve_lnk($filename)

This will return the path the .lnk file is pointing to.

It will return C<undef> on error.

    use Parse::Lnk qw(resolve_lnk);
    
    my $path = resolve_lnk $filename;
    
    if ($path) {
        print "$filename points to path $path";
    } else {
        print "Could not parse $filename";
    }


=head1 METHODS

You can create a C<Parse::Lnk> instance and call a few methods on it. This
may give you more control/information when something goes wrong while parsing
the file.

=head2 new

This creates a new instance. You can pass the C<filename> value as argument,
or you can set/change it later.

    use Parse::Lnk;
    
    my $lnk = Parse::Lnk->new(filename => $filename);
    
    # or
    
    my $lnk = Parse::Lnk->new;
    $lnk->{filename} = $filename;

=head2 parse

This method will parse the current C<filename> in the instance. You can change
the value of C<filename> and parse again at any point.

    use Parse::Lnk;
    
    my $lnk = Parse::Lnk->new(filename => $filename);
    
    $lnk->parse;
    
    if ($lnk->{error}) {
        # handle the error
    } else {
        print "$filename points to $lnk->{base_path}";
    }
    
    for my $other_filename (@filenames) {
        $lnk->{filename} = $other_filename;
        $lnk->parse;
        
        if ($lnk->{error}) {
            # handle the error
            next;
        }
        
        print "$other_filename points to $lnk->{base_path}";
    }

=head2 from

It will return a C<Parse::Lnk> instance, or undef on error. This method was
written with plain package name calling in mind:

    use Parse::Lnk;
    
    my $lnk = Parse::Lnk->from($filename);
    
    if ($lnk) {
        print "$filename points to path $lnk->{base_path}\n";
        
        my $create_date = localtime $lnk->{create_time};
        print "$filename was created on $create_date";
    } else {
        print "Could not parse $filename";
    }


=head1 AUTHOR

Francisco Zarabozo, C<< <zarabozo at cpan.org> >>

=head1 BUGS

I'm sure there are many. I haven't found bugs with the lnk files I've tested
it. If you find a bug or you have a problem reading a shortcut/lnk file,
please don't hesitate to report it and don't forget to include the file in
question. If you are on Windows, you will have to zip the file in a way that
is the lnk file the one being zipped and not the actual directory/file it
is pointing to. I promise to look at any report and work on a solution as
fast as I can.

Please report any bugs or feature requests to C<bug-parse-lnk at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Parse-Lnk>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Parse::Lnk


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Parse-Lnk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Parse-Lnk>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Parse-Lnk>

=item * Search CPAN

L<https://metacpan.org/release/Parse-Lnk>

=back


=head1 ACKNOWLEDGEMENTS

Many sections of the code were adapted from Jacob Cunningham's
L<Windows LNK File Parser|https://sourceforge.net/projects/jafat/files/lnk-parse/lnk-parse-1.0/lnk-parse-1.0.tar.gz>,
licensed under the GNU General Public License Version 2.


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2021-2024 by Francisco Zarabozo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;
