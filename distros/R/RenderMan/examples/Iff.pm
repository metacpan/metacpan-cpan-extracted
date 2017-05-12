package Iff;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
    open_iff
    encode_chunks
    decode_chunks
    write_iff
    open_raw
    open_rwx
);
$VERSION = '0.01';


# Preloaded methods go here.

$Iff::megadebug = 0;
$Iff::debug = 0;

sub reverse_endian {
  my ($data) = @_;
  my $val;
  $val = substr($data, 3, 1) . substr($data, 2, 1) .
	 substr($data, 1, 1) . substr($data, 0, 1);
  printf(STDERR "reverse_endian: %08lX = %08lX\n",
    unpack("l", $data),
    unpack("l", $val));
  return($val);
}

sub full_name {
  my ($type) = @_;
  if ($type eq "LWOB") {
      return("LightWave3D Object");
  } elsif ($type eq "REAL") {
      return("Real3D");
  } elsif ($type eq "AAPO") {
      return("SoftF/X");
  } elsif ($type eq "TDDD") {
      return("Imagine");
  }
  return("Unknown");
}

sub open_iff {
  my ($name) = @_;
  my $file;
  my $total;
  my $size;
  my $offset;
  my @data;
  my $type;
  my $chunknum;
  if (!(-e $name)) {
    print STDERR "ERROR!  File '$name' does not exist.\n";
    return(0);
  }
  if (!open(INP, "<$name")) {
    print STDERR "ERROR!  Unable to open file '$name'.\n";
    return(0);
  }
  binmode INP;  # For MSDOS use
  $total = (-s $name);
  if (!$total) {
    print STDERR "ERROR!  File '$name' has zero size.\n";
    return(0);
  }
  $file = "";
  read INP, $file, $total;
  close(INP);
  if (substr($file, 0, 4) ne "FORM") {
    print STDERR "ERROR!  File '$name' is not an IFF 'FORM' file.\n";
    return(0);
  }
  $size = unpack "L", substr($file, 4, 4);
  if ($total-8 != $size) {
    print STDERR "WARNING!  IFF size ($size) is not 8 less than actual size ($total)!\n";
  }
  $type = substr($file, 8, 4);
  print STDERR "Parsing IFF FORM '$type' file: '$name'...\n";
  $offset = 12;
  $total -= 12;
  $chunknum = 0;
  while ($total > 0) {
      $data[$chunknum]->{"name"} = substr($file, $offset, 4);
      $offset+=4; $total-=4;
      $size = $data[$chunknum]->{"size"} = unpack "L", substr($file, $offset, 4);
      $offset+=4; $total-=4;
      $data[$chunknum]->{"data"} = substr($file, $offset, $size);
      $offset+=$size; $total-=$size;
      if ($size % 2) { $offset++; $total--; }	# Ignore pad byte
      print STDERR "Read chunk #$chunknum: '$data[$chunknum]->{\"name\"}', size $size\n" if ($Iff::debug);
      $chunknum++;
  }
  return($type, \@data);
}

sub encode_chunks {
  my ($type, $data) = @_;
  if ($type eq "LWOB") { encode_LWOB($data); }		# LightWave3D
  elsif ($type eq "REAL") { encode_REAL($data); }	# Real3D
  elsif ($type eq "AAPO") { encode_AAPO($data); }	# SoftF/X
  elsif ($type eq "TDDD") { encode_TDDD($data); }	# Imagine
  else { return; }
}

sub encode_LWOB {
  my ($data) = @_;
  my $chunk;
  my $num;
  my $i;
  foreach $chunk (@$data) {
    if ($chunk->{"name"} eq "SRFS") {
    } elsif ($chunk->{"name"} eq "PNTS") {
      $num = $chunk->{"size"} / 12;
      if ($num >= 65536) {
	  print STDERR "ERROR! Number of points exceeds 65536 limit! ($num)\n";
      }
      print STDERR "Encoding $num PNTS...\n" if ($Iff::debug);
      $chunk->{"data"} = "";
      for ($i=0; $i<$num; $i++) {
	$chunk->{"data"} .= pack "f", $chunk->{"x"}->[$i];
	$chunk->{"data"} .= pack "f", $chunk->{"y"}->[$i];
	$chunk->{"data"} .= pack "f", $chunk->{"z"}->[$i];
	print STDERR "pnts[$i]=($chunk->{\"x\"}->[$i],$chunk->{\"y\"}->[$i],$chunk->{\"z\"}->[$i])\n" if ($Iff::megadebug);
      }
    } elsif ($chunk->{"name"} eq "POLS") {
      $num = $chunk->{"size"} / 2;
      print STDERR "Encoding $num POLS shorts...\n" if ($Iff::debug);
      $chunk->{"data"} = "";
      for ($i=0; $i<$num; $i++) {
	$chunk->{"data"} .= pack "S", $chunk->{"pnt"}->[$i];
	print STDERR "pols[$i]=$chunk->{\"pnt\"}->[$i]\n" if ($Iff::megadebug);
      }
    } else {
      print STDERR "Unknown LWOB chunk '$chunk->{\"name\"}', size $chunk->{\"size\"}...\n";
    }
  }
}

sub encode_REAL {
  my ($data) = @_;
  my $chunk;
  foreach $chunk (@$data) {
    print STDERR "Looking at REAL chunk '$chunk->{\"name\"}', size $chunk->{\"size\"}...\n";
  }
}

sub encode_AAPO {
  my ($data) = @_;
  my $chunk;
  foreach $chunk (@$data) {
    print STDERR "Looking at AAPO chunk '$chunk->{\"name\"}', size $chunk->{\"size\"}...\n";
  }
}

sub encode_TDDD {
  my ($data) = @_;
  my $chunk;
  foreach $chunk (@$data) {
    print STDERR "Looking at TDDD chunk '$chunk->{\"name\"}', size $chunk->{\"size\"}...\n";
  }
}


sub decode_chunks {
  my ($type, $data) = @_;
  if ($type eq "LWOB") { decode_LWOB($data); }		# LightWave3D
  elsif ($type eq "REAL") { decode_REAL($data); }	# Real3D
  elsif ($type eq "AAPO") { decode_AAPO($data); }	# SoftF/X
  elsif ($type eq "TDDD") { decode_TDDD($data); }	# Imagine
  else { return; }
}

sub decode_LWOB {
  my ($data) = @_;
  my $chunk;
  my $num;
  my $i;
  foreach $chunk (@$data) {
    if ($chunk->{"name"} eq "SRFS") {
    } elsif ($chunk->{"name"} eq "PNTS") {
      $num = $chunk->{"size"} / 12;
      print STDERR "Parsing $num PNTS...\n" if ($Iff::debug);
      for ($i=0; $i<$num; $i++) {
	$chunk->{"x"}->[$i] = unpack "f",
		    substr($chunk->{"data"}, $i*12, 4);
	$chunk->{"y"}->[$i] = unpack "f",
		    substr($chunk->{"data"}, $i*12+4, 4);
	$chunk->{"z"}->[$i] = unpack "f",
		    substr($chunk->{"data"}, $i*12+8, 4);
	print STDERR "pnts[$i]=($chunk->{\"x\"}->[$i],$chunk->{\"y\"}->[$i],$chunk->{\"z\"}->[$i])\n" if ($Iff::debug);
      }
    } elsif ($chunk->{"name"} eq "POLS") {
      $num = $chunk->{"size"} / 2;
      print STDERR "Parsing $num POLS...\n" if ($Iff::debug);
      for ($i=0; $i<$num; $i++) {
	$chunk->{"pnt"}->[$i] = unpack "S", substr($chunk->{"data"}, $i*2, 2);
	print STDERR "pols[$i]=$chunk->{\"pnt\"}->[$i]\n" if ($Iff::megadebug);
      }
    } else {
      print STDERR "Unknown LWOB chunk '$chunk->{\"name\"}', size $chunk->{\"size\"}...\n";
    }
  }
}

sub decode_REAL {
  my ($data) = @_;
  my $chunk;
  foreach $chunk (@$data) {
    print STDERR "Looking at REAL chunk '$chunk->{\"name\"}', size $chunk->{\"size\"}...\n";
  }
}

sub decode_AAPO {
  my ($data) = @_;
  my $chunk;
  foreach $chunk (@$data) {
    print STDERR "Looking at AAPO chunk '$chunk->{\"name\"}', size $chunk->{\"size\"}...\n";
  }
}

sub decode_TDDD {
  my ($data) = @_;
  my $chunk;
  foreach $chunk (@$data) {
    print STDERR "Looking at TDDD chunk '$chunk->{\"name\"}', size $chunk->{\"size\"}...\n";
  }
}

######################################################################

sub write_iff {
  my ($filename, $type, $data) = @_;
  my $total = 4;  # for the "type" field
  my $chunk;
  if ($type eq "") {
    print STDERR "ERROR.  Must supply IFF type\n";
    return(0);
  }
  if (!open(OUT, ">$filename")) {
    print STDERR "Can't open '$filename' for output.\n";
    return(0);
  }
  binmode(OUT);
  foreach $chunk (@$data) {		# Ignore the existing "size" field
    $chunk->{"size"} = length($chunk->{"data"});
    $total += (8 + $chunk->{"size"});
    if ($chunk->{"size"} % 2) { $total++; }
  }
  print OUT "FORM";
  print OUT pack("L", $total);
  print OUT $type;
  foreach $chunk (@$data) {
    print OUT $chunk->{"name"};
    print OUT pack("L", $chunk->{"size"});
    print OUT $chunk->{"data"};
    if ($chunk->{"size"} % 2) { print OUT 0x00; }  # pad it
  }
}

######################################################################

sub open_raw {
  my ($name) = @_;
  my $file;
  my $total;
  my $size;
  my $offset;
  my @data;
  my $type;
  my $count;
  my $pnt;
  if (!(-e $name)) {
    print STDERR "ERROR!  File '$name' does not exist.\n";
    return(0);
  }
  if (!open(INP, "<$name")) {
    print STDERR "ERROR!  Unable to open file '$name'.\n";
    return(0);
  }

  $type = "LWOB";
  $data[0]->{"name"} = "SRFS";
  $data[1]->{"name"} = "PNTS";
  $data[2]->{"name"} = "POLS";

  $data[0]->{"size"} = 8;
  $data[0]->{"data"} = "Default\0";

  $count = 0;
  $pnt = 0;
  while (<INP>) {
    print STDERR "." if ($Iff::debug);
    ($data[1]->{"x"}->[$count],
    $data[1]->{"y"}->[$count],
    $data[1]->{"z"}->[$count],
    $data[1]->{"x"}->[$count+1],
    $data[1]->{"y"}->[$count+1],
    $data[1]->{"z"}->[$count+1],
    $data[1]->{"x"}->[$count+2],
    $data[1]->{"y"}->[$count+2],
    $data[1]->{"z"}->[$count+2]) = split(" ");
    $data[2]->{"pnt"}->[$pnt++] = 3;
    $data[2]->{"pnt"}->[$pnt++] = $count;
    $data[2]->{"pnt"}->[$pnt++] = $count+1;
    $data[2]->{"pnt"}->[$pnt++] = $count+2;
    $data[2]->{"pnt"}->[$pnt++] = 1;  # Surface number
    $count += 3;
  }
  $data[1]->{"size"} = $count * 12;
  $data[2]->{"size"} = $pnt * 2;
  return($type, \@data);
}

######################################################################

sub open_rwx {
  my ($name) = @_;
  my $file;
  my $total;
  my $size;
  my $offset;
  my @data;
  my $type;
  my $count;
  my $lev;
  my @offx;
  my @offy;
  my @offz;
  my $pnt;
  my $output_name;
  my $new_name;
  my $srf;
  my $look_for_surf_name;
  if (!(-e $name)) {
    print STDERR "ERROR!  File '$name' does not exist.\n";
    return(0);
  }
  if (!open(INP, "<$name")) {
    print STDERR "ERROR!  Unable to open file '$name'.\n";
    return(0);
  }

  $type = "LWOB";
  $data[0]->{"name"} = "SRFS";
  $data[1]->{"name"} = "PNTS";
  $data[2]->{"name"} = "POLS";

  $data[0]->{"size"} = 0;
  $data[0]->{"data"} = ""; # "Default\0";

  $lev = 0;
  $offx[0] = $offy[0] = $offz[0] = 0.0;

  $count = 0;
  $pnt = 0;
  $srf = 0;
  $look_for_surf_name = 0;
  $output_name = 0;
  $new_name = "";
  while (<INP>) {
    print STDERR "." if ($Iff::debug);
    if (/TransformBegin/) {
      $lev++;
      $offx[$lev] = $offx[$lev-1];
      $offy[$lev] = $offy[$lev-1];
      $offz[$lev] = $offz[$lev-1];
    } elsif (/Transform /) {
      @_ = split(" ");
      $offx[$lev] += $_[13];
      $offy[$lev] += $_[14];
      $offz[$lev] += $_[15];
      print STDERR "New offset at level $lev: $offx[$lev], $offy[$lev], $offz[$lev]\n" if ($Iff::debug);
      $look_for_surf_name = 1;
      $output_name = 1;
    } elsif (/TransformEnd/) {
      $lev--;
    } elsif ($look_for_surf_name && /# (.+)$/) {
      $new_name = $1;
      $look_for_surf_name = 0;
    } elsif (/Vertex\S+\s+(\S+)\s+(\S+)\s+(\S+)\s+/) {
	if ($output_name) {
	  $srf++;
	  if ($look_for_surf_name) {
	    $new_name = "Default$srf";
	    $look_for_surf_name = 0;
	  }
	  $data[0]->{"data"} .= "$new_name\0";
	  $data[0]->{"size"} = length($data[0]->{"data"});
	  if ($data[0]->{"size"} & 0x01) {  # Always keep each surface name even
	    $data[0]->{"size"}++;
	    $data[0]->{"data"} .= "\0";
	  }
	  $output_name = 0;
	}
	$data[1]->{"x"}->[$count] = $1 + $offx[$lev];
	$data[1]->{"y"}->[$count] = $2 + $offy[$lev];
	$data[1]->{"z"}->[$count] = $3 + $offz[$lev];
        $count++;
    } elsif (/Triangle\s+(\d+)\s+(\d+)\s+(\d+)/) {
	$data[2]->{"pnt"}->[$pnt++] = 3;
	$data[2]->{"pnt"}->[$pnt++] = $1 - 1;
	$data[2]->{"pnt"}->[$pnt++] = $2 - 1;
	$data[2]->{"pnt"}->[$pnt++] = $3 - 1;
	$data[2]->{"pnt"}->[$pnt++] = $srf;
    }
  }
  $data[1]->{"size"} = $count * 12;
  $data[2]->{"size"} = $pnt * 2;
  return($type, \@data);
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Iff - Perl extension for reading/writing IFF (Interchange File Format) files and other 3D file formats

=head1 SYNOPSIS

  use Iff;

  ($type, $data) = open_rwx($ARGV);  # Read in raw triangles from RenderWare

  ($type, $data) = open_raw($ARGV);  # Read in raw triangles from Rhino

  ($type, $data) = open_iff($ARGV);  # Read in an IFF file
  decode_chunks($type[$iff], $data[$iff]);  # Decode the IFF chunks into data

  encode_chunks($type[$out], $data[$out]);  # Encode data into IFF chunks
  write_iff($name, $type, $data);    # Write an IFF file

=head1 DESCRIPTION

The Iff module provides routines to read and write IFF files.
The currently supported file types are:
LightWave3D object (LWOB IFF or ".lwo") files
Rhino raw 3D object (".raw") files
RenderWare 3D object (".rwx") files
Other 3D object formats that should be easy to support are:
Real3D object (".r3d") files
SoftF/X object (".sfx") files
Imagine object (".iob") files
3D Studio object (".3ds") files
3D Studio MAX object (".max") files
DXF object (".dxf") files

=head1 AUTHOR

Glenn M. Lewis, glenn@gmlewis.com, www.gmlewis.com

=head1 SEE ALSO

perl(1).

=cut
