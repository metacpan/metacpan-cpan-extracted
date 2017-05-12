#!/usr/bin/perl
use strict;
use warnings;
use DBM::Deep;
use File::Spec;
use Cwd;
my $file = shift @ARGV or die;
my $zip = 0;
if ($file =~ /\.zip$/i) {
    $zip = 1;
    my ($v,$p,$f) = File::Spec->splitpath($file);
    my $dir = Cwd::cwd();
    chdir($p);
    system('unzip', $f);
    chdir $dir;
    $file =~ s/\.zip$//i;
}
tie my %hash => 'DBM::Deep', $file;
use Data::Dumper;
print Dumper \%hash;
if ($zip) {
    unlink($file);
}
