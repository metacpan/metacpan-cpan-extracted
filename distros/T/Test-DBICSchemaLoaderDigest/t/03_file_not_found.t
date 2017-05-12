use strict;
use warnings;
use Test::More tests => 1;
use Test::DBICSchemaLoaderDigest;

local $ENV{LANG} = 'C';

eval {
    test_dbic_schema_loader_digest('/;THIS;/IS$==-/!!INVALID((((FILENAME))))');
};
like $@, qr{No such file or directory}, 'file not found';

