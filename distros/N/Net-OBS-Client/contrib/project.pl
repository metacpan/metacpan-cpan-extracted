#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Net::OBS::Client;

$::ENV{NET_OBS_DEBUG} = 1;

my $project = 'OBS:Server:Unstable';
my $package = 'obs-server';
my $repo    = 'openSUSE_Factory';
my $arch    = 'x86_64';

my $c = Net::OBS::Client->new(
  use_oscrc  => 0,
);

my $prj = $c->project(name=>$project, repository=>$repo, arch=>$arch);
my $s = $prj->fetch_resultlist(package => $package);

print Dumper($s);

print "code: ".$prj->code($repo, $arch)."\n";
print "dirty: ".$prj->dirty($repo, $arch)."\n";

exit 0;
