#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Net::OBS::Client;

my $project = 'OBS:Server:Unstable';
my $package = 'obs-server';
my $repo    = 'openSUSE_Factory';
my $arch    = 'x86_64';

my $c   = Net::OBS::Client->new();
my $obj = $c->buildresults(
  project    => $project,
  package    => $package,
  repository => $repo,
  arch       => $arch,
);

my $bin = $obj->binarylist;

print Dumper($bin);

my @bla = grep { $_->{filename} =~ /^obs-server.*noarch\.rpm$/ } @$bin;
my $inf = $obj->fileinfo($bla[0]->{filename});
print Dumper($inf);

exit 1;
