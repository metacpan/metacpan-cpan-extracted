# OLE::Storage_Lite Sample
# Name : smpadd.pl
#  by Kawai, Takanori (Hippo2000) 2000.12.21, 2001.1.4
#=================================================================
use strict;
use OLE::Storage_Lite;
my $oOl = OLE::Storage_Lite->new('test.xls');
my $oPps = $oOl->getPpsTree(1);
die( "test.xls must be a OLE file") unless($oPps);

my $oF = OLE::Storage_Lite::PPS::File->new(
		    OLE::Storage_Lite::Asc2Ucs('Last Added'), 
		'ABCDEF');
my $oF2 = OLE::Storage_Lite::PPS::File->new(
		    OLE::Storage_Lite::Asc2Ucs('Length 0'), 
		'');
push @{$oPps->{Child}}, $oF;
push @{$oPps->{Child}}, $oF2;
$oPps->save('add_test.xls');
