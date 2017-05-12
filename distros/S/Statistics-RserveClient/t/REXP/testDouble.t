use warnings;
use autodie;

use Statistics::RserveClient::REXP::Double;

use Test::More tests => 8;

my $dbl = new Statistics::RserveClient::REXP::Double;
isa_ok( $dbl, 'Statistics::RserveClient::REXP::Double', 'new returns an object that' );
ok( $dbl->isDouble(), 'Double is a double' );
ok( $dbl->isVector(), 'Double is a vector' );

is( $dbl->length(), 0, 'empty vector has length 0' );
ok( !defined $dbl->getValues(), 'empty vector has no values' );

my @val = ( 1.0, 2.0, 3.0 );
$dbl->setValues( \@val );

is( $dbl->length(), 3, 'length 3 when set to 3 values' );

is( $dbl->getValues(), @val, 'values is [1, 2, 3]' );

my $expected_html = << 'END_HTML';
<div class='rexp vector xt_33'>
<span class="typename">real*</span>
<span class='length'>3</span>
<div class='values'>
<div class='value'>1</div>
<div class='value'>2</div>
<div class='value'>3</div>
</div>
</div>
END_HTML

chomp($expected_html);
     
is( $dbl->toHTML(), $expected_html, 'convert to HTML' );

done_testing();
     
