#!/usr/bin/perl
#-*-perl-*-

use FindBin qw( $Bin );
use lib $Bin. '/../lib';

use Test::More;
use File::Compare;

my $SCRIPTS = $Bin.'/../scripts/convert';
my $DATA    = $Bin.'/xml';

my $null = "2> /dev/null >/dev/null";

system("$SCRIPTS/opus2multi $DATA sv de en es fr $null");
is( compare( "sv-de.xml", "$DATA/sv-de.xml" ),0, "multilingual corpus (sv-de)" );
is( compare( "sv-en.xml", "$DATA/sv-en.xml" ),0, "multilingual corpus (sv-en)" );
is( compare( "sv-es.xml", "$DATA/sv-es.xml" ),0, "multilingual corpus (sv-es)" );
is( compare( "sv-fr.xml", "$DATA/sv-fr.xml" ),0, "multilingual corpus (sv-fr)" );

system("$SCRIPTS/opus2moses -r -d $DATA -e test.sv1 -f test.de < sv-de.xml $null");
system("$SCRIPTS/opus2moses -r -d $DATA -e test.sv2 -f test.en < sv-en.xml $null");
system("$SCRIPTS/opus2moses -r -d $DATA -e test.sv3 -f test.es < sv-es.xml $null");
system("$SCRIPTS/opus2moses -r -d $DATA -e test.sv4 -f test.fr < sv-fr.xml $null");

is( compare( "test.sv1", "test.sv2" ),0, "identical source (sv-de & sv-en)" );
is( compare( "test.sv1", "test.sv3" ),0, "identical source (sv-de & sv-es)" );
is( compare( "test.sv1", "test.sv4" ),0, "identical source (sv-de & sv-fr)" );

unlink('sv-de.xml');
unlink('sv-en.xml');
unlink('sv-es.xml');
unlink('sv-fr.xml');

unlink('test.sv1');
unlink('test.sv2');
unlink('test.sv3');
unlink('test.sv4');

unlink('test.de');
unlink('test.en');
unlink('test.es');
unlink('test.fr');

done_testing;

