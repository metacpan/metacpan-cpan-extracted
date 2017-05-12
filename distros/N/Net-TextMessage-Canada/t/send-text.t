#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'Net::TextMessage::Canada';
}

my $ntmc = Net::TextMessage::Canada->new;

my $providers = $ntmc->providers;
isa_ok $providers, 'ARRAY';
is scalar(@$providers), 8, '8 providers found';

is_deeply $providers->[0], {
    id => 'bell',
    name => 'Bell Canada',
}, 'provider list has correct format';


is $ntmc->to_email('bell', '6045551234'), '6045551234@txt.bell.ca',
    'to_email()';

done_testing();
exit;
