#!/usr/bin/env perl

use warnings;
use strict;

use Test::Chimps::Client;
use Test::TAP::Model::Visual;
use Getopt::Long;

my $server;
my $tests = "t/*.t t/*/*.t";

my $result = GetOptions("server|s=s", \$server,
                        "tests|t=s", \$tests);

if (! $result) {
  print "Error during argument processing\n";
  exit 1;
}

if (! defined $server) {
  print "You must specify a server to upload results to\n";
  exit 1;
}

print "running tests\n";
my $model = Test::TAP::Model::Visual->new_with_tests(glob($tests));

my $duration = $model->structure->{end_time} - $model->structure->{start_time};

my $client = Test::Chimps::Client->new(
  model  => $model,
  server => $server,
  {
# put the variables your Chimps server requires below
#     project   => $project,
#     revision  => $revision,
#     committer => $committer,
#     duration  => $duration,
#     osname    => $Config{osname},
#     osvers    => $Config{osvers},
#     archname  => $Config{archname}
  }
);

my ($status, $msg) = $client->send;

if (! $status) {
  print "Error: $msg\n";
  exit(1);
}
