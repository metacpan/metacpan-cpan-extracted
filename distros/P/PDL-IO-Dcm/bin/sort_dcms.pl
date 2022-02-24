#!/usr/bin/perl

=head1 sort_dcm.pl

Reads dicom files from a zip file or directory, extracts Series, Study, and
Instance Number as well as series description and properly renames them.

Call with 
	sort_dcms.pl < zip | directory > [ target ] [copy_flag]

Default is to move (rename) the file to its new location, set copy_flag if you
want to copy instead.

=cut 

use DicomPack::IO::DicomReader;
use Storable qw/dclone/;
use DicomPack::DB::DicomTagDict qw/getTag getTagDesc/;
use DicomPack::DB::DicomVRDict qw/getVR/;
use File::Copy 'move';
#use Exporter;
use strict;
use File::Copy;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use 5.10.0;


my $path=shift || '.';
my $target=shift || "dicom";
my $cpy=shift ||0;
mkdir ("$target") unless (-d "$target");

sub new_name {
	my $file=shift;
	my $dcm=DicomPack::IO::DicomReader->new($file) || return;
	my $sn=$dcm->getValue("SeriesNumber");
	my $in=$dcm->getValue("InstanceNumber");
	my $st=$dcm->getValue("StudyID");
	my $fn=$dcm->getValue("SeriesDescription");
	my $en=eval{ $dcm->getValue("EchoNumbers"); } ||1;
	return if ($fn=~/Phoenix.*Report/i);
	$fn=~s/-\d*$//;
	$fn=~s/ /_/g;
	#say "file $file fn $fn";
	my $newfile="Series_$st\_$sn\_$in\_echo_$en\_".$fn;
	#say "new file $newfile;";
	return $newfile;
}

# directory or zip?
if ( -f $path && $path =~/.zip/ ) {
	my $zip = new Archive::Zip;
	($zip->read($path) == AZ_OK) || die "Not a zip archive!\n";
	my $tf='extract.tmp';
	say "reading from zip";
	for my $file ($zip->memberNames) {
		#say "file $file";
		$zip->extractMemberWithoutPaths($file,$tf);
		my $newfile=new_name('extract.tmp');
		if ($cpy)  {
			copy $tf,"$target/$newfile.IMA" ; 
		} else {
			#say "move $tf, $target/$newfile.dcm" ; 
			move $tf,"$target/$newfile.IMA" ; 
		}
	}
} else {
	opendir( my $p ,$path) || die "Could not read from directory $path\n";
	say "reading from directory";
	for my $d (readdir ($p)) {
		my $dir="$path/$d";
		next if ($d eq '..' );
		next unless ((-d $dir) || ((-f $dir) && $dir=~m/.IMA$|.dcm$/)) ;
		opendir (my $dd ,$dir);
		for my $f (readdir ($dd)) {
			my $file="$dir/$f";
			next unless ((-f $file) && $file=~m/.IMA$|.dcm$/) ;
			my $newfile=new_name($file);
			if ($cpy)  {
				copy $file,"$target/$newfile.IMA" ; 
			} else {
				move $file,"$target/$newfile.IMA" ; 
			}
		}
		close $dd;
	}	
	close $p;
}
