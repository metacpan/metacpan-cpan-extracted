#!perl
use 5.022;
use strict;
use warnings;
use utf8;
use Test::More;
use Encode ();
use MIME::Base64 ();
use SION;

my $s = SION->new->canonical;

# atoms
is $s->encode(undef),         'nil',   'undef => nil';
is $s->encode( SION::true() ),  'true',  'SION::true';
is $s->encode( SION::false() ), 'false', 'SION::false';
is $s->encode( \1 ),          'true',  '\1 => true';
is $s->encode( \0 ),          'false', '\0 => false';

SKIP: {
    skip 'native booleans need perl 5.36+', 2 if $] < 5.035009;
    is $s->encode( !!1 ), 'true',  'native true';
    is $s->encode( !!0 ), 'false', 'native false';
}

# numbers
is $s->encode(42),     '42',    'Int';
is $s->encode(-42),    '-42',   'negative Int';
is $s->encode(0),      '0',     'zero Int';
is $s->encode(42.195), '0x1.518f5c28f5c29p+5', 'Double as hexfloat';
is $s->encode(1.0),    '0x1p+0',  'Double 1.0 stays Double';
is $s->encode(0.0),    '0x0p+0',  'Double 0.0';
is $s->encode(0.25),   '0x1p-2',  'Double 0.25';
is $s->encode( 9**9**9 ),           'inf',  'inf';
is $s->encode( -9**9**9 ),          '-inf', '-inf';
is $s->encode( 9**9**9 - 9**9**9 ), 'nan',  'nan';

# strings
is $s->encode('hello'),  '"hello"', 'simple string';
is $s->encode(''),       '""',      'empty string';
is $s->encode('42'),     '"42"',    'string of digits stays String';
is $s->encode("tab\tlf\n"), q{"tab\tlf\n"}, 'control chars escaped';
is $s->encode(qq{"\\}),     q{"\"\\\\"},    'quote and backslash escaped';
is $s->encode("\x01"),      q{"\u0001"},    'other control chars as \uXXXX';
is $s->encode('漢字'), '"漢字"', 'unicode passes through';

# ascii mode
{
    my $a = SION->new->ascii;
    like $a->encode('日'), qr/^"\\u65e5"$/, 'ascii: \uXXXX';
    like $a->encode('😇'), qr/^"\\ud83d\\ude07"$/, 'ascii: surrogate pair';
    ok $a->encode('漢字と😇') !~ /[^\x00-\x7f]/, 'ascii output is pure ASCII';
}

# String vs Data
{
    my $gif = "GIF89a\x01\x00\x01\x00\x80\xff";    # invalid UTF-8
    is $s->encode($gif),
      '.Data("' . MIME::Base64::encode_base64( $gif, '' ) . '")',
      'invalid UTF-8 byte string => Data';
    is $s->encode("GIF"), '"GIF"', 'ASCII byte string => String';
    my $utf8_bytes = Encode::encode( 'UTF-8', '日' );
    is $s->encode($utf8_bytes), '"日"',
      'valid UTF-8 byte string => String (decoded)';
    is $s->encode( SION::Data->new('GIF') ), '.Data("R0lG")',
      'SION::Data forces Data';
}

# dates
is $s->encode( SION::Date->new(0) ),   '.Date(0x0p+0)', 'SION::Date epoch 0';
is $s->encode( SION::Date->new(0.5) ), '.Date(0x1p-1)', 'fractional epoch';
SKIP: {
    eval { require Time::Piece; 1 } or skip 'Time::Piece not available', 1;
    # scalar context matters: Time::Piece->gmtime is list-context sensitive
    my $t = Time::Piece->gmtime(86400);
    is $s->encode($t), '.Date(0x1.518p+16)',
      'objects with ->epoch encode as Date';
}

# ext
{
    my $ext = SION::Ext->new("\xd4\xd4\xd4");
    is $s->encode($ext), '.Ext("1NTU")', 'SION::Ext';
}

# arrays and dictionaries
is $s->encode( [] ),        '[]',      'empty array';
is $s->encode( {} ),        '[:]',     'empty dictionary';
is $s->encode( [ 1, 2 ] ),  '[1,2]',   'compact array';
is $s->encode( { a => 1, b => 2 } ), '["a":1,"b":2]', 'canonical dictionary';
is $s->encode( [ 1, [ 2, [3] ] ] ), '[1,[2,[3]]]', 'nested arrays';
is( SION->new->space_after->encode( [ 1, 2 ] ), '[1, 2]', 'space_after' );
is( SION->new->space_before->space_after->encode( { a => 1 } ),
    '["a" : 1]', 'space around colon' );

# pretty
{
    my $pretty = SION->new->canonical->pretty;
    is $pretty->encode( { a => [ 1, {} ] } ), <<'EOT' =~ s/\n\z//r, 'pretty';
[
    "a" : [
        1,
        [:]
    ]
]
EOT
    is $pretty->indent_length(2)->encode( [1] ), "[\n  1\n]", 'indent_length';
}

# blessed objects
{
    ok !eval { $s->encode( bless {}, 'Foo' ); 1 }, 'unknown blessed croaks';
    like $@, qr/allow_blessed/, '... with a helpful message';
    is( SION->new->allow_blessed->encode( bless {}, 'Foo' ), 'nil',
        'allow_blessed => nil' );

    package Foo2 { sub TO_SION { [1] } }
    is( SION->new->convert_blessed->encode( bless {}, 'Foo2' ), '[1]',
        'convert_blessed uses TO_SION' );
}

# other refs croak
ok !eval { $s->encode( sub { } ); 1 }, 'coderef croaks';
ok !eval { $s->encode( \'x' );    1 }, 'scalar ref (non-bool) croaks';

# utf8 mode
{
    my $out = SION->new->utf8->encode( ['日'] );
    ok !utf8::is_utf8($out), 'utf8 mode returns octets';
    is $out, Encode::encode( 'UTF-8', '["日"]' ), '... UTF-8 encoded';
    is encode_sion( ['日'] ), $out, 'encode_sion == SION->new->utf8->encode';
}

done_testing;
