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

diag("Testing distributions api");

# replace with the actual test
use_ok('Net::Launchpad::Client');


my $lp = Net::Launchpad::Client->new(consumer_key => $ENV{LP_CONSUMER_KEY},
                                    access_token => $ENV{LP_ACCESS_TOKEN},
                                    access_token_secret => $ENV{LP_ACCESS_TOKEN_SECRET});

use_ok('Net::Launchpad::Model');
my $model = Net::Launchpad::Model->new(lpc => $lp);


my $distro = $model->distribution('ubuntu');
ok(does_role($distro, 'Net::Launchpad::Role::Distribution'), 'has distribution role');
ok ($distro->result->{name} eq 'ubuntu', 'found distribution name in result');

done_testing;
