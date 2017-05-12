use Test::More 0.94;

my $class = 'Surveyor::Benchmark::SchwartzianTransform::SortFilesBySize';

subtest setup => sub {
	use_ok( $class );
	$class->set_up( './*' );
	can_ok( $class, 'bench_glob', 'bench_assign' );
	my @array = $class->bench_glob;
	ok( @array > 1, 'There are files returned from the glob pattern' ) or 
		diag( sprintf "In current directory [%s]", join ' ', $class->bench_glob );
	};

subtest ordinary => sub {
	my @subs = qw( bench_ordinary_mod bench_ordinary_orig );
	try_it( @subs );
	};

subtest schwartzian => sub {
	my @subs = qw( bench_schwartz_mod bench_schwartz_orig );
	try_it( @subs );	
	};

subtest sort_names => sub {
	my @subs = qw( bench_sort_names bench_sort_names_assign );
	try_it( @subs );	
	};

sub try_it {
	can_ok( $class, @_ );
	my @results = ();
	foreach my $sub ( @_ ) {
		push @results, [ &{"${class}::$sub"} ];
		ok( $results[-1] > 1, "$sub return more than one item" );
		#diag( "$sub: [ @{$results[-1]} ]" );
		}
	
	foreach my $i ( 1 .. $#results ) {
		is_deeply( $results[$i-1], $results[$i] );
		}
	}

done_testing();
