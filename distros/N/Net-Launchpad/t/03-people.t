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

diag("testing people api");
# replace with the actual test
use_ok('Net::Launchpad::Client');


my $lp = Net::Launchpad::Client->new(consumer_key => $ENV{LP_CONSUMER_KEY},
                                    access_token => $ENV{LP_ACCESS_TOKEN},
                                    access_token_secret => $ENV{LP_ACCESS_TOKEN_SECRET});

use_ok('Net::Launchpad::Model');
my $model = Net::Launchpad::Model->new(lpc => $lp);

# person
my $person = $model->person('~adam-stokes');
ok($person->result->{name} eq 'adam-stokes', $person->result->{name} . " found correctly.");

use_ok('Net::Launchpad::Query');
my $query           = Net::Launchpad::Query->new(lpc => $lp);
my $person_by_email = $query->people->get_by_email('adam.stokes@ubuntu.com');
my $person_by_fuzzy = $query->people->find('adam.stokes');
ok( $person_by_fuzzy->result->{total_size} == 1,
    "a least one 'adam.stokes' found correctly."
);
ok( $person_by_email->result->{name} eq 'adam-stokes',
    $person_by_email->result->{name} . " found correctly."
);

done_testing;
