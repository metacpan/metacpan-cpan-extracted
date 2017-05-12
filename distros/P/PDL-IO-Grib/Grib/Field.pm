=head1 NAME

  PDL::IO::Grib::Field - Field tools for Grib files

=head1 SYNOPSIS

       use PDL;
       use PDL::IO::Grib;

       $gh = new PDL::IO::Grib;
       $gh->readgrib("filename");
       $gh->getfield("fieldname");
       $f = $gh->anyfield();

=head1  DESCRIPTION

Field.pm gives you access to the individual fields of a Grib
file. Here is the code that attempts to decipher each of the sections
associated with the format.  All of the data is read into PDLs (one
for each section) and it only deciphers those pdls on demand.  It only
knows how to decipher a small subset of the possibilities at this
time, but should allow the developer to write and test new or local
decipher methods easily.  Of course if you write a new method and can
cleanly merge it with whats working please feel free to send it back
to me.

=head1 FUNCTIONS

=head2 new

=for ref

PDL::IO::Grib::Field new creates a new Field structure hash and if passed an
open file handle reads the next grib record into that structure.  It reads 
each of the sections into a PDL.  

=cut

package PDL::IO::Grib::Field;
use strict;
#use warnings;
use FileHandle;
use PDL;
use PDL::IO::FlexRaw;
use PDL::IO::Grib::Wgrib;

use fields qw/IS PDS_pos PDS_len GDS_len BMS_len BDS_len
              PDS GDS BMS BDS BDS_pos DATA name/;

sub new {
  my($class,$fh) = @_;

  no strict 'refs';
  my $field = bless [ \%{"$class\::FIELDS"}], $class;

  my $id;
  $field->{IS} = pdl(byte,[71,82,73,66,0,0,0,1]);
  if(defined $fh){
    $field->initialize($fh);


#	 return if($fh->eof);
  }else{
    $field->{PDS_len}=28;
    $field->{PDS} = zeroes(byte,28);
    $field->{GDS} = zeroes(byte,32);
    $field->{BDS} = zeroes(byte,11);
    $field->pds_attribute(1,28);  # default length of PDS
    $field->pds_attribute(8,128); # GDS defined BMS undef
    $field->gds_attribute(1,32);  # default length of GDS
  }

#  use Data::Dumper;
#  my $out = Dumper($field);
#  print $out;
  return ($field);
}

=head2 name

=for ref 

$f->name('fred') assigns the name fred to field, 
$name = $f->name(); retreves the name of $f if it has one.  Initial names
are read from Gribtables.pm

=cut

sub name{
  my($field,$name) = @_;
  if(defined $name){
	 $field->{name} = $name;
  }
  return $field->{name};
} 


=head2 id

=for ref

  It takes 5 fields to uniquely identify a grib variable we concatinate these
  fields return them, Grib.pm uses this to identify each variable

=cut

sub id{
  my($field) = @_;
  # should be an error
  
  return unless defined $field->{PDS};

  my $id;
  if($field->pds_has_octet12()){
	  $id = sprintf("%u:%u:%u:%u:%u",
							$field->pds_attribute(9),
							$field->pds_attribute(4),
							$field->pds_attribute(10),
							$field->pds_attribute(11),
							$field->pds_attribute(12));
  }else{
	  $id = sprintf("%u:%u:%u:%u",
							$field->pds_attribute(9),
							$field->pds_attribute(4),
							$field->pds_attribute(10),
							$field->pds_attribute(11));


  }
  print "id = $id\n" if($PDL::IO::Grib::debug);
  return $id;
}

=head2 initialize

=for ref

Should only be called from new - reads a Grib record from a file handle

=cut

sub initialize{
  my($field,$fh) = @_;

#
# Read the length of each section.  I seem to have problems finding 
# the header exactly
# but the word GRIB should appear followed by another 4 bytes 
#
  my $tin;

  my $r = $fh->read( $tin, 4);

  until($tin =~ /GRIB$/ || $r==0){
	 my $in;
    $r = $fh->read( $in, 1);
    $tin .= $in;
  }
#  $tin =~ s/.*(.{4})GRIB/$1GRIB/;  
  $tin =~ s/.*GRIB/GRIB/;  



  unless($r>=1){
	 warn 'Could not find record marker in file';
	 return;
  }

  
  
  my $a =  PDL->zeroes((new PDL::Type(byte)),4);
  $r = PDL::IO::FlexRaw::readchunk($fh,$a,4);

  
  (my $t = $field->{IS}->slice("4:7")) .= $a;


  my $trl = $a->PDL::unpackint3();

  print " Total record length: $trl\n" if($PDL::IO::Grib::debug);
   
  $field->{PDS_pos}=$fh->tell;

  print "Read PDS\n"  if($PDL::IO::Grib::debug);

  ($field->{PDS_len},$field->{PDS}) = $field->read_section($fh);

  my $gdsbms = $field->pds_attribute(8); 


  if($gdsbms & 128){
	 print "Read GDS\n"  if($PDL::IO::Grib::debug);
    ($field->{GDS_len},$field->{GDS}) = $field->read_section($fh);
  }

  if($gdsbms & 64){
	 print "Read BMS\n"  if($PDL::IO::Grib::debug);
    ($field->{BMS_len},$field->{BMS}) = $field->read_section($fh);
  }
  $field->{BDS_pos} = $fh->tell();

  print "Read BDS\n"  if($PDL::IO::Grib::debug);
  ($field->{BDS_len},$field->{BDS}) = $field->read_section($fh,1);

  my @flags = $field->bds_attribute(4);
  if($flags[0]+$flags[1]==0){
    $field->{BDS} = $field->{BDS}->slice("0:10");
  }


  print "Trl = $trl $field->{PDS_len} $field->{GDS_len} $field->{BMS_len} $field->{BDS_len}\n" if($PDL::IO::Grib::debug);
    
}

=head2 read_section

=for ref

read_section is an internal subroutine to read a record section from a 
grib file it expects a file handle and an optional flag to tell it that the
bds section is being read.  We only read the first 16 bytes of the bds. 

=cut

sub read_section{
  my($field,$fh,$bds) = @_;
#
# first unpack the section length then go back and read the entire section 
# into an appropriatly sized PDL
#
  my $a =  PDL->zeroes((new PDL::Type(byte)),3);
  PDL::IO::FlexRaw::readchunk($fh,$a,3);

  my $len = $a->PDL::unpackint3();

  print "section length = $len\n" if($PDL::IO::Grib::debug);

  $fh->seek(-3,1);
  my $section;
#
# Usually we read everything but we do not read the actual data in the 
# BDS section
#
  if($bds){
	 #
	 # We need at least the first 16 octets
	 #
	 $section = PDL->zeroes((new PDL::Type(byte)),16);
    PDL::IO::FlexRaw::readchunk($fh,$section,16);
	 # -16 for header read +4 for end record.
    $fh->seek($len-16+4,1);
    
  }else{
	 $section = PDL->zeroes((new PDL::Type(byte)),$len);
    PDL::IO::FlexRaw::readchunk($fh,$section,$len);
  }

  print "read_section  $len ", ushort($section)," \n" if($PDL::IO::Grib::debug);
  return($len,$section);
}

=head2 pds_has_octet12

=for ref

Returns true if pds octet 10 indicates that octet 11 is one byte and 
octet 12 is a seperate field, returns 0 otherwise

=cut

sub pds_has_octet12{
  my ($f) = @_;

  my $o10 = $f->pds_attribute(10);
  if($o10 == 100 || 
     $o10 == 103 || 
     $o10 == 105 || 
     $o10 == 107 || 
     $o10 == 109 || 
     $o10 == 111 || 
     $o10 == 113 || 
     $o10 == 125 || 
     $o10 >= 160 ){
    return(0);
  }
  return(1) ;
}

=head2 pds_attribute

=for ref

$f->pds_attribute($num) returns the value of the PDS field which
begins at octet $num.  You really need to have the Grib document
(http://www.wmo.ch/web/www/reports/Guide-binary-2.html) in hand to use
these things.  If this function recognizes that a value beginning at
octet $num spans several octets and really takes another form, it
decodes and returns that value.  The default is to return the unsigned
integer value of the byte at that octet.  In a few cases it recognizes
that no value exists for a given octet and returns undef.

=cut

sub pds_attribute{
  my($f, $num, $val) = @_;

  my $offset = $num-1;
  if($num==1){
    if(defined $val){
      my $lof=$offset+2;
      (my $t=$f->{PDS}->slice("$offset:$lof")) .= PDL::packint3($val);
      $f->{PDS_len}=$val;
    }else{
      return $f->{PDS_len};
    }
  }elsif( $num > $f->{PDS_len}){
    barf("$num is not a valid PDS octet identifier\n");
  }elsif($num == 11){
    if($f->pds_has_octet12()){
      if(defined $val){
		  (my $t = $f->{PDS}->slice("($offset)")) .= $val;
      }else{
		  return $f->{PDS}->slice("($offset)");
      }
    }else{
      if(defined $val){
		  (my $t=$f->{PDS}->slice("$offset:$num")) .= PDL::packint2($val);
      }else{
		  return $f->{PDS}->slice("$offset:$num")->unpackint2();
      }
    }
  }elsif($num == 12 && !$f->pds_has_octet12()){
    return undef;
  }elsif($num == 22){
    if(defined $val){
      (my $t=$f->{PDS}->slice("$offset:$num")) = PDL::packint2($val);
    }else{
      return  $f->{PDS}->slice("$offset:$num")->unpackint2();
    }
  }elsif($num == 27){
    my $tval =  $f->{PDS}->slice("$offset:$num")->unpackint2('signed');
    return $tval;
  }
  else{
    if(defined $val){
      if($val<0 or $val>255 or $val != int($val)){
	barf "ERROR: cannot store $val in byte";
      }
      (my $t = $f->{PDS}->slice("($offset)")) .= $val;
    }else{
      return $f->{PDS}->slice("($offset)");
    }
  }
}

=head2 gds_attribute

=for ref

see the pds_attribute description

=cut

sub gds_attribute{
  my($f, $num, $val) = @_;
  my $offset = $num-1;

  if($num==1){
    if(defined $val){
		my $lof=$offset+2;
		(my $t=$f->{GDS}->slice("$offset:$lof")) .= PDL::packint3($val);
		$f->{GDS_len}=$val;
    }else{
      return $f->{GDS_len};
    }
  }elsif($num<4 or $num > $f->{GDS_len}){
    barf("$num is not a valid GDS octet identifier\n");
  }elsif($num == 7 || $num == 9){
    if(defined $val){
		(my $t=$f->{GDS}->slice("$offset:$num")) .= PDL::packint2($val);
	 }else{
		return $f->{GDS}->slice("$offset:$num")->unpackint2();
	 }
  }elsif($num == 11 || $num == 14 || $num == 18 || $num==21){
    my $ep=$offset+2;
	 if(defined $val){
		(my $t=$f->{GDS}->slice("$offset:$ep")) .= PDL::packint3($val,'signed');
	 }else{
		my $tval =  $f->{GDS}->slice("$offset:$ep")->unpackint3('signed');
		return $tval/1000;
	 }
#
# note that we can't call $f->gds_attribute(5) here, we need to 
# decode it directly to avoid recursion
#
  }elsif($num < 255 && $num ==  $f->{GDS}->slice("(4)")){ 
    my $end =  $offset+4*$f->gds_attribute(4)-1;
	 if(defined $val){
		(my $t = $f->{GDS}->slice("$offset:$end")).= PDL::IO::Grib::Wgrib::encode_ref_val($val);
	 }else{
		print  $f->{GDS}->nelem," Getting PV $offset:$end\n" if($PDL::IO::Grib::debug);

		my $a = $f->{GDS}->slice("$offset:$end")->reshape(4,($end-$offset+1)/4);

		return(PDL::IO::Grib::Wgrib::decode_ref_val($a));
	 }
  }
  else{
    if(defined $val){
      (my $t = $f->{GDS}->slice("($offset)")) .= $val;
    }else{
      return $f->{GDS}->slice("($offset)");
    }
  }
  
}

=head2 bms_attribute

=for ref

see the pds_attribute description

=cut


sub bms_attribute{
  my($f, $num, $val) = @_;

  my $offset = $num-1;
  if($num==1){
    if(defined $val){
      my $lof=$offset+2;
      (my $t=$f->{BMS}->slice("$offset:$lof")) .= PDL::packint3($val);
      $f->{BMS_len}=$val;
    }else{
      return $f->{BMS_len};
    }
  }else{
    if(defined $val){
      (my $t = $f->{BMS}->slice("($offset)")) .= $val;
    }else{
      return $f->{BMS}->at($offset);
    }
  }
  
}

=head2 bds_attribute

=for ref

see the pds_attribute description

=cut

sub bds_attribute{
  my($f, $num, $val) = @_;
  my $offset = $num-1;

#  print $f->{BDS},"\n";

  if($num == 1){
    my $lof = $offset+2;
    if(defined $val){
      (my $t=$f->{BDS}->slice("$offset:$lof")) .= PDL::packint3($val);
    }else{
      return PDL::unpackint3($f->{BDS}->slice("$offset:$lof"));
    }
  }elsif($num == 4 && ! defined $val){
    # return an array reference 
    
    my $v = $f->{BDS}->slice("($offset)");
    return ($v & 128, $v & 64, $v & 32, $v & 16, $v & 15);
  }elsif($num == 5){
    if(defined $val){
      if($val != 0){
	$val = int(log($val)/log(2));
      }
      (my $t = $f->{BDS}->slice("$offset:$num")) .= PDL::packint2($val,'signed');
#      print "Encoding bds 5: $val ",$f->{BDS}->slice("$offset:$num"),"\n";
    }else{
#      print "Decoding bds 5: ",$f->{BDS}->slice("$offset:$num"),"\n";
      return 2**($f->{BDS}->slice("$offset:$num")->unpackint2('signed'));
    }
  }elsif($num == 7){
    my $lof = $offset+3;
    if(defined $val){
      (my $t = $f->{BDS}->slice("$offset:$lof")) .= PDL::IO::Grib::Wgrib::encode_ref_val($val);
    }else{
      return PDL::IO::Grib::Wgrib::decode_ref_val($f->{BDS}->slice("$offset:$lof"));
    }
  }else{
    if(defined $val){
      (my $t = $f->{BDS}->slice("($offset)")) .= $val;
    }else{
      return $f->{BDS}->at($offset);
    }
  }

}  

=head2 section_dump

=for ref

section_dump returns a string which includes the entire contents of the 
specified section, except in the case of the BDS where it only includes the
first 16 bytes.  It is a little braindead - if I know that octet 42 is really 
a list of 21 float values I return a pdl of 21 values from octet 42 but I also 
return octets 43 - 126 as well.  

=cut

sub section_dump{
  my($f,$section) = @_;
  my $function;

  $section = uc $section;
  if($section eq 'PDS'){
    $function = \&PDL::IO::Grib::Field::pds_attribute;
  }elsif($section eq 'GDS'){
    $function = \&PDL::IO::Grib::Field::gds_attribute;
  }elsif($section eq 'BMS'){
    $function = \&PDL::IO::Grib::Field::bms_attribute;
  }elsif($section eq 'BDS'){
    $function = \&PDL::IO::Grib::Field::bds_attribute;
  }else{
    barf("invalid section name $section\n");
  }
  my $out = "$section octet  value\n";
    

  $out.="     1   ". &{$function}($f,1)."\n";
  for(4 .. $f->{$section."_len"}-1){
    $out.="     $_   ".&{$function}($f,$_)."\n";
  }
  return $out;
}

=head2 PDL::packint3

=for ref

Given an integer value this packs it into a 3 byte PDL.  The optional signed flag
causes a signed pack.

=cut

# private 
sub PDL::packint3{
  my($val,$signed) = @_;
  if(defined $signed && $val<0){
	 $val = -($val & 8388607);
  }
  pdl(byte,[$val>>16,($val&65535)>>8,($val&255)]);
}

=head2 PDL::unpackint3

=for ref

Given a PDL of 3 bytes unpacks into a integer, if the signed flag is on 
the highest bit indicates sign of the output value.

=cut

sub PDL::unpackint3{
  my($pd,$signed) = @_;
  
  my $val = (($pd->at(0)<<16) + ($pd->at(1)<<8) + $pd->at(2));
  if(defined $signed and $val>8388607){
    $val =  -($val & 8388607);
  }
  $val;
  
}

=head2 PDL::packint2

=for ref

Packs the integer passed in $val into a two byte pdl optionally
setting the signed flag if the signed option is defined.

=cut

sub PDL::packint2{
  my($val,$signed) = @_;
  if(defined $signed && $val<0){
	 $val = -($val & 32767);
  }
  pdl(byte,[$val>>8,($val&255)]);
}

=head2 PDL::unpackint2

=for ref

Given a PDL of 2 bytes unpacks into a integer, if the signed flag is on 
the highest bit indicates sign of the output value.

=cut

sub PDL::unpackint2{
  my($pd,$signed) = @_;
  my $val = (($pd->at(0)<<8) + $pd->at(1));

  if(defined $signed && $val > 32767){
	 $val = -($val & 32767);
  }
  $val;
}

=for ref

Given a PDL of length $cnt unpacks into a integer.

=cut

sub PDL::unpackint{
  my($slice,$cnt) = @_;

  my $val;
  $cnt--;

  if($cnt > 0){
	 $val = (256**$cnt)*$slice->at(0)+$slice->slice("1:-1")->unpackint($cnt);
  }else{
	 $val =  $slice->at(0);
  }
  return($val);
}


=head2 gds_vertical_parameters

=for ref

Function to decode the vertical parameter field if present.
Convenience function, could be done with gds_attribute directly.

=cut

sub gds_vertical_parameters{
  my($f) = @_;
  return $f->gds_attribute( $f->gds_attribute(5) );
}

use PDL::IO::Misc qw(bswap2 bswap4);

=head2 read_data

=for ref

Decode the data section of a grib record.  Currently only handles grid
point simple packing, but should be able to handle any number of bits
per value.

=cut

sub read_data{
  my($f, $fh)=@_;

  my @flags = $f->bds_attribute(4);

  

#  print "flags = @flags\n";
  my $dataarray;
  

  if($flags[0]+$flags[1] == 0){
	 # easiest case - grid point simple packing
	 my $xdim = $f->gds_attribute(7);
	 my $ydim = $f->gds_attribute(9);

	 $fh->seek($f->{BDS_pos}+11,0);
	 my $len = $f->{BDS_len}-11;	 
    $len-- if($flags[4]>0);


    if($len<=0){
		print "Warning: data length reported as 0\n";
		$f->{DATA} = $f->bds_attribute(7);
		return( $f->{DATA} );
	 }
    print "dimensions $xdim $ydim $len \n"  if($PDL::IO::Grib::debug);
    my $decoded;
	 my $bitsperval = $f->bds_attribute(11);
	 print "Reading $bitsperval bits per value ",ref($bitsperval),"\n"  if($PDL::IO::Grib::debug);
	 if($bitsperval == 8){
		$dataarray = PDL->zeroes((new PDL::Type(byte)),$xdim,$ydim);
		PDL::IO::FlexRaw::readchunk($fh,$dataarray,$len);
	 }elsif($bitsperval ==  16){
		$dataarray = PDL->zeroes((new PDL::Type(ushort)),$xdim,$ydim);

#		print "Reading from ",$fh->tell," bds_pos= ",$f->{BDS_pos},"\n";

		PDL::IO::FlexRaw::readchunk($fh,$dataarray,$len);

		bswap2($dataarray) if($PDL::IO::Grib::swapbytes);
	 }else{
		my $bytearray = PDL->zeroes((new PDL::Type(byte)),$len);
		$dataarray = PDL->zeroes((new PDL::Type(float)),$xdim*$ydim);
      
		PDL::IO::FlexRaw::readchunk($fh,$bytearray,$len);
		my $bitmap;

		if(defined $f->{BMS}){
		  $bitmap = $f->{BMS}->slice("6:-1");
		}else{
		  $bitmap = 255+PDL->zeroes((new PDL::Type(byte)),$xdim*$ydim/8+1); 
		}
      
		PDL::IO::Grib::Wgrib::BDSunpack($bytearray,$bitmap, $bitsperval, 
					 $f->bds_attribute(7),$f->bds_attribute(5), $dataarray);
      $dataarray = $dataarray->reshape($xdim,$ydim);
		$decoded=1;
		#		barf "Do not know how to handle $bitsperval bits per value";
    }
	 unless($decoded || ($f->bds_attribute(5) == 1) && ($f->bds_attribute(7) == 0)){
		print "before decode: ",join(' ',$dataarray->minmax),"\n" if($PDL::IO::Grib::debug);
	   $dataarray=float $dataarray*$f->bds_attribute(5)+ $f->bds_attribute(7);
	 }
  }else{
	 barf "Do not know how to handle bds octet 4 = @flags yet";
  }

  $dataarray *= (10**( -$f->pds_attribute(27))) if($f->pds_attribute(27));
 
  $f->{DATA} = $dataarray;

  my $endrec;
  
  read $fh, $endrec, 1 if($flags[4]);  

  read $fh, $endrec, 4;
  if($endrec ne '7777'){
	 print "Unexpected endrec: $endrec\n";
  }
  
  return($dataarray);
}


=head2 write_bds

=for ref 

Write the bds section and encoded data to a filehandle (fh), recomputes the 
data minimum and scale value before packing.

=cut



sub write_bds{
  my($f,$fh,$options)=@_;

  my @flags = $f->bds_attribute(4);

  $fh->seek($f->{BDS_pos},0) if(defined $options->{INSERT});

  unless(defined $f->{DATA}){
	 print "DATA not defined for field in write_bds ",$f->{name},"\n";
	 print $fh $ { $f->{BDS}->get_dataref};
	 return;
  }

  my $dataarray = double $f->{DATA};
  
  if($flags[0]+$flags[1] == 0){
    # easiest case - grid point simple packing
    
    $dataarray *= (10**$f->pds_attribute(27)) if($f->pds_attribute(27));

    my($min,$max);
    ($min,$max) = $dataarray->minmax;

    $f->bds_attribute(7,$min);

    if($min == $max){
      print "Warning: data length reported as 0\n";
      $f->bds_attribute(1,12);
      print $fh $ { $f->{BDS}->get_dataref};
      return;
    }

    my $decoded;
    my $bitsperval = $f->bds_attribute(11);
    my $r = ($max-$min)/(2 **$bitsperval);
    $f->bds_attribute(5,$r);

    print "$r Writing $bitsperval bits per value ",ref($bitsperval),' min=',
    $f->bds_attribute(7),' scale=',$f->bds_attribute(5),"\n"   if($PDL::IO::Grib::debug);

    if($min!=0 or $f->bds_attribute(5)!=1){
      $dataarray = ($dataarray-$f->bds_attribute(7))/$f->bds_attribute(5);
    }
    if($bitsperval == 8){
      $dataarray=byte($dataarray);
    }elsif($bitsperval ==  16){
      $dataarray=ushort($dataarray);
      bswap2($dataarray) if($PDL::IO::Grib::swapbytes);
    }else{
		$dataarray=BDSpack($dataarray,$bitsperval);	
    }
    print $fh $ { $f->{BDS}->get_dataref};
    
    print $fh $ { $dataarray->get_dataref};

    
	 print $fh  ' '	 if($flags[4]);
  }else{
    barf "Do not know how to handle bds octet 4 = @flags yet";
  }
}

=head2 write

=for ref 

Write a complete grib record.

=cut


sub write{
  my ($field,$fh,$options) = @_;

# insert assumes the file already exists and already contains the field and
# that we are replacing that field with another of the same length

  binmode $fh;
  if(defined $options->{INSERT}){
	 $fh->seek($field->{PDS_pos}-8,0);
  }else{
	 # we don't want to modify the length if we're inserting, do we?

	 $field->{BDS_len} = 11+$field->{DATA}->nelem*$field->bds_attribute(11)/8;
  

#    print "BDS_len = ",$field->{BDS_len}," bpv=",$field->bds_attribute(11),"\n";
	 $field->{BDS_len} = int($field->{BDS_len})+1 
		if($field->{BDS_len} != int($field->{BDS_len}));
  
#    print "BDS_len = ",$field->{BDS_len}," bpv=",$field->bds_attribute(11),"\n";
	 if($field->{BDS_len} % 2){
		$field->{BDS_len} = $field->{BDS_len}+1;
	   my @flags = $field->bds_attribute(4);
	   my $val = ($flags[0]<<7) + ($flags[1]<<6) + ($flags[2]<<5) + ($flags[3]<<4) + 8;
		$field->bds_attribute(4,$val);
	 }
#    print "BDS_len = ",$field->{BDS_len}," bpv=",$field->bds_attribute(11),"\n";
	 $field->bds_attribute(1,$field->{BDS_len});

	 if(defined $field->{GDS}){
		$field->{GDS} = $field->{GDS}->append(pdl [0]) 
		  if($field->{GDS}->nelem %2);
		$field->gds_attribute(1,$field->{GDS}->nelem);
	 }
	 if(defined $field->{BMS}){
		$field->{BMS} = $field->{BMS}->append(pdl [0]) 
		  if($field->{BMS}->nelem %2);
		$field->bms_attribute(1,$field->{BMS}->nelem);
	 }
	 $field->{PDS} = $field->{PDS}->append(pdl [0]) 
		if($field->{PDS}->nelem %2);
	 $field->pds_attribute(1,$field->{PDS}->nelem);
  }

  my $trl = $field->{IS}->nelem + $field->{PDS}->nelem + $field->{BDS_len}+4;
  $trl += $field->{GDS}->nelem if(defined $field->{GDS});
  $trl += $field->{BMS}->nelem if(defined $field->{BMS}) ;

  (my $t = $field->{IS}->slice("4:6")) .=  PDL::packint3($trl);

  print $fh $ { $field->{IS}->get_dataref};

  $field->pds_attribute(1,$field->{PDS}->nelem);

  print $fh $ { $field->{PDS}->get_dataref};

  print $fh $ { $field->{GDS}->get_dataref}  if(defined $field->{GDS});

  print $fh $ { $field->{BMS}->get_dataref}if(defined $field->{BMS});

  $field->write_bds($fh,$options);

  print $fh '7777';

}


sub BDSpack{
  my($f, $bitsperval) = @_;
  
  if($f->min<0 or $f->max >= 2**$bitsperval){
	 barf "Bad range in BDSpack, trying to put ".join(' ',$f->minmax)." into $bitsperval bits\n";
  }

  my $nvals = $f->nelem*$bitsperval/8;

  $nvals = int($nvals)+1  if($nvals != int($nvals));

  my $pows = 2**zeroes($bitsperval)->xvals->slice("-1:0");
  
  my $c = byte(($f->dummy(0) & $pows)>0)->reshape(8,$nvals);

  my $b = ($c->slice("0")<<7) +
	    ($c->slice("1")<<6) +
	    ($c->slice("2")<<5) +
	    ($c->slice("3")<<4) +
	    ($c->slice("4")<<3) +
	    ($c->slice("5")<<2) +
  	    ($c->slice("6")<<1) +
	    $c->slice("7");
}


  
1;
