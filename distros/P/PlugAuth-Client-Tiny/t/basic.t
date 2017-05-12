use strict;
use warnings;
use Test::More tests => 2;
use PlugAuth::Client::Tiny;

my $client = eval { PlugAuth::Client::Tiny->new };
diag $@ if $@;
isa_ok $client, 'PlugAuth::Client::Tiny';

is eval { $client->url }, 'http://localhost:3000/', 'default url';
diag $@ if $@;
