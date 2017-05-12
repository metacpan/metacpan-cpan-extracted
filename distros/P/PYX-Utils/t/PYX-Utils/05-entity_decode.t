# Pragmas.
use strict;
use warnings;

# Modules.
use PYX::Utils qw(entity_decode);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $str = 'a&lt;b';
my $ret = entity_decode($str);
is($ret, 'a<b', "Decode '&lt;' string.");

# Test.
$str = 'a&amp;b';
$ret = entity_decode($str);
is($ret, 'a&b', "Decode '&amb;' string.");

# Test.
$str = 'a&quot;b';
$ret = entity_decode($str);
is($ret, 'a"b', "Decode '&quot;' string.");

# Test.
$str = '&lt;&amp;&quot;';
$ret = entity_decode($str);
is($ret, '<&"', "Decode all '&lt;', '&amp;' and '&quot;' characters.");
