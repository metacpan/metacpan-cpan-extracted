# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 3;
BEGIN { use_ok('Net::Friends') };

#########################

my $friends = Net::Friends->new('localhost');

ok( defined $friends, 'new() returned something');
ok( $friends->isa('Net::Friends'), "and it's the right class");

# vim: syntax=perl

