package HRTests::Threads;
use strict;
use warnings;
use Test::More;
my $can_use_threads = eval 'use threads; 1';
BEGIN {
    $INC{'HRTests/Threads.pm'} = 1;
}

our $Impl;

sub threads_test_kscalar {
    note "Testing threads (String keys)";
    my $table = $Impl->new();
    my $v = ValueObject->new();
    my $k = "some_key";
    $table->store_sk($k, $v);
    my $k2 = "other_key";
    $table->store_sk($k2, $v);
    #$table->dump();
    
    my $fn = sub {
        #$table->dump();
        my $res = $table->fetch_sk($k) == $v && $table->fetch_sk($k2) == $v;
        return $res;
    };
    my $thr = threads->create($fn); #line displaying message
    ok($fn->(), "Same thing works in the parent!");
    ok($thr->join(), "Thread duplication");

}

sub threads_test_kencap {
    note "Testing threads (Object keys)";
    my $table = $Impl->new();
    my $v = ValueObject->new();
    my $ko = KeyObject->new();
    $table->store_sk($ko, $v);
    
    my $fn = sub {
        my $ret = $table->fetch_sk($ko) == $v;
        return $ret;
    };
    
    my $thr = threads->create($fn);
    ok($fn->(), "Object keys working");
    ok($thr->join(),"Thread duplication for encapsulated object keys");
}

sub threads_test_kchained {
    note "Testing threads (chained keys)";
    my $table = $Impl->new();
    my $k_first = KeyObject->new();
    my $v_first = ValueObject->new();
    my $v_second = ValueObject->new();
    
    $table->store_sk($k_first, $v_first);
    $table->store_sk($v_first, $v_second);
    
    my $fn = sub {
        $table->fetch_sk($k_first) == $v_first &&
            $table->fetch_sk($v_first) == $v_second
    };
    
    my $thr = threads->create($fn);
    ok($fn->(), "Ok in parent");
    ok($thr->join(), "Ok in thread!");
    
    note "About to undef table";
    $table->purge($_) foreach ($k_first,$v_first,$v_second);
    undef $table;
}

sub threads_test_attr_scalar {
    note "Testing threads (scalar attributes)";
    my $v = ValueObject->new();
    my $table = $Impl->new();
    $table->register_kt('attr1');
    $table->store_a(1, 'attr1', $v);
    my $thr = threads->create(sub {
        grep $v, $table->fetch_a(1, 'attr1');
    });
    
    ok($thr->join(),"Got value from attribute store");
}

sub threads_test_attr_encap_single {
    note "Testing threads (object attributes -- single value)";
    my $table = $Impl->new();
    $table->register_kt('ATTROBJ');
    my $aobj = KeyObject->new();
    my $v = ValueObject->new();
    note sprintf("value=%x, attr=%x", $v, $aobj);
    $table->store_a($aobj, 'ATTROBJ', $v);
    
    my $thr = threads->create(sub{
        note sprintf("new value=%x, new attr=%x", $v, $aobj);
        grep $v, $table->fetch_a($aobj, 'ATTROBJ') &&
        scalar $table->fetch_a($aobj, 'ATTROBJ') == 1;
    });
    
    ok($thr->join(),"Attribute object -- single value");
}

sub threads_test_attr_encap_multi {
    note "Testing threads (object attributes -- multiple values)";
    my $table = $Impl->new();
    $table->register_kt('ATTROBJ');
    my $aobj = KeyObject->new();
    my $v_first = ValueObject->new();
    my $v_second = ValueObject->new();
    
    $table->store_a($aobj, 'ATTROBJ', $v_first);
    $table->store_a($aobj, 'ATTROBJ', $v_second);
    
    my $thr = threads->create(sub{
        grep($v_first, $table->fetch_a($aobj, 'ATTROBJ')) &&
        grep($v_second, $table->fetch_a($aobj, 'ATTROBJ')) &&
        scalar $table->fetch_a($aobj, 'ATTROBJ') == 2
    });
    ok($thr->join(), "Attribute Object -- multiple values");
    note "Returning...";
}

sub threads_test_attr {
    note "Testing threads (attributes)";
    my $v = ValueObject->new();
    my $v_second = ValueObject->new();
    my $v_first = ValueObject->new();
    
    my $table = $Impl->new();
    
    $table->register_kt("ATTR");
    $table->store_a(1, "ATTR", $v);
    
    my $thr = threads->create(sub{
        grep $v, $table->fetch_a(1, 'ATTR')
    });
    ok($thr->join(), "Got value from attribute store");
    
    $table->register_kt('ATTROBJ');
    $table->store_a($v_first, 'ATTROBJ', $v);
    $table->store_a($v_first, 'ATTROBJ', $v_second);
    
    $thr = threads->create(sub{
            grep($v, $table->fetch_a($v_first, 'ATTROBJ')) &&
            grep($v_second, $table->fetch_a($v_first, 'ATTROBJ'))
    });
    
    ok($thr->join(), "Attribute Object");
}

sub threads_test_all {
    SKIP: {
        skip "Perl not threaded", 4 unless $can_use_threads;
        
        threads_test_kscalar();
        threads_test_kencap();
        threads_test_kchained();
        threads_test_attr();
        threads_test_attr_encap_single();
        threads_test_attr_encap_multi();
    }
}

use base qw(Exporter);
our @EXPORT = qw(
    threads_test_kscalar
    threads_test_kencap
    threads_test_kchained
    threads_test_attr
    threads_test_attr_scalar
    threads_test_attr_encap_single
    threads_test_attr_encap_multi
    threads_test_attr_encap
    threads_test_all
);


1;
