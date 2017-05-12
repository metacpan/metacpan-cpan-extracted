#!/usr/bin/perl -w
# $Id: 02indexer.t,v 1.2 2002/04/01 11:17:14 piers Exp $
use strict;
use lib qw(./lib ../lib);
use Test;
use Cwd;
use File::Spec::Functions;
use Module::Dependency::Indexer;
BEGIN { plan tests => 11; }

my $dir = cwd();
if (-d 't') {
	$dir = catfile( $dir, 't');
}

my $index = catfile( $dir, 'dbindext.dat' );
my $index2 = catfile( $dir, 'dbindex2.dat' );
my $tree = catfile( $dir, 'u' );

#print "$dir\n$index\n$tree\n";

ok( $dir );
ok( $index );
ok( $tree );

if ( -f $index ) { unlink($index); }
if ( -f $index2 ) { unlink($index2); }
ok( ! -f $index );
ok( ! -f $index2 );

ok( Module::Dependency::Indexer::setIndex( $index ) );
ok( Module::Dependency::Indexer::makeIndex( $tree ) );

ok( -f $index );

ok( Module::Dependency::Indexer::setIndex( $index2 ) );
ok( Module::Dependency::Indexer::makeIndex( $tree ) );

ok( -f $index2 );

