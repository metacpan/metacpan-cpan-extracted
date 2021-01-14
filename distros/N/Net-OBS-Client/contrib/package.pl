#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Net::OBS::Client;

my $c = Net::OBS::Client->new(
);

my $pkg = $c->package(
  project    => 'OBS:Server:Unstable',
  name       => 'obs-server',
  repository => 'openSUSE_Factory',
  arch       => 'x86_64',
);

my $s = $pkg->fetch_status();

print Dumper($s);

my $repo    = 'openSUSE_Factory';
my $arch    = 'x86_64';

print "code: ".$pkg->code($repo, $arch)."\n";


exit 0;
