#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper::Concise;
use Moose::Util qw(does_role);

plan skip_all => 'must export launchpad credentials to enable these tests'
  unless $ENV{LP_CONSUMER_KEY}
  && $ENV{LP_ACCESS_TOKEN}
  && $ENV{LP_ACCESS_TOKEN_SECRET};

diag("testing projects api");
# replace with the actual test
use_ok('Net::Launchpad::Client');


my $lp = Net::Launchpad::Client->new(consumer_key => $ENV{LP_CONSUMER_KEY},
                                    access_token => $ENV{LP_ACCESS_TOKEN},
                                    access_token_secret => $ENV{LP_ACCESS_TOKEN_SECRET});

use_ok('Net::Launchpad::Model');
my $model = Net::Launchpad::Model->new(lpc => $lp);

my $project = $model->project('sosreport');
ok($project->result->{name} eq 'sosreport', $project->result->{name} . " found correctly.");

use_ok('Net::Launchpad::Query');
my $query = Net::Launchpad::Query->new(lpc => $lp);
my $project_search =
  $query->projects->search('sosreport');
ok( $project_search->result->{total_size} >= 1, 'Found 1 or more projects for sosreport');

done_testing();
