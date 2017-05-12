use Test::Most tests => 32;

use Parse::Path;

my $path;
die_on_fail;
lives_ok {
   $path = Parse::Path->new( path => 'a.b.c' );
} "Initial path construction didn't die";
isa_ok $path, 'Parse::Path::DZIL', "path";
restore_fail;

my $orig_path = $path->clone;

# concat
$path .= 'd';
lives_and { is($path->as_string, 'a.b.c.d', '.= $') } '.= $ lives';

$path .= ['e', 'f'];
lives_and { is($path->as_string, 'a.b.c.d.e.f', '.= []') } '.= [] lives';

# basic overloads
lives_and { is(0+$path,  6,               '0+') } '0+ lives';
lives_and { is(0-$path, -6,               '0-') } '0- lives';
lives_and { is(-$path,  -6,               '-' ) } '-  lives';
lives_and { is("$path", $path->as_string, '""') } '"" lives';
lives_and { is(!$path,  '',                '!') } '!  lives';

# numeric comparisons
lives_and { ok($orig_path <  $path,     '<'  ) } '<   lives';
lives_and { ok($orig_path <= $path,     '<=' ) } '<=  lives';
lives_and { ok($path >  $orig_path,     '>'  ) } '>   lives';
lives_and { ok($path >= $orig_path,     '>=' ) } '>=  lives';
lives_and { ok($path == $path,          '==' ) } '==  lives';
lives_and { ok($path != $orig_path,     '!=' ) } '!=  lives';
lives_and { is($path <=> $orig_path, 1, '<=>') } '<=> lives';

# string comparisons
lives_and { ok($orig_path lt $path,     'lt' ) } 'lt  lives';
lives_and { ok($orig_path le $path,     'le' ) } 'le  lives';
lives_and { ok($path gt $orig_path,     'gt' ) } 'gt  lives';
lives_and { ok($path ge $orig_path,     'ge' ) } 'ge  lives';
lives_and { ok($path eq $path,          'eq' ) } 'eq  lives';
lives_and { ok($path ne $orig_path,     'ne' ) } 'ne  lives';
lives_and { is($path cmp $orig_path, 1, 'cmp') } 'cmp lives';

# different string comparisons
$path->_path->[2]{key}  = 'a';
$path->_path->[2]{step} = 'a';

lives_and { ok($path lt $orig_path,     'lt  aba') } 'lt  aba lives';
lives_and { ok($path le $orig_path,     'le  aba') } 'le  aba lives';
lives_and { ok($orig_path gt $path,     'gt  aba') } 'gt  aba lives';
lives_and { ok($orig_path ge $path,     'ge  aba') } 'ge  aba lives';
lives_and { ok($orig_path eq $orig_path,'eq  aba') } 'eq  aba lives';
lives_and { ok($orig_path ne $path,     'ne  aba') } 'ne  aba lives';
lives_and { is($orig_path cmp $path, 1, 'cmp aba') } 'cmp aba lives';

# dereferencing
lives_and { is       ($$path,  $path->as_string, '${}') } '${} lives';
lives_and { is_deeply(\@$path, $path->as_array,  '@{}') } '@{} lives';
