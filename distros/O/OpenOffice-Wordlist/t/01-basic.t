#!perl

use Test::More tests => 3;
use File::Compare;
use utf8;

BEGIN {
    use_ok( 'OpenOffice::Wordlist' );
}

-d "t" && chdir "t";

my $dict = OpenOffice::Wordlist->new
  ( type => "WBSWG6", language => 2057, neg => 0 );
$dict->append( qw(Arial CAcert CAcert.org Cacert.org Joan's
		  Pántone Vèrdana org www.cacert.org) );
$dict->write("test6.dic");
ok( !compare("wbswg6.dic", "test6.dic"), "create WBSWG6 dict" );

$dict = OpenOffice::Wordlist->new
  ( type => "WBSWG5", language => 2057, neg => 0 );
$dict->append( qw(Arial CAcert CAcert.org Cacert.org Joan's
		  Pántone Vèrdana org www.cacert.org) );
$dict->write("test5.dic");
ok( !compare("wbswg5.dic", "test5.dic"), "create WBSWG5 dict" );
