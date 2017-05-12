# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ODG-Record.t'


use Test::More tests => 10;

BEGIN { use_ok('ODG::Record') };


{ 
	package  # HIDE FROM PAUSE 
		MyClass;

		use Moose;
			extends 'ODG::Record';

		has area_code => (
			is 			=> 'ro' ,
			isa			=> 'Int',
			index		=> 0 ,
			traits		=> [ 'Index' ] ,
		);

		has exchange	=> (
			is			=> 'rw' ,
			isa			=> 'Int' ,
			index		=> 1 ,
			traits		=> [ 'Index' ] ,

		);

		has number	=> (
			is			=> 'rw' ,
			isa 		=> 'Int' ,
			index		=> 2 ,
			traits		=> [ 'Index' ] ,
		);


}


my $record = MyClass->new( _data => [ 213, 555, 1212 ] );
	isa_ok( $record, 'MyClass' );
	ok $record->_has_data, '_has_data';
	ok $record->area_code == 213, 'ro attribute';
	ok $record->exchange  == 555, 'rw attribute';
	ok $record->number    == 1212,'rw attribute';


	$record->exchange( 444 );
	ok $record->exchange  == 444, 'Standard Moose Accessor no type checking';

 	$record->number = 1234;
	ok $record->number    == 1234, 'Lvalue accessor';

  # Data operations

	ok $record->_has_data, '_has_data';
	$record->_data = [ 000, 000, 0000 ];
	ok $record->area_code == 000  , 'lvalue data replacement';

	




