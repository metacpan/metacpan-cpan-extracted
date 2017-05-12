#!perl
#
# Merges the PPD files from 2 or more directories containing
# PPD files for a particular architecture.
#
# e.g. 'mergePPDs.pl destdir MSWin32 linux solaris'
#

use XML::Parser;
use PPM::XML::PPMConfig;
use strict;

my $destdir = shift;

die "Usage: $0 destdir ppddir1 ppddir2 [ppddir3...]" unless $#ARGV >= 1;

mkdir($destdir, 0777) unless -d $destdir;

my %files;
foreach my $dir (@ARGV) {
    opendir(DIR, $dir) or die "Can't open $dir: $!";
    map { /\.ppd$/ && push(@{$files{$_}}, "$dir/$_") } readdir(DIR);
    closedir(DIR);
}

foreach my $file (sort keys %files) {
    my $parser = new XML::Parser(Style => 'Objects', Pkg => 'PPM::XML::PPD');
    my $basefile = shift (@{$files{$file}});
    my $baseppd = $parser->parsefile($basefile);

    print "Base file is: $basefile\n";

    foreach my $ppdfile (@{$files{$file}}) {
        my $ppd = $parser->parsefile($ppdfile);
        my $i = 0;

        print "Merging in: $ppdfile\n";
        foreach my $elem (@{$ppd->[0]->{Kids}}) {
            if((ref $elem) =~ /.*::IMPLEMENTATION$/) {
                splice(@{$baseppd->[0]->{Kids}}, $i, 0, $elem);
            }
            $i++;
        }
    }

    print "Writing file: $destdir/$file\n\n";
    open(FILE, ">$destdir/$file") or 
        die "Could not open $destdir/$file : $!";
    my $oldfh = select(FILE);
    my $Config_ref = bless($baseppd->[0], "PPM::XML::PPMConfig::SOFTPKG");
    $Config_ref->output();
    select($oldfh);
    close(FILE);
}
