use strict;
use warnings;
use Test::More tests => 2;
use Net::Drizzle ':constants';

my $c1 = Net::Drizzle::Connection->new()
                                 ->set_data('c1');
my $c2 = Net::Drizzle::Connection->new()
                                 ->set_data('c2');

is $c2->data, 'c2', $c2;
is $c1->data, 'c1', $c1;
