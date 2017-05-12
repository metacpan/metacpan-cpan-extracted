#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use PkgForge::Job;

my $job = PkgForge::Job->new( bucket => 'foo' );

isa_ok $job, 'PkgForge::Job';

my @available = (
   { name => 'sl5', arch => 'i386',   auto => 1 },
   { name => 'sl5', arch => 'x86_64', auto => 1 },
   { name => 'sl6', arch => 'i386',   auto => 0 },
   { name => 'sl6', arch => 'x86_64', auto => 0 },
   { name => 'f13', arch => 'i386',   auto => 1 },
   { name => 'f13', arch => 'x86_64', auto => 1 },
);

my @auto = (
  [ 'f13', 'i386' ],
  [ 'f13', 'x86_64' ],
  [ 'sl5', 'i386' ], 
  [ 'sl5', 'x86_64' ],
);

my @auto_i386 = (
  [ 'f13', 'i386' ],
  [ 'sl5', 'i386' ], 
);

my @all = (
  [ 'f13', 'i386' ],
  [ 'f13', 'x86_64' ],
  [ 'sl5', 'i386' ],
  [ 'sl5', 'x86_64' ],
  [ 'sl6', 'i386' ],
  [ 'sl6', 'x86_64' ],
);

my @all_i386 = (
  [ 'f13', 'i386' ],
  [ 'sl5', 'i386' ],
  [ 'sl6', 'i386' ],
);

$job->platforms(['auto']);
$job->archs(['all']);
my @wanted1 = $job->process_build_targets(@available);
is_deeply \@wanted1, \@auto;

$job->platforms(['all']);
$job->archs(['all']);
my @wanted2 = $job->process_build_targets(@available);
is_deeply \@wanted2, \@all;

$job->platforms(['auto']);
$job->archs(['i386']);
my @wanted3 = $job->process_build_targets(@available);
is_deeply \@wanted3, \@auto_i386;

$job->platforms(['all']);
$job->archs(['i386']);
my @wanted4 = $job->process_build_targets(@available);
is_deeply \@wanted4, \@all_i386;

$job->platforms(['auto']);
$job->archs(['i386','x86_64']);
my @wanted5 = $job->process_build_targets(@available);
is_deeply \@wanted5, \@auto;

$job->platforms(['all']);
$job->archs(['i386','x86_64']);
my @wanted6 = $job->process_build_targets(@available);
is_deeply \@wanted6, \@all;

my @all_not_sl6 = (
  [ 'f13', 'i386' ],
  [ 'f13', 'x86_64' ],
  [ 'sl5', 'i386' ],
  [ 'sl5', 'x86_64' ],
);

$job->platforms(['all','!sl6']);
$job->archs(['all']);
my @wanted7 = $job->process_build_targets(@available);
is_deeply \@wanted7, \@all_not_sl6;

my @all_not_i386 = (
  [ 'f13', 'x86_64' ],
  [ 'sl5', 'x86_64' ],
  [ 'sl6', 'x86_64' ],
);

$job->platforms(['all']);
$job->archs(['all','!i386']);
my @wanted8 = $job->process_build_targets(@available);
is_deeply \@wanted8, \@all_not_i386;

my @auto_not_sl5 = (
  [ 'f13', 'i386' ],
  [ 'f13', 'x86_64' ],
);

$job->platforms(['auto','!sl5']);
$job->archs(['all']);
my @wanted9 = $job->process_build_targets(@available);
is_deeply \@wanted9, \@auto_not_sl5;

my @auto_not_i386 = (
  [ 'f13', 'x86_64' ],
  [ 'sl5', 'x86_64' ],
);

$job->platforms(['auto']);
$job->archs(['all','!i386']);
my @wanted10 = $job->process_build_targets(@available);
is_deeply \@wanted10, \@auto_not_i386;

$job->platforms(['auto','foo']);
$job->archs(['all']);
my @wanted11 = $job->process_build_targets(@available);
is_deeply \@wanted11, \@auto;

$job->platforms(['auto','!foo']);
$job->archs(['all']);
my @wanted12 = $job->process_build_targets(@available);
is_deeply \@wanted12, \@auto;

$job->platforms(['auto']);
$job->archs(['all','foo']);
my @wanted13 = $job->process_build_targets(@available);
is_deeply \@wanted13, \@auto;

$job->platforms(['auto']);
$job->archs(['all','!foo']);
my @wanted14 = $job->process_build_targets(@available);
is_deeply \@wanted14, \@auto;

$job->platforms(['auto','sl6']);
$job->archs(['all']);
my @wanted15 = $job->process_build_targets(@available);
is_deeply \@wanted15, \@all;

$job->platforms(['!sl5']);
$job->archs(['all']);
my @wanted16 = $job->process_build_targets(@available);
is_deeply \@wanted16, \@auto_not_sl5;

$job->platforms(['auto']);
$job->archs(['!i386']);
my @wanted17 = $job->process_build_targets(@available);
is_deeply \@wanted17, \@auto_not_i386;

done_testing;
