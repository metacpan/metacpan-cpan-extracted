use Net::ISC::DHCPd::Config;
use Test::More;
use warnings;

# without this it seeks back to beginning of the perl script
my $data_pos = tell DATA;
my $output = do { local($/); <DATA> };
seek DATA, $data_pos, 0;

my $config = Net::ISC::DHCPd::Config->new(fh => \*DATA);
is($config->parse, 12, 'Parsed all lines?');
is($config->sharednetworks->[0]->name, 'Hello', 'testing quoted named sharednetworks');
is($config->sharednetworks->[1]->name, 'not-quoted2', 'named sharednetwork that is unquoted with dashes and number');
is($config->sharednetworks->[2]->name, 'With Spaces', 'testing spaces in name');
is($config->sharednetworks->[4]->name, 'prefix-192.0.2.0', 'testing periods in name');
ok(defined($config->sharednetworks->[3]), 'Do unnamed sharednetworks still work?');
is($config->generate, $output, 'Does generated config match input?');
done_testing();

__DATA__
shared-network "Hello" {
}
# numbers should work as well as dashes
shared-network not-quoted2 {
}
shared-network "With Spaces" {
}
shared-network {
}
# gh#20 lines like prefix-192.0.2.0
shared-network prefix-192.0.2.0 {
}
