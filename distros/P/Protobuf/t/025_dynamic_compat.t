use strict;
use warnings;
use Test::More;
use Google::ProtocolBuffers::Dynamic;

my $dynamic = Google::ProtocolBuffers::Dynamic->new;
ok($dynamic, 'Instantiated Google::ProtocolBuffers::Dynamic');

done_testing();
