use strict;
use warnings;

use English;

use Test::More;
use Test::Exception;

use PDLA::LiteF;
use PDLA::Lvalue;

BEGIN { 
    if ( PDLA::Lvalue->subs and !$PERLDB) {
	plan tests => 3;
    } else {
	plan skip_all => "no lvalue sub support";
    }
} 

$| = 1;

ok (PDLA::Lvalue->subs('slice'),"slice is an lvalue sub");

my $pa = sequence 10;
lives_ok {
	$pa->slice("") .= 0;
} "lvalue slice ran OK";

is($pa->max, 0, "lvalue slice modified values");
