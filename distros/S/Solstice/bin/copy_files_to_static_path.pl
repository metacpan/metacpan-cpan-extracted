#!/usr/bin/perl

use strict;
use warnings;

use File::Path;
use Solstice::Configure;

unless(defined $ARGV[0] && $ARGV[0]){
    print "Usage:\ncopy_files_to_static_path.pl /path/to/destination/\n";
    exit;
}

my $config = Solstice::Configure->new();    
my $virtual_root = $config->getVirtualRoot();
my $static_dirs = $config->getStaticDirs();

my $main_content_dir = $ARGV[0];

#check to ensure that the main directory exists, and attempt to create it if it does not exist
die "static server path already exists" if -e $main_content_dir;    

mkpath($main_content_dir .'/'.$virtual_root) or die "dead creating the main content directory:$!";
    

foreach my $destination (keys %$static_dirs){
    my $paths = $static_dirs->{$destination};

    #grab the app_directory if one exists
    $destination =~ /\/$virtual_root\/(.*)\/.*\//;
    my $app_dir = $1;
    
    #strip the virtual root
    $destination =~    s/^\/$virtual_root\///;
    
    $destination = $main_content_dir .'/'. $destination;
    
    #copy files
    mkpath($destination);
    my $source = $paths->{'filesys_path'};
    warn "$source -> $destination";
    `cp -r $source/* $destination`;
}

`find $main_content_dir -name .svn -exec rm -rf {} \\; >& /dev/null`;

exit;
