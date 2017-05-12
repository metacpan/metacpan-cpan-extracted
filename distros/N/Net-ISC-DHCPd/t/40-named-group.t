use Net::ISC::DHCPd::Config;
use Test::More;
use warnings;

# without this it seeks back to beginning of the perl script
my $data_pos = tell DATA;
my $output = do { local($/); <DATA> };
seek DATA, $data_pos, 0;

my $config = Net::ISC::DHCPd::Config->new(fh => \*DATA);
is($config->parse, 9, 'Parsed 9 lines?');
is($config->groups->[0]->name, 'Hello', 'testing quoted named groups');
is($config->groups->[1]->name, 'not-quoted2', 'named group that is unquoted with dashes and number');
is($config->groups->[2]->name, 'With Spaces', 'testing spaces in name');
ok(defined($config->groups->[3]), 'Do unnamed groups still work?');
is($config->generate, $output, 'Does generated config match input?');
done_testing();

__DATA__
group "Hello" {
}
# numbers should work as well as dashes
group not-quoted2 {
}
group "With Spaces" {
}
group {
}
