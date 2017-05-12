use strict;
use warnings;
use Test::More tests => 1;
use Module::CoreList::DBSchema;
isa_ok( Module::CoreList::DBSchema->new(), 'Module::CoreList::DBSchema' );
