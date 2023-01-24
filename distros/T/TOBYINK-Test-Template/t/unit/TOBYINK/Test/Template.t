=pod

=encoding utf-8

=head1 PURPOSE

Unit tests for L<TOBYINK::Test::Template>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2023 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0 -target => 'TOBYINK::Test::Template';
use Test2::Tools::Spec;
use Data::Dumper;

describe "class `$CLASS`" => sub {

	tests 'it inherits from Moo::Object' => sub {
		isa_ok( $CLASS, 'Moo::Object' );
	};
	
	tests 'it can be instantiated' => sub {
	
		can_ok( $CLASS, 'new' );
	};
};

describe "attribute `foo`" => sub {

	tests 'it works' => sub {
	
		my $object = $CLASS->new( foo => 'Hello' );
		is( $object->foo, 'Hello', 'it can be set via constructor' );
		
		eval { $object->foo( 'Goodbye' ) };
		eval { $object->foo = 'Goodbye' };
		is( $object->foo, 'Hello', 'it is read-only' );
		
		my $e = dies {
			my $object2 = $CLASS->new();
		};
		like( $e, qr/required/, 'it is required' );
	};
};

describe "attribute `bar`" => sub {

	tests 'it works' => sub {
	
		my $object = $CLASS->new( foo => 'Hello', bar => 'world' );
		is( $object->bar, 'world', 'it can be set via constructor' );
		
		$object->bar( 'there' );
		is( $object->bar, 'there', 'it is read-write' );
		
		my $e = dies {
			my $object2 = $CLASS->new( foo => 'Hello' );
		};
		is( $e, undef, 'it is optional' );
	};
};

describe "method `foo_bar`" => sub {

	my ( $foo, $bar, $expected_foo_bar );
	
	case 'both defined' => sub {
		$foo = 'Hello';
		$bar = 'world';
		$expected_foo_bar = 'Hello world';
	};
	
	case 'both defined, but foo is empty string' => sub {
		$foo = '';
		$bar = 'world';
		$expected_foo_bar = ' world';
	};
	
	case 'both defined, but bar is empty string' => sub {
		$foo = 'Hello';
		$bar = '';
		$expected_foo_bar = 'Hello ';
	};
	
	case 'both defined, but both are empty string' => sub {
		$foo = '';
		$bar = '';
		$expected_foo_bar = ' ';
	};
	
	case 'foo is undefined' => sub {
		$foo = undef;
		$bar = 'world';
		$expected_foo_bar = 'world';
	};
	
	case 'bar is undefined' => sub {
		$foo = 'Hello';
		$bar = undef;
		$expected_foo_bar = 'Hello';
	};
	
	case 'both are undefined' => sub {
		$foo = undef;
		$bar = undef;
		$expected_foo_bar = '';
	};
	
	tests 'it works' => sub {
		my ( $object, $got_foo_bar, $got_exception, $got_warnings );
		
		$got_exception = dies {
			$got_warnings = warns {
				$object = $CLASS->new( foo => $foo, bar => $bar );
				$got_foo_bar = $object->foo_bar;
			};
		};
		is( $got_exception, undef, 'no exception thrown' );
		is( $got_warnings, 0, 'no warnings generated' );
		is( $got_foo_bar, $expected_foo_bar, 'expected string returned' );
		is(
			$object,
			object {
				call foo => $foo;
				call bar => $bar;
			},
			"method call didn't alter the values of the attributes",
		) or diag Dumper( $object );
	};
};

done_testing;
