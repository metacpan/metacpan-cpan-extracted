use strict;
use warnings;
use OPCUA::Open62541 qw(:TYPES);

use Test::More tests => 24;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;

ok(my $variant = OPCUA::Open62541::Variant->new(), "variant new");

my $guid = "00000001-0002-0003-4142-434344454647";
no_leaks_ok { $variant->setScalar($guid, TYPES_GUID) } "scalar set leak";
ok($variant->isScalar(), "scalar is");
is($variant->getScalar(), $guid, "scalar get");
no_leaks_ok { $variant->getScalar() } "scalar get leak";

$guid = "00000001-0002-0003-4142-434344454647-";
throws_ok { $variant->setScalar($guid, TYPES_GUID) }
    (qr/Guid string length 37 is not 36 /, "scalar long");
no_leaks_ok { eval { $variant->setScalar($guid, TYPES_GUID) } }
    "scalar long leak";

$guid = "00000001-0002-0003-4142-43434445464";
throws_ok { $variant->setScalar($guid, TYPES_GUID) }
    (qr/Guid string length 35 is not 36 /, "scalar short");
no_leaks_ok { eval { $variant->setScalar($guid, TYPES_GUID) } }
    "scalar short leak";

$guid = "00000001a0002-0003-4142-434344454647";
throws_ok { $variant->setScalar($guid, TYPES_GUID) }
    (qr/Guid string character 'a' at 8 is not - separator /,
    "scalar separator 1");
no_leaks_ok { eval { $variant->setScalar($guid, TYPES_GUID) } }
    "scalar separator 1 leak";

$guid = "00000001-0002b0003-4142-434344454647";
throws_ok { $variant->setScalar($guid, TYPES_GUID) }
    (qr/Guid string character 'b' at 13 is not - separator /,
    "scalar separator 2");
no_leaks_ok { eval { $variant->setScalar($guid, TYPES_GUID) } }
    "scalar separator 2 leak";

$guid = "00000001-0002-0003c4142-434344454647";
throws_ok { $variant->setScalar($guid, TYPES_GUID) }
    (qr/Guid string character 'c' at 18 is not - separator /,
    "scalar separator 3");
no_leaks_ok { eval { $variant->setScalar($guid, TYPES_GUID) } }
    "scalar separator 3 leak";

$guid = "00000001-0002-0003-4142d434344454647";
throws_ok { $variant->setScalar($guid, TYPES_GUID) }
    (qr/Guid string character 'd' at 23 is not - separator /,
    "scalar separator 4");
no_leaks_ok { eval { $variant->setScalar($guid, TYPES_GUID) } }
    "scalar separator 4 leak";

$guid = "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF";
lives_ok { $variant->setScalar($guid, TYPES_GUID) } "scalar max lives";
is($variant->getScalar(), $guid, "scalar max");

$guid = "01234567-89ab-acdf-1234-aAbBcCdDeEfF";
lives_ok { $variant->setScalar($guid, TYPES_GUID) } "scalar case lives";
is($variant->getScalar(), uc($guid), "scalar case");

$guid = "01234567-89ab-acdf-ghij-klmnopqrstuv";
throws_ok { $variant->setScalar($guid, TYPES_GUID) }
    (qr/Guid string character 'g' at 19 is not hex digit /, "scalar hex");
no_leaks_ok { eval { $variant->setScalar($guid, TYPES_GUID) } }
    "scalar scalar leak";
