use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;

eval { use MooseTester; };

if ($@) {
  plan skip_all => 'Moose not installed';
}

ok(my $obj = MooseTester->new, 'Got an object');
isa_ok($obj, 'MooseTester');
can_ok($obj, qw[ foo bar json_ld_type json_ld_fields
                 json_ld_data json_ld json_ld_encoder ]);

is($obj->foo, 'Foo', 'foo is Foo');
is($obj->bar, 'Bar', 'bar is Bar');

is_deeply($obj->json_ld_data, {
  '@type' => 'Example',
  '@context' => 'http://schema.org',
  foo => 'Foo',
  bar => 'Bar',
  bax => 'Bar',
  baz => 'Bar Foo',
}, 'JSON data is correct');
is($obj->json_ld, '{
   "@context" : "http://schema.org",
   "@type" : "Example",
   "bar" : "Bar",
   "bax" : "Bar",
   "baz" : "Bar Foo",
   "foo" : "Foo"
}
', 'JSON is correct');

done_testing;
