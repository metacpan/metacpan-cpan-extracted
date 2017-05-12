use strict;
use warnings;
use Parse::RecDescent;
use Test::More tests => 8;

my $grammar = <<'END_OF_GRAMMAR';
    foo:             item(s) eotext { $return = $item[1] }
    foo_with_skip:   <skip: qr/(?mxs: \s+ |\# .*?$)*/>
                     item(s) eotext { $return = $item[1] }
    item:            name value { [ @item[1,2] ] }
    name:            'whatever' | 'another'
    value:           /\S+/
    eotext:          /\s*\z/
END_OF_GRAMMAR

my $text = <<'END_OF_TEXT';
whatever value

# some spaces, newlines and a comment too!

another value

END_OF_TEXT

# Test setting the initial skip via the <skip:> global directive
RunTests(q{
<skip:'(?mxs: \s+ |\# .*?$)*'>
});

# Test setting the initial skip via $Parse::RecDescent::skip global
local $Parse::RecDescent::skip = qr/(?mxs: \s+ |\# .*?$)*/;
RunTests();

sub RunTests {
    my $prefix = shift || '';

    my $parser = Parse::RecDescent->new($prefix . $grammar);
    ok($parser, 'got a parser');

    my $inskip = $parser->foo_with_skip($text);
    ok($inskip, 'foo_with_skip()');

  {
      my $outskip = $parser->foo($text);
      ok($outskip, 'foo() with regex $P::RD::skip');
  }

  {
      my $outskip = $parser->foo($text);
      ok($outskip, 'foo() with string $P::RD::skip');
  }
}
