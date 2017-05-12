use strict;
use warnings;
use Test::More tests => 1;
use Test::DBICSchemaLoaderDigest;

no warnings 'redefine';
*Test::DBICSchemaLoaderDigest::ok = sub ($;$) {
    like $_[1], qr{md5sum not found}, 'md5sum not found';
};

test_dbic_schema_loader_digest($0);

