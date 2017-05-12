use warnings;
use strict;
use Net::ISC::DHCPd::Config;
use Test::More;

# without this it seeks back to beginning of the perl script
my $data_pos = tell DATA;
my $output = do { local($/); <DATA> };
seek DATA, $data_pos, 0;

my $config = Net::ISC::DHCPd::Config->new(fh => \*DATA);
is($config->parse, 3, 'Parsed 3 lines?');
is($config->generate, $output, 'Is output = input?');
done_testing();


__DATA__
option space cable-labs;
option cable-labs.tsp-primary-dhcp-server code 1 = ip-address;
option cable-labs.tsp-secondary-dhcp-server code 2 = ip-address;
