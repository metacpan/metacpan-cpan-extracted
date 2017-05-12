#!/usr/bin/perl
#for building, fake the location of a RT install
use strict;
use warnings;
use File::Temp qw/tempdir/;
use File::Spec;
my $dir = tempdir();
my $libFile = File::Spec->catfile($dir, "RT.pm");
if(open(PM, ">$libFile")){
	print PM "package RT;\n";
	print PM "our \$LocalPath = '$dir';\n";
	print PM "return 1;\n";
	close(PM);
}
else{
	die("Can't create lib file: $libFile: $!\n");
}
print "RT lib location: $dir\n";
exit(0);