# multidimensional binning & histogramming - tests of the object-oriented interface

use strict;
use warnings;
use Test::More tests => 169;
use Test::PDL 0.04 qw( is_pdl :deep );
use Test::Exception;
use Test::NoWarnings;
use Test::Deep;
use PDL;
use PDL::NDBin;
use List::Util qw( reduce );
use Module::Pluggable sub_name    => 'actions',
		      require     => 1,
		      search_path => [ 'PDL::NDBin::Action' ];

# compatibility with non-64-bit PDL versions
BEGIN {
	if( ! defined &PDL::indx ) { *indx = \&PDL::long }
	if( ! defined &Test::PDL::test_indx ) { *test_indx = \&Test::PDL::test_long }
}

# variable declarations
my ( $expected, $got, $binner, $x, $y );
our ( $a, $b );

#
# SETUP
#
note 'SETUP';

# test argument parsing
lives_ok { PDL::NDBin->new( axes => [ [ 'dummy', step=>0, min=>0, n=>1 ] ] ) } 'correct arguments: one axis';
lives_ok { PDL::NDBin->new( axes => [ [ 'dummy', step=>0, min=>0, n=>1 ],
				      [ 'dummy', step=>0, min=>0, n=>1 ] ] ) } 'correct arguments: two axes';
lives_ok { PDL::NDBin->new( axes => [ [ 'dummy', step=>0, min=>0, n=>1 ],
				      [ 'dummy', step=>0, min=>0, n=>1 ],
				      [ 'dummy', step=>0, min=>0, n=>1 ] ] ) } 'correct arguments: three axes';
lives_ok { PDL::NDBin->new( axes => [ [ 'dummy', step=>0, min=>0, n=>1 ],
				      [ 'dummy', step=>0, min=>0, n=>1 ],
				      [ 'dummy', step=>0, min=>0, n=>1 ] ],
			    vars => [ [ 'dummy', sub {} ] ] ) } 'correct arguments: three axes, one variable';
lives_ok { PDL::NDBin->new( axes => [ [ 'dummy', step=>0, min=>0, n=>1 ],
				      [ 'dummy', step=>0, min=>0, n=>1 ],
				      [ 'dummy', step=>0, min=>0, n=>1 ] ],
			    vars => [ [ 'dummy', sub {} ],
				      [ 'dummy', sub {} ] ] ) } 'correct arguments: three axes, two variables';
lives_ok { PDL::NDBin->new( axes => [ [ 'dummy', step=>0, min=>0, n=>1 ],
				      [ 'dummy', step=>0, min=>0, n=>1 ],
				      [ 'dummy', step=>0, min=>0, n=>1 ] ],
			    vars => [ [ 'dummy', sub {} ],
				      [ 'dummy', sub {} ],
				      [ 'dummy', sub {} ] ] ) } 'correct arguments: three axes, three variables';
{
	my $obj = PDL::NDBin->new;
	ok $obj, 'no arguments';
	isa_ok $obj, 'PDL::NDBin';
}
dies_ok { PDL::NDBin->new( axes => [ [ ] ] ) } 'no axis name';
lives_ok { PDL::NDBin->new( axes => [ [ 'dummy' ] ] ) } 'no specs';
dies_ok { PDL::NDBin->new( axes => [ [ 'dummy', 0 ] ] ) } 'wrong specs';
dies_ok { PDL::NDBin->new( axes => [ [ 'dummy', 0, 0, 1 ] ] ) } 'oldstyle specs';
lives_ok { PDL::NDBin->new( axes => [ [ 'dummy', step=>0 ] ] ) } 'no full specs';
lives_ok { PDL::NDBin->new( axes => [ [ 'dummy', min=>0 ] ] ) } 'no full specs';
lives_ok { PDL::NDBin->new( axes => [ [ 'dummy', n=>0 ] ] ) } 'no full specs';
lives_ok { PDL::NDBin->new( axes => [ [ 'dummy', step=>0, min=>0 ] ] ) } 'no full specs';
lives_ok { PDL::NDBin->new( axes => [ [ 'dummy', step=>0, n=>0 ] ] ) } 'no full specs';
lives_ok { PDL::NDBin->new( axes => [ [ 'dummy', min=>0, n=>0 ] ] ) } 'no full specs';
lives_ok { PDL::NDBin->new( axes => [ [ 'dummy', step=>0, min=>0, n=>1 ],
				     [ 'dummy' ] ] ) } 'no full specs for second axis';
lives_ok { PDL::NDBin->new( axes => [ [ 'dummy', step=>0, min=>0, n=>1 ],
				     [ 'dummy', step=>0 ] ] ) } 'no full specs for second axis';
dies_ok { PDL::NDBin->new( axes => [ [ 'dummy', unknown=>3 ] ] ) } 'unknown key in axis spec';

# return values
$binner = PDL::NDBin->new( axes => [ [ u => (step=>1,min=>0,n=>10) ] ] );
ok $binner, 'constructor returns a value';
isa_ok $binner, 'PDL::NDBin', 'return value from new()';
isa_ok $binner->process( u => sequence(10) ), 'PDL::NDBin', 'return value from process()';
isa_ok $binner->process( u => sequence(10) )->process( u => sequence(10) ), 'PDL::NDBin', 'return value from chained calls to process()';

# context
my $anon_sub = sub {};
$binner = PDL::NDBin->new( axes => [ [ u => (step=>1,min=>0,n=>10) ] ],
			   vars => [ [ v => $anon_sub ] ] );
$expected = [ { name => 'u', min => 0, n => 10, step => 1 } ];
$got = $binner->axes;
cmp_deeply $got, $expected, 'axes in scalar context';
$got = [ $binner->axes ];
cmp_deeply $got, $expected, 'axes in list context';
$expected = [ { name => 'v', action => $anon_sub } ];
$got = $binner->vars;
cmp_deeply $got, $expected, 'vars in scalar context';
$got = [ $binner->vars ];
cmp_deeply $got, $expected, 'vars in list context';

#
# SUPPORT STUFF
#
note 'SUPPORT STUFF';

# axis processing
$x = pdl( -65,13,31,69 );
$y = pdl( 3,30,41,-66.9 );
$expected = [ { name => 'x', pdl => test_pdl($x), min => -65, max => 69, n => 4, step => 33.5 } ];
$binner = PDL::NDBin->new( axes => [[ 'x' ]] );
$binner->autoscale( x => $x );
$got = $binner->axes;
cmp_deeply $got, $expected, 'autoscale() with auto parameters';
$expected = [ { name => 'x', pdl => test_pdl($x), min => -70, max => 70, n => 7, step => 20 } ];
$binner = PDL::NDBin->new( axes => [[ x => (min => -70, max => 70, step => 20) ]] );
$binner->autoscale( x => $x );
$got = $binner->axes;
cmp_deeply $got, $expected, 'autoscale() with manual parameters';
$expected = [ { name => 'x', pdl => test_pdl($x), min => -70, max => 70, n => 7, step => 20, round => 10 },
	      { name => 'y', pdl => test_pdl($y), min => -70, max => 50, n => 6, step => 20, round => 10 } ];
$binner = PDL::NDBin->new( axes => [[ x => ( round => 10, step => 20 ) ],
				    [ y => ( round => 10, step => 20 ) ]] );
$binner->autoscale( x => $x, y => $y );
$got = $binner->axes;
cmp_deeply $got, $expected, 'autoscale() with two axes and rounding';

# labels
{
    my $expected = [ [ { range => [0,4] }, { range => [4,8] }, { range => [8,12] } ] ];

    {
	my $got = PDL::NDBin->new( axes => [[ x => (min=>0, max=>12, step=>4) ]] )->labels( x => pdl );
	is_deeply $got, $expected, 'labels() with one axis, range 0..12, step = 4';
    }

    {
	my $got = PDL::NDBin->new( axes => [[ x => grid => sequence( 4 ) * 4 ]] )->labels( x => pdl );
	is_deeply $got, $expected, 'labels() with one axis, grid';
    }
}

{
    my $expected = [ [ { range => [0,7]  },  { range => [7,14] } ],
		     [ { range => [0,11]  }, { range => [11,22] }, { range => [22,33] } ] ];

    {
	my $got = PDL::NDBin->new( axes => [[ x => ( n => 2 ) ],
					    [ y => ( n => 3 ) ]] )->labels( x => pdl( 0,14 ), y => pdl( 0,33 ) );
	is_deeply $got, $expected, 'labels() with two axes, range 0..14 x 0..33, n = 2 x 3';
    }

    {
	# set up same binning as above test, but since grid doesn't autoscale, create
	# appropriate bin by hand
	my $got
	  = PDL::NDBin->new( axes => [ [ x => ( grid => sequence( 3 ) * 7 )  ],
				       [ y => ( grid => sequence( 4 ) * 11 ) ],
				     ],
			   ) ->labels( x => pdl( 0, 14 ), y => pdl( 0, 33 ) );
	is_deeply $got, $expected,
	  'labels() with two axes, grid, range 0..14 x 0..33, n = 2 x 3';
    }
}

$expected = [ [ { range => [-3,-2] }, { range => [-1,0] }, { range => [1,2] } ] ];
$got = PDL::NDBin->new( axes => [[ x => ( n => 3 ) ]] )->labels( x => short( -3,2 ) );
is_deeply $got, $expected, 'labels() with one axis, integral data, range -3..2, n = 3';
$expected = [ [ { range => [-3,0] }, { range => [1,3] } ] ];
$got = PDL::NDBin->new( axes => [[ x => ( n => 2 ) ]] )->labels( x => short( -3,3 ) );
is_deeply $got, $expected, 'labels() with one axis, integral data, range -3..3, n = 2';
$expected = [ [ { range => [-3,-1] }, { range => [0,1] }, { range => [2,3] } ] ];
$got = PDL::NDBin->new( axes => [[ x => ( n => 3 ) ]] )->labels( x => short( -3,3 ) );
is_deeply $got, $expected, 'labels() with one axis, integral data, range -3..3, n = 3';
$expected = [ [ { range => 1 }, { range => 2 }, { range => 3 }, { range => 4 } ] ];
$got = PDL::NDBin->new( axes => [[ x => ( step => 1 ) ]] )->labels( x => short( 1,2,3,4 ) );
is_deeply $got, $expected, 'labels() with one axis, integral data, range 1..4, step = 1';



#
# BASIC FUNCTIONALITY
#
note 'BASIC FUNCTIONALITY';

# the example from PDL::histogram
$x = pdl( 1,1,2 );
# by default histogram() returns a piddle of the same type as the axis,
# but output() returns a piddle of type I<indx> when histogramming
$expected = { histogram => test_indx( 0,2,1 ) };
$binner = PDL::NDBin->new( axes => [ [ 'x', step=>1, min=>0, n=>3 ] ] );
$binner->process( x => $x );
$got = $binner->output;
cmp_deeply $got, $expected, 'example from PDL::histogram';
$expected = { z => test_long( 0,2,1 ) };
$binner = PDL::NDBin->new( axes => [ [ 'x', step=>1, min=>0, n=>3 ] ],
			   vars => [ [ 'z', sub { shift->want->nelem } ] ] );
$binner->process( x => $x, z => zeroes( long, $x->nelem ) );
$got = $binner->output;
cmp_deeply $got, $expected, 'variable and action specified explicitly';
$expected = { x => test_pdl( 0,2,1 ) }; # this is an exception, because the type is
					# locked to double by `$x => sub { ... }'
$binner = PDL::NDBin->new( axes => [ [ x => ( step=>1, min=>0, n=>3 ) ] ],
			   vars => [ [ x => sub { shift->want->nelem } ] ] );
$binner->process( x => $x );
$got = $binner->output;
cmp_deeply $got, $expected, 'different syntax';
$expected = { x => test_indx( 0,2,1 ) };
$binner = PDL::NDBin->new( axes => [ [ x => ( step=>1, min=>0, n=>3 ) ] ],
			   vars => [ [ x => 'Count' ] ] );
$binner->process( x => $x );
$got = $binner->output;
cmp_deeply $got, $expected, 'different syntax, using action class name';

# this idiom with only chained calls should work
$x = pdl( 1,1,2 );
$expected = { histogram => test_indx( 0,2,1 ) };
$got = PDL::NDBin->new( axes => [ [ v => (step=>1,min=>0,n=>3) ] ] )->process( v => $x )->output;
cmp_deeply $got, $expected, 'all calls chained';

# the example from PDL::histogram2d
$x = pdl( 1,1,1,2,2 );
$y = pdl( 2,1,1,1,1 );
$expected = { histogram => test_indx( [0,0,0],
				      [0,2,2],
				      [0,1,0] ) };
$binner = PDL::NDBin->new( axes => [ [ x => (step=>1,min=>0,n=>3) ],
				     [ y => (step=>1,min=>0,n=>3) ] ] );
$binner->process( x => $x, y => $y );
$got = $binner->output;
cmp_deeply $got, $expected, 'example from PDL::histogram2d';

#
$x = pdl( 1,1,1,2,2,1,1 );
$y = pdl( 2,1,3,4,1,4,4 );
$expected = { histogram => test_indx( [1,1],
				      [1,0],
				      [1,0],
				      [2,1] ) };
$binner = PDL::NDBin->new( axes => [ [ 'x', step=>1, min=>1, n=>2 ],
				     [ 'y', step=>1, min=>1, n=>4 ] ] );
$binner->process( x => $x, y => $y );
$got = $binner->output;
cmp_deeply $got, $expected, 'nonsquare two-dimensional histogram';

# binning integer data
$x = byte(1,2,3,4);
$expected = { histogram => test_indx( 1,1,1,1 ) };
$binner = PDL::NDBin->new( axes => [ [ x => (step=>1,min=>1,n=>4) ] ] );
$binner->process( x => $x );
$got = $binner->output;
cmp_deeply $got, $expected, 'binning integer data: base case';
$x = short( 0,-1,3,9,6,3,1,0,1,3,7,14,3,4,2,-6,99,3,2,3,3,3,3 ); # contains out-of-range data
$expected = { x => test_short( 8,9,1,0,5 ) };
$binner = PDL::NDBin->new( axes => [ [ x => (step=>1,min=>2,n=>5) ] ],
			   vars => [ [ x => sub { shift->want->nelem } ] ] );
$binner->process( x => $x );
$got = $binner->output;
cmp_deeply $got, $expected, 'binning integer data: step = 1';
$expected = { histogram => test_indx( 18,1,1,1,2 ) };
$binner = PDL::NDBin->new( axes => [ [ x => (step=>2,min=>3,n=>5) ] ] );
$binner->process( x => $x );
$got = $binner->output;
cmp_deeply $got, $expected, 'binning integer data: step = 2';

# more actions & missing/undefined/invalid stuff
$x = sequence 21;
$expected = { x => test_double( 1,4,7,10,13,16,19 ) };
$binner = PDL::NDBin->new( axes => [ [ 'x', step=>3, min=>0, n=>7 ] ],
			   vars => [ [ 'x', sub { shift->selection->avg } ] ] );
$binner->process( x => $x );
$got = $binner->output;
cmp_deeply $got, $expected, 'variable with action = average';
$binner = PDL::NDBin->new( axes => [ [ 'x', step=>3, min=>0, n=>7 ] ],
			   vars => [ [ 'x', 'Avg' ] ] );
$binner->process( x => $x );
$got = $binner->output;
cmp_deeply $got, $expected, 'variable with action = average, using action class name';
$x = 5+sequence 3; # 5 6 7
$expected = { x => test_pdl( double( 0,0,1,1,1 )->inplace->setvaltobad( 0 ) ) };
$binner = PDL::NDBin->new( axes => [ [ 'x', step=>1,min=>3,n=>5 ] ],
			   vars => [ [ 'x', sub { shift->want->nelem || undef } ] ] );
$binner->process( x => $x );
$got = $binner->output;
cmp_deeply $got, $expected, 'empty bins unset'; # cannot be achieved with action classes

# cross-check with histogram and some random data
$x = pdl( 0.7143, 0.6786, 0.9214, 0.5065, 0.9963, 0.9703, 0.1574, 0.4718,
	0.4099, 0.7701, 0.1881, 0.9412, 0.0034, 0.4440, 0.9423, 0.2065, 0.9656,
	0.5672, 0.2300, 0.5300, 0.1842 );
$y = pdl( 0.7422, 0.0299, 0.6629, 0.9118, 0.1224, 0.6173, 0.9203, 0.9999,
	0.1480, 0.4297, 0.5000, 0.9637, 0.1148, 0.2922, 0.0846, 0.0954, 0.1379,
	0.3187, 0.1655, 0.5777, 0.3047 );
$expected = { histogram => test_pdl( histogram( $x, .1, 0, 10 )->convert( indx ) ) };
$binner = PDL::NDBin->new( axes => [ [ 'x', step=>.1, min=>0, n=>10 ] ] );
$binner->process( x => $x );
$got = $binner->output;
cmp_deeply $got, $expected, 'cross-check with histogram';
$expected = { histogram => test_pdl( histogram2d( $x, $y, .1, 0, 10, .1, 0, 10 )->convert( indx ) ) };
$binner = PDL::NDBin->new( axes => [ [ 'x', step=>.1, min=>0, n=>10 ],
				     [ 'y', step=>.1, min=>0, n=>10 ] ] );
$binner->process( x => $x, y => $y );
$got = $binner->output;
cmp_deeply $got, $expected, 'cross-check with histogram2d';

# the example from PDL::hist
$x = pdl( 13,10,13,10,9,13,9,12,11,10,10,13,7,6,8,10,11,7,12,9,11,11,12,6,12,7 );
$expected = { histogram => test_indx( 0,0,0,0,0,0,2,3,1,3,5,4,4,4,0,0,0,0,0,0 ) };
$binner = PDL::NDBin->new( axes => [ [ x => min=>0, max=>20, step=>1 ] ] );
$binner->process( x => $x );
$got = $binner->output;
cmp_deeply $got, $expected, 'example from PDL::hist';

# check that actions are being called in the order they appear in 'vars'
{
	my @log = ();
	my $gensub = sub {
		my $ident = shift;
		return sub {
			my $iter = shift;
			push @log, sprintf "%s_%d", $ident, $iter->bin;
		};
	};
	my @vars = map [ "f_$_" => $gensub->( $_ ) ], 'A' .. 'F';
	my %data = map { ("f_$_" => sequence 5) } 'A' .. 'F';
	my $binner = PDL::NDBin->new( axes => [['x', n=>5]], vars => \@vars );
	$binner->process( x => sequence(5), %data );
	# So what do we expect? we expect a list of 'codes' of the type 'A_1',
	# with 'A' signifying the action, and '1' the bin. The actions vary
	# fastest, and the bins slowest. This means we expect
	#   A_0, B_0, C_0, ..., A_1, B_1, ...
	my $expected = [
		map do {
			my $bin = $_;
			map { sprintf "%s_%d", $_, $bin } 'A' .. 'F'
		}, 0 .. 4
	];
	cmp_deeply \@log, $expected, 'actions are called in the order they are given';
}

# check that calling output() twice doesn't break anything
for my $class ( __PACKAGE__->actions ) {
	# CodeRef does not compute anything by itself
	next if $class eq 'PDL::NDBin::Action::CodeRef';
	my( $action ) = $class =~ /:([^:]+)$/;
	my $binner = PDL::NDBin->new(
		axes => [ ['x', n=>5], ['y', n=>7] ],
		vars => [ ['u', $action] ],
	);
	$binner->feed( x => random(100), y => random(100), u => random(100) );
	$binner->process;
	my $got1 = $binner->output;
	# we need to convert the piddles in $got1 to 'expected piddles', hence
	# this dirty hack
	$got1->{u} = test_pdl $got1->{u};
	my $got2 = $binner->output;
	cmp_deeply $got2, $got1, "calling output() twice doesn't break anything, action class $class";
}

#
# MORE TESTS WITH ACTIONS
#
note 'MORE TESTS WITH ACTIONS';

{
	my $u = float( 0.785, 0.025, 0.385, 0.219, 0.133, 0.405, 0.761, 0.777,
		0.704, 0.346, 0.267, 0.051, 0.129, 0.485, 0.227, 0.216, 0.673,
		0.433, 0.581, 0.990 );
	my $x = zeroes long, $u->nelem;
	my $avg = $u->sum/$u->nelem;
	my $coderef = sub { shift->selection->avg };
	my %table = (
		'action coderef' => {
			vars     => [ [ 'u', $coderef ] ],
			# type is 'float' since $u is float
			expected => { u => test_float( [$avg] ) },
		},
		'action coderef, specified as hashref' => {
			vars     => [ [ 'u', { class => 'CodeRef', coderef => $coderef } ] ],
			expected => { u => test_float( [$avg] ) },
		},
		'action coderef, specified as hashref with type' => {
			vars     => [ [ 'u', { class => 'CodeRef', coderef => $coderef, type => PDL::double } ] ],
			expected => { u => test_double( [$avg] ) },
		},
		'action class' => {
			vars     => [ [ 'u', 'Avg' ] ],
			# type is 'double' since 'Avg' initializes to double
			expected => { u => test_double( [$avg] ) },
		},
		'action class with hashref' => {
			vars     => [ [ 'u', { class => 'Avg' } ] ],
			expected => { u => test_double( [$avg] ) },
		},
		'action class with hashref and parameters' => {
			vars     => [ [ 'u', { class => 'Avg', type => float } ] ],
			expected => { u => test_float( [$avg] ) },
		},
	);
	while( my($name,$data) = each %table ) {
		my $binner = PDL::NDBin->new(
			axes => [ [ 'x', n=>1 ] ],
			vars => $data->{vars},
		);
		$binner->process( x => $x, u => $u );
		my $got = $binner->output;
		my $expected = $data->{expected};
		cmp_deeply $got, $expected, "extended action tests: $name";
	}
}

#
# DATA FEEDING & AUTOSCALING
#
note 'DATA FEEDING & AUTOSCALING';

#
for my $n ( 5,21,99,100,101,1000 ) {
	my $x = random( $n );
	my $binner = PDL::NDBin->new( axes => [ [ 'x' ] ] );
	$binner->process( x => $x );
	my $got = $binner->output->{histogram};
	is $got->nelem, $n < 100 ? $n : 100, q{uses $n bins if 'n' not supplied, where $n = nelem} or diag $x;
}

#
$x = random( 30 );
$y = random( 30 );
$binner = PDL::NDBin->new( axes => [[ x => (step=>.1,min=>0,n=>10) ],
				    [ y => (step=>.1,min=>0,n=>10) ]] );
$got = $binner->axes;
is_deeply $got, [ { name => 'x',
		    step => .1,min=>0,n=>10 },
		  { name => 'y',
		    step => .1,min=>0,n=>10 } ], 'contents of axes() before feeding';
$binner->feed( x => $x );
$got = $binner->axes;
cmp_deeply $got, [ { name => 'x',
		     pdl  => test_pdl($x),
		     step => .1, min => 0, n => 10 },
		   { name => 'y',
		     step => .1, min => 0, n => 10 } ], 'contents of axes() after feeding x';
$binner->feed( y => $y );
$got = $binner->axes;
cmp_deeply $got, [ { name => 'x',
		     pdl  => test_pdl($x),
		     step => .1, min => 0, n => 10 },
		   { name => 'y',
		     pdl  => test_pdl($y),
		     step => .1, min => 0, n => 10 } ], 'contents of axes() after feeding y';

#
$x = random( 30 );
$y = random( 30 );
$binner = PDL::NDBin->new( axes => [[ x => (step=>.1,min=>0,n=>10) ],
				    [ y => (step=>.1,min=>0,n=>10) ]] );
$got = $binner->axes;
is_deeply $got, [ { name => 'x',
		    step => .1,min=>0,n=>10 },
		  { name => 'y',
		    step => .1,min=>0,n=>10 } ], 'contents of axes() before feeding';
$binner->feed( x => $x,
	       y => $y );
$got = $binner->axes;
cmp_deeply $got, [ { name => 'x',
		     pdl  => test_pdl($x),
		     step => .1, min => 0, n => 10 },
		   { name => 'y',
		     pdl  => test_pdl($y),
		     step => .1, min => 0, n => 10 } ], 'contents of axes() after feeding x and y at once';
$y = random( 30 );
$binner->feed( y => $y );
cmp_deeply $got, [ { name => 'x',
		     pdl  => test_pdl($x),
		     step => .1, min => 0, n => 10 },
		   { name => 'y',
		     pdl  => test_pdl($y),
		     step => .1, min => 0, n => 10 } ], 'contents of axes() after re-feeding y';

# test auto axes
$x = pdl( 13,10,13,10,9,13,9,12,11,10,10,13,7,6,8,10,11,7,12,9,11,11,12,6,12,7 );
$binner = PDL::NDBin->new( axes => [[ x => (step=>1, min=>0, n=>10) ]] );
$binner->autoscale( x => $x );
$got = $binner->axes;
cmp_deeply $got, [ { name => 'x',
		     pdl  => test_pdl($x),
		     step => 1,
		     min  => 0,
		     n    => 10 } ], 'returns early if step,min,n are known';
$got = reduce { $a * $b } map { $_->{n} } $binner->axes;
is $got, 10, 'number of bins';

{
	my $binner = PDL::NDBin->new( axes => [ [ data => (min=>1, max=>4, step=>1) ] ] );
	$binner->process( data => short( 1,2,3,4 ) );
	is_pdl $binner->output->{histogram}, indx( 1,1,1,1 ), '(short) 1..4 step=1';
}

{
	my $binner = PDL::NDBin->new( axes => [ [ data => (min=>1, max=>4, step=>1) ] ] );
	$binner->process( data => pdl( 1,2,3,4 ) );
	is_pdl $binner->output->{histogram}, indx( 1,1,2 ), '(pdl  ) 1..4 step=1';
}

{
	my $binner = PDL::NDBin->new( axes => [ [ data => (min=>1, max=>4, step=>2) ] ] );
	$binner->process( data => short( 1,2,3,4 ) );
	is_pdl $binner->output->{histogram}, indx( 2,2 ), '(short) 1..4 step=2';
}

{
	my $binner = PDL::NDBin->new( axes => [ [ data => (min=>1, max=>4, step=>2) ] ] );
	$binner->process( data => pdl( 1,2,3,4 ) );
	is_pdl $binner->output->{histogram}, indx( 2,2 ), '(pdl  ) 1..4 step=2';
}

{
	my $binner = PDL::NDBin->new( axes => [ [ data => (min=>1, max=>4, step=>3) ] ] );
	$binner->process( data => short( 1,2,3,4 ) );
	is_pdl $binner->output->{histogram}, indx( 3,1 ), '(short) 1..4 step=3';
}

{
	my $binner = PDL::NDBin->new( axes => [ [ data => (min=>1, max=>4, step=>3) ] ] );
	$binner->process( data => pdl( 1,2,3,4 ) );
	is_pdl $binner->output->{histogram}, indx( [4] ), '(pdl  ) 1..4 step=3';
}

{
	my $binner = PDL::NDBin->new( axes => [ [ data => (min=>1, max=>4, n=>1) ] ] );
	$binner->process( data => short( 1,2,3,4 ) );
	is_pdl $binner->output->{histogram}, indx( [4] ), '(short) 1..4 n=1';
}

{
	my $binner = PDL::NDBin->new( axes => [ [ data => (min=>1, max=>4, n=>1) ] ] );
	$binner->process( data => pdl( 1,2,3,4 ) );
	is_pdl $binner->output->{histogram}, indx( [4] ), '(pdl  ) 1..4 n=1';
}

{
	my $binner = PDL::NDBin->new( axes => [ [ data => (min=>1, max=>4, n=>2) ] ] );
	$binner->process( data => short( 1,2,3,4 ) );
	is_pdl $binner->output->{histogram}, indx( 2,2 ), '(short) 1..4 n=2';
}

{
	my $binner = PDL::NDBin->new( axes => [ [ data => (min=>1, max=>4, n=>2) ] ] );
	$binner->process( data => pdl( 1,2,3,4 ) );
	is_pdl $binner->output->{histogram}, indx( 2,2 ), '(pdl  ) 1..4 n=2';
}

{
	my $binner = PDL::NDBin->new( axes => [ [ data => (min=>1, max=>4, n=>4) ] ] );
	$binner->process( data => short( 1,2,3,4 ) );
	is_pdl $binner->output->{histogram}, indx( 1,1,1,1 ), '(short) 1..4 n=4';
}

{
	my $binner = PDL::NDBin->new( axes => [ [ data => (min=>1, max=>4, n=>4) ] ] );
	$binner->process( data => pdl( 1,2,3,4 ) );
	is_pdl $binner->output->{histogram}, indx( 1,1,1,1 ), '(pdl  ) 1..4 n=4';
}

#
# MIXED CODEREFS/CLASSES
#
note 'MIXED CODEREFS/CLASSES';

# The point here is to check that it is OK to mix action coderefs (which get
# called many times, i.e., once per bin) and action classes (which get called
# only once and compute all the bins at the same time) in the same call to
# process().
#
# For this to work properly, we rely on the actions having been cross-checked
# for correctness with regular PDL functions in t/02-actions.t.
$x = pdl( 0.665337628832283, -0.629370177449402, -0.611923922242319,
	0.146148441539381, -0.965210860804142, -0.821292959182784,
	0.497487420955331, -0.695206422742402, 0.0690564401273335,
	0.660776787555278, 0.790259459088325, 0.412517377156249,
	-0.912338356893109, -0.85339648912165, -0.307537768821028,
	0.329217496502892, 0.115705397854647, -0.416813576362927,
	0.707663545047488, -0.0639842132495545, 0.707644934900408,
	0.86550561953581, 0.219006175713098, -0.164623503609349,
	0.0103715544978016, 0.131996097622164, 0.961809571556124,
	-0.761399714469846, -0.78839870139236, 0.104065357533415,
	-0.706695560024293, -0.583065692362325, -0.215110521289482,
	0.14993000571593, 0.402443117969163, -0.34965346572595,
	-0.52588798019368, 0.311159910978148, 0.136275080812929,
	0.979419053792682, -0.13846015488155, 0.328787991194758,
	-0.960724071158587, 0.987148387986238, 0.894432391743273,
	0.0591228267492454, -0.21633965680099, 0.326279066456195,
	0.821408439770387, -0.576806894616027, -0.406264558618069,
	-0.437032097904861, 0.683982381247041, 0.0650105325215407,
	-0.87634868260961, 0.209158747497483, -0.450902524229882,
	-0.389235584171843, 0.0296209443781308, 0.425369106352562,
	-0.0599898385381934, -0.736890222190681, 0.0852026748151431,
	0.935228950924838, -0.033503261379785, -0.597415309439896,
	-0.0717940806291395, -0.873103418410764, -0.831668656566158,
	-0.0961553125630701, 0.61308484597901, 0.329484482065411,
	-0.578162294191024, -0.458964287625349, 0.192466739861707,
	0.831187999483021, -0.0721876364182421, -0.281304756157596,
	0.0911116286692888, 0.617499436710872, -0.533730589828217,
	-0.0822228979863553, -0.503241470666218, 0.101537910496077,
	-0.90846789091821, 0.817692139620334, 0.212871839737822,
	-0.375790772114854, 0.228710441558128, 0.702847654168295,
	0.142399603867226, -0.669041809862776, -0.145678511800632,
	0.175506066710255, 0.94968424874434, -0.423133727109544,
	0.890747106335546, 0.596571315205153, 0.536266550130698,
	-0.553391321294256 ); # 100 random values in the range [-1:1]
$expected = { avg1 => code( sub { shift->isa('PDL') } ),
	      avg2 => code( sub { shift->isa('PDL') } ) };
$binner = PDL::NDBin->new( axes => [ [ data => step=>2,min=>-1,n=>1 ] ],
			   vars => [ [ avg1 => sub { shift->selection->avg } ],
				     [ avg2 => 'Avg' ] ] );
$binner->process( data => $x, avg1 => $x, avg2 => $x );
$got = $binner->output;
cmp_deeply $got, $expected, 'mixed coderef/class with one bin, average';
cmp_ok abs( $got->{avg1}->at(0) ), '<', 1e-2, 'average of 100 random numbers in the range [-1:1] should be (more or less) close to 0';
is_pdl $got->{avg1}, $got->{avg2}, 'mixed coderef/class with one bin, average';

$expected = { sd1 => code( sub { shift->isa('PDL') } ),
	      sd2 => code( sub { shift->isa('PDL') } ) };
$binner = PDL::NDBin->new( axes => [ [ data => step=>.1,min=>-1,n=>20 ] ],
			   vars => [ [ sd1 => sub { (shift->selection->stats)[6] } ],
				     [ sd2 => 'StdDev' ] ] );
$binner->process( data => $x, sd1 => $x, sd2 => $x );
$got = $binner->output;
cmp_deeply $got, $expected, 'mixed coderef/class with 20 bins, standard deviation';
is_pdl $got->{sd1}, $got->{sd2}, 'mixed coderef/class with 20 bins, standard deviation';

#
# CONCATENATION
#
note 'CONCATENATION';
{
	my $u0 = pdl( -39.5879651748746, -1.61266445735144, -101, -101,
		14.8418955069236, -101, -8.26646389031183, 25.088753865478,
		23.8853755713542, -101, -21.6533850376752 )->inplace->setvaltobad( -101); # 11 random values [-50:50]
	my $u1 = pdl( 45.610085425162, -44.8090783225684, -27.334777692904,
		34.0608028167306, -101, -101, -2.56326878236344,
		-20.1093765242415, -36.7126503801988 )->inplace->setvaltobad( -101 ); # 9 random values [-50:50]
	my $u2 = pdl( -23.9802424215636, -45.4591971834436, -1.27709553320408,
		36.9333932550145, -101, -23.1580394609267 )->inplace->setvaltobad( -101 ); # 6 random values [-50:50]
	my $u3 = pdl( 15.3884236956522, -17.9424192631203, -10.0026229609036,
		-4.13046468116249, 40.3056552926195, -13.8882183825032,
		26.2092994583604, -28.9333103012069, -101, 47.7954550755687,
		42.5291780050966, -101, 12.06914489876 )->inplace->setvaltobad( -101 ); # 13 random values [-50:50]
	my $u4 = pdl( 8.28086562230297, 46.8340738920247, -37.15661354396 ); # 3 random values [-50:50]
	my $N = 42;
	my $u = $u0->append( $u1 )->append( $u2 )->append( $u3 )->append( $u4 );
	cmp_ok( $N, '>', 0, 'there are values to test' );
	ok( $u->nelem == $N, 'number of values is consistent' );
	for my $class ( __PACKAGE__->actions ) {
		# CodeRef is not supposed to be able to concatenate results
		next if $class eq 'PDL::NDBin::Action::CodeRef';
		my $binner = PDL::NDBin->new( axes => [ [ u => (step=>4,min=>-50,n=>25) ] ],
					      vars => [ [ u => "+$class" ] ] );
		for my $var ( $u0, $u1, $u2, $u3, $u4 ) { $binner->process( u => $var ) };
		my $got = $binner->output;
		my $expected = PDL::NDBin->new( axes => [ [ u => (step=>4,min=>-50,n=>25) ] ],
						vars => [ [ u => "+$class" ] ] )
					 ->process( u => $u )
					 ->output;
		# we must turn the 'u' key into a special testing object, hence
		# this somewhat dirty hack:
		$expected->{u} = test_pdl( $expected->{u} );
		cmp_deeply $got, $expected, "repeated invocation of process() equal to concatenation with action $class";
	}
}

#
# BAD VALUES
#
note 'BAD VALUES';
{
	my %matrix = (
		allgood => {
			axis   => short(0,0,0,1),
			var    => float(5,4,3,2),
			Avg    => double(4,2),
			Count  => indx(3,1),
			Max    => float(5,2),
			Min    => float(3,2),
			StdDev => double(sqrt(2/3),0),
			Sum    => float(12,2),
		},
		allaxisbad => {
			axis   => short(-1,-1,-1,-1),
			var    => float(5,4,3,2),
			Avg    => double(-1,-1),
			Count  => indx(0,0),
			Max    => float(-1,-1),
			Min    => float(-1,-1),
			StdDev => double(-1,-1),
			Sum    => float(-1,-1),
		},
		axisbad1 => {
			axis   => short(-1,0,0,0),
			var    => float(5,4,3,2),
			Avg    => double(3,-1),
			Count  => indx(3,0),
			Max    => float(4,-1),
			Min    => float(2,-1),
			StdDev => double(sqrt(2/3),-1),
			Sum    => float(9,-1),
		},
		axisbad1_var => {
			axis   => short(-1,1,1,1),
			var    => float(5,4,3,2),
			Avg    => double(-1,3),
			Count  => indx(0,3),
			Max    => float(-1,4),
			Min    => float(-1,2),
			StdDev => double(-1,sqrt(2/3)),
			Sum    => float(-1,9),
		},
		axisbad2 => {
			axis   => short(0,-1,0,0),
			var    => float(5,4,3,2),
			Avg    => double(10/3,-1),
			Count  => indx(3,0),
			Max    => float(5,-1),
			Min    => float(2,-1),
			StdDev => double(sqrt((5-10/3)*(5-10/3) + (3-10/3)*(3-10/3) + (2-10/3)*(2-10/3))/sqrt(3),-1),
			Sum    => float(10,-1),
		},
		axisbad23 => {
			axis   => short(0,-1,-1,0),
			var    => float(5,4,3,2),
			Avg    => double(3.5,-1),
			Count  => indx(2,0),
			Max    => float(5,-1),
			Min    => float(2,-1),
			StdDev => double(sqrt((5-3.5)*(5-3.5) + (2-3.5)*(2-3.5))/sqrt(2),-1),
			Sum    => float(7,-1),
		},
		axisbad23_var => {
			axis   => short(0,-1,-1,1),
			var    => float(5,4,3,2),
			Avg    => double(5,2),
			Count  => indx(1,1),
			Max    => float(5,2),
			Min    => float(5,2),
			StdDev => double(0,0),
			Sum    => float(5,2),
		},
		axisbad4 => {
			axis   => short(1,0,1,-1),
			var    => float(5,4,3,2),
			Avg    => double(4,4),
			Count  => indx(1,2),
			Max    => float(4,5),
			Min    => float(4,3),
			StdDev => double(0,1),
			Sum    => float(4,8),
		},
		allvarbad => {
			axis   => short(0,1,0,1),
			var    => float(-1,-1,-1,-1),
			Avg    => double(-1,-1),
			Count  => indx(0,0),
			Max    => float(-1,-1),
			Min    => float(-1,-1),
			StdDev => double(-1,-1),
			Sum    => float(-1,-1),
		},
		varbad4 => {
			axis   => short(1,1,1,1),
			var    => float(5,4,3,-1),
			Avg    => double(-1,4),
			Count  => indx(0,3),
			Max    => float(-1,5),
			Min    => float(-1,3),
			StdDev => double(-1,sqrt(2/3)),
			Sum    => float(-1,12),
		},
	);
	while( my($name,$hash) = each %matrix ) {
		my $axis = $hash->{axis}->setvaltobad( -1 );
		my $var  = $hash->{var}->setvaltobad( -1 );
		for my $class ( __PACKAGE__->actions ) {
			# CodeRef does not compute anything by itself
			next if $class eq 'PDL::NDBin::Action::CodeRef';
			my( $action ) = $class =~ /:([^:]+)$/;
			my $expected = $hash->{ $action }->setvaltobad( -1 );
			my $binner = PDL::NDBin->new(
				axes => [ [ 'axis', step => .5, min => 0, n => 2 ] ],
				vars => [ [ 'var' => "+$class" ] ],
			);
			$binner->process( axis => $axis, var => $var );
			is_pdl $binner->output->{var}, $expected, "bad value test $name, action class $class";
		}
	}
}
