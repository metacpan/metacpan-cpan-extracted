=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<Newtype>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0 -target => 'Newtype';
use Test2::Tools::Spec;
use Data::Dumper;

use Types::Common -types;
use Type::Registry ();

$Data::Dumper::Deparse = 1;

describe "class `$CLASS`" => sub {

	tests 'meta' => sub {

		ok $CLASS->isa( 'Newtype' );
		ok $CLASS->isa( 'Type::Tiny::Class' );
		ok $CLASS->isa( 'Type::Tiny' );
		ok $CLASS->isa( 'Exporter::Tiny' );
	};
};

describe "method `_exporter_fail`" => sub {

	tests 'it works' => sub {

		my %func = $CLASS->_exporter_fail(
			'TestHash',
			{ inner => HashRef },
			{ into  => 'Local::Test1' },
		);

		is( scalar( keys %func ), 4, 'expected number of functions returned' );

		is( ref( $func{TestHash} ), 'CODE', 'got a function called TestHash' );
		is( ref( $func{is_TestHash} ), 'CODE', 'got a function called is_TestHash' );
		is( ref( $func{assert_TestHash} ), 'CODE', 'got a function called assert_TestHash' );
		is( ref( $func{to_TestHash} ), 'CODE', 'got a function called to_TestHash' );

		subtest 'TestHash( $inner_value ) seems to work' => sub {
			my $value = $func{TestHash}->( {} );
			isa_ok( $value, 'Local::Test1::Newtype::TestHash' );
			ok( $value->DOES( 'Hash' ) );
		};

		subtest 'TestHash() seems to work' => sub {
			my $value = $func{TestHash}->();
			isa_ok( $value, 'Type::Tiny' );
			is( $value->class, 'Local::Test1::Newtype::TestHash', 'class attribute' );
			is( $value->inner_type->name, HashRef->name, 'inner_type attribute' );
			is( $value->kind, 'Hash', 'kind attribute' );
		};

		subtest 'is_TestHash( $thing ) seems to work' => sub {
			ok( $func{is_TestHash}->( $func{TestHash}->( {} ) ) );
			ok( ! $func{is_TestHash}->( {} ) );
		};

		subtest 'is_TestHash( $thing ) seems to work' => sub {
			lives { $func{assert_TestHash}->( $func{TestHash}->( {} ) ) } or fail;
			my $e = dies { $func{assert_TestHash}->( {} ) };
			like $e, qr/did not pass type constraint/;
		};

		subtest 'to_TestHash( $inner_value ) seems to work' => sub {
			my $value = $func{to_TestHash}->( {} );
			isa_ok( $value, 'Local::Test1::Newtype::TestHash' );
		};
	};
};

describe "method `new`" => sub {

	my ( $invocant, @args, $expected_exception, $expected_return, $also );

	case 'when called on a blessed object' => sub {
		my $inner_type_was_checked;

		sub Local::Test2::new { shift; return [ @_ ] }

		$invocant = mock( {}, add => [
			class      => sub { return 'Local::Test2' },
			inner_type => sub { return sub { ++$inner_type_was_checked; $_[0]; } }
		] );

		@args = 42;
		$expected_exception = undef;
		$expected_return = [ 42 ];

		$also = sub {
			ok( $inner_type_was_checked, 'inner type was checked during construction of wrapper object' );
		};
	};

	case 'when called with string inner' => sub {
		$invocant = $CLASS;
		@args = (
			caller => 'main',
			name   => 'Test3',
			inner  => 'Local::Test3',
		);
		$expected_exception = undef;
		$expected_return = object {
			prop isa => 'Newtype';
			prop isa => 'Type::Tiny';
			call class => 'main::Newtype::Test3';
			call inner_type => object {
				prop isa => 'Type::Tiny::Class';
				call class => 'Local::Test3';
			};
		};
		$also = undef;
	};

	case 'when called with type constraint inner' => sub {
		$invocant = $CLASS;
		@args = (
			caller => 'main',
			name   => 'Test4',
			inner  => HashRef,
		);
		$expected_exception = undef;
		$expected_return = object {
			prop isa => 'Newtype';
			prop isa => 'Type::Tiny';
			call class => 'main::Newtype::Test4';
			call inner_type => object {
				prop isa => 'Type::Tiny';
				call name => HashRef->name;
			};
		};
		$also = undef;
	};

	case 'when called with no inner' => sub {
		$invocant = $CLASS;
		@args = (
			caller => 'main',
			name   => 'Test5',
		);
		$expected_exception = match( qr/^Expected option: inner/ );
		$expected_return = undef;
		$also = undef;
	};

	case 'when called with type constraint inner (hashref edition!)' => sub {
		$invocant = $CLASS;
		@args = ( {
			caller => 'main',
			name   => 'Test6',
			inner  => HashRef,
		} );
		$expected_exception = undef;
		$expected_return = object {
			prop isa => 'Newtype';
			prop isa => 'Type::Tiny';
			call class => 'main::Newtype::Test6';
			call inner_type => object {
				prop isa => 'Type::Tiny';
				call name => HashRef->name;
			};
		};
		$also = undef;
	};

	tests 'it works' => sub {

		my $got_return;
		my $got_exception = dies {
			$got_return = Newtype::new( $invocant, @args );
		};

		is(
			$got_exception,
			$expected_exception,
			defined( $expected_exception ) ? 'expected exception' : 'no exception',
		);

		is(
			$got_return,
			$expected_return,
			defined( $expected_return ) ? 'expected return value' : 'no return value',
		);

		$also->() if $also;
	};
};

describe "attribute `inner_type`" => sub {

	tests 'it works' => sub {

		my $newtype = $CLASS->new(
			inner  => Int,
			name   => 'MyInt',
			caller => 'main',
		);
		is( $newtype->inner_type->name, 'Int' );
	};
};

describe "attribute `kind`" => sub {

	tests 'it works' => sub {

		my $newtype = $CLASS->new(
			inner  => Int,
			name   => 'MyInt2',
			caller => 'main',
		);
		is( $newtype->kind, 'Counter', 'implicit' );

		my $newtype2 = $CLASS->new(
			inner  => Int,
			name   => 'MyInt3',
			caller => 'main',
			kind   => 'String',
		);
		is( $newtype2->kind, 'String', 'explicit' );
	};
};

describe "method `_build_kind`" => sub {

	my ( $input, $expected, $expected_e );

	case 'with ArrayRef' => sub {
		$input      = ArrayRef;
		$expected   = 'Array';
		$expected_e = undef;
	};

	case 'with subtype of ArrayRef[HashRef[Int]]' => sub {
		$input      = ArrayRef->of( HashRef->of(Int) )->where( q{ 1 } );
		$expected   = 'Array';
		$expected_e = undef;
	};

	case 'with Bool' => sub {
		$input      = Bool;
		$expected   = 'Bool';
		$expected_e = undef;
	};

	case 'with CodeRef' => sub {
		$input      = CodeRef;
		$expected   = 'Code';
		$expected_e = undef;
	};

	case 'with Int' => sub {
		$input      = Int;
		$expected   = 'Counter';
		$expected_e = undef;
	};

	case 'with PositiveInt' => sub {
		$input      = PositiveInt;
		$expected   = 'Counter';
		$expected_e = undef;
	};

	case 'with HashRef' => sub {
		$input      = HashRef;
		$expected   = 'Hash';
		$expected_e = undef;
	};

	case 'with Num' => sub {
		$input      = Num;
		$expected   = 'Number';
		$expected_e = undef;
	};

	case 'with LaxNum' => sub {
		$input      = LaxNum;
		$expected   = 'Number';
		$expected_e = undef;
	};

	case 'with StrictNum' => sub {
		$input      = StrictNum;
		$expected   = 'Number';
		$expected_e = undef;
	};

	case 'with Str' => sub {
		$input      = Str;
		$expected   = 'String';
		$expected_e = undef;
	};

	case 'with StrMatch[qr//]' => sub {
		$input      = StrMatch[qr//];
		$expected   = 'String';
		$expected_e = undef;
	};

	case 'with NonEmptyStr' => sub {
		$input      = NonEmptyStr;
		$expected   = 'String';
		$expected_e = undef;
	};

	case 'with Object' => sub {
		$input      = Object;
		$expected   = 'Object';
		$expected_e = undef;
	};

	case 'with InstanceOf["Foo"]' => sub {
		$input      = InstanceOf["Foo"];
		$expected   = 'Object';
		$expected_e = undef;
	};

	case 'with HasMethods["foo"]' => sub {
		$input      = HasMethods["foo"];
		$expected   = 'Object';
		$expected_e = undef;
	};

	case 'with Any' => sub {
		$input      = Any;
		$expected   = undef;
		$expected_e = match( qr/^Could not determine kind of inner type/ );
	};

	case 'with Item' => sub {
		$input      = Item;
		$expected   = undef;
		$expected_e = match( qr/^Could not determine kind of inner type/ );
	};

	case 'with Ref' => sub {
		$input      = Ref;
		$expected   = undef;
		$expected_e = match( qr/^Could not determine kind of inner type/ );
	};

	tests 'it works' => sub {

		local $SIG{__WARN__} = sub {}; # :(
		my $obj = bless( { inner => $input }, $CLASS );
		my $got;
		my $got_e = dies { $got = $obj->_build_kind };

		is(
			$got_e,
			$expected_e,
			defined( $expected_e )
				? 'got expected exception'
				: 'got no exception',
		);
		is(
			$got,
			$expected,
			'got expected kind',
		) if defined $expected;
	};
};

# TODO: exportables

describe "method `_make_newclass_name`" => sub {

	tests 'it works' => sub {
		is(
			$CLASS->_make_newclass_name( { caller => 'ABC', name => 'XYZ' } ),
			'ABC::Newtype::XYZ',
			'expected class name',
		);
	};
};

# TODO: _make_newclass
# TODO: _make_newclass_basics
# TODO: _make_newclass_overloading
# TODO: _make_newclass_metamethods
# TODO: _make_newclass_metamethods_for_known_class
# TODO: _make_newclass_metamethods_for_generic_object
# TODO: _make_newclass_metamethods_for_kind
# TODO: _make_newclass_native_methods
# TODO: _make_newclass_custom_methods

describe "method `_kind_default`" => sub {

	my ( $input, $expected );

	case 'with Array' => sub {
		$input    = 'Array';
		$expected = array { end() };
	};

	case 'with Bool' => sub {
		$input    = 'Bool';
		$expected = F();
	};

	case 'with Code' => sub {
		$input    = 'Code';
		$expected = D();
	};

	case 'with Counter' => sub {
		$input    = 'Counter';
		$expected = number 0;
	};

	case 'with Hash' => sub {
		$input    = 'Hash';
		$expected = hash { end() };
	};

	case 'with Number' => sub {
		$input    = 'Number';
		$expected = number 0;
	};

	case 'with String' => sub {
		$input    = 'String';
		$expected = string '';
	};

	tests 'it works' => sub {

		local $SIG{__WARN__} = sub {}; # :(
		my $obj = bless( { kind => $input }, $CLASS );
		my $got = $obj->_kind_default->();

		is(
			$got,
			$expected,
			'got expected default',
		);
	};
};

# TODO: _make_coercions

done_testing;
