use Test::More;

require Test::Data;

Test::Data->import( qw(Scalar Array Hash Function) );

my @scalar_functions = qw( blessed_ok defined_ok greater_than
length_ok less_than maxlength_ok minlength_ok number_ok readonly_ok
ref_ok ref_type_ok strong_ok tainted_ok untainted_ok weak_ok undef_ok
number_between_ok string_between_ok );

my @hash_functions = qw(exists_ok not_exists_ok hash_value_defined_ok
hash_value_undef_ok hash_value_true_ok hash_value_false_ok);

my @array_functions = qw(array_any_ok array_none_ok array_once_ok
	array_multiple_ok array_max_ok array_min_ok array_maxstr_ok
	array_minstr_ok array_sum_ok array_length_ok array_empty_ok
	array_sortedstr_ascending_ok array_sortedstr_descending_ok
	array_sorted_ascending_ok array_sorted_descending_ok );

my @function_functions = qw(prototype_ok);

plan tests => @scalar_functions + @hash_functions +
	@array_functions + @function_functions;

# Scalar
test_functions( "Scalar", @scalar_functions );

# Array
test_functions( "Array", @array_functions );

# Hashes
test_functions( "Hash", @hash_functions );

# Functions
test_functions( "Function", @function_functions );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub test_functions {
	my( $package, @function_names ) = @_;

	foreach my $function ( @function_names ) {
		check_function( $function, $package );
		}
	}

sub check_function {
	my( $function, $package ) = @_;

	my $ok = sub_defined( $function );

	unless( $ok ) {
		diag( "\tFunction [$function] not defined in main::" );
		$a = sub_defined( "Test\::Data\::$package\::$function" );
		diag( "\tFunction is defined in $package, though" ) if $a;
		}

	ok( $ok, "$package package exported $function" );
	}

sub sub_defined {
	my $function = shift;
	eval( "defined \&$function" );
	}
