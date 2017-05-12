#!/usr/bin/perl -w
use strict;
use PBS::Client;
use Test::More (tests => 1);

#----------------------------------------
# Test copying job
#----------------------------------------

my $fail = 0;
my $oJob = PBS::Client::Job->new(
    mem   => '600mb',
    nodes => 1,
);

#----------------------
# Copy without argument
my $nJob = $oJob->copy;
$fail = 1 if ($nJob->{mem} ne '600mb' || $nJob->{nodes} ne 1);

$oJob->nodes(2);
$fail = 1 if ($oJob->{nodes} ne 2 || $nJob->{nodes} ne 1);

$nJob->nodes(10);
$fail = 1 if ($oJob->{nodes} ne 2 || $nJob->{nodes} ne 10);
#----------------------

#---------------------
# Make multiple copies
my @nJob = $oJob->copy(2);
$fail = 1 if (@nJob ne 2);
$fail = 1 if ($nJob[0]->{mem} ne '600mb' || $nJob[0]->{nodes} ne 2);
$fail = 1 if ($nJob[1]->{mem} ne '600mb' || $nJob[1]->{nodes} ne 2);

$oJob->nodes(1);
$fail = 1 if ($oJob->{nodes} ne 1 || $nJob[0]->{nodes} ne 2 ||
    $nJob[1]->{nodes} ne 2);

$nJob[0]->nodes(10);
$fail = 1 if ($oJob->{nodes} ne 1 || $nJob[0]->{nodes} ne 10 ||
    $nJob[1]->{nodes} ne 2);

$nJob[1]->nodes(20);
$fail = 1 if ($oJob->{nodes} ne 1 || $nJob[0]->{nodes} ne 10 ||
    $nJob[1]->{nodes} ne 20);
#---------------------

is($fail, 0, "copying job object");
