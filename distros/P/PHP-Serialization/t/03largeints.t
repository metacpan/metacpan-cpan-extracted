use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok('PHP::Serialization') };

my $text = PHP::Serialization::serialize(744763740179);
is($text, 's:12:"744763740179";', 'Large integers serialize correctly');
$text = PHP::Serialization::serialize([1, 2]);
is($text, 'a:2:{i:0;i:1;i:1;i:2;}', 'Array serializes correctly');

