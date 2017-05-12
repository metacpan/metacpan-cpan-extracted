use strict;
use warnings;
use Test::More tests => 2;
use PlugAuth::Client;

ok(PlugAuth::Client->can('_remove_prefixes'), 'private method _remove_prefixes');

is_deeply([PlugAuth::Client::_remove_prefixes(qw( /usr /usr/local /usr/X11 /opt ))], [sort qw( /usr /opt )], "_remove_prefixes returned correct");
