
# Tests for session related api. see code block marked "Session fun".

use Test::More tests => 3;

use warnings;
use strict;
use POE;
use Data::Dumper;

use_ok('POE::API::Peek');

my $api;

eval { $api = POE::API::Peek->new(); };
ok(!$@, "new() throws no execptions");
is(ref $api, "POE::API::Peek", "new() returns a Peek object");

