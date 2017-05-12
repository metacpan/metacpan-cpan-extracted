#!/usr/bin/env perl 

use 5.8.0;
use strict;
use warnings;

use NetSDS::Util::Convert;
use NetSDS::Util::String;

use NetSDS::Queue;
use Data::Dumper;

my $q = NetSDS::Queue->new();

my $data = {
	from => '380671112233',
	to => '1234',
	text => 'Test message'x200,
};

for (my $i = 1; $i < 100; $i++) {
$q->push('test_queue.1', $data);
my $res = $q->pull('test_queue.1');
if ($i % 10 == 0) { print Dumper($res); } 
}

print Dumper($q);

1;
