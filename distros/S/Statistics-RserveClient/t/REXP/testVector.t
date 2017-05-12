use warnings;
use autodie;

use Statistics::RserveClient::REXP::Vector;

use Test::More tests => 18;

my $vector = new Statistics::RserveClient::REXP::Vector;

isa_ok( $vector, 'Statistics::RserveClient::REXP::Vector', 'new returns an object that' );
ok( !$vector->isExpression(), 'Vector is not an expression' );
ok( $vector->isVector(),      'Vector is an vector' );

is( $vector->length(), 0, 'empty vector has length 0' );
ok( !defined $vector->getValues(), 'empty vector has no values' );

my @arr1 = ( 'a', 'b', 4 );
$vector->setValues( \@arr1 );
is( $vector->length(), 3, 'length 3 when set to 3 values' );

is( $vector->getValues(), @arr1, 'values is ["a", "b", 4]' );

my $expected_html = << 'END_HTML';
<div class='rexp vector xt_16'>
<span class="typename">vector</span>
<span class='length'>3</span>
<div class='values'>
<div class='value'>a</div>
<div class='value'>b</div>
<div class='value'>4</div>
</div>
</div>
END_HTML
chomp($expected_html);

is( $vector->toHTML(), $expected_html, 'convert to HTML' );

my $vector2 = new Statistics::RserveClient::REXP::Vector;

isa_ok( $vector2, 'Statistics::RserveClient::REXP::Vector', 'new returns an object that' );
ok( !$vector2->isExpression(), 'Vector is not an expression' );
ok( $vector2->isVector(),      'Vector is an vector' );

is( $vector2->length(), 0, 'empty vector has length 0' );
ok( !defined $vector2->getValues(), 'empty vector has no values' );

my @arr2 = ( 'c', 'd', $vector );
$vector2->setValues( \@arr2 );
is( $vector2->length(), 3, 'length 3 when set to 3 values' );

is( $vector2->getValues(), @arr2, 'values is ["c", "d", 4]' );

$expected_html = << 'END_HTML';
<div class='rexp vector xt_16'>
<span class="typename">vector</span>
<span class='length'>3</span>
<div class='values'>
<div class='value'>c</div>
<div class='value'>d</div>
<div class='value'><div class='rexp vector xt_16'>
<span class="typename">vector</span>
<span class='length'>3</span>
<div class='values'>
<div class='value'>a</div>
<div class='value'>b</div>
<div class='value'>4</div>
</div>
</div></div>
</div>
</div>
END_HTML
chomp($expected_html);
is( $vector2->toHTML(), $expected_html, 'convert to HTML' );

is( $vector->getValues(), @arr1, 'the first vector is unchanged' );
is( $vector2->getValues(), @arr2,
    'the second vector is distinct from the first' );

done_testing();
