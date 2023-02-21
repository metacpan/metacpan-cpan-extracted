# OLE::Storage_Lite Sample
# Name : smpadd.pl
#  by Kawai, Takanori (Hippo2000) 2000.12.21, 2001.1.4, 2001.3.1
#=================================================================
use strict;
use OLE::Storage_Lite;

#0. prepare test file
	open OUT, ">test.tmp";
	print OUT "1234567890";
	close OUT;

#1. Normal
{
	my $oOl = OLE::Storage_Lite->new('test.xls');
	my $oPps = $oOl->getPpsTree(1);
	die( "test.xls must be a OLE file") unless($oPps);

	my $oF = OLE::Storage_Lite::PPS::File->new(
			    OLE::Storage_Lite::Asc2Ucs('Add Strting Len 5'), 
			'12345');
	my $oF2 = OLE::Storage_Lite::PPS::File->new(
			    OLE::Storage_Lite::Asc2Ucs('Length 0'), 
			'');
	push @{$oPps->{Child}}, $oF;
	push @{$oPps->{Child}}, $oF2;
	$oPps->save('add_test.xls');
}
#2. Tempfile
{
	my $oOl = OLE::Storage_Lite->new('test.xls');
	my $oPps = $oOl->getPpsTree(1);
	die( "test.xls must be a OLE file") unless($oPps);

	my $oF = OLE::Storage_Lite::PPS::File->newFile(
			    OLE::Storage_Lite::Asc2Ucs('Add tempfile Len 6'), 
			);
	my $oF2 = OLE::Storage_Lite::PPS::File->newFile(
			    OLE::Storage_Lite::Asc2Ucs('Length 0'), 
			'');
	$oF->append('123456');
	push @{$oPps->{Child}}, $oF;
	push @{$oPps->{Child}}, $oF2;
	$oPps->save('add_tmp.xls');
}
#3. Filename
{
	my $oOl = OLE::Storage_Lite->new('test.xls');
	my $oPps = $oOl->getPpsTree(1);

	die( "test.xls must be a OLE file") unless($oPps);
	my $oF = OLE::Storage_Lite::PPS::File->newFile(
			    OLE::Storage_Lite::Asc2Ucs('Add filename Len b'), 
			'test.tmp');

	my $oF2 = OLE::Storage_Lite::PPS::File->newFile(
			    OLE::Storage_Lite::Asc2Ucs('Length 0'), 
			'');
	$oF->append('a');
	push @{$oPps->{Child}}, $oF;
	push @{$oPps->{Child}}, $oF2;
	$oPps->save('add_name.xls');
}
#4. IO::File
{
	my $oOl = OLE::Storage_Lite->new('test.xls');
	my $oPps = $oOl->getPpsTree(1);
	die( "test.xls must be a OLE file") unless($oPps);

	my $oFile = new IO::File;
	$oFile->open('test.tmp', 'r+');

	my $oF = OLE::Storage_Lite::PPS::File->newFile(
			    OLE::Storage_Lite::Asc2Ucs('Add IO::File Len c'), 
			$oFile);

	my $oF2 = OLE::Storage_Lite::PPS::File->newFile(
			    OLE::Storage_Lite::Asc2Ucs('Length 0'), 
			'');
	$oF->append('b');
	push @{$oPps->{Child}}, $oF;
	push @{$oPps->{Child}}, $oF2;
	$oPps->save('add_io.xls');
}
#4.1 IO::File(r)
{
	my $oOl = OLE::Storage_Lite->new('test.xls');
	my $oPps = $oOl->getPpsTree(1);
	die( "test.xls must be a OLE file") unless($oPps);

	my $oFile = new IO::File;
	$oFile->open('test.tmp', 'r');

	my $oF = OLE::Storage_Lite::PPS::File->newFile(
			    OLE::Storage_Lite::Asc2Ucs('Add IO2::File Len c'), 
			$oFile);

	my $oF2 = OLE::Storage_Lite::PPS::File->newFile(
			    OLE::Storage_Lite::Asc2Ucs('Length 0'), 
			'');
	$oF->append('b'); #No Work
	push @{$oPps->{Child}}, $oF;
	push @{$oPps->{Child}}, $oF2;
	$oPps->save('add_io2.xls');
}
