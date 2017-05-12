use Test::Most 0.22;
use Test::FailWarnings;
use RedisDB::Parser;
use RedisDB::Parser::PP;
use Encode;

my $binary = "\x{01}\x{00}\x{c0}\x{d1}\x{ff}\x{fe}";
my $hi_utf = "\x{4f60}\x{597d}";
my $hi_oct = "\x{e4}\x{bd}\x{a0}\x{e5}\x{a5}\x{bd}";

my $lf = "\015\012";

sub binary_test {
    my $parser = shift;
    my $req    = $parser->build_request( 'set', $binary );
    my $exp    = "*2$lf\$3${lf}set${lf}\$6$lf$binary$lf";
    is $req, $exp, "octets encoded as octets";
    my $parsed;
    $parser->push_callback( sub { $parsed = $_[1] } ) for 1 .. 2;
    $parser->parse($exp);
    eq_or_diff $parsed, [ 'set', $binary ], "response parsed as octets";

    # shouldn't it warn here to indicate that data is not encoded?
    $req = $parser->build_request( 'set', $hi_utf );
    $exp = "*2$lf\$3${lf}set${lf}\$6$lf$hi_oct$lf";
    is $req, $exp, "utf value encoded as octets";
    $parser->parse($exp);
    eq_or_diff $parsed, [ 'set', $hi_oct ], "response parsed as octets";
};

sub utf_test {
    my $parser  = shift;
    my $req     = $parser->build_request( 'set', $binary );
    my $encoded = Encode::encode_utf8($binary);
    my $exp     = "*2$lf\$3${lf}set${lf}\$" . length($encoded) . "$lf$encoded$lf";
    is $req, $exp, "octets were encoded as utf8";
    my $parsed;
    $parser->push_callback( sub { $parsed = $_[1] } ) for 1 .. 2;

    $req = $parser->build_request( 'set', $hi_utf );
    $exp = "*2$lf\$3${lf}set${lf}\$6$lf$hi_oct$lf";
    is $req, $exp, "utf value encoded as octets";
    $parser->parse($exp);
    eq_or_diff $parsed, [ 'set', $hi_utf ], "response decoded as utf8";

    $exp = "*2$lf\$3${lf}set${lf}\$6$lf$binary$lf";
    dies_ok { $parser->parse($exp) } "parser dies if response contains invalid utf8";
};

my $pp = RedisDB::Parser::PP->new();
subtest "default, PP" => sub { binary_test($pp) };
my $ppu = RedisDB::Parser::PP->new( utf8 => 1 );
subtest "with utf8, PP" => sub { utf_test($ppu) };
if ( RedisDB::Parser->implementation eq 'RedisDB::Parser::XS' ) {
    my $xs = RedisDB::Parser::XS->new();
    subtest "default, XS" => sub { binary_test($xs) };
    my $xsu = RedisDB::Parser::XS->new( utf8 => 1 );
    subtest "default, XS" => sub { utf_test($xsu) };
}
else {
  SKIP: {
        skip "XS implementation is not loaded", 2;
    }
}

done_testing;
