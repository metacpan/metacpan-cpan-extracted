#!perl -T

use Test::More tests => 3;
use utf8;

BEGIN {
    use_ok( 'Net::YASA' );
    my $ny = Net::YASA->new();
    my $termset = $ny->extract("我要去上學我想去上學");
    like ($$termset[0], qr/去上學/, 'Content from extraction');
    is ($$termset[1], "我\t2", 'Content from extraction');
    diag( "Testing Net::YASA function, extract()");
}
