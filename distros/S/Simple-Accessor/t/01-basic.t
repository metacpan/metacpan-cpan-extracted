use strict;
use warnings;

use Test::More tests => 28;
use FindBin;

use lib $FindBin::Bin. '/lib';

use_ok 'MyObject';

my $o = MyObject->new();
isa_ok $o, 'MyObject';
for my $att (qw{a list of attributes}) {
    is $o->$att(), undef, "can call att $att";
    my $v = 1 + int rand(42);
    ok $o->$att($v), "set $att";
    is $o->$att(), $v, "get $att";
}

{
	# test for 0
	$o = MyObject->new();
	is $o->a, undef;
	is $o->a(0), 0, 'set 0';
	is $o->a(), 0, "we can set/get 0";

	$o = MyObject->new( a => 0 );
	is $o->a(), 0, "we can init 0";
}

use_ok 'Initialize';

my $init = Initialize->new();
isa_ok $init, 'Initialize';

is $init->foo(), 51, "foo has been set by initialize";

$init = Initialize->new( bar => 123 );
is $init->bar(), 123, "bar set by new";

$init = Initialize->new( rab => 321 );
is $init->bar(), 321, "bar set by init";

$init = Initialize->new();
is $init->bar(), 1031, 'from initialize hook';

use_ok 'Hooks';

my $h = Hooks->new();
$h->invalid(1324156);
is $h->invalid(), undef, "everything is invalid";

$h->kiwi('fruit');
is $h->kiwi() => 'fruit', "before and validate";

is $h->apple() => 'fruit', 'after hook';
