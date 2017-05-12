# Pragmas.
use strict;
use warnings;

# Modules.
use PYX::Utils qw(entity_encode);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $str = 'a<b';
my $ret = entity_encode($str);
is($ret, 'a&lt;b');

# Test.
$str = 'a&b';
$ret = entity_encode($str);
is($ret, 'a&amp;b');

# Test.
$str = 'a"b';
$ret = entity_encode($str);
is($ret, 'a&quot;b');

# Test.
$str = '<&"';
$ret = entity_encode($str);
is($ret, '&lt;&amp;&quot;');
