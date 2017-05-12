#!/usr/bin/perl

# this file takes the solstice code base (by default), copies it to a tmp folder, removes all the .svn directories, and stores it into a tarball

use strict;
use warnings;

unless(defined $ARGV[0] && $ARGV[0]){
    print "Usage:\ntar.pl tarballpath packagepath1 packagepath2\n";
    exit;
}

my $destination = $ARGV[0];

# either i can specify the install path here, or use a use lib line, specify it there, and use solstice configure to
# get the path, for this small script, this is the better solution
# XXX change this line as needed
my $solstice_install = '/home/jdr99/solstice/';

# we need to remove all .svn directories, so we need to copy the files to a tmp directory
my $temp_folder = '/tmp/tarball_tmp';

# first lets make sure we have a clean start
if (-e $temp_folder){
    print 'deleting temp files for start fresh \n';
    `rm -rf $temp_folder`;
}

mkdir $temp_folder;

my @packages;
my $i=1;
while(defined $ARGV[$i] && $ARGV[$i]){
    warn $ARGV[$i];
    push @packages , $ARGV[$i];
    $i++;
}

#just pack up solstice if no other packages have been passed in
unless (defined @packages) {
    push @packages , $solstice_install;
}

foreach my $package (@packages){
    `cp -rf $package $temp_folder`;
}

#remove all svn directories
`find $temp_folder -name .svn -exec rm -rf {} \\; >& /dev/null`;

#create the tarball
`tar -cvf $destination $temp_folder`;

exit;

