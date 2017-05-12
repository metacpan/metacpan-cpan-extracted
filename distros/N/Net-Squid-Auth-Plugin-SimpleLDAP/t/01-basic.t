#!perl -T

use Test::More tests => 2;

use Net::Squid::Auth::Plugin::SimpleLDAP;

my $p1 = eval { Net::Squid::Auth::Plugin::SimpleLDAP->new() };
ok( !defined($p1) );

my $p2 = Net::Squid::Auth::Plugin::SimpleLDAP->new(
    { binddn => 1, bindpw => 2, basedn => 3, server => 4 } );
ok( defined($p2) );
