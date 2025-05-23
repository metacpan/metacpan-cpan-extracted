#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Params::Get qw(get_params);

# Test get_params with a hash reference
my $params = get_params(undef, { foo => 'bar' });
is_deeply($params, { foo => 'bar' }, 'get_params correctly returns hash reference');

# Test get_params with key-value pairs
$params = get_params(undef, foo => 'bar', baz => 'qux');
is_deeply($params, { foo => 'bar', baz => 'qux' }, 'get_params correctly processes key-value pairs');

# Test get_params with ref to key-value pairs
$params = get_params(undef, { foo => 'bar', baz => 'qux' });
is_deeply($params, { foo => 'bar', baz => 'qux' }, 'get_params correctly processes ref to key-value pairs');

# Test get_params with a default key and single argument
$params = get_params('key', 'value');
is_deeply($params, { key => 'value' }, 'get_params correctly assigns default key');

# Test get_params with an empty argument list
throws_ok { $params = get_params('key') }
	qr /^Usage: /,
	'get_params throws exception with no arguments and no default';

$params = get_params();
ok(!defined $params, 'get_params returns undef with no arguments and no default');

$params = get_params('key', 'value1', 'value2');
is_deeply($params, { value1 => 'value2' });

$params = get_params(undef, ['value1', 'value2']);
is_deeply($params, { value1 => 'value2' });

{
	package MyClassArray;

	sub new {
		my $class = shift;

		return bless Params::Get::get_params(undef, @_), $class;
	}
}

{
	package MyClassArrayRef;

	sub new {
		my $class = shift;

		return bless Params::Get::get_params(undef, \@_), $class;
	}
}

my $obj = MyClassArray->new('one', 'two');
is_deeply($obj, { one => 'two' });

diag(Data::Dumper->new([$obj])->Dump()) if($ENV{'TEST_VERBOSE'});

$obj = MyClassArray->new({ 'one' => 'two' });
is_deeply($obj, { one => 'two' });

diag(Data::Dumper->new([$obj])->Dump()) if($ENV{'TEST_VERBOSE'});

$obj = MyClassArrayRef->new('one', 'two');
is_deeply($obj, { one => 'two' });

diag(Data::Dumper->new([$obj])->Dump()) if($ENV{'TEST_VERBOSE'});

$obj = MyClassArrayRef->new({ 'one' => 'two' });
is_deeply($obj, { one => 'two' });

diag(Data::Dumper->new([$obj])->Dump()) if($ENV{'TEST_VERBOSE'});

{
	package MyClassArrayRequired;

	sub new {
		my $class = shift;

		return bless Params::Get::get_params('count', @_), $class;
	}
}

{
	package MyClassArrayRefRequired;

	sub new {
		my $class = shift;

		return bless Params::Get::get_params('count', \@_), $class;
	}
}

$obj = MyClassArrayRequired->new(2, { 'one' => 'two' });
is_deeply($obj, { count => 2, one => 'two' });

diag(Data::Dumper->new([$obj])->Dump()) if($ENV{'TEST_VERBOSE'});

$obj = MyClassArrayRequired->new({ 'count' => 2, 'one' => 'two' });
is_deeply($obj, { count => 2, one => 'two' });

diag(Data::Dumper->new([$obj])->Dump()) if($ENV{'TEST_VERBOSE'});

$obj = MyClassArrayRefRequired->new({ 'count' => 2, 'one' => 'two' });
is_deeply($obj, { count => 2, one => 'two' });

diag(Data::Dumper->new([$obj])->Dump()) if($ENV{'TEST_VERBOSE'});

$obj = MyClassArrayRefRequired->new(2, { 'one' => 'two' });
is_deeply($obj, { count => 2, one => 'two' });

diag(Data::Dumper->new([$obj])->Dump()) if($ENV{'TEST_VERBOSE'});

$obj = MyClassArrayRefRequired->new({ 'count' => 2, 'one' => 'two' });
is_deeply($obj, { count => 2, one => 'two' });

diag(Data::Dumper->new([$obj])->Dump()) if($ENV{'TEST_VERBOSE'});

$obj = MyClassArrayRefRequired->new({ 'count' => 2, 'one' => 'two' });
is_deeply($obj, { count => 2, one => 'two' });

diag(Data::Dumper->new([$obj])->Dump()) if($ENV{'TEST_VERBOSE'});

done_testing();
