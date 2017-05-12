use Set::Object;

require 't/object/Person.pm';
package Person;

populate();

$patty = $patty;
$selma = $selma;
$burns = $burns;

Set::Object->new->remove($patty);

$simpsons = Set::Object->new($homer, $marge, $bart, $lisa, $maggie);

use Test::More tests => 7;

$removed = $simpsons->remove($homer);

is($simpsons->size(), 4, "new size correct after remove");
is($removed, 1, "remove returned number of elements removed");
is($simpsons, Set::Object->new($marge, $bart, $lisa, $maggie),
   "set contents correct");

$removed = $simpsons->remove($burns);
is($simpsons->size(), 4, "remove of non-member didn't reduce size");
is($removed, 0, "remove returned no elements removed");

$removed = $simpsons->remove($patty, $marge, $selma);
is($simpsons->size(), 3, "remove of mixed members & non-members");
is($removed, 1, "remove returned correct num of elements removed");
