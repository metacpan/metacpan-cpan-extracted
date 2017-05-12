use Net::ISC::DHCPd::Config;
use Test::More;
use warnings;
use strict;

my $config = Net::ISC::DHCPd::Config->new(fh => \*DATA);

is($config->parse, 15, 'Parsed 15 lines in config file.');
my @subnets;

is(@subnets = $config->find_all_children('subnets'), 3, 'Found 3 subnets');
is($subnets[1]->address, '127.0.2.0/24', 'Second address is correct');

done_testing();

__DATA__
subnet 127.0.0.0 netmask 255.255.255.0 {

}

shared-network "snow" {
    subnet 127.0.2.0 netmask 255.255.255.0 {
    }
}

group {
    shared-network shared {
        subnet 127.0.3.0 netmask 255.255.255.0 {
        }
    }
}
