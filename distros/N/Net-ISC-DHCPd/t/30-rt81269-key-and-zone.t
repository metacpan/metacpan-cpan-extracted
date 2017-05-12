use lib './lib';
use Net::ISC::DHCPd::Config;
use Test::More;
use strict;
use warnings;

my $config = Net::ISC::DHCPd::Config->new(fh => \*DATA);
is($config->parse, 16, 'Parsed 16 lines?');
is($config->keys->[0]->name, 'box', 'is key 0 name = box?');
is($config->keys->[1]->name, 'second key', 'key supports quoting and spaces');
is($config->keys->[0]->secret, '...', 'is key 0 secret = ...?');
is($config->keys->[1]->algorithm, 'hmac-md5', 'is key 2 algorithm = hmac-md5?');
is($config->zones->[0]->name, 'example.com', 'is zone 0 name = example.com?');
is($config->zones->[0]->key, 'secondkey', 'is zone 0 key = secondkey?');
is($config->zones->[0]->primary, '10.0.0.5', 'is zone 0 primary = 10.0.0.5?');
done_testing();


__DATA__
zone example.com
{
    primary 10.0.0.5;
    key secondkey;
}

key box {
    algorithm hmac-md5;
    secret "...";
};

# testing optional semicolon at end and brace on next line
key "second key"
{
    algorithm hmac-md5;
}
