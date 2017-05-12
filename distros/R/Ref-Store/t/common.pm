package _ObjBase;
use strict;
use warnings;

sub new {
    my ($cls,%opts) = @_;
    no strict 'refs';
    my $counter_vref = \${$cls."::Counter"};
    my $v = $$counter_vref;
    my $self = \$v;
    $$counter_vref++;
    bless $self, $cls;
}

sub reset_counter {
    my $self = shift;
    no strict 'refs';
    ${ref($self) . "::Counter" } = 0;
}

@ValueObject::ISA = qw(_ObjBase);
@KeyObject::ISA = qw(_ObjBase);


package HRTests;
use Ref::Store::Common;
use Scalar::Util qw(weaken isweak);
use Test::More;
use Data::Dumper;
use Log::Fu;
use Devel::Peek qw(Dump);
use Dir::Self;

use lib __DIR__;
use threadtests;
use HRTests::Threads;

use blib;

our $Impl;

sub test_scalar_key {
    my $hash = $Impl->new();
    my $key = "Hello";
    my @object_list;
    my $obj = ValueObject->new();
    push @object_list, $obj;
    $hash->store_sk($key, $obj);
    is($hash->fetch_sk($key), $obj, "Simple retrieval");
    $hash->purge($obj);
    ok(!$hash->fetch_sk($key), "Item deleted by value");
    my @keys = qw(Key1 Key2 Key3);
    foreach (@keys) {
        $hash->store_sk($_, $obj);
    }
    
    {
        my @otmp;
        foreach (@keys) {
            push @otmp, $hash->fetch_sk($_);
        }
        is(scalar grep($_ == $obj, @otmp),
           scalar @keys, "Multi-key lookup");
        my $ktmp = pop @keys;
        $hash->unlink_sk($ktmp);
        ok(!$hash->fetch_sk($ktmp), "Single key deletion");
        $hash->purgeby_sk(shift @keys);
        ok(!$hash->fetch_sk(shift @keys), "Delete by single key");
    }
    weaken($obj);
    $hash->store("Key", $obj);
    @object_list = ();
    ok(!$hash->fetch("Key"), "Auto-deletion of keys");
}

sub test_multiple_hashes {
    my @hashes = (
        $Impl->new(),
        $Impl->new(),
    );
    my $obj = ValueObject->new();
    foreach (@hashes) {
        $_->store("Key", $obj);
    }
    my $results = 0;
    foreach (@hashes) {
        if($_->fetch("Key") == $obj) {
            $results++;
        }
    }
    
    is($results, 2, "Storage in multiple HR objects");
    $hashes[1]->store('key', $obj, StrongValue => 1);
    $hashes[0]->store('key', $obj);
    weaken($obj);
    ok($hashes[1]->fetch('key') && $hashes[0]->fetch('key'), "Different retention policies");    
    $hashes[0]->store($obj,\do { my $o },StrongValue => 1);
    $hashes[1]->unlink('key');
    ok($hashes[0]->is_empty() && $hashes[1]->is_empty, "Global Deletion");
}

sub test_object_keys {
    my $hash = $Impl->new();
    my $v = ValueObject->new();
    
    {
        my $key = KeyObject->new();
        $hash->store($key, $v);
        is($hash->fetch($key), $v, "Object key matching");
    }
    #print Dumper($hash);
    ok(!$hash->has_value($v),  "Object key GC");
    
    #Try key GC with value going out of scope
}

sub test_object_keys2 {
    my $hash = $Impl->new();
    my $key2 = KeyObject->new();
    {
        my $v2 = ValueObject->new();
        $hash->store($key2, $v2);
    }
    ok(!$hash->has_key($key2), "Value (OKEY) GC");
    
}

sub test_scalar_attr {
    my $hash = $Impl->new;
    my $t = "my_attribute";
    my $v = ValueObject->new();
    $hash->register_kt($t);
    $hash->store_a(42, $t, $v);
    ok(grep ($v, $hash->fetch_a(42, $t)), "Attr store");
    {
        my $v2 = ValueObject->new();
        $hash->store_a(42, $t, $v2);
        my @stored = $hash->fetch_a(42, $t);
        is(@stored, 2, "Added new value to attribute");
    }
    is($hash->fetch_a(42, $t), 1, "Value GC from attr collection");
    
    $hash->dissoc_a(42, $t, $v);
    ok(!$hash->has_value($v), "Value automatically deleted");
    
    #use Data::Dumper;
    #print Dumper($hash);
    
    ok(!$hash->has_attr(42, $t), "Attribute automatically deleted");
    my $v2 = ValueObject->new();
    
    $hash->store_a(42, $t, $v);
    $hash->store_a(42, $t, $v2);
    $hash->unlink_a(42, $t);
    ok(!($hash->has_attr(42, $t) || $hash->has_value($v) || $hash->has_value($v2)),
       "Totally deleted!");
    #print Dumper($hash);
}

sub test_object_attr {
    my $hash = $Impl->new();
    my $t = "OBJECT_ATTRIBUTE_";
    $hash->register_kt($t);
    my $v = ValueObject->new();
    my $attr = KeyObject->new();
    $hash->store_a($attr, $t, $v);
    ok(grep($v, $hash->fetch_a($attr, $t)), "Object attribute fetch");
    #print Dumper($hash);
    $hash->dissoc_a($attr, $t, $v);
    ok(!($hash->has_attr($attr,$t)||$hash->has_value($v)), "Object attribute deletion");
    #print Dumper($hash);
    
    
    note "Destroying $attr";
    undef $attr;
    
    note "Trying object GC";
    {
        my $tmpattr = KeyObject->new();
        $hash->store_a($tmpattr, $t, $v);
    }
    ok(!$hash->has_value($v), "Attribute object GC");
    #print Dumper($hash);
    
    #Test value GC
    $attr = KeyObject->new();
    $hash->store_a($attr, $t, $v);
    undef $v;
    ok(!($hash->has_value($v)||$hash->has_attr($attr,$t)),
       "Attribute object Value GC");
    #print Dumper($hash);
    note "Attribute tests done";
    #print Dumper($hash);
}

sub test_multilookup_attrobj {
    my $rs = $Impl->new();
    $rs->register_kt('foo');
    $rs->register_kt('bar');
    my $attrobj = KeyObject->new();
    
    my $foo_obj = ValueObject->new();
    my $bar_obj = ValueObject->new();
    
    $rs->store_a($attrobj, 'foo', $foo_obj);
    $rs->store_a($attrobj, 'bar', $bar_obj);
    $rs->store($attrobj, $foo_obj);
    $rs->unlink($attrobj);
    
    my @bar_list = $rs->fetch_a($attrobj, 'bar');
    my @foo_list = $rs->fetch_a($attrobj, 'foo');
    
    is(grep($_ == $bar_obj, @foo_list), 0, "Bar not in Foo lookup");
    is(grep($_ == $foo_obj, @bar_list), 0, "Foo not in Bar lookup");
    undef $attrobj;
    ok($rs->is_empty, "Deletion for both lookups");
    ok(1, "Bonus points. We also used the same object as a key lookup");
}

sub test_cyclical {
    $Data::Dumper::Deepcopy = 1;
    my $rs = $Impl->new();
    my $kobj = KeyObject->new();
    my $vobj = ValueObject->new();
    {
        $rs->store($kobj, $vobj);
        $rs->store($vobj, $kobj);
    }
    
    #print Dumper($rs->Dumperized);
    
    $rs->purge($vobj);
    ok(!$rs->vexists($vobj), sprintf("Value %x (%d) no longer valid", $vobj+0, $vobj+0));
    #undef $vobj;
    $vobj = undef;
    
    ok(!$rs->vexists($kobj), "Key no longer value");
    #print Dumper($rs->Dumperized);    
}

sub test_purge {
    my $rs = $Impl->new();
    $rs->register_kt('attr');
    
    my $vobj = ValueObject->new();
    my $kobj = KeyObject->new();
    my $attrobj = KeyObject->new();
    
    $rs->store('scalar_key', $vobj);
    $rs->store($kobj, $vobj);
    $rs->store_a($attrobj, 'attr', $vobj, StrongValue => 1);
    $rs->store_a('other_attr', 'attr', $vobj, StrongAttr => 1); #StrongAttr should be noop
    
    #Switch keys and values, for dramatic effect
    diag "Reverse-storing for dramatic effect";
    $rs->store($vobj, $kobj);
    
    note "purge()ing";
    
    $rs->purge($vobj);
    
    note "purged";
    
    ok(!(
        $rs->fetch('scalar_key') ||
        $rs->fetch($kobj) ||
        $rs->fetch_a($attrobj, 'attr') ||
        $rs->fetch_a('other_attr', 'attr')
    ), "Object as value deleted");
    
    ok(!$rs->vexists($vobj), "Value not present at all");
    note "About to undef $vobj";
    note "Reverse Lookup:", $rs->reverse;
    
    weaken($vobj);
    is($vobj, undef, "No more remaining references");
    
    $Data::Dumper::Deepcopy = 1;
    #print Dumper($rs->Dumperized);
    ok($rs->is_empty, "Purge");
}

use constant {
    ATTR_FOO => '_attr_foo',
    ATTR_BAR => '_attr_bar',
    KEY_GAH  => '_key_gah',
    KEY_MEH  => '_key_meh'
};
sub test_chained_basic {
    note "Chained tests";
    my $hash = $Impl->new();
    
    ValueObject->reset_counter();
    KeyObject->reset_counter();
    
    my $nested_obj = ValueObject->new();
    my $key = 'first_key';
    
    {
        $hash->store($key, $nested_obj);
        my $second_obj = ValueObject->new();
        $hash->store($nested_obj, $second_obj, StrongValue => 1);
        my $third_obj = ValueObject->new();
        $hash->store($second_obj, $third_obj, StrongValue => 1);
        $hash->register_kt(ATTR_FOO);
        $hash->register_kt(ATTR_BAR);
        $hash->store_a("1", ATTR_FOO, $third_obj);
        $hash->store_a("1", ATTR_FOO, $nested_obj);
        $hash->store_a("1", ATTR_BAR, $second_obj);
        $hash->store_a("1", ATTR_BAR, $third_obj);
    }
    $Data::Dumper::Useqq = 1;
    undef $nested_obj;
    ok($hash->is_empty(), "Nested deletion OK");
}

sub test_oexcl {
    my $h = $Impl->new();
    my $v = \time();
    $h->store("foo", $v);
    my $v2 = \time();
    local $SIG{__DIE__} = 'DEFAULT';
    eval {
        $h->store("foo", $v2);
    };
    ok($@, "Error for duplicate insertion ($@)");
}

sub just_wondering {
    my $rs = $Impl->new();
    
    $rs->register_kt('rfds');
    $rs->register_kt('wfds');
    
    pipe my($placeholder_rfd,$placeholder_wfd);
    my $orig_fd = fileno($placeholder_rfd);
    
    for (0..10) {
        pipe my($rfd,$wfd);
        $rs->store_a(1, 'rfds', $rfd);
        $rs->store_a(1, 'wfds', $wfd);
        $rs->store($rfd, $wfd, StrongKey => 1, StrongValue => 1);
    }
    ok($rs->fetch_a(1, 'wfds'));
    foreach my $wfd ($rs->fetch_a(1, 'wfds')) {
        note "Printing to $wfd";
        syswrite($wfd, "$wfd\n");
    }
    foreach my $rfd ($rs->fetch_a(1, 'rfds')) {
        my $input = sysread($rfd, my $buf, 4096);
        note "Got input $buf";
        $rs->purgeby($rfd);
    }
    #diag "Done!";
    ok($rs->is_empty(), "Cool file deletion crap..");
    
    close($placeholder_rfd);
    close($placeholder_wfd);
    
    pipe my ($nrfd,$nwfd);
    
    is(fileno($nrfd), $orig_fd, "Got same filenumber (no FD leak)");
    #$rs->dump();
}

sub retention {
    my $rs = $Impl->new();
    $rs->register_kt('some_attr');
    {
        my $v = "Hello";
        $rs->store('some_key', \$v, StrongValue => 1);
        my $v2 = "World";
        $rs->store_a(1, 'some_attr', \$v2, StrongValue => 1);
    }
    ok($rs->fetch('some_key'), "StrongValue - String Keys");
    ok($rs->fetch_a(1, 'some_attr'), "Strong Value - String Attributes");
    
    $rs->purgeby('some_key');
    $rs->purgeby_a(1, 'some_attr');
    
    my $ev1 = [];
    my $ev2 = {};
    
    {
        my $k1 = [];
        my $k2 = [];
        $rs->store($k1, $ev1, StrongKey => 1);
        $rs->store_a($k2, 'some_attr', $ev2, StrongAttr => 1);
    }
    ok($rs->vexists($ev1) && $rs->vexists($ev2), "key persistence");
    #$rs->dump();
    
}

sub test_kt {
    my $rs = $Impl->new();
    $rs->register_kt('foo');
    $rs->register_kt('bar');
    my $foo_obj = ValueObject->new();
    my $bar_obj = ValueObject->new();
    $rs->store_kt(42, 'foo', $foo_obj);
    $rs->store_kt(42, 'bar', $bar_obj);
    is($rs->fetch_kt(42, 'foo'), $foo_obj);
    is($rs->fetch_kt(42, 'bar'), $bar_obj);
}

sub test_iter {
    use Ref::Store qw(:ref_store_constants);
    my $rs = $Impl->new();
    $rs->register_kt('attr');
    $rs->register_kt('keytype');
    
    my $attrobj = KeyObject->new();
    my $vobj    = ValueObject->new();
    my $kobj    = KeyObject->new();
    
    $rs->store_kt('simple_key', 'keytype', $vobj);
    $rs->store_kt($kobj, 'keytype', $vobj);
    $rs->store_a($attrobj, 'attr', $vobj);
    
    my %seen_hash;
    
    $rs->iterinit();
    while( my ($lt,$pfix,$key,$obj) = $rs->iter() ) {
        note sprintf("TYPE=%s, PREFIX=%s, KEY=%s, OBJ=%s",
           ref_store_constants_to_str($lt), $pfix, $key, $obj);
        my $obj_s = $obj;
        if($lt == REF_STORE_ATTRIBUTE) {
            $obj_s = $obj->[0];
        }
        $seen_hash{$lt.$pfix.$key.$obj_s} = 1;
    }
    ok($seen_hash{REF_STORE_KEY . 'keytype' . 'simple_key' . $vobj});
    ok($seen_hash{REF_STORE_KEY . '' . $kobj . $vobj });
    ok($seen_hash{REF_STORE_ATTRIBUTE . 'attr' . $attrobj . $vobj });
}

sub misc_api {
    my $rs = $Impl->new();
    $rs->register_kt('some_attr');
    my @objs = map { \do { $_ } } (0..10);
    
    $rs->store($$_, $_, StrongValue => 1) for @objs;
    my @vlist = $rs->vlist;
    my $ok = 1;
    foreach my $obj (@objs) {
        if(!grep $_, @vlist) {
            $ok = 0;
        }
    }
    ok($ok, "Got all values from vlist()");
    $ok = 1;
    foreach my $obj (@objs) {
        if(!$rs->vexists($obj)) {
            $ok = 0;
        }
    }
    ok($ok, "All values ok with vexists()");
    $rs->purge($_) foreach @objs;
    ok($rs->is_empty(), "Table is empty");
    
    
}

sub test_all {
    eval "require $Impl";
    subtest "Simple Scalar Keys"            => \&test_scalar_key;
    subtest "Object Keys - Basic tests"     => \&test_object_keys;
    subtest "Object Keys - Extended tests"  => \&test_object_keys2;

    subtest "Scalar Attributes"             => \&test_scalar_attr;
    subtest "Object Attributes"             => \&test_object_attr;
    subtest "Multi Lookup Attribute Objects"=> \&test_multilookup_attrobj;

    subtest "Chained Object Graphs"         => \&test_chained_basic;

    subtest "Duplicate Errors"              => \&test_oexcl;
    subtest "Typed Keys"                    => \&test_kt;
    
    SKIP : {
        skip "PP Backend is crappy", 2 unless $Impl !~ /PP/;
        subtest "Purge"                         => \&test_purge;
        subtest "Cyclical Keys"                 => \&test_cyclical;

    }
    
    $HRTests::Threads::Impl = $Impl;
    
    SKIP : {
        skip "Only implemented in XS", 1 unless $Impl =~ /XS/;
        subtest "Iteration"                 => \&test_iter;
    }
    
    if($Impl =~ /XS/) {
        threads_test_all();
    } else {
        TODO: {
            todo_skip "PP Backend doesn't support threads", 1;
            subtest "Threads (PP)"  => \&threads_test_all;
        };
    }
    
    subtest "Simple use case (Filehandle tracking" =>\&just_wondering;
    subtest "Retention Policy"              =>\&retention;
    subtest "Debug/Info API"                => \&misc_api;
    subtest "Multiple table sanity check"   => \&test_multiple_hashes;
    diag "Done testing";
    done_testing();
}
1;
