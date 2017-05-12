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
done_testing();

__DATA__
authoritative;
authoritative ;
default-lease-time 2592000;
preferred-lifetime 604800;
