#!perl

# -*- perl -*-

use DateTime;
use URI;
use Path::Class;
use Test::More tests => 4;

use_ok('Store::Digest::Driver::FileSystem');

diag("DB version: $BerkeleyDB::db_version");

my $driver = Store::Digest::Driver::FileSystem->new(dir => 't/content');

my $mf = Path::Class::File->new('Makefile.PL');

my $stat = $mf->stat;

my $fh = $mf->openr;

my $obj = $driver->add(content => $fh, mtime => $stat->mtime);

diag($obj->as_string);

my @objs = $driver->get(URI->new('ni:///md5;lSF_'));
#my @objs = $driver->get(URI->new('ni:///sha-256;Icnx'));

ok(scalar @objs, 'successfully retrieved objects from partial match');

isa_ok($objs[0], 'Store::Digest::Object', 'retrieved object');

#diag($objs[0]->as_string);

my $stats = $driver->stats;

isa_ok($stats, 'Store::Digest::Stats', 'store stats');

diag($stats->as_string);
