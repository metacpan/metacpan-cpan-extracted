#!perl

use Test::More tests => 5;
use File::Compare;
use utf8;

BEGIN {
    use_ok( 'OpenOffice::Wordlist' );
}

-d "t" && chdir "t";

my $dict = OpenOffice::Wordlist->new->read("wbswg6.dic");
$dict->write("test6.dic");
ok( !compare("wbswg6.dic", "test6.dic"), "C R6 W6" );

$dict->write("test5.dic", 'WBSWG5' );
ok( !compare("wbswg5.dic", "test5.dic"), "C R6 W5" );

$dict = OpenOffice::Wordlist->new(type => 'WBSWG5')->read("wbswg5.dic");
$dict->write("test5.dic");
ok( !compare("wbswg5.dic", "test5.dic"), "C5 R5 W5" );

$dict = OpenOffice::Wordlist->new(type => 'WBSWG6')->read("wbswg5.dic");
$dict->write("test6.dic");
ok( !compare("wbswg6.dic", "test6.dic"), "C6 R5 W6" );

