#! /usr/bin/env perl
use Test2::V0;
use Mock::Data 'mock_data_subclass';

{
	package Mock::Data::TestA;
	our @ISA= ( 'Mock::Data' );
	sub foo { 42 }
}
{
	package Mock::Data::TestB;
	sub foo { 43 }
}
{
	package Mock::Data::TestC;
	our @ISA= ( 'Mock::Data::TestA', 'Mock::Data::TestB' );
	sub foo { 44 }
}
{
	package Mock::Data::TestD;
	our @ISA= ( 'Mock::Data::TestB', 'Mock::Data::TestA' );
	sub foo { 44.5 }
}
{
	package Mock::Data::TestE;
	our @ISA= ( 'Mock::Data::TestC', 'Mock::Data::TestD' );
	sub foo { 44.75 }
}
{
	package Mock::Data::FooBar;
	sub foo { 45 }
}
{
	package Mock::Data::Foo::Bar;
	sub foo { 46 }
}
{
	package Mock::Data::Foo_Bar;
	sub foo { 47 }
}

subtest 'package inheriting Mock::Data' => sub {
	my $derived= mock_data_subclass('Mock::Data', 'Mock::Data::TestA');
	is( $derived, 'Mock::Data::TestA', 'derived is package itself' );
	my $obj= mock_data_subclass(Mock::Data->new, 'Mock::Data::TestA');
	is( ref $obj, 'Mock::Data::TestA', 'object gets re-blessed' );
};

subtest 'package not inheriting Mock::Data' => sub {
	my $derived= mock_data_subclass('Mock::Data', 'Mock::Data::TestB');
	is( $derived, 'Mock::Data::_AUTO_TestB', 'derived package has expected name' );
	is( $derived->foo, 43, 'can call TestB::foo' );
	
	$derived= mock_data_subclass('Mock::Data', 'Mock::Data::TestB');
	is( $derived, 'Mock::Data::_AUTO_TestB', 'same derived name when repeated' );
};

subtest 'multiple inheritance' => sub {
	my $derived= mock_data_subclass('Mock::Data', 'Mock::Data::TestA', 'Mock::Data::TestB');
	is( $derived, 'Mock::Data::_AUTO_TestA_TestB', 'expected package name' );
	is( $derived->foo, 42, 'TestA takes precdence' );
	
	$derived= mock_data_subclass('Mock::Data', 'Mock::Data::TestB', 'Mock::Data::TestA');
	is( $derived, 'Mock::Data::_AUTO_TestB_TestA', 'expected package name' );
	is( $derived->foo, 43, 'TestB takes precedence' );

	$derived= mock_data_subclass(
		'Mock::Data', 'Mock::Data::TestB', 'Mock::Data::TestC', 'Mock::Data::TestD'
	);
	is( $derived, 'Mock::Data::_AUTO_TestC_TestD', '[C,D], removed B' );

	$derived= mock_data_subclass(
		'Mock::Data', 'Mock::Data::TestD', 'Mock::Data::TestB', 'Mock::Data::TestC'
	);
	is( $derived, 'Mock::Data::_AUTO_TestD_TestC', '[D,C], removed B' );

	$derived= mock_data_subclass(
		'Mock::Data',
		'Mock::Data::TestB',
		'Mock::Data::TestD',
		'Mock::Data::TestE',
		'Mock::Data::TestC',
	);
	is( $derived, 'Mock::Data::TestE', 'E encompases all others' );
};

subtest 'derived name conflict' => sub {
	my $derived= mock_data_subclass(
		'Mock::Data', 'Mock::Data::FooBar', 'Mock::Data::TestB'
	);
	is( $derived, 'Mock::Data::_AUTO_FooBar_TestB', 'expected name' );
	
	$derived= mock_data_subclass('Mock::Data', 'Mock::Data::Foo::Bar', 'Mock::Data::TestB');
	is( $derived, 'Mock::Data::_AUTO_FooBar_TestB_1', 'expected inc name' );
	
	$derived= mock_data_subclass('Mock::Data', 'Mock::Data::Foo_Bar', 'Mock::Data::TestB');
	is( $derived, 'Mock::Data::_AUTO_FooBar_TestB_2', 'expected inc name' );
	
	$derived= mock_data_subclass('Mock::Data', 'Mock::Data::Foo::Bar', 'Mock::Data::TestB');
	is( $derived, 'Mock::Data::_AUTO_FooBar_TestB_1', 'repeat of earlier inc name' );
};

done_testing;
