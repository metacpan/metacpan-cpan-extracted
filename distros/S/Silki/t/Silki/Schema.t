use strict;
use warnings;

use Test::Most;

use lib 't/lib';
use Silki::Test::FakeSchema;

use Silki::Schema;

lives_ok { Silki::Schema->LoadAllClasses() } 'call LoadAllClasses';

done_testing();
