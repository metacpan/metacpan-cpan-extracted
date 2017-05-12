use strict;
use warnings;

use Test::More;

BEGIN{ use_ok 'Net::Hadoop::HuahinManager'; }
require_ok 'Net::Hadoop::HuahinManager';

subtest 'new' => sub {
    my $client = Net::Hadoop::HuahinManager->new(server => 'localhost');
    is ($client->{server}, 'localhost');
    is ($client->{port}, 9010);
    is ($client->{timeout}, 10);
};

done_testing;
