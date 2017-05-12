use strict;
#use Test::More qw(no_plan);
use Test::More tests => 38;
use Object::AutoAccessor;


#1 new()
{
	my $obj = Object::AutoAccessor->new();
	
	is ( ref($obj) => 'Object::AutoAccessor' );
}


#2 setter/getter, param
{
	my $obj = Object::AutoAccessor->new();
	
	$obj->foo('FOO');
	is ( $obj->foo => 'FOO' );
	
	$obj->set_bar('BAR');
	is ( $obj->get_bar => 'BAR' );
	
	$obj->param(baz => 'BAZ', up => 'DOWN');
	is ( $obj->param('baz') => 'BAZ' );
	
	is_deeply ( [sort $obj->param] => ['bar', 'baz', 'foo', 'up'] );
}


#3 node, is_node, has_node
{
	my $obj = Object::AutoAccessor->new();
	
	$obj->new_node('foo');
	is ( ref( $obj->foo ) => 'Object::AutoAccessor' );
	ok ( $obj->is_node('foo') );
	is ( $obj->has_node() => 1 );
	is ( $obj->foo->has_node() => 0 );
	
	$obj->foo->bar('baz');
	is ( $obj->foo->bar => 'baz' );
	is ( $obj->foo->has_node() => 0 );
	
	$obj->new_node('bar')->new_node('baz')->up('DOWN');
	is ( ref( $obj->bar ) => 'Object::AutoAccessor' );
	ok ( $obj->is_node('bar') );
	is ( $obj->has_node() => 2 );
	is ( $obj->bar->has_node() => 1 );
	is ( $obj->bar->baz->has_node() => 0 );
	is ( $obj->bar->baz->up => 'DOWN' );
	
	$obj->baz('zzz');
	ok ( !$obj->is_node('baz') );
	is_deeply ( [sort $obj->node] => ['bar', 'foo'] );
	is_deeply ( [sort $obj->param] => ['baz'] );
}


#4 param
{
	my $obj = Object::AutoAccessor->new();
	
	$obj->testhash({ key1 => 'val1', key2 => 'val2' });
	$obj->testarray(['array1','array2']);
	$obj->testscalar('scalarval');
	
	is_deeply ( [sort $obj->param] => ['testarray', 'testhash', 'testscalar'] );
	is ( $obj->param('testscalar'), 'scalarval' );
	
	$obj->param(testscalar => 'foo');
	is ( $obj->param('testscalar'), 'foo' );
	
	$obj->param(childtest => $obj->renew());
	is ( $obj->param('childtest'), undef );
	is_deeply ( [sort $obj->param] => ['testarray', 'testhash', 'testscalar'] );
}


#5 defined, exists, delete, undef
{
	my $obj = Object::AutoAccessor->new();
	
	$obj->foo('bar');
	ok ( $obj->defined('foo'), 'defined 1' );
	ok ( $obj->exists('foo'), 'exists 1' );
	
	$obj->undef('foo');
	ok ( !$obj->defined('foo'), 'defined 2' );
	ok ( $obj->exists('foo'), 'exists 2' );
	
	$obj->foo('bar');
	is ( $obj->delete('foo'), 'bar', 'delete' );
	ok ( !$obj->defined('foo'), 'defined 3' );
	ok ( !$obj->exists('foo'), 'exists 3' );
}

#6 new with 'noautoload'
{
	my $obj = Object::AutoAccessor->new(autoload => 0);
	
	eval { $obj->test('!!!'); };
	ok ( !$obj->defined('test') );
	
	$obj->autoload(1);
	eval { $obj->test('!!!'); };
	ok ( $obj->defined('test') );
	
	$obj->autoload(0);
	eval { $obj->test2('!!!'); };
	ok ( !$obj->defined('test2') );
}


#7 renew with 'noautoload'
{
	my $obj = Object::AutoAccessor->new(autoload => 0);
	
	eval { $obj->retest('???'); };
	ok(!$obj->defined('retest'));
	
	$obj->autoload(1);
	eval { $obj->retest('???'); };
	ok($obj->defined('retest'));
	
	$obj->autoload(0);
	eval { $obj->retest2('???'); };
	ok(!$obj->defined('retest2'));
}

# END
