#$Id: test.pl,v 1.14 2007/02/11 10:59:14 dk Exp $

use Test::More tests => 79;
use strict;

# pre-test. bail out if PHP libraries are not installed on this system.



BEGIN {
    ok( eval "use PHP;1", 'use_ok PHP' );
    if ($@ && $@ =~ /Can't locate loadable object for module PHP/) {
	diag $@;
	BAIL_OUT(
	    "PHP libraries compiled for embedded SAPI not found" );
    }
}
require_ok('PHP');

# 3 
eval {
PHP::eval(<<'S1');

function loopback($var)
{
	return $var;
}

function new_array()
{
	return array();
}

function print_val($arr,$val)
{
	echo $arr[$val];
}

class TestClass
{
	var $prop;
	function TestClass ($a) { echo $a; }
	function method($val) { return $val + 1; }
	function getprop() { return $this->prop; }
};

S1
};
ok( !$@, 'eval');
die $@ if $@;

# 4,5
my $val;
eval {
	$val = PHP::call( 'loopback', 42);
};
ok( !$@, 'call');
ok( defined $val && $val eq '42', 'pass arguments, return values');

# 6
eval {
	PHP::eval('$');
};
ok( $@, 'invalid syntax exceptions');

# 7 
my $output = '';
PHP::options( stdout => sub { $output = shift});
PHP::eval( 'echo 42;');
ok( $output eq '42', 'catch output');

# 8 
my $a = PHP::new_array();
ok( $a, 'get array from php');

# 9
my $b = PHP::ArrayHandle-> new();
ok( $b, 'create array handle');

my ( @array, %hash);
$a->tie(\%hash);
$a->tie(\@array);

# 10
$array[1] = 'array';
ok( defined $array[1] && $array[1] eq 'array', 'tied array');

# 11
$hash{'h'} = 'hash';
ok( defined $hash{'h'} && $hash{'h'} eq 'hash', 'tied hash');

# 12
PHP::print_val($a, 1);
ok( $output eq 'array', 'query array value');

# 13
PHP::print_val($a, 'h');
ok( $output eq 'hash', 'query hash value');

# 14
PHP::TieHash::STORE( $b, '42', '42');
ok( PHP::TieHash::FETCH( $b, '42') eq '42', 'direct array access');

# 15
$output = '';
my $TestClass = PHP::Object-> new('TestClass', '43');
ok( $TestClass && $output eq '43', 'class');

# 16
ok( $TestClass-> method(42) == 43, 'methods');

# 17
$TestClass->tie(\%hash);
$hash{prop} = 42;
ok( $TestClass-> getprop() == 42, 'properties');

# 18
eval {
PHP::eval('call_unexistent_function_wekljfhv2kwfwkfvbwkfbvwjkfefv();');
};
ok($@ && $@ =~ /call_unexistent_function/, 'undefined function exceptions');

# 19
my $arr = PHP::array;
$arr->[1] = 42;
ok( $arr->[1] == 42, 'pseudo-hash, as array');

# 20
$arr->{'mm'} = 42;
ok( $arr->{'mm'} == 42, 'pseudo-hash, as hash');

# 21
my @k = keys %$arr;
ok(( 2 == @k and 2 == scalar grep { m/^(1|mm)$/ } @k), 'hash keys');

$output = '';
SKIP:{
	skip "php5 required", 3 unless PHP::options('version') =~ /^(\d+)/ and $1 > 4;
	eval { PHP::eval(<<'MOO'); };
class P5 {
	function __construct() { echo "CREATE"; }
	function __destruct() { echo "DESTROY"; }
}
function p5(){$a = new P5;return $a;}
MOO
	{
	my $P5 = PHP::Object-> new('P5');
	ok(!$@ && $P5, 'php5 syntax');
	ok($output eq 'CREATE', 'php5 constructors');
	}
	ok($output eq 'DESTROY', 'php5 destructors');
}

# 25
ok( scalar( @$arr) == 2, 'sparse arrays');

# 26
ok( 5 == push (@$arr, qw(1 2 3)), 'push');

# 27
my $k = 0 || pop @$arr; 
ok(( 4 == @$arr and '3' eq $k), 'pop');

undef $arr;


# 28
eval { PHP::eval('throw new Exception("bork");'); };
my $exc = $@;
$val = PHP::call( 'loopback', 42);
ok(( $exc and $val == 42), 'exceptions in eval');

# 29
SKIP:{
skip "php5 required", 1 unless PHP::options('version') =~ /^(\d+)/ and $1 > 4;
PHP::eval('function boom() { throw new Exception("bork"); } '); 
eval { PHP::call( 'boom'); };
my $exc = $@;
$val = PHP::call( 'loopback', 42);
ok(( $exc and $val == 42), 'exceptions in calls');
}

# 30
my @test30 = ();
PHP::eval('$foo = 43;');
PHP::options( stdout => sub { push @test30, $_[0] } );
PHP::eval('echo "hello " . $foo;');

PHP::__reset();
PHP::options( stdout => sub { push @test30, $_[0] } );
PHP::eval('echo "world " . $foo;');
ok(@test30 == 2 && $test30[0] eq 'hello 43' && $test30[1] eq 'world ',
    "PHP::__reset clears variables in previous instance");

# 31
PHP::assign_global("test31", 75);
PHP::eval('function test31() { global $test31; return $test31; }');
my $a31 = PHP::call('test31');
ok($a31 == 75, "assign_global simple scalar");

# 32
PHP::assign_global("test32", [1, 19, "qwert"]);
PHP::eval('function test32() { global $test32; return $test32; }');
my $a32 = PHP::call('test32');
ok(ref($a32) eq 'PHP::Array' && $a32->[0]==1 && $a32->[1]==19 && $a32->[2]eq'qwert',
    "assign_global listref");

# 33
PHP::assign_global("test33", { foo => [ 19, 52 ], cats => "the other white meat" });
PHP::eval('function test33() { global $test33; return $test33; }');
my $a33 = PHP::call('test33');
ok(ref($a33) eq 'PHP::Array' && $a33->{foo}[1]==52 && $a33->{cats} =~ /white meat/,
    "assign_global complex data structure");

# 34
my $r = PHP::eval_return('40+2');
ok( $r == 42, 'simple eval/return');

# 35
$r = PHP::eval_return('$test33');
ok( $r && ref($r) && ref($r) eq 'PHP::Array' && $r->{cats} =~ /white meat/,
    'global var in eval/return');

# 36
my @h36 = ();
PHP::options( header => sub { push @h36, $_[0]; } );
PHP::eval('header("Subject: Payload");');
PHP::eval_return('header("Header-X: This is a header");');
ok( $h36[0] eq 'Subject: Payload' && $h36[1] =~ /This is a header/,
    "PHP::options(header => ...) callback" );

# 37
my $a37 = [ 42 ];
my $b37 = [ $a37 ];
$a37->[0] = $b37;
$SIG{ALRM} = sub { die "Timeout assigning global with circular ref\n" };
alarm 5;
my $z37 = eval {
    PHP::assign_global( 'foo', $a37 );
    1;
};
alarm 0;
ok( $z37, 'assign_global with circular ref didn\'t cause infinite loop' );

# 38
PHP::assign_global( 'g38', bless ['I','II','III','IV'],'Roman::Numeral::Array' );
my $g38 = PHP::eval_return('$g38;');
ok( $g38 && ref($g38) && ref($g38) eq 'PHP::Array'
    && $g38->[0] eq 'I' && $g38->[3] eq 'IV',
    'assign_global blessed list reference' );

# 39
PHP::assign_global( 'g39', bless { Brazil => 'Brasilia', Uruguay => 'Montevideo' }, 'South::American::Capitols' );
my $g39 = PHP::eval_return( '$g39;' );
ok( $g39 && ref($g39) && ref($g39) eq 'PHP::Array'
    && $g39->{Brazil} eq 'Brasilia' && $g39->{Uruguay} eq 'Montevideo',
    'assign_global blessed hash reference' );

# 40
PHP::assign_global( 'g40', { hash => { abc => 'def' }, list => [3,4,5], scalar => 4 } );
my $g40 = PHP::eval_return( '$g40;' );
ok( $g40 && ref($g40) && ref($g40) eq 'PHP::Array'
    && ref($g40->{hash}) eq 'PHP::Array'
    && ref($g40->{list}) eq 'PHP::Array'
    && ref($g40->{scalar}) eq '',
    'assign_global: complex data structure has nested PHP::Array' );

# 41
ok( PHP::eval_return('"Evaluate PHP statement from Perl? Awesome!";') =~ /awesome/i,
    'eval/return simple string' );

# 42
PHP::eval('$foo=5;');
ok( PHP::eval_return('$foo*$foo;') == 25,
    'eval/return simple expression with variables ');

# 43-45
ok( PHP::eval_return('TRUE;') == 1, 'eval/return TRUE maps to 1' );
ok( PHP::eval_return('FALSE;') eq '', 'eval/return FALSE maps to ""' );
ok( !defined(PHP::eval_return('NULL;')), 'eval/return NULL maps to undef' );

# 46-47
ok( PHP::eval_return('4 > 5 ? 19 : 42;') == 42, 'eval/return ternary 1' );
ok( PHP::eval_return('4 < 5 ? 19 : 42;') == 19, 'eval/return ternary 2' );

# 48-53: the don'ts of eval_return
eval { PHP::eval_return('return "foo";') };
ok( $@, 'don\'t use "return" inside PHP::eval_return' );

eval { PHP::eval_return('if (2<17) 8; else 9;') };
ok ($@, 'don\'t use "if", "if/else" inside PHP::eval_return' );

eval { PHP::eval_return('function foo() { return 42; }') };
ok ($@, 'don\'t declare functions inside PHP::eval_return' );

eval { PHP::eval_return('echo 16;') };
ok ($@, 'don\'t use echo inside PHP::eval_return' );

eval { PHP::eval_return('die("die message");') };
ok ($@, 'don\'t call die() inside PHP::eval_return' );

eval { PHP::eval_return('exit(4);') };
ok ($@, 'don\'t call exit() inside PHP::eval_return' );

# 54-55
my $t54 = eval { PHP::eval_return(''); };
ok( !$@ && !defined($t54), 'eval/return(empty) ok, undef' );

my $t55 = eval { no warnings 'uninitialized'; PHP::eval_return(undef); };
ok( !$@ && !defined($t55), 'eval/return(undef) ok, undef' );

# 56-57
my $t56 = eval { PHP::eval_return('abs(-6)-log10(1000);') ; };
ok( $t56==3, 'eval/return with math functions' );

my $t57 = eval { PHP::eval_return("date('Y',$^T);"); };
ok($t57 >= 2012 && $t57 < 2020, 'eval/return with datetime functions');

# 58-60
my $t58 = eval { PHP::eval_return("array(5,10,15,20);"); };
ok($t58->[0] == 5 && $t58->[3] == 20, 'eval/return simple array');

my $t59 = eval { PHP::eval_return('array("abc"=>45, "ghi"=>"tennis");') };
ok($t59->{abc} == 45 && $t59->{ghi} eq "tennis" && !defined($t59->{foo}),
    'eval/return simple associative array');

my $t60 = eval { PHP::eval_return( q^
array(11, 16, array( "Perl" => "good", "PHP" => "meh" ),
      array(5, 8, 13, 21, 34));^) };
ok($t60->[1] == 16 && $t60->[2]{PHP} !~ /good/ && $t60->[3][3] == 21,
    'eval/return more complex data structure');

# 61-63
my $fake_file = "/fj234oi/453rerf3v434v3.txt";
my $fake_file2 = "/fj234o1e2123ei/453rqwrqe1241423rwerf3v434v3.txt";
ok( ! PHP::eval_return( "is_uploaded_file('$fake_file')" ),
    "is_uploaded_file false for fake file" );
PHP::_spoof_rfc1867($fake_file);
ok( PHP::eval_return( "is_uploaded_file('$fake_file')" ),
    "is_uploaded_file true for spoofed fake file" );
PHP::_spoof_rfc1867($fake_file2);
ok( PHP::eval_return( "is_uploaded_file('$fake_file') && is_uploaded_file('$fake_file2')" ),
    "is_uploaded_file true for two spoofed files" );

# 64-71
my @superglobals = qw(_SERVER _GET _POST _FILES _COOKIE _SESSION _REQUEST _ENV);
my $jj = 0;
foreach my $global (@superglobals) {
    $jj++;
    my $data = { foo => 123, bar => 'def', name => $global, jj => $jj };
    PHP::assign_global( $global, $data );
    my $t = PHP::eval_return( '$' . $global );
    ok( $t->{foo} eq '123' && $t->{bar} eq 'def' && $t->{name} eq $global && $t->{jj} == $jj,
	"assignment to superglobal \$$global");
}

# 72-75
my $test_file = "upload_test1";
my $test_file2 = "upload test2";
unlink $test_file, $test_file2;
ok( ! PHP::call('move_uploaded_file', $test_file, $test_file2),
    'move_uploaded_file not successful yet' );
open my $fh, '>', $test_file;
print $fh "upload test file\n";
close $fh;
PHP::_spoof_rfc1867( $test_file );
ok( -f $test_file && PHP::eval_return( "is_uploaded_file('$test_file')" ),
    'test upload file acknowledged by PHP' );
ok( PHP::call('move_uploaded_file', $test_file, $test_file2),
    'move_uploaded_file successful on spoofed upload' );
ok( -f $test_file2 && ! -f $test_file,
    'moved uploaded file has a new name' );
unlink $test_file, $test_file2;

# 76
PHP::set_php_input("0123456789012345678\n" x 568);
my $t76 = PHP::eval_return( 'file_get_contents("php://input")' );
ok( $t76 eq "0123456789012345678\n" x 568,
    'post content avail in php://input' );

# 77-79
my ($t77,$t78);
PHP::options( header => sub { ($t77,$t78) = @_ } );
PHP::header("foo: bar", 1);
ok($t77 eq 'foo: bar' && $t78 == 1, 'header callback receives 2 args');
PHP::header("bar: foo", 0);
ok($t77 eq 'bar: foo' && $t78 == 0, 'header callback receives replace arg');
PHP::header("bar: foo");
ok($t77 eq 'bar: foo' && $t78 == 1,'default replace arg is true');
