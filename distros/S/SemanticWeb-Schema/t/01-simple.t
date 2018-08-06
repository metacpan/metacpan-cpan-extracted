use Test::Most;
use Test::JSON::More;

use aliased 'SemanticWeb::Schema::Person';

my $obj = Person->new(
    id          => 'https://en.wikipedia.org/wiki/James_Clerk_Maxwell',
    name        => 'James Clerk Maxwell',
    birth_date  => '1831-06-13',
    birth_place => 'Edinburgh',
);

isa_ok $obj, 'SemanticWeb::Schema';
isa_ok $obj, 'SemanticWeb::Schema::Thing';
isa_ok $obj, 'SemanticWeb::Schema::Person';

ok $obj->has_id, 'has_id';

ok_json( my $json = $obj->json_ld );

cmp_json(
    $json,
    q|
 { "@id"        : "https://en.wikipedia.org/wiki/James_Clerk_Maxwell",
   "@context"   : "http://schema.org/",
   "@type"      : "Person",
   "birthDate"  : "1831-06-13",
   "birthPlace" : "Edinburgh",
   "name"       : "James Clerk Maxwell" }
|
);

note $json;

done_testing;
