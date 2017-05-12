=head1 NAME

PDL::IO::Grib - Grib file utilities for perl

=head1 SYNOPSIS

       use PDL;
       use PDL::IO::Grib;

       $gh = new PDL::IO::Grib;
       $gh->readgrib("filename");
       $gh->getfield("fieldname");
         

=head1 DESCRIPTION

Grib.pm allows the user to read files in the grib FORM FM 92-IX
Ext. GRIB Edition 1 - it may not read all possible grib format
combinations.  The Grib format has 4 sections (PDS, GDS, BMS, BDS),
two of which (GDS, BMS) are optional.  Each field of a section is
described in the definition by an offset in bytes from the beginning
of the section and a length.  The contents of each field can vary
widely according to the center of origin of the data.  This decoder
reads the entire section into a PDL and only decodes fields on
request, it has a default decoding method and allows the user to
define methods not known to this decoder.  So for example, the first 3
bytes of the PDS section describes the length of that section, each of
the next 10 bytes can be decoded as unsigned integers.  Bytes 11 and
12 may be two seperate integers or one two-byte integer depending on
the value of byte 10.  It gets worse from there... 

=head1 FUNCTIONS

=head2 new

=for ref

PDL::IO::Grib::new creates a GribHandle, which is a reference to a
newly created data structure.  If it receives any parameters, they are
passed to Grib::readgrib; if readgrib fails, the GribHandle object is
destroyed.  Otherwise, it is returned to the caller.

=cut


package PDL::IO::Grib;
use vars qw/$VERSION/;
$VERSION = 2.0;
#CPAN has problems with CVS version numbers
#( $VERSION ) = '$Revision: 1.24 $ ' =~ /\$Revision:\s+([^\s]+)/;

use FileHandle;
use PDL;
use PDL::IO::Grib::Field;
use PDL::IO::Grib::Gribtables;
use strict;

$PDL::IO::Grib::debug=0;
$PDL::IO::Grib::swapbytes=0;


sub new {
    my($type,$filename,$mode) = @_;
 
    @_ >= 1 or barf 'usage: new PDL::IO::Grib [FILENAME]';
    my $class = shift;
    my $gh={};
    bless $gh, $class;
   
    use Config;

    $PDL::IO::Grib::swapbytes=1 if($Config{byteorder} =~ "1234");
    
    if(defined $filename){
      if(defined $mode){
	$gh->{_FILEHANDLE} = new FileHandle "$filename","$mode" or
	  barf "Failed to open $filename with mode $mode";
      }else{
	$gh->{_FILEHANDLE} = new FileHandle "$filename" or
	  barf "Failed to open $filename ";
      }
      binmode $gh->{_FILEHANDLE};
      
      $gh->readgrib() if(-s $filename);
      
    }
		
    return $gh;
}

=head2 Grib::readgrib

=for ref

Grib::readgrib accepts a Grib Object and a filename. It reads grib
header information for all variables in the specified grib file. 

=cut


sub readgrib {
  my($self) = @_;

  my %fields;
  my $cnt=0;


  while(!$self->{_FILEHANDLE}->eof){
#
# Read in the pds
#  
    my $f = new PDL::IO::Grib::Field($self->{_FILEHANDLE});
	 unless(defined $f){
		barf "Field unreadable at byte ",$self->{_FILEHANDLE}->tell,"\n";
	 }
    my $id = $f->id();
    print "id = $id\n" if($PDL::IO::Grib::debug);
	 barf "No id defined for field $id" unless(defined $id);
    $self->{$id} = $f;
	 $cnt++;
	 last if($self->{_FILEHANDLE}->eof);
  }
  $self->get_grib_names();

  


  return $self;
}



=head2 Grib::getfield 

=for ref

Grib::getfield accepts one parameter which is either the 5 field
identifier for grib variables (pds octets 9:4:10:11:12 as defined in
the grib format definition) or a variable name associated with that
identifier as defined in the file .gribtables and returns the name and
data field for that variable.  Grib::getfield will check to see if the
data has already been read into memory and will only read the file
when this is not the case.  The data field can be returned as a 2 or 3
Dimensional PDL piddle or an array of PDL piddles where the identifier
matchs more than one field.  If an array or a 3D piddle is returned it
is sorted from the largest value to the smallest value of octets
11:12.  getfield uses wantarray to return what you ask for.

=cut

sub getfield{
  my($gh,$field,$options) = @_;
  
  my ($he,$key);
  my ($level);

  if(defined $gh->{$field}){
	 $gh->{$field}->read_data($gh->{_FILEHANDLE}) unless defined $gh->{$field}{DATA};
	 return $gh->{$field}{DATA} ;
  }

  if($field=~/^([^:]+):(\d+:*\d*)$/){
	 $field = $1;
	 $level = $2;
  }
  

  print "looking for >$field<$level<\n"  if($PDL::IO::Grib::debug);
    
  my @keys = keys %$gh;

# gets rid of the non-numeric fields
  for my $i (0 .. $#keys-1){
    unless($keys[$i] =~ /:/){
#      print "removing $i $#keys $keys[$i]\n";
      splice(@keys,$i,1);
      redo;
    }
  }


  foreach $key (sort idsort @keys){
#  foreach $key (keys %$gh){
    next unless($key =~ /:/); # special keys
    my $name = $gh->{$key}->name();
    next unless(defined $name && $name eq $field);
    if(defined $level){
      next unless($key=~/:$level$/);
    }
    print "lev: $level $key $name $field\n"  if($PDL::IO::Grib::debug);
    push(@$he,$gh->{$key});
  }

  if(defined $options->{NAMESONLY}){
	 return $he;
  }

  unless(defined $he){
    $field.=":$level" if(defined $level);
    print "WARNING: Could not find match for $field in gribfile\n";
    return;
  }
  my ($href,$retval,@pdllist,$name);

  foreach $href (@$he){
    print "href = $href\n" if($PDL::IO::Grib::debug==1);
    $name=$href->name() ;
    $name.=":$level" if(defined $level);
   
	 push(@pdllist,$href->read_data($gh->{_FILEHANDLE}));

  }
  
  if($#pdllist==0){
    return wantarray ? @pdllist  : $pdllist[0];
  }elsif($#pdllist>0){
    return wantarray ? (@pdllist) : stack2d(@pdllist);
  }
 
}

sub filehandle{
  my($self,$val) = @_;
  
  if(defined $val){
    $self->{_FILEHANDLE}->close() if(defined $self->{_FILEHANDLE});
    $self->{_FILEHANDLE}=$val;
  }
  $self->{_FILEHANDLE};
  
}


sub idsort{

  my(@a) = split(/:/,$a);
  my(@b) = split(/:/,$b);

  $#a<=1
	 or
  $#b<=1
	 or
  $b[0] <=> $a[0]
    or
  $b[1] <=> $a[1]
    or
  $b[2] <=> $a[2]
    or
  $b[3] <=> $a[3]
    or
  $b[4] <=> $a[4]
    or
  $b cmp $a;
}

sub getallfields{
  my($gh) = @_;
  my $fieldlist;

  foreach(sort idsort keys %$gh){
    next if(/^[^\d]/); # ignore special keys
    push(@$fieldlist,getfield($gh,$_));
  }
  $fieldlist;
}

#
# Create a single 3d piddle from a list of 2d piddles
#

sub stack2d{
  my(@pdls)=@_;
  
  my $cube = PDL->zeroes($pdls[0]->type,$pdls[0]->dims,$#pdls+1); # make 3D piddle

  for (0.. $#pdls){
    (my $tmp = $cube->slice(":,:,($_)")) .= $pdls[$_];
  }
  return($cube);
}

sub stack{
  my(@pdls) = @_;

  my $ndims = $pdls[0]->getndims;

  my $cube = PDL->zeroes($pdls[0]->type,$pdls[0]->dims,$#pdls+1); # make $ndims+1 piddle

  my $slice_str;
  for(1..$ndims){
    $slice_str.=":,";
  }
  
  for (0.. $#pdls){
    (my $tmp = $cube->slice("$slice_str($_)")) .= $pdls[$_];
    
  }
  return($cube);
}
  


=head2 Grib::showinventory 

=for ref

Grib::showinventory prints a list of variables found in the open file and names
associated with them from the .gribtables file.

=cut

sub showinventory{
  my($gh) = @_;

  foreach(sort idsort keys %$gh){
    next if(/^[^\d]/); # ignore special keys
    if(defined $gh->{$_}->name()){
        print "$_  name=",$gh->{$_}->name(),"\n";
      }else{
        print "$_\n"; 
      }
  }
}


sub fieldcnt{
  my($gh) = @_;
  my $cnt=0;
  foreach(keys %$gh){
    next if(/^[^\d]/); # ignore special keys
    $cnt++;
  }
  $cnt;
}

=head2 get_grib1_date()

=for ref

Returns the initialization date from a grib file in the form
yyyymmddhh.  Takes either the file name or a valid Grib handle as
an input argument.

=cut

sub get_grib1_date{
  my $gh = shift;

  my $passed_file_name;
  unless(ref($gh)){
    $gh = new PDL::IO::Grib($gh);
    $passed_file_name=1;
  }
  my $anyfield;
  foreach(%$gh){
    next unless(/:/);
    $anyfield = $gh->{$_};
    last;
  }
  my $date = sprintf("%4.4d%2.2d%2.2d%2.2d",$anyfield->pds_attribute(13)+1900,
                               $anyfield->pds_attribute(14),
                               $anyfield->pds_attribute(15),
                               $anyfield->pds_attribute(16));

#  $date = ($anyfield->pds_attribute(13)+1900)*1000000
#               + $anyfield->pds_attribute(14)*10000
#               + $anyfield->pds_attribute(15)*100
#               + $anyfield->pds_attribute(16);

#  print $anyfield->pds_attribute(13)," ",
#  $anyfield->pds_attribute(14)," ",
#  $anyfield->pds_attribute(15)," ",
#  $anyfield->pds_attribute(16)," ",
#  $anyfield->pds_attribute(17),"\n";

  $gh->close if($passed_file_name==1);

  return $date;

}

=head2 anyfield

=for ref

  $gh->anyfield(); returns a reference to an arbitrary field of gh

=cut

sub anyfield {
  my($gh) = @_;
  foreach(%$gh){
    next unless(/:/);
    return $gh->{$_};
  }
}


sub close {
  my($gh) = @_;
  $gh->{_FILEHANDLE}->close;
}



1;

=head1 .gribtables

The .gribtables file is searched for first in the working directory then 
in the user's home directory.  The format is rather simple - anything following a 
B<#> sign is a comment otherwise a 

name:pds[9]:pds[4]:pds[10]:pds[11]:pds[12]  
 
is expected where name can be anything as long as it begins with an alpha character and does not containb{:} 
and the pds[#] refers to the octet number in the pds
sector of the grib file.  Fields 11 and 12 are optional in the file and if
not found all of the records which match fields 9 4 10 will be combined into a 
single 3d dataset by getfield

So suppose the file .gribtables contains the entry

T_PG:11:2:100

to specify 3d temperature on a pressure grid, then to get the 500mb
pressure you would do

$t500 = $gh->getfield ("T_PG:500");

=head1 Author

Jim Edwards <jedwards@inmet.gov.br> 

=cut
