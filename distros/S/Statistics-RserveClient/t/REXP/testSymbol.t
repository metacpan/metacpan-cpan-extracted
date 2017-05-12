use warnings;
use autodie;

use Statistics::RserveClient::REXP::Symbol;

use Test::More tests => 7;

my $symbol = new Statistics::RserveClient::REXP::Symbol('foo');

isa_ok( $symbol, 'Statistics::RserveClient::REXP::Symbol', 'new returns an object that' );
ok( !$symbol->isExpression(), 'Symbol is not an expression' );
ok( $symbol->isSymbol(),      'Symbol is a symbol' );

is( $symbol->getValue(), 'foo', 'symbol name') ;
is( $symbol->__toString(), '"foo"', 'symbol string') ;
is( Statistics::RserveClient::Parser::xtName($symbol->getType()), 'symbol', 'symbol type') ;

my $expected_html = << 'END_HTML';
<div class="rexp xt_5">
<span class="typename">symbol</span>
foo
</div>
END_HTML
chomp($expected_html);

is($symbol->toHTML(), $expected_html, 'convert to HTML');

done_testing();
