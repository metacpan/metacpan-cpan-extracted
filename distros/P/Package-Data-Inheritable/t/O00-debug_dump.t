#!perl -T
use warnings;
use strict;

use Test::More tests => 1;
use Data::Dumper;

use lib qw( t t/lib ./lib );
#use OPerson;    # do not use if you want to check proper call of import() via use base
#use OWorker;    # do not use if you want to check proper call of import() via use base
use OEmployee;
BEGIN { inherit OEmployee }

print <<ZZZ;
---------
    OPerson::EXPORT_OK:        (@OPerson::EXPORT_OK)
    OWorker::EXPORT_OK:        (@OWorker::EXPORT_OK)
    OEmployee::EXPORT_OK:      (@OEmployee::EXPORT_OK)
    OPerson::EXPORT:           (@OPerson::EXPORT)
    OWorker::EXPORT:           (@OWorker::EXPORT)
    OEmployee::EXPORT:         (@OEmployee::EXPORT)
    OPerson::EXPORT_INHERIT:   (@OPerson::EXPORT_INHERIT)
    OWorker::EXPORT_INHERIT:   (@OWorker::EXPORT_INHERIT)
    OEmployee::EXPORT_INHERIT: (@OEmployee::EXPORT_INHERIT)
---------
ZZZ

print "OPerson::USERNAME_mk_st:   $OPerson::USERNAME_mk_st\n";
print "OEmployee::USERNAME_mk_st: $OEmployee::USERNAME_mk_st\n";
print "\@OPerson::ISA: ", Dumper(\@OPerson::ISA), "\n";

ok( 1, 'Test placeholder' );    # Test::More wants at least one test

