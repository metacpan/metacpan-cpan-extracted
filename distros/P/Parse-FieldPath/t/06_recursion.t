use strict;
use warnings;

use Test::More tests => 1;
use Test::Deep;
use Test::MockObject;

use Parse::FieldPath qw/extract_fields/;

my $obj = Test::MockObject->new();
$obj->set_always( obj => $obj );
$obj->set_always( all_fields => ['obj'] );

eval { extract_fields($obj, 'obj') };
like($@, qr/maximum recursion limit reached/i, 'won\'t recurse forever');
