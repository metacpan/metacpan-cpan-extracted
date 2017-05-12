#perl -T

### Test importing/exporting subs and UIDs from other packages ###

use lib "t"; use expo;	  # our testing module -- exports "stuff" function & "ID"
use Test::More 'no_plan';


#ID gets imported
is_deeply [stuff "extra", ID 42],         [\42, ["extra"]], "Exporting/importing";
is_deeply [stuff "extra", expo::ID 42],   [\42, ["extra"]], "Exporting/importing -- package-qualified UID";

#FOO doesn't, we'll need to refer to it from package expo
is_deeply [things "extra", expo::FOO 42], [\42, ["extra"]], "Exporting/importing -- package-qualified-only UID";
