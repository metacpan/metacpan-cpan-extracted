use strict;
use warnings;
use Test::More tests => 2;
use PlugAuth::Client::Tiny;

my $client = eval { PlugAuth::Client::Tiny->new({url => 'http://1.2.3.4/booger/auth/'}) };
diag $@ if $@;
isa_ok $client, 'PlugAuth::Client::Tiny';

is eval { $client->url }, 'http://1.2.3.4/booger/auth/', 'non default url';
diag $@ if $@;
