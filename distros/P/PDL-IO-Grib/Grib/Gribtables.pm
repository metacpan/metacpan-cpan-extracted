#
# Assign names to fields
#
# format:
# name:pds[9]:pds[4]:pds[10]:pds[11]:pds[12]
#
# where pds[#] refers to the grib pds table elements (starting from 0)
# see the WMO document 'A Guide to the Code Form FM 92-IX Ext. GRIB Edition 1'
# fields  and 9 are optional  
#
# These names are from the HRM users guide
#
package PDL::IO::Grib;
use strict;
use FileHandle;

sub get_grib_names{
  my($self) = @_;

  my $namekey;
  my $fname;

  my $names = gribnames();

# assign the defaults from this file

  foreach(keys %$names){
    foreach my $rec (keys %$self){
      next unless($rec =~ /:/);
      my $str = $names->{$_};
      next unless($rec =~ /^$str/);
#      print "$rec = $_\n";
      $self->{$rec}->name($_);
    }
  }
  if(-e ".gribtables"){
    $fname = ".gribtables";
  }elsif(-e "$ENV{HOME}/.gribtables"){
    $fname = "$ENV{HOME}/.gribtables" ;
  }
  if(defined $fname){
    print "Reading table file $fname\n";
    my $table = new FileHandle $fname;
    
    foreach($table->getlines){
      chomp;
      next if /^\#/;
      next if /^\s*$/;
      s/ //g;
      s/\#.*$//;
      my($name,@tmp) = split /:/,$_;
      my $namekey = join(':',@tmp);

#
# Maintains backward compatibility after bug fix for vertical type 105
#

      if($namekey =~ /105:0:\d+$/){
	print "Warning out of data format in $fname \n";
	print "old format: $name:$namekey\n";
	$namekey =~ s/105:0:(\d+)$/105:$1/;
	print "should be $name:$namekey please update $fname\n";
      }


      foreach my $rec (keys %$self){
	next unless($rec =~ /^$namekey/);
	$self->{$rec}->name($name);
      }
    }
    $table->close();
  }



}

sub gribnames{

  return ({PS=>'1:2:1:0:0',
	  ASOB_S=>'111:2:1',                  # shortwave radiation
	  ATHB_S=>'112:2:1',                  # longwave radiation     
	  ASOB_T=>'113:2:8',
	  ATHB_T=>'114:2:8',
	  T=>'11:2:110',
	  FIS=>'6:2:1',                       # topo * gravity
	  T_G=>'11:2:1:0:0',
	  QC=>'31:201:110',
	  U=>'33:2:110',
	  V=>'34:2:110',
	  QV=>'51:2:110',
	  W_SNOW=>'65:2:1',
	  T_S=>'85:2:111:0:0',
	  T_M=>'85:2:111:0:9',
	  W_G1=>'86:2:112:0:10',  
	  W_G2=>'86:2:112:10:100',  
	  W_I=>'200:201:1:0:0',  
	  T_SNOW=>'203:201:1:0:0',
	  QV_S=>'51:2:1:0:0',                 # specific humidity at the surface
	  SOILTYP=>'57:202:1:0:0',  
	  ROOT=>'62:202:1:0:0',
	  FR_LAND=>'81:2:1:0:0',
	  Z0=>'83:2:1:0:0', 
	  T_CL=>'85:2:111:0:36', 
	  W_CL=>'86:2:112:100:190',  
	  PCLOV=>'87:2:1:0:0',
	  RAIN_GSP=>'102:201:1:0:0',
	  RAIN_CON=>'113:201:1:0:0',
	  SNOW_GSP=>'79:2:1:0:0',
	  SNOW_CON=>'78:2:1:0:0',
	  CLCL=>'73:2:1:0:0',
	  CLCH=>'75:2:1:0:0',
	  CLCT=>'71:2:1:0:0',
	  U_10M=>'33:2:105:10',
	  V_10M=>'34:2:105:10',
	  TD_2M=>'17:2:105:2',
	  T_2M=>'11:2:105:2',
	  TMIN_2M=>'16:2:105:2',
	  TMAX_2M=>'15:2:105:2',
	  GPprs=>'6:2:100',
	  PRESmsl=>'2:2:102',
	  RHprs=>'52:2:100',
	  TMPprs=>'11:2:100',
	  UGRDprs=>'33:2:100',
	  VGRDprs=>'34:2:100',
	  VVELprs=>'39:2:100'});
}

1;
