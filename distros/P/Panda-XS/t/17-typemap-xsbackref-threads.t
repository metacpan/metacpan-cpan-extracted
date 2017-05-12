use 5.012;
use warnings;
use lib 't/lib';
use PXSTest 'full', 'threads';

my @info = (
    ['Panda::XS::Test::BRStorage',   'Panda::XS::Test::MyBRUnit', 'Panda::XS::Test::BRUnit', 1],
    ['Panda::XS::Test::BRSPStorage', 'Panda::XS::Test::MyBRUnitSP', 'Panda::XS::Test::BRUnitSP', 2],
);

foreach my $row (@info) {
    my ($stclass, $uclass, $base_uclass, $udcnt) = @$row;
    my ($obj, $thr, $br_addr, $s);
    my @thres : shared;
    dcnt(0);

    # 1) clone-policy, backref should point to cloned SV after clone
    $obj = $uclass->new_enabled(100);
    $br_addr = $obj->br_addr;
    $thr = threads->create(sub {
        $obj->id(200);
        my $s = $stclass->new;
        $s->unit($obj);
        my $r = $s->unit;
        @thres = (ref($obj), $obj->id, $obj->br_addr, ref($r), $r->id, $r->br_addr);
    });
    $thr->join;
    undef $thr;
    is($obj->id, 211, "main thread object not damaged");
    is($obj->br_addr, $br_addr, "main thread object not damaged");
    cmp_deeply([@thres[0,1,3,4]], [$uclass, 311, $uclass, 311], "object works in thread");
    is($thres[2], $thres[5], "XSBackref work in thread");
    isnt($thres[2], $br_addr, "XSBackref has detached in thread");
    is(dcnt, 1 + $udcnt, "thread not leaked (storage and cloned unit have been destroyed)");
    
    dcnt(0);
    
    
    # inside-C (deeply) cloned objects don't preserve backrefs (impossible)
    $s = $stclass->new;
    $s->unit($obj);
    $thr = threads->create(sub {
        $obj->id(300);
        my $r = $s->unit;
        $r->id(400);
        @thres = (ref($obj), $obj->id, $obj->br_addr, ref($r), $r->id, $r->br_addr);
    });
    $thr->join;
    undef $thr;
    is($obj->id, 211);
    is($obj->br_addr, $br_addr);
    cmp_deeply([@thres[0,1,3,4]], [$uclass, 411, $base_uclass, 400]);
    isnt($thres[2], $thres[5]);
    isnt($thres[2], $br_addr);
    isnt($thres[5], $br_addr);
    is(dcnt, 1 + 2*$udcnt, "thread not leaked (obj + storage + storage's unit)");
}

done_testing();
