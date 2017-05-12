use Net::ISC::DHCPd::Config;
use Test::More;
use warnings;

# without this it seeks back to beginning of the perl script
my $data_pos = tell DATA;
my $input = do { local($/); <DATA> };
seek DATA, $data_pos, 0;

my $config = Net::ISC::DHCPd::Config->new(fh => \*DATA);
is($config->parse, 4, 'Parsed 4 lines?');
is($config->generate, $input, 'Does generated config match input?');
is(scalar(@_=$config->subnets->[0]->ranges), 2, 'Did we find two ranges?');
done_testing();

__DATA__
subnet 127.0.0.0 netmask 255.255.255.0 {
    range 127.0.0.1;
    range 127.0.0.2 127.0.0.5;
}
