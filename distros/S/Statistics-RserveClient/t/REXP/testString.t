use warnings;
use autodie;

use Statistics::RserveClient::REXP::String;

use Test::More tests => 8;

my $string = new Statistics::RserveClient::REXP::String;

isa_ok( $string, 'Statistics::RserveClient::REXP::String', 'new returns an object that' );
ok( $string->isString(),      'String is a string' );
ok( $string->isVector(),      'String is a vector' );

is( $string->length(), 0, 'empty vector has length 0' );
ok( !defined $string->getValues(), 'empty vector has no values' );

my @val = ( "foo", "bar", "baz" );
$string->setValues( \@val );

is( $string->length(), 3, 'length 3 when set to 3 values' );

is( $string->getValues(), @val, 'values is [1, 2, 3]' );

my $expected_html = << 'END_HTML';
<div class='rexp vector xt_34'>
<span class="typename">string*</span>
<span class='length'>3</span>
<div class='values'>
<div class='value'>"foo"</div>
<div class='value'>"bar"</div>
<div class='value'>"baz"</div>
</div>
</div>
END_HTML
chomp($expected_html);

is( $string->toHTML(), $expected_html, 'convert to HTML' );

done_testing();
