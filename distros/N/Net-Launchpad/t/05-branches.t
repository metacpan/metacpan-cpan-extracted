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

diag("testing branches api");

# replace with the actual test
use_ok('Net::Launchpad::Client');


my $lp = Net::Launchpad::Client->new(
    consumer_key        => $ENV{LP_CONSUMER_KEY},
    access_token        => $ENV{LP_ACCESS_TOKEN},
    access_token_secret => $ENV{LP_ACCESS_TOKEN_SECRET}
);

use_ok('Net::Launchpad::Model');
my $model = Net::Launchpad::Model->new(lpc => $lp);

# branch
my $branch = $model->branch('~adam-stokes', '+junk', 'cloud-installer');
ok($branch->result->{branch_type} eq 'Hosted', 'branch type found');

use_ok('Net::Launchpad::Query');
my $query = Net::Launchpad::Query->new(lpc => $lp);
my $branch_q_uniq_name =
  $query->branches->get_by_unique_name('~adam-stokes/+junk/cloud-installer');
ok( $branch_q_uniq_name->result->{unique_name} eq
      '~adam-stokes/+junk/cloud-installer',
    "Queried ".$branch_q_uniq_name->result->{unique_name}. " properly"
);

done_testing;
