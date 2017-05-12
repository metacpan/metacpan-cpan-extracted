use 5.012;
use warnings;
use lib 't/lib';
use PXSTest 'full', 'threads';

my ($obj, $thr);
my @thres : shared;

# 1) object has CLONE_SKIP (not support threads)
$obj = Panda::XS::Test::MixBase->new(123);
is($obj->val, 123);
$thr = threads->create(\&thr_mybase);
$thr->join;
is($obj->val, 123);
cmp_deeply(\@thres, ['SCALAR', undef, undef], "XS MixBase must self-destroy");
is(dcnt(), 0, 'MixBase must not exist in thread');
undef $obj;
is(dcnt(), 1, 'MixBase has been destroyed in parent');
dcnt(0);

# 2) object is thread-unsafe, clones itself on thread creation
$obj = Panda::XS::Test::MyChild->new(234, 345);
cmp_deeply([$obj->val, $obj->val2], [234, 345]);
@thres = ();
$thr = threads->create(\&thr_mychild);
$thr->join;
cmp_deeply([$obj->val, $obj->val2], [234, 345], 'Parent thread MyChild object not changed');
cmp_deeply(\@thres, ['Panda::XS::Test::MyChild', 100, 200], 'Child thread MyChild object works and changed');
is(dcnt(), 2, 'MyChild has been destroyed in thread');
undef $obj;
is(dcnt(), 4, 'MyChild has been destroyed in parent also');
dcnt(0);

# 3) object is thread-safe, increments refcnt on thread creation
$obj = Panda::XS::Test::MyThreadSafe->new(12);
is($obj->val, 12);
@thres = ();
$thr = threads->create(\&thr_mythread_safe);
$thr->join;
is($obj->val, 100, 'Parent thread MyThreadSafe object changed');
cmp_deeply(\@thres, ['Panda::XS::Test::MyThreadSafe', 100], 'Child thread MyChild object works and same');
is(dcnt(), 0, 'MyThreadSafe has not been destroyed in thread');
undef $obj;
is(dcnt(), 1, 'MyThreadSafe has been destroyed in parent');

done_testing();

sub thr_mybase {
    @thres = (ref($obj), $$obj, scalar eval { $obj->val; 1 });
}

sub thr_mychild {
    $obj->val(100);
    $obj->val2(200);
    @thres = (ref($obj), $obj->val, $obj->val2);
}

sub thr_mythread_safe {
    $obj->val(100);
    @thres = (ref($obj), $obj->val);
}