#!/usr/bin/perl

# Requires p2e from App::Packer

# Par::Packer might work better:
# http://par.wikia.com/wiki/Main_Page

my @stubs = qw/
cubic2erect
enblend-mask
enblend-svg
enfuse-mask
erect2cubic
erect2mercator
erect2planet
erect2qtvr
gigastart
gigatile
gmaptemplate
jpeg2qtvr
match-n-shift
nona-mask
pafextract
panostart
process-masks
pto2mk2
ptoanchor
ptobind
ptocentre
ptochain
ptoclean
ptodouble
ptodummy
ptofill
ptoget
ptohalve
ptoinfo
ptomerge
ptopath
ptoset
ptosort
ptosplit
ptovariable
ptsed
ptscluster
qtvr2erect
tif2svg
transform-pano/;

for my $stub (@stubs)
{
    system ('copy', "bin\\$stub", "$stub.pl");
    system ('p2e', '--add-module=Win32', '--add-module=File::Spec::Win32', "--output-file=$stub.exe", "$stub.pl"); 
    unlink ("$stub.pl");
}
