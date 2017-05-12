#!perl -T
use warnings;
use strict;

use Test::More tests => 1;
use Data::Dumper;

use lib qw( t t/lib ./lib );
use MEmployee;
BEGIN { inherit MEmployee }

print <<ZZZ;
---------
    MPerson::EXPORT_OK:        (@MPerson::EXPORT_OK)
    MWorker::EXPORT_OK:        (@MWorker::EXPORT_OK)
    MEmployee::EXPORT_OK:      (@MEmployee::EXPORT_OK)
    MPerson::EXPORT:           (@MPerson::EXPORT)
    MWorker::EXPORT:           (@MWorker::EXPORT)
    MEmployee::EXPORT:         (@MEmployee::EXPORT)
    MPerson::EXPORT_INHERIT:   (@MPerson::EXPORT_INHERIT)
    MWorker::EXPORT_INHERIT:   (@MWorker::EXPORT_INHERIT)
    MEmployee::EXPORT_INHERIT: (@MEmployee::EXPORT_INHERIT)
---------
ZZZ

print "MPerson::USERNAME_mk_st:   $MPerson::USERNAME_mk_st\n";
print "MEmployee::USERNAME_mk_st: $MEmployee::USERNAME_mk_st\n";
print "\@MPerson::ISA: ", Dumper(\@MPerson::ISA), "\n";

ok( 1, 'Test placeholder' );    # Test::More wants at least one test

