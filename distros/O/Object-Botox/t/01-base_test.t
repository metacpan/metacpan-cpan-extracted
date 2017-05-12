#!perl -T

#use Test::More tests => 1;
use Test::More qw( no_plan );

{	package Parent;

	use Object::Botox qw(new);

	use constant PROTOTYPE => {
		'prop1_ro' => 1 ,
		'prop2' => 'abcde'
	};
	
	sub show_prop1{ # It`s poinlessly - indeed property IS A accessor itself
		my ( $self ) = @_;
		return $self->prop1;
	}
	
	sub set_prop1{ # It`s NEEDED for RO property
		my ( $self, $value ) = @_;
		$self->prop1($value);
	}
	
	sub parent_sub{ # It`s class method itself
		my $self = shift;
		return $self->prop1;
	}
	1;
}
   
{	package Child;
	
	use Data::Dumper;
	
	use base 'Parent';
	
	use constant PROTOTYPE => {
		'prop1_ro' => 44,
		'prop5' => 55,
		'prop8_ro' => 'tetete'
	};
	
	my $make_test = sub {	
		my ( $self, $i ) = @_ ;		
		main::ok($self->prop1 == 1 && $self->prop2 eq 'abcde', "Init test pass");
		main::ok($self->show_prop1 == 1, "Read accessor test pass");
		main::ok(! eval{ $self->prop1(4*$i) } && $@ && $self->prop1 == 1 , 
				"Read-only property test pass" );
		main::ok($self->set_prop1(5*$i) && $self->prop1 == 5*$i,
				"Write accessor method test pass");
		main::ok($self->prop2 ne 'wxyz'.$i && $self->prop2('wxyz'.$i) 
				&& $self->prop2 eq 'wxyz'.$i, "Read-write property test pass");
		main::ok($self->parent_sub == $self->prop1, "Class method test pass");
	};
	
	my $persistent_test = sub{
		my $self = shift;		
		main::ok($self->prop1 == 5 && $self->prop2 eq 'wxyz1', 
					"Persistent data test pass");	
	};
	
	main::note ('First object test:');
	my $foo = main::new_ok( 'Parent' => [] ,"First object create" );
	
	&$make_test($foo,1);

	main::note ('Second object test:');
	my $bar = main::new_ok( 'Parent' => [] ,"Second object create" );
	&$make_test($bar,2);
	main::note ("Persistent data test:");
	&$persistent_test($foo);
	
	sub child_sub{
		my $self = shift;
		return $self->prop8.'-2';
	}


	sub parent_sub{ # It`s class method itself
		my $self = shift;
		return $self->prop5.' mutating';
	}
	
	my $grand_foo = new $foo;
	main::isa_ok $grand_foo, 'Parent', 'New from object';	

	1;
}


{ package GrandChild;
	
	my $baz = main::new_ok( 'Child' => [{prop1 => 888888, prop2 => 333}], 'GrandChild' );

	main::is  ( $baz->show_prop1, '888888', 'First sub' );
	main::is  ( $baz->child_sub, 'tetete-2', 'Second sub' );
	main::is  ( $baz->parent_sub, '55 mutating', 'Third sub' );	
	
	1;
}

{ package BirthToDead;
	 
	 main::note ('Init setup error test:');
	 main::ok(! eval{ Child->new( prop666 => 666 ) } && $@ , 
				"Setup missmatch catched" );
	1;
}

{ package EmptyCreate;
	 
	 main::note ('Empty object creation:');
	 main::new_ok ( 'Child' => [] , 'Empty object' );
	1;
}
