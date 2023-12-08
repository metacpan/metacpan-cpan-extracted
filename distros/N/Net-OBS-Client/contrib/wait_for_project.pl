#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Net::OBS::Client::Project;

my $project    = 'OBS:Server:Unstable';
my $package    = 'obs-server';
my $repository = 'openSUSE_Factory';
my $arch       = 'x86_64';

my $p = Net::OBS::Client::Project->new(
  name       => $project,
  repository => $repository,
  arch       => $arch,
);

my $s= {result=>[{code=>''}]};

while ($s->{result}->[0]->{code} ne 'published') {
  my $d = {
    package => $package,
    multibuild => 1,
    locallink => 1,
  };
  $d->{oldstate} = $s->{state} if $s->{state};
  print "Fetching\n".Dumper($d);
  $s = $p->fetch_resultlist(%$d);
  print Dumper($p->dirty);
  print Dumper($p->code);
  print Dumper($s);
  sleep 1;
}


exit 0;
