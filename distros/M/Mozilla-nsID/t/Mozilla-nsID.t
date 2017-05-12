use strict;
use warnings FATAL => 'all';

use Test::More tests => 13;
BEGIN { use_ok('Mozilla::nsID') };

my $id = Mozilla::nsID->new(0x95611356, 0xf583, 0x46f5, [ 0x81, 0xff
		, 0x4b, 0x3e, 0x01, 0x62, 0xc6, 0x19 ]);
isa_ok($id, 'Mozilla::nsID');
is($id->m0, 0x95611356);
is($id->m1, 0xf583);
is($id->m2, 0x46f5);
is_deeply([ $id->m3 ], [ 0x81, 0xff, 0x4b, 0x3e, 0x01, 0x62, 0xc6, 0x19 ]);

is($id->ToString, '{95611356-f583-46f5-81ff-4b3e0162c619}');

my $id2 = Mozilla::nsID->new_empty;
isa_ok($id2, 'Mozilla::nsID');
is($id2->m2, 0);

is($id2->Parse('{95611356-f583-46f5-81ff-4b3e0162c619}'), 1);
is($id2->m2, $id->m2);

is($id2->Parse('{dieoielf-f583-46f5-81ff-4euuee}'), undef);
is_deeply([ $id2->m3 ], [ 0x81, 0xff, 0x4b, 0x3e, 0x01, 0x62, 0xc6, 0x19 ]);
