#!perl
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Net::RCON::Minecraft')
        or BAIL_OUT('use failed. No point continuing.');
}

diag "Testing Net::RCON::Minecraft $Net::RCON::Minecraft::VERSION, Perl $]";
