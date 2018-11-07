use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
use MooTester3;

ok(my $obj = MooTester3->new);
isa_ok($obj, 'MooTester3' );
isa_ok($obj, 'MooTester2' );
can_ok($obj, qw[ foo bar boop json_ld_type json_ld_fields
                 json_ld_data json_ld json_ld_encoder ]);

is($obj->foo, 'Foo', 'foo is Foo');
is($obj->bar, 'Bar', 'bar is Bar');
is($obj->boop, 'Bop!', 'boop is Bop!');

is_deeply($obj->json_ld_data, {
  '@type' => 'Another',
  '@context' => 'http://schema.org/',
  bax => 'Bar',
  baz => 'Bar Foo',
  boop => 'Bop!',
  zip => 'Pow',
}, 'JSON data is correct');

is($obj->json_ld, '{
   "@context" : "http://schema.org/",
   "@type" : "Another",
   "bax" : "Bar",
   "baz" : "Bar Foo",
   "boop" : "Bop!",
   "zip" : "Pow"
}
', 'JSON is correct');

done_testing;
