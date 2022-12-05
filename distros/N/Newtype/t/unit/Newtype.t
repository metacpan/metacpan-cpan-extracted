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

use Types::Common qw( HashRef Int );
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
			lives { $func{assert_TestHash}->( $func{TestHash}->( {} ) ) };
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

# TODO: need to test underscore methods too!

done_testing;
