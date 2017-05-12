use strict ;

use Data::Dumper ;

use Test::More ;
use Benchmark ;

use Sort::Maker qw( :all ) ;

use vars '$bench' ;

sub common_driver {

	my( $sort_tests, $sort_styles, $default_sizes ) = @_ ;

	if ( $bench ) {

		benchmark_driver( $sort_tests, $sort_styles, $default_sizes ) ;
		return ;
	}

	test_driver( $sort_tests, $sort_styles ) ;
}

sub test_driver {

	my( $sort_tests, $default_styles ) = @_ ;

	$default_styles ||= [] ;

	my $total_tests = count_tests( $sort_tests, $default_styles ) ;

	plan tests => $total_tests ;

	foreach my $test ( @{$sort_tests} ) {

		if ( $test->{skip} ) {

			SKIP: {
				skip( "sort of $test->{name}\n",
					$test->{count} ) ;
			}
			next ;
		}

		make_test_sorters( $test, $default_styles ) ;

		if ( $test->{error} ) {

			handle_errors( $test ) ;
			next ;
		}

		$test->{data} ||= generate_data( $test ) ;

#print Dumper $test->{data} ;

		run_tests( $test ) ;
	}
}

sub handle_errors {

	my( $test ) = @_ ;

	foreach my $sort_name ( sort test_name_cmp keys %{$test->{sorters}} ) {

#print "NAME $sort_name\n" ;
		if ( my $error = $test->{make_error}{$sort_name} ) {

			if ( $test->{error} && $error =~ /$test->{error}/ ) {

				ok( 1, "$sort_name sort of $test->{name}" ) ;
			}
			else {

				ok( 0, "$sort_name sort of $test->{name}" ) ;
				print "unexpected error:\n$@\n" ;
			}
		}
	}
}

sub run_tests {

	my( $test ) = @_ ;

	my $input = $test->{data} ;

	my @gold_sorted = sort { $test->{gold}->() } @{$input} ;

	foreach my $sort_name ( sort test_name_cmp keys %{$test->{sorters}} ) {

		my @sorter_in = $sort_name =~ /ref_in/ ? $input : @{$input} ;

		my $sorter = $test->{sorters}{$sort_name} ;
		my @test_sorted = $sorter->( @sorter_in ) ;
		@test_sorted = @{$test_sorted[0]} if $sort_name =~ /ref_out/ ;

		my $ok = eq_array( \@gold_sorted, \@test_sorted ) ;

print "TEST [@test_sorted]\n" unless $ok ;
print "GOLD [@gold_sorted]\n" unless $ok ;

		ok( $ok, "$sort_name sort of $test->{name}" ) ;
	}
}

sub test_name_cmp {

	my @a = split /_/, $a ;
	my @b = split /_/, $b ;

	lc $a[0] cmp lc $b[0]
		||
	lc $a[1] cmp lc $b[1]
		||
	lc $a[2] cmp lc $b[2]
}

sub benchmark_driver {

	my( $sort_tests, $default_styles, $default_sizes ) = @_ ;

	my $duration = shift @ARGV || -2 ;

	foreach my $test ( @{$sort_tests} ) {

		next if $test->{skip} ;

		$test->{input_sets} = [generate_data( $test, $default_sizes )] ;

		make_test_sorters( $test, $default_styles ) ;

		run_benchmarks( $test, $duration ) ;
	}
}

sub run_benchmarks {

	my( $test, $duration ) = @_ ;

	my( %entries, @input, $in_ref ) ;

	while( my( $name, $sorter ) = each %{$test->{sorters}} ) {

		$entries{ $name } = $name =~ /ref_in/ ?
			sub { my @sorted = $sorter->( $in_ref ) } :
			sub { my @sorted = $sorter->( @input ) } ;
	}

	$entries{ 'gold' } =
		sub { my @sorted = sort { $test->{gold}->() } @input } ;

	foreach my $input_set ( @{$test->{input_sets}} ) {

		my $size = @{$input_set} ;

		print "Sorting $size elements of '$test->{name}'\n" ;

		@input = @{$input_set} ;
		$in_ref = $input_set ;

		timethese( $duration, \%entries ) ;
	}
}

sub generate_data {

	my( $test, $default_sizes ) = @_ ;

	my $gen_code = $test->{gen} ;
	$gen_code or die "no 'gen' code for test $test->{name}" ;

	my @sizes = @{ $test->{sizes} || $default_sizes || [100] } ;

# return a single data set when called in scalar context (from test_driver)

	return [ map $gen_code->(), 1 .. shift @sizes ] unless wantarray ;

# return multiple data sets when called in list context (from benchmark_driver)

	return map [ map $gen_code->(), 1 .. $_ ], @sizes ;
}

sub make_test_sorters {

	my( $test, $default_styles ) = @_ ;

	my $styles = $test->{styles} || $default_styles ;

# if no styles, we need a dummy style just to force the style loop

	$styles = [ qw(NO_STYLE) ] unless @{$styles} ;

	my $suffix = ( $test->{ref_in} ? '_RI' : '' ) .
		     ( $test->{ref_out} ? '_RO' : '' ) ;

	my $args = $test->{args} or die "$test->{name} has no args\n" ;
	my $arg_sets = ( ref $args eq 'HASH' ) ? $args : { '' => $args } ;

	foreach my $arg_name ( sort keys %{$arg_sets} ) {

		my $test_args = $arg_sets->{$arg_name} ;

		foreach my $style ( @{$styles} ) {

			my $sort_name = $arg_name ?
				"${style}_$arg_name" : "$style$suffix" ;

# if no real styles, use an empty list for them

			my @style_args = $style eq 'NO_STYLE' ? () : $style ;

			my $sorter = make_sorter( @style_args, @{$test_args} ) ;

#print "sorter [$sorter]\n" ;
#print sorter_source( $sorter ) ;


#print "SOURCE $test->{source}\n" ;

			unless( $sorter ) {

#print "SORT $sort_name [$@]\n" ;

				$test->{make_error}{$sort_name} = $@ ;
				$test->{sorters}{$sort_name} = 'NONE' ;
				next ;
			}

			print "Source of $sort_name $test->{name} is:\n",
				sorter_source( $sorter ) if $test->{source} ;

			$test->{sorters}{$sort_name} = $sorter ;
		}
	}

# all sorters built ok

	return 1 ;
}

sub count_tests {

	my( $tests, $default_styles ) = @_ ;

	my $sum = 0 ;

	foreach my $test ( @{$tests} ) {

		my $style_count = @{ $test->{styles} || $default_styles } || 1 ;

		my $arg_sets_count = ref $test->{args} eq 'ARRAY' ?
			1 : keys %{$test->{args}} ;

		my $test_count = $style_count * $arg_sets_count ;
		$test->{count} = $test_count ;

		$sum += $test_count ;
	}

	return $sum ;
}

my @alpha_digit = ( 'a' .. 'z', 'A' .. 'Z', '0' .. '9' ) ;
my @alpha = ( 'a' .. 'z', 'A' .. 'Z' ) ;
my @bytes = ( "\x00" .. "\xff" ) ;

sub rand_token {

	rand_string( \@alpha_digit, @_ ) ;
}

sub rand_alpha {

	rand_string( \@alpha, @_ ) ;
}

sub rand_bytes {

	rand_string( \@bytes, @_ ) ;
}

sub rand_string {

	my( $char_set, $min_len, $max_len ) = @_ ;

	$min_len ||= 8 ;
	$max_len ||= $min_len ;

	my $length = $min_len + int rand( $max_len - $min_len + 1 ) ;

	return join '', map $char_set->[rand @{$char_set}], 1 .. $length ;
}

sub rand_number {

	my( $lo_range, $hi_range ) = @_ ;

	( $lo_range, $hi_range ) = ( 0, $lo_range ) unless $hi_range ;

	my $range = $hi_range - $lo_range ;

	return rand( $range ) + $lo_range ;
}

sub rand_choice {

	return @_[rand @_] ;
}

1 ;
