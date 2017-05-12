use 5.012;
use warnings;
use lib 't/lib';
use PXSTest 'full';

our $dcnt = 0;
our $called = 0;
our $argsum = 0;

# check that subs/methods are called, arguments are passed, retvals are okay and no memleaks (check destructor calls count)

{
    package ValPack;
    sub new     { my $v = $_[1]; return bless \$v, __PACKAGE__ }
    sub DESTROY { $main::dcnt++ }
    
    package SubPack;
    
    *val   = *main::val;
    *dcall = *main::dcall;
    
    sub r0 { dcall(@_); return }
    sub r1 { dcall(@_); return val(1) }
    sub rN { dcall(@_); return (val(1), val(2), val(3), val(4), val(5)) }
    
    package ObjPack;
    our @ISA = 'ImplPack';
    
    sub new { my $v = $_[1]; return bless \$v, __PACKAGE__ }
    
    package ImplPack;
    
    *val   = *main::val;
    *dcall = *main::dcall;
    
    sub r0 { dcall(@_); return }
    sub r1 { dcall(@_); return val(1) }
    sub rN { dcall(@_); return (val(1), val(2), val(3), val(4), val(5)) }
    
}

my ($ret, @ret, $aret);
my $obj = new ObjPack(1000);

test_call_sub_void();
test_call_sub_scalar();
test_call_sub_list();
test_call_sub_av();
test_call_method_void();
test_call_method_scalar();
test_call_method_list();
test_call_method_av();

sub test_call_sub_void {
	Panda::XS::Test::call_sub_void("SubPack::r0");
	cmp_deeply(chk(), [1, 0, 0], "void sub in void context with no args");
	rst();
	
	Panda::XS::Test::call_sub_void("SubPack::r0", [val(2), val(3)]);
	cmp_deeply(chk(), [1, 5, 2], "void sub in void context with args, args not leaked");
	rst();
	
	Panda::XS::Test::call_sub_void("SubPack::r1");
	cmp_deeply(chk(), [1, 0, 1], "scalar sub in void context, retval not leaked");
	rst();
	
	Panda::XS::Test::call_sub_void("SubPack::rN", [val(11)]);
	cmp_deeply(chk(), [1, 11, 6], "list sub in void context with args, retvals not leaked");
	rst();
}

sub test_call_sub_scalar {
	is(Panda::XS::Test::call_sub_scalar("SubPack::r0"), undef, "void sub in scalar context, returns undef");
	cmp_deeply(chk(), [1, 0, 0], "called");
	rst();
	
	is(Panda::XS::Test::call_sub_scalar("SubPack::r0", [val(555)]), undef, "void sub in scalar context with args, returns undef");
	cmp_deeply(chk(), [1, 555, 1], "args not leaked");
	rst();
	
	cmp_deeply(Panda::XS::Test::call_sub_scalar("SubPack::r1"), noclass(\1), "scalar sub in scalar context, retval ok");
	cmp_deeply(chk(), [1, 0, 1], "retval not leaked");
	rst();
	
	cmp_deeply(Panda::XS::Test::call_sub_scalar("SubPack::rN"), noclass(\5), "list sub in scalar context, returns last val");
	cmp_deeply(chk(), [1, 0, 5], "all values not leaked");
	rst();
	
	cmp_deeply(Panda::XS::Test::call_sub_scalar("SubPack::r1", undef, 1), "NULL", "scalar sub in scalar discard context, returns NULL");
	cmp_deeply(chk(), [1, 0, 1], "retval not leaked");
	rst();
	
	cmp_deeply(Panda::XS::Test::call_sub_scalar("SubPack::rN", undef, 1), "NULL", "list sub in scalar discard context, returns NULL");
	cmp_deeply(chk(), [1, 0, 5], "all values not leaked");
	rst();
}

sub test_call_sub_list {
	is(Panda::XS::Test::call_sub_list("SubPack::r0", $aret, 10), 0, "void sub in list context, returns zero vals");
	cmp_deeply(chk(), [1, 0, 0], "called");
	cmp_deeply($aret, [], "retarr is empty");
	rst();
	
	is(Panda::XS::Test::call_sub_list("SubPack::r0", $aret, 10, [val(111), val(222)]), 0, "void sub in list context with args, returns nothing");
	cmp_deeply(chk(), [1, 333, 2], "args not leaked");
	cmp_deeply($aret, [], "retarr is empty");
	rst();
	
	is(Panda::XS::Test::call_sub_list("SubPack::r1", $aret, 1), 1, "scalar sub in list context (expect 1), returns one value");
	cmp_deeply(chk(), [1, 0, 0], "retval still alive");
	cmp_deeply($aret, [noclass(\1)], "retarr contains correct value");
	undef $aret;
	is($dcnt, 1, "retval not leaked");
	rst();
	
	is(Panda::XS::Test::call_sub_list("SubPack::r1", $aret, 10), 1, "scalar sub in list context (expect 10), returns one value");
	cmp_deeply(chk(), [1, 0, 0], "retval still alive");
	cmp_deeply($aret, [noclass(\1)], "retarr contains correct value");
	undef $aret;
	is($dcnt, 1, "retval not leaked");
	rst();
	
	is(Panda::XS::Test::call_sub_list("SubPack::r1", $aret, 0), 0, "scalar sub in list context (expect 0), returns nothing");
	cmp_deeply(chk(), [1, 0, 1], "retval discarded and not leaked");
	cmp_deeply($aret, [], "retarr is empty");
	rst();
	
	is(Panda::XS::Test::call_sub_list("SubPack::r1", $aret, 5, undef, 1), 0, "scalar sub in list discard context, returns nothing");
	cmp_deeply(chk(), [1, 0, 1], "retval not leaked");
	cmp_deeply($aret, [], "retarr is empty");
	rst();
	
	is(Panda::XS::Test::call_sub_list("SubPack::rN", $aret, 5), 5, "list sub in list context (expect 5), returns 5 values");
	cmp_deeply(chk(), [1, 0, 0], "retvals still alive");
	cmp_deeply($aret, [map {noclass(\$_)} 1..5], "retarr contains correct values");
	undef $aret;
	is($dcnt, 5, "retvals not leaked");
	rst();
	
	is(Panda::XS::Test::call_sub_list("SubPack::rN", $aret, 3), 3, "list sub in list context (expect 3), returns 3 values");
	cmp_deeply(chk(), [1, 0, 2], "3 retvals still alive, 2 discarded and not leaked");
	cmp_deeply($aret, [map {noclass(\$_)} 1..3], "retarr contains correct values");
	undef $aret;
	is($dcnt, 5, "retvals not leaked");
	rst();
	
	is(Panda::XS::Test::call_sub_list("SubPack::rN", $aret, 0), 0, "list sub in list context (expect 0), returns nothing");
	cmp_deeply(chk(), [1, 0, 5], "all retvals discarded and not leaked");
	cmp_deeply($aret, [], "retarr is empty");
	rst();
	
	is(Panda::XS::Test::call_sub_list("SubPack::rN", $aret, 10), 5, "list sub in list context (expect 10), returns 5 values");
	cmp_deeply(chk(), [1, 0, 0], "retvals still alive");
	cmp_deeply($aret, [map {noclass(\$_)} 1..5], "retarr contains correct values");
	undef $aret;
	is($dcnt, 5, "retvals not leaked");
	rst();
	
	is(Panda::XS::Test::call_sub_list("SubPack::rN", $aret, 5, undef, 1), 0, "list sub in list discard context, returns nothing");
	cmp_deeply(chk(), [1, 0, 5], "retvals not leaked");
	cmp_deeply($aret, [], "retarr is empty");
	rst();
}

sub test_call_sub_av {
	cmp_deeply(Panda::XS::Test::call_sub_av("SubPack::r0"), undef, "void sub in list context (expect any), returns NULL");
	cmp_deeply(chk(), [1, 0, 0], "called");
	rst();
	
	cmp_deeply(Panda::XS::Test::call_sub_av("SubPack::r0", [val(111), val(222)]), undef, "void sub in list context (expect any) with args, returns NULL");
	cmp_deeply(chk(), [1, 333, 2], "and args not leaked");
	rst();
	
	cmp_deeply(Panda::XS::Test::call_sub_av("SubPack::r1"), [noclass(\1)], "scalar sub in list context (expect any), returns one value");
	cmp_deeply(chk(), [1, 0, 1], "retval not leaked");
	rst();
	
	cmp_deeply(Panda::XS::Test::call_sub_av("SubPack::r1", undef, 1), undef, "scalar sub in list discard context (expect any), returns NULL");
	cmp_deeply(chk(), [1, 0, 1], "retval not leaked");
	rst();
	
	cmp_deeply(Panda::XS::Test::call_sub_av("SubPack::rN"), [map {noclass(\$_)} 1..5], "list sub in list context (expect any), returns 5 values");
	cmp_deeply(chk(), [1, 0, 5], "retvals not leaked");
	rst();
	
	cmp_deeply(Panda::XS::Test::call_sub_av("SubPack::rN", undef, 1), undef, "list sub in list discard context (expect any), returns NULL");
	cmp_deeply(chk(), [1, 0, 5], "retvals not leaked");
	rst();
}

sub test_call_method_void {
	Panda::XS::Test::call_method_void($obj, "r0");
    cmp_deeply(chk(), [1, 1000, 0], "void method in void context with no args");
    rst();
    
    Panda::XS::Test::call_method_void($obj, "r0", [val(2), val(3)]);
    cmp_deeply(chk(), [1, 1005, 2], "void method in void context with args, args not leaked");
    rst();
    
    Panda::XS::Test::call_method_void($obj, "r1");
    cmp_deeply(chk(), [1, 1000, 1], "scalar method in void context, retval not leaked");
    rst();
    
    Panda::XS::Test::call_method_void($obj, "rN", [val(11)]);
    cmp_deeply(chk(), [1, 1011, 6], "list method in void context with args, retvals not leaked");
    rst();
}

sub test_call_method_scalar {
    cmp_deeply(Panda::XS::Test::call_method_scalar($obj, "r1"), noclass(\1), "scalar method in scalar context, retval ok");
    cmp_deeply(chk(), [1, 1000, 1], "retval not leaked");
    rst();
    
    cmp_deeply(Panda::XS::Test::call_method_scalar($obj, "r1", undef, 1), "NULL", "scalar method in scalar discard context, returns NULL");
    cmp_deeply(chk(), [1, 1000, 1], "retval not leaked");
    rst();
}

sub test_call_method_list {
    is(Panda::XS::Test::call_method_list($obj, "rN", $aret, 10), 5, "list method in list context (expect 10), returns 5 values");
    cmp_deeply(chk(), [1, 1000, 0], "retvals still alive");
    cmp_deeply($aret, [map {noclass(\$_)} 1..5], "retarr contains correct values");
    undef $aret;
    is($dcnt, 5, "retvals not leaked");
    rst();
    
    is(Panda::XS::Test::call_method_list($obj, "rN", $aret, 5, undef, 1), 0, "list method in list discard context, returns nothing");
    cmp_deeply(chk(), [1, 1000, 5], "retvals not leaked");
    cmp_deeply($aret, [], "retarr is empty");
    rst();
}

sub test_call_method_av {
    cmp_deeply(Panda::XS::Test::call_method_av($obj, "rN"), [map {noclass(\$_)} 1..5], "list method in list context (expect any), returns 5 values");
    cmp_deeply(chk(), [1, 1000, 5], "retvals not leaked");
    rst();
    
    cmp_deeply(Panda::XS::Test::call_method_av($obj, "rN", undef, 1), undef, "list method in list discard context (expect any), returns NULL");
    cmp_deeply(chk(), [1, 1000, 5], "retvals not leaked");
    rst();
}


sub val { return new ValPack(shift()) }

sub dcall {
    $argsum += $$_ for @_;
    $called++;
}

sub rst {
    $aret = [];
    $argsum = $called = $dcnt = 0;
}

sub chk { [$called, $argsum, $dcnt] }

done_testing();
