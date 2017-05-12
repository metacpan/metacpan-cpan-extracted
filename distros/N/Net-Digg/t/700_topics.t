# -*- perl -*-

# t/700_topics.t - check topics endpoint

use Test::Simple tests => 1;
use Net::Digg;
use Data::Dumper;

my $digg = Net::Digg->new();
my $result = $digg->get_topics();

ok(defined $result->{'topics'}[0]->{'name'} );
