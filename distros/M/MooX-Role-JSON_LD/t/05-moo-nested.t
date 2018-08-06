use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
use MooTester2;
use MooTester3;

ok(my $obj = MooTester3->new( zip => MooTester2->new(), boop => undef ));
isa_ok($obj, 'MooTester3' );
can_ok($obj, qw[ foo bar boop json_ld_type json_ld_fields
                 json_ld_data json_ld json_ld_encoder ]);

is($obj->foo, 'Foo', 'foo is Foo');
is($obj->bar, 'Bar', 'bar is Bar');
is($obj->boop, undef, 'boop is undefined');

is_deeply($obj->json_ld_data, {
  '@type' => 'Another',
  '@context' => 'http://schema.org/',
  bax => 'Bar',
  baz => 'Bar Foo',
  zip => {
      '@type' => 'Example',
      '@context' => 'http://schema.org/',
      bax => 'Bar',
      baz => 'Bar Foo',
      boop => 'Bop!',
  },
}, 'JSON data is correct');

is($obj->json_ld, '{
   "@context" : "http://schema.org/",
   "@type" : "Another",
   "bax" : "Bar",
   "baz" : "Bar Foo",
   "zip" : {
      "@context" : "http://schema.org/",
      "@type" : "Example",
      "bax" : "Bar",
      "baz" : "Bar Foo",
      "boop" : "Bop!"
   }
}
', 'JSON is correct');

done_testing;
