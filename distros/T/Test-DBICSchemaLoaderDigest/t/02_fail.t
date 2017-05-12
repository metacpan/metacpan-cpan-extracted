use strict;
use warnings;
use Test::More tests => 1;
use Test::DBICSchemaLoaderDigest;

# tricky way :)
*Test::DBICSchemaLoaderDigest::is = *Test::DBICSchemaLoaderDigest::isnt;

test_dbic_schema_loader_digest($0);

# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:INVALIDMD5//////////gw

1;

