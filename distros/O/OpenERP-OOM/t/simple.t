use Test::Most;

use FindBin;
use lib "$FindBin::Bin/lib";
use Object;

my $o = Object->new({ foo => 'test' });
is $o->foo, 'test';
ok $o->all_attributes_clean;

$o->foo('changed');
ok $o->has_dirty_attributes;

$o->mark_all_clean;
ok $o->all_attributes_clean;


done_testing;

