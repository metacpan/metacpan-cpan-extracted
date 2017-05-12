#!/usr/bin/perl -w
# $Id: 03indexing.t,v 1.4 2002/04/28 23:42:21 piers Exp $
use strict;
use lib qw(./lib ../lib);
use Test::More;
use Cwd;
use File::Spec::Functions;
use Module::Dependency::Info;
BEGIN { plan tests => 26; }

my $dir = cwd();
if (-d 't') { $dir = catfile( $dir, 't'); }
my $index = catfile( $dir, 'dbindext.dat' );
my $index2 = catfile( $dir, 'dbindex2.dat' );

ok( $dir );
ok( $index );

if ( -f $index ) {
	ok(1);
} else {
	for (3..26) { ok(1); }
	warn( "You need to run all the tests in order! $index not found, so skipping tests!" );
	exit;
}

Module::Dependency::Info::setIndex( $index );
ok( Module::Dependency::Info::retrieveIndex );

is( scalar @{ Module::Dependency::Info::allItems() }, 19 );
ok( Module::Dependency::Info::allScripts()->[1] =~ m/(x.pl|y.pl|z.cgi)/ );

my $i = Module::Dependency::Info::getItem('d');
use Data::Dumper;
print Dumper($i);
ok( $i->{'filename'} =~ m|d\.pm| );
is $i->{'package'}, 'd';
is join(' ', sort @{$i->{'depended_upon_by'}}), 'a b c';
is join(' ', sort @{$i->{'depends_on'}}), 'f g h lib';

like Module::Dependency::Info::getFilename('f'), '/f\.pm$/';
is Module::Dependency::Info::getChildren('f')->[0], 'strict';
is Module::Dependency::Info::getParents('f')->[0], 'd';

ok( Module::Dependency::Info::dropIndex() );
ok( ! defined( $Module::Dependency::Info::UNIFIED ) );

# implicit load - only need one test
ok( Module::Dependency::Info::getParents('f')->[0] eq 'd');

# bad data
ok( ! defined( Module::Dependency::Info::getItem('floop') ) );
ok( ! defined( Module::Dependency::Info::getFilename('floop') ) );
ok( ! defined( Module::Dependency::Info::getChildren('floop') ) );
ok( ! defined( Module::Dependency::Info::getParents('floop') ) );

Module::Dependency::Info::setIndex( $index2 );
ok( Module::Dependency::Info::getFilename('f') =~ m|f\.pm$|);
ok( Module::Dependency::Info::getChildren('f')->[0] eq 'strict');
ok( Module::Dependency::Info::getParents('f')->[0] eq 'd');

my $rv;
$rv = Module::Dependency::Info::relationship('./z.cgi', 'a');
ok( $rv eq 'NONE');
#print "$rv\n";

$rv = Module::Dependency::Info::relationship('b', 'e');
ok( $rv eq 'CHILD');
#print "$rv\n";

$rv = Module::Dependency::Info::getChildren('b');
my $j = join('', @$rv);
ok($j =~ m/Oberheim/);
#print $j, "\n";


# right, that's tested the Indexing system
