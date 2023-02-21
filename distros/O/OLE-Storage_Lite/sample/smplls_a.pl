# OLE::Storage_Lite Sample
# Name : smpllsv.pl
#  by Kawai, Takanori (Hippo2000) 2001.2.2
# Displays PPS structure of specified file (reading it into a variable)
# Just subset of lls that is distributed with OLE::Storage
#=================================================================
use strict;
use OLE::Storage_Lite;
die "No files is specified" if($#ARGV < 0);

#File
print "--------------- File\n";
my $oOl = OLE::Storage_Lite->new($ARGV[0]);
my $oPps = $oOl->getPpsTree();
die( $ARGV[0]. " must be a OLE file") unless($oPps);
my $iTtl = 0;
PrnItem($oPps, 0, \$iTtl, 1);

#Variable
print "--------------- File\n";
open IN, '<'. $ARGV[0];
binmode(IN);
my $sBuff;
read(IN, $sBuff, -s $ARGV[0]);
close IN;
$oOl = OLE::Storage_Lite->new(\$sBuff);
$oPps = $oOl->getPpsTree();
die( "file.xls must be a OLE file") unless($oPps);
$iTtl = 0;
PrnItem($oPps, 0, \$iTtl, 1);

#IO::File
print "--------------- IO::File\n";
use IO::File;
my $oIo = new IO::File;
$oIo->open('<' . $ARGV[0]);
binmode($oIo);
$oOl = OLE::Storage_Lite->new($oIo);
$oPps = $oOl->getPpsTree();
die( "iofile.xls must be a OLE file") unless($oPps);
$iTtl = 0;
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
