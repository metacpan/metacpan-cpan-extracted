#!perl
use 5.022;
use strict;
use warnings;
use utf8;
use Test::More;
use SION;

my $s = SION->new;    # character mode

# atoms
ok !defined $s->decode('nil'), 'nil => undef';
{
    my $t = $s->decode('true');
    ok SION::is_bool($t), 'true is a boolean';
    ok $t, 'true is true';
    isa_ok $t, 'JSON::PP::Boolean', 'true';
    my $f = $s->decode('false');
    ok SION::is_bool($f), 'false is a boolean';
    ok !$f, 'false is false';
}

# integers
is $s->decode('42'),       42,  'decimal int';
is $s->decode('-42'),      -42, 'negative decimal int';
is $s->decode('0'),        0,   'zero';
is $s->decode('0x2a'),     42,  'hexadecimal int';
is $s->decode('-0x2a'),    -42, 'negative hexadecimal int';
is $s->decode('0o52'),     42,  'octal int';
is $s->decode('0b101010'), 42,  'binary int';

# doubles
cmp_ok $s->decode('42.195'),               '==', 42.195, 'decimal double';
cmp_ok $s->decode('0x1.518f5c28f5c29p+5'), '==', 42.195, 'hexfloat double';
cmp_ok $s->decode('0x1p-2'),               '==', 0.25,   'hexfloat, no frac';
cmp_ok $s->decode('1e3'),                  '==', 1000,   'exponential';
cmp_ok $s->decode('-2.5e-1'),              '==', -0.25,  'negative exponential';
{
    my $nan = $s->decode('nan');
    cmp_ok $nan, '!=', $nan, 'nan';
    cmp_ok $s->decode('inf'),       '>', 1.7e308,  'inf';
    cmp_ok $s->decode('+Infinity'), '>', 1.7e308,  'Infinity';
    cmp_ok $s->decode('-inf'),      '<', -1.7e308, '-inf';
}

# Int/Double distinction survives a round trip
is $s->encode( $s->decode('1') ),   '1',      'Int stays Int';
is $s->encode( $s->decode('1.0') ), '0x1p+0', 'Double stays Double';

# strings
is $s->decode('"hello"'),        'hello',   'simple string';
is $s->decode('""'),             '',        'empty string';
is $s->decode(q{"a\tb\nc"}),     "a\tb\nc", 'escapes';
{
    my $text = <<'EOT';    # "\"\\" -- escaped quote and backslash
"\"\\"
EOT
    chomp $text;
    is $s->decode($text), q{"} . qq{\\}, 'escaped quote and backslash';
}
is $s->decode(q{"\u65e5\u672c\u8a9e"}),  q{日本語}, q{\uXXXX escapes};
is $s->decode(q{"\ud83d\ude07"}),          q{😇},       q{surrogate pair};
is $s->decode(q{"\u{1F607}"}),          '😇',     'swift-style \u{...}';
is $s->decode('"漢字"'),                '漢字',   'raw unicode';

# data
{
    my $data = $s->decode('.Data("R0lGODdh")');
    is $data, 'GIF87a', '.Data decodes from base64';
    ok !utf8::is_utf8($data), '.Data is a byte string';
}

# date
{
    my $date = $s->decode('.Date(0x0p+0)');
    isa_ok $date, 'SION::Date';
    cmp_ok $date->epoch, '==', 0, 'epoch 0';
    cmp_ok $s->decode('.Date(1234567890)')->epoch, '==', 1234567890,
      'int epoch';
    cmp_ok 0 + $s->decode('.Date(0x1p-1)'), '==', 0.5, 'numification';
}

# ext
{
    my $ext = $s->decode('.Ext("1NTU")');
    isa_ok $ext, 'SION::Ext';
    is $ext->data, "\xd4\xd4\xd4", '.Ext payload';
}

# arrays
is_deeply $s->decode('[]'),        [],          'empty array';
is_deeply $s->decode('[1,2,3]'),   [ 1, 2, 3 ], 'array of ints';
is_deeply $s->decode('[1, 2, 3,]'), [ 1, 2, 3 ], 'trailing comma';
is_deeply $s->decode('[nil,true,1,"one",[1]]'),
  [ undef, SION::true, 1, 'one', [1] ], 'mixed array';

# dictionaries
is_deeply $s->decode('[:]'), {}, 'empty dictionary';
is_deeply $s->decode('["one":1]'), { one => 1 }, 'simple dictionary';
is_deeply $s->decode('["a":1,"b":[2],"c":[:],]'),
  { a => 1, b => [2], c => {} }, 'nested, with trailing comma';
is_deeply $s->decode('[1:"one"]'), { 1 => 'one' },
  'non-string key is stringified';
is_deeply $s->decode('[nil:0,true:1]'), { nil => 0, true => 1 },
  'atom keys are stringified';

# comments and whitespace
is_deeply $s->decode(<<'EOT'), [ 1, 2 ], 'comments are skipped';
[ // this is an array
    1, // one
    2  // two
]
EOT
is_deeply $s->decode(qq{\t[ "a" :\r\n 1 ]\n}), { a => 1 }, 'whitespace';
is $s->decode('["url":"https://github.com/"]')->{url},
  'https://github.com/', '// inside a string is not a comment';

# utf8 mode
{
    use Encode ();
    my $octets = Encode::encode( 'UTF-8', '["日本":"語"]' );
    is_deeply decode_sion($octets), { '日本' => '語' }, 'decode_sion octets';
}

# errors
for my $bad (
    '',      '[',    '[1,',    '"abc', '[1:]', 'bogus',
    '01',    '[1 2]', '["a" 1]', '1 2', '.Date()', '.Date(nil)',
    '[1:2', q{"\q"},
  )
{
    ok !eval { $s->decode($bad); 1 }, "croaks on malformed input: '$bad'";
}
like $@, qr/at character offset/, 'error message contains offset'
  if !eval { $s->decode('[1,'); 1 };

done_testing;
