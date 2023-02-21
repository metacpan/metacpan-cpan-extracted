# OLE::Storage_Lite Sample
# Name : smplls.pl
#  by Kawai, Takanori (Hippo2000) 2000.11.4
# Displays PPS structure of specified file
# Just subset of lls that is distributed with OLE::Storage
#=================================================================
use strict;
use OLE::Storage_Lite;
die "No files is specified" if($#ARGV < 0);
my $oOl = OLE::Storage_Lite->new($ARGV[0]);
my $oPps = $oOl->getPpsTree();
die( $ARGV[0]. " must be a OLE file") unless($oPps);
my $iTtl = 0;
PrnItem($oPps, 0, \$iTtl, 1);
#----------------------------------------------------------------
# PrnItem: Displays PPS infomations
#----------------------------------------------------------------
sub PrnItem($$\$$) {
  my($oPps, $iLvl, $iTtl, $iDir) = @_;
  my $raDate;
  my %sPpsName = (1 => 'DIR', 2 => 'FILE', 5=>'ROOT');
# Make Name (including PPS-no and level)
  my $sName = OLE::Storage_Lite::Ucs2Asc($oPps->{Name});
  $sName =~ s/\W/ /g;
  $sName = sprintf("%s %3d '%s' (pps %x)", 
			' ' x ($iLvl * 2), $iDir, $sName, $oPps->{No});
# Make Date 
  my $sDate;
  if($oPps->{Type}==2) {
    $sDate = sprintf("%10x bytes", $oPps->{Size});
  }
  else {
    $raDate = $oPps->{Time2nd};
    $raDate = $oPps->{Time1st} unless($raDate);
    $sDate = ($raDate)?
  		sprintf("%02d.%02d.%4d %02d:%02d:%02d", 
			$raDate->[3], $raDate->[4]+1, $raDate->[5]+1900,
			$raDate->[2], $raDate->[1],   $raDate->[0]) : "";
  }
# Display
  printf "%02d %-50s %-4s %s\n", 
			${$iTtl}++,
			$sName,
			$sPpsName{$oPps->{Type}},
			$sDate;
# For its Children
  my $iDirN=1;
  foreach my $iItem (@{$oPps->{Child}}) {
	PrnItem($iItem, $iLvl+1, $iTtl, $iDirN);
    $iDirN++;
  }
}
