# multidimensional binning & histogramming - test actions

use strict;
use warnings;
use Test::More;
use Test::PDL;
use Test::Exception;
use Test::NoWarnings;
use Carp qw( confess );
use PDL;
use PDL::Types;
use PDL::NDBin::Iterator;
use Module::Pluggable sub_name    => 'actions',
		      require     => 1,
		      search_path => [ 'PDL::NDBin::Action' ];

# compatibility with non-64-bit PDL versions
BEGIN { if( ! defined &PDL::indx ) { *indx = \&PDL::long; } }

sub apply
{
	my ( $x, $y, $N, $f ) = @_;
	my $pdl = zeroes $N;
	for my $bin ( 0 .. $N-1 ) {
		my $want = which $y == $bin;
		$pdl->set( $bin, $f->( $x->index($want) ) );
	}
	$pdl;
}

# create a temporary iterator with the given arguments
sub iter
{
	my( $var, $idx, $N ) = @_;
	PDL::NDBin::Iterator->new( bins => [ $N ], array => [ $var ], idx => $idx );
}

# systematically list all types used by PDL
my @all_types = PDL::Types::types;
plan tests => 117 + (8 + __PACKAGE__->actions) * @all_types;

# variable declarations
my ( $expected, $got, $N, $x, $y, @u, @v, $obj, $iter );

#
#
#
note 'SETUP';
{
	my %plugins = map { $_ => 1 } __PACKAGE__->actions;
	note 'registered plugins: ', join ', ' => keys %plugins;
	for my $p ( qw(	PDL::NDBin::Action::Count  PDL::NDBin::Action::Sum
			PDL::NDBin::Action::Max    PDL::NDBin::Action::Min
			PDL::NDBin::Action::Avg    PDL::NDBin::Action::StdDev ) )
	{
		ok $plugins{ $p }, "$p is there";
		delete $plugins{ $p };
		# create wrapper function 'ifunc' around the class '::Func'
		my $function = do { $p =~ /::(\w+)$/; 'i' . lc $1 };
		no strict 'refs';
		*$function = sub {
			my $iter = shift;
			confess 'too many arguments' if @_;
			my $obj = $p->new( N => $iter->nbins );
			$obj->process( $iter );
			return $obj->result;
		};
	}
	for my $p ( qw(	PDL::NDBin::Action::CodeRef ) )
	{
		ok $plugins{ $p }, "$p is there";
		delete $plugins{ $p };
		# create wrapper function around the class
		my $function = do { $p =~ /::(\w+)$/; 'i' . lc $1 };
		no strict 'refs';
		*$function = sub {
			my $iter = shift;
			my $coderef = shift;
			confess 'too many arguments' if @_;
			my $obj = $p->new( N => $iter->nbins, coderef => $coderef );
			$obj->process( $iter );
			return $obj->result;
		};
	}
	ok( ! %plugins, 'no more unknown plugins left' ) or diag 'remaining plugins: ', join ', ' => keys %plugins;
}

#
# _SETNULLTOBAD()
#
note '_SETNULLTOBAD()';
{
	my $count = indx(  4, 1, 0, 1 );
	my $sum   = long( 24, 7, 0, 8 );
	for my $type ( @all_types ) {
		my $s1 = $sum->convert( $type );
		$s1->inplace->_setnulltobad( $count );
		my $expected = long( 24, 7,-1, 8 )->inplace->setvaltobad( -1 )->convert( $type );
		is_pdl $s1, $expected, "_setnulltobad() on type $type";
	}
}

#
# BASIC OO FUNCTIONALITY
#
note 'BASIC OO FUNCTIONALITY';

#
$N = 10;
my %test_args = (
	'PDL::NDBin::Action::CodeRef' => [ N => $N, coderef => sub {} ],
	'PDL::NDBin::Action::Avg'     => [ N => $N ],
	'PDL::NDBin::Action::Count'   => [ N => $N ],
	'PDL::NDBin::Action::Max'     => [ N => $N ],
	'PDL::NDBin::Action::Min'     => [ N => $N ],
	'PDL::NDBin::Action::StdDev'  => [ N => $N ],
	'PDL::NDBin::Action::Sum'     => [ N => $N ],
);
for my $class ( __PACKAGE__->actions ) {
	$obj = $class->new( @{ $test_args{ $class } } );
	isa_ok $obj, $class;
	can_ok $obj, qw( new process result );
	my $ret = $obj->process( iter null, null, $N );
	isa_ok $ret, $class, 'return value of process()';
	my $result = $obj->result;
	ok eval { $result->isa('PDL') }, 'result() returns a pdl';
}

#
# OUTPUT PIDDLE RETURN TYPE
#
note 'OUTPUT PIDDLE RETURN TYPE';

#
$N = 4;
@u = ( 4,5,6,7,8,9 );	# data values
@v = ( 0,0,0,1,3,0 );	# bin numbers
$x = pdl( @u );
$y = indx( @v );

#
note '   function = icount';
for my $type ( @all_types ) {
	cmp_ok( icount( iter $x->convert($type), $y, $N )->type, '==', indx, "return type is indx for input type $type" );
}

#
note '   function = isum';
for my $type ( @all_types ) {
	my $expected_type = ($type < long) ? long : $type;
	cmp_ok( isum( iter $x->convert($type), $y, $N )->type, '==', $expected_type, "return type is $expected_type for input type $type" );
}

#
for my $what ( ['iavg', \&iavg], ['istddev', \&istddev] ) {
	note '   function = ' . $what->[0];
	for my $type ( @all_types ) {
		cmp_ok( $what->[1]->( iter $x->convert($type), $y, $N )->type, '==', double, "return type is double for input type $type" );
	}
}

#
for my $class ( qw( PDL::NDBin::Action::Max PDL::NDBin::Action::Min ) ) {
	note "   class = $class";
	for my $type ( @all_types ) {
		$obj = $class->new( N => $N );
		$obj->process( iter $x->convert($type), $y, $N );
		cmp_ok $obj->result->type, '==', $type, "return type is $type for input type $type";
	}
}

#
note '   class = PDL::NDBin::Action::CodeRef';
for my $type ( @all_types ) {
	$obj = PDL::NDBin::Action::CodeRef->new( N => $N, coderef => sub {} );
	$obj->process( iter $x->convert($type), $y, $N );
	cmp_ok $obj->result->type, '==', $type, "return type is $type for input type $type";
}

#
note '   type set by user';
for my $class ( __PACKAGE__->actions ) {
	for my $type ( @all_types ) {
		my @args = ( N => $N );
		push @args, coderef => sub {} if $class eq 'PDL::NDBin::Action::CodeRef';
		$obj = $class->new( @args, type => $type );
		$obj->process( iter $x->convert($type), $y, $N );
		cmp_ok $obj->result->type, '==', $type, "return type is $type for class $class with type => $type";
	}
}

#
# FUNCTIONALITY
#
note 'FUNCTIONALITY';

#
$N = 4;
@u = ( 4,5,6,7,8,9 );	# data values
@v = ( 0,0,0,1,3,0 );	# bin numbers
$x = short( @u );
$y = indx( @v );

# icount
$expected = indx( 4,1,0,1 );
$got = icount( iter $x, $y, $N );
is_pdl $got, $expected, "icount, input type short";
$got = icount( iter $x->float, $y, $N );
is_pdl $got, $expected, "icount, input type float";
# the following test should succeed because a piddle without any bad values
# will be created automatically by _icount_loop() in place of the 'undef'
$got = icount( iter undef, $y, $N );
is_pdl $got, $expected, "icount, input undef";
# the following test would fail with "Error in _icount_loop:Wrong dims" because
# PDL::null isn't resized automatically, it seems
#$got = icount( iter null, $y, $N );
#is_pdl $got, $expected, "icount, input null";

# isum
$expected = long( 24,7,-1,8 )->inplace->setvaltobad( -1 );
$got = isum( iter $x, $y, $N );
is_pdl $got, $expected, "isum, input type short";
$got = isum( iter $x->float, $y, $N );
is_pdl $got, $expected->float, "isum, input type float";

# imax
$expected = long( 9,7,-1,8 )->inplace->setvaltobad( -1 );
$got = imax( iter $x->short, $y, $N );
is_pdl $got, $expected->short, "imax, input type short";
$got = imax( iter $x->float, $y, $N );
is_pdl $got, $expected->float, "imax, input type float";
$got = imax( iter $x->double, $y, $N );
is_pdl $got, $expected->double, "imax, input type double";

# imin
$expected = long( 4,7,-1,8 )->inplace->setvaltobad( -1 );
$got = imin( iter $x->short, $y, $N );
is_pdl $got, $expected->short, "imin, input type short";
$got = imin( iter $x->float, $y, $N );
is_pdl $got, $expected->float, "imin, input type float";
$got = imin( iter $x->double, $y, $N );
is_pdl $got, $expected->double, "imin, input type double";

# iavg
$expected = pdl( 6,7,-1,8 )->inplace->setvaltobad( -1 );
$got = iavg( iter $x, $y, $N );
is_pdl $got, $expected, "iavg, input type short";
$got = iavg( iter $x->float, $y, $N );
is_pdl $got, $expected, "iavg, input type float";
$got = iavg( iter $x->double, $y, $N );
is_pdl $got, $expected, "iavg, input type double";

# istddev
$expected = pdl( sqrt(3.5),0,-1,0 )->inplace->setvaltobad( -1 );
$got = istddev( iter $x, $y, $N );
is_pdl $got, $expected, "istddev, input type short";
$got = istddev( iter $x->float, $y, $N );
is_pdl $got, $expected, "istddev, input type float";
$got = istddev( iter $x->double, $y, $N );
is_pdl $got, $expected, "istddev, input type double";

# PDL::NDBin::Action::CodeRef
$expected = pdl( 6,7,-1,8 )->inplace->setvaltobad( -1 );
$obj = PDL::NDBin::Action::CodeRef->new( N => $N, coderef => sub { $_[0]->want->nelem ? ($_[0]->selection->stats)[0] : undef } );
$iter = iter $x, $y, $N;
while( $iter->advance ) { $obj->process( $iter ) }
$got = $obj->result;
is_pdl $got, $expected->short, "PDL::NDBin::Action::CodeRef, input type short";
$obj = PDL::NDBin::Action::CodeRef->new( N => $N, coderef => sub { $_[0]->want->nelem ? ($_[0]->selection->stats)[0] : undef } );
$iter = iter $x->float, $y, $N;
while( $iter->advance ) { $obj->process( $iter ) }
$got = $obj->result;
is_pdl $got, $expected->float, "PDL::NDBin::Action::CodeRef, input type float";
$obj = PDL::NDBin::Action::CodeRef->new( N => $N, coderef => sub { $_[0]->want->nelem ? ($_[0]->selection->stats)[0] : undef } );
$iter = iter $x->double, $y, $N;
while( $iter->advance ) { $obj->process( $iter ) }
$got = $obj->result;
is_pdl $got, $expected, "PDL::NDBin::Action::CodeRef, input type double";

#
#
#
note 'BAD VALUE FUNCTIONALITY';

#
$N = 4;
@u = ( 4,5,-1,7,8,9 );	# data values
@v = ( 0,0, 0,1,3,0 );	# bin numbers
$x = short( @u )->inplace->setvaltobad( -1 );
$y = indx( @v );

# icount
# note that in the next test, the count in the very first bin is one lower than
# before due to the bad value (-1) in the third position
$expected = indx( 3,1,0,1 );
$got = icount( iter $x, $y, $N );
is_pdl $got, $expected, "icount with bad values, input type short";
$got = icount( iter $x->float, $y, $N );
is_pdl $got, $expected, "icount with bad values, input type float";

# isum
$expected = long( 18,7,-1,8 )->inplace->setvaltobad( -1 );
$got = isum( iter $x, $y, $N );
is_pdl $got, $expected, "isum with bad values, input type short";
$got = isum( iter $x->float, $y, $N );
is_pdl $got, $expected->float, "isum with bad values, input type float";

# imax
$expected = long( 9,7,-1,8 )->inplace->setvaltobad( -1 );
$got = imax( iter $x->short, $y, $N );
is_pdl $got, $expected->short, "imax with bad values, input type short";
$got = imax( iter $x->float, $y, $N );
is_pdl $got, $expected->float, "imax with bad values, input type float";
$got = imax( iter $x->double, $y, $N );
is_pdl $got, $expected->double, "imax with bad values, input type double";

# imin
$expected = long( 4,7,-1,8 )->inplace->setvaltobad( -1 );
$got = imin( iter $x->short, $y, $N );
is_pdl $got, $expected->short, "imin with bad values, input type short";
$got = imin( iter $x->float, $y, $N );
is_pdl $got, $expected->float, "imin with bad values, input type float";
$got = imin( iter $x->double, $y, $N );
is_pdl $got, $expected->double, "imin with bad values, input type double";

# iavg
$expected = pdl( 6,7,-1,8 )->inplace->setvaltobad( -1 );
$got = iavg( iter $x, $y, $N );
is_pdl $got, $expected, "iavg with bad values, input type short";
$got = iavg( iter $x->float, $y, $N );
is_pdl $got, $expected, "iavg with bad values, input type float";
$got = iavg( iter $x->double, $y, $N );
is_pdl $got, $expected, "iavg with bad values, input type double";

# istddev
$expected = pdl( sqrt(14/3),0,-1,0 )->inplace->setvaltobad( -1 );
$got = istddev( iter $x, $y, $N );
is_pdl $got, $expected, "istddev with bad values, input type short";
$got = istddev( iter $x->float, $y, $N );
is_pdl $got, $expected, "istddev with bad values, input type float";
$got = istddev( iter $x->double, $y, $N );
is_pdl $got, $expected, "istddev with bad values, input type double";

# PDL::NDBin::Action::CodeRef
$expected = pdl( 6,7,-1,8 )->inplace->setvaltobad( -1 );
$obj = PDL::NDBin::Action::CodeRef->new( N => $N, coderef => sub { $_[0]->want->nelem ? ($_[0]->selection->stats)[0] : undef } );
$iter = iter $x, $y, $N;
while( $iter->advance ) { $obj->process( $iter ) }
$got = $obj->result;
is_pdl $got, $expected->short, "PDL::NDBin::Action::CodeRef with bad values, input type short";
$obj = PDL::NDBin::Action::CodeRef->new( N => $N, coderef => sub { $_[0]->want->nelem ? ($_[0]->selection->stats)[0] : undef } );
$iter = iter $x->float, $y, $N;
while( $iter->advance ) { $obj->process( $iter ) }
$got = $obj->result;
is_pdl $got, $expected->float, "PDL::NDBin::Action::CodeRef with bad values, input type float";
$obj = PDL::NDBin::Action::CodeRef->new( N => $N, coderef => sub { $_[0]->want->nelem ? ($_[0]->selection->stats)[0] : undef } );
$iter = iter $x->double, $y, $N;
while( $iter->advance ) { $obj->process( $iter ) }
$got = $obj->result;
is_pdl $got, $expected, "PDL::NDBin::Action::CodeRef with bad values, input type double";

#
$N = 4;
@u = ( 4,5, 6,7,8,9 );	# data values
@v = ( 0,0,-1,1,3,0 );	# bin numbers
$x = short( @u );
$y = indx( @v )->inplace->setvaltobad( -1 );

# icount
# note that in the next test, the count in the very first bin is one lower than
# before due to the bad value (-1) in the third position
$expected = indx( 3,1,0,1 );
$got = icount( iter $x, $y, $N );
is_pdl $got, $expected, "icount with bad bin numbers, input type short";
$got = icount( iter $x->float, $y, $N );
is_pdl $got, $expected, "icount with bad bin numbers, input type float";

# isum
$expected = long( 18,7,-1,8 )->inplace->setvaltobad( -1 );
$got = isum( iter $x, $y, $N );
is_pdl $got, $expected, "isum with bad bin numbers, input type short";
$got = isum( iter $x->float, $y, $N );
is_pdl $got, $expected->float, "isum with bad bin numbers, input type float";

# imax
$expected = long( 9,7,-1,8 )->inplace->setvaltobad( -1 );
$got = imax( iter $x->short, $y, $N );
is_pdl $got, $expected->short, "imax with bad bin numbers, input type short";
$got = imax( iter $x->float, $y, $N );
is_pdl $got, $expected->float, "imax with bad bin numbers, input type float";
$got = imax( iter $x->double, $y, $N );
is_pdl $got, $expected->double, "imax with bad bin numbers, input type double";

# imin
$expected = long( 4,7,-1,8 )->inplace->setvaltobad( -1 );
$got = imin( iter $x->short, $y, $N );
is_pdl $got, $expected->short, "imin with bad bin numbers, input type short";
$got = imin( iter $x->float, $y, $N );
is_pdl $got, $expected->float, "imin with bad bin numbers, input type float";
$got = imin( iter $x->double, $y, $N );
is_pdl $got, $expected->double, "imin with bad bin numbers, input type double";

# iavg
$expected = pdl( 6,7,-1,8 )->inplace->setvaltobad( -1 );
$got = iavg( iter $x, $y, $N );
is_pdl $got, $expected, "iavg with bad bin numbers, input type short";
$got = iavg( iter $x->float, $y, $N );
is_pdl $got, $expected, "iavg with bad bin numbers, input type float";
$got = iavg( iter $x->double, $y, $N );
is_pdl $got, $expected, "iavg with bad bin numbers, input type double";

# istddev
$expected = pdl( sqrt(14/3),0,-1,0 )->inplace->setvaltobad( -1 );
$got = istddev( iter $x, $y, $N );
is_pdl $got, $expected, "istddev with bad bin numbers, input type short";
$got = istddev( iter $x->float, $y, $N );
is_pdl $got, $expected, "istddev with bad bin numbers, input type float";
$got = istddev( iter $x->double, $y, $N );
is_pdl $got, $expected, "istddev with bad bin numbers, input type double";

# PDL::NDBin::Action::CodeRef
$expected = pdl( 6,7,-1,8 )->inplace->setvaltobad( -1 );
$obj = PDL::NDBin::Action::CodeRef->new( N => $N, coderef => sub { $_[0]->want->nelem ? ($_[0]->selection->stats)[0] : undef } );
$iter = iter $x, $y, $N;
while( $iter->advance ) { $obj->process( $iter ) }
$got = $obj->result;
is_pdl $got, $expected->short, "PDL::NDBin::Action::CodeRef with bad bin numbers, input type short";
$obj = PDL::NDBin::Action::CodeRef->new( N => $N, coderef => sub { $_[0]->want->nelem ? ($_[0]->selection->stats)[0] : undef } );
$iter = iter $x->float, $y, $N;
while( $iter->advance ) { $obj->process( $iter ) }
$got = $obj->result;
is_pdl $got, $expected->float, "PDL::NDBin::Action::CodeRef with bad bin numbers, input type float";
$obj = PDL::NDBin::Action::CodeRef->new( N => $N, coderef => sub { $_[0]->want->nelem ? ($_[0]->selection->stats)[0] : undef } );
$iter = iter $x->double, $y, $N;
while( $iter->advance ) { $obj->process( $iter ) }
$got = $obj->result;
is_pdl $got, $expected, "PDL::NDBin::Action::CodeRef with bad bin numbers, input type double";

#
#
#
note 'CROSS-CHECK';

#
$N = 10;
@u = ( 0.380335783193917, 0.431569737239869, 0.988228581651253,
	0.369529166348862, 0.015659808076709, 0.0128772388998044,
	0.574823006425813, 0.307950317667824, 0.203820671877484,
	0.689137032780081, 0.196232563366532, 0.673725380087014,
	0.338351708168364, 0.618128376628889, 0.0686126943478449,
	0.467397968837865, 0.24772883995394, 0.908459824625453,
	0.385466358455641, 0.694874773806994, 0.890462725956144,
	0.654082910438362, 0.455010756187814, 0.477250284962928,
	0.701090630071324, 0.357419784470324, 0.454056307535307,
	0.410569424644144, 0.660074882361915, 0.780762636481384,
	0.861702069810971, 0.363648213432661, 0.293263267962747,
	0.0660826236986338, 0.144319047939245, 0.180976557519053,
	0.0723328240807923, 0.242442573592697, 0.530066073796629,
	0.443430523052676, 0.638280157347285, 0.639442502229826,
	0.171132424601108, 0.400188119465021, 0.0354213266424388,
	0.901766545993169, 0.782722425788162, 0.929661711654482,
	0.681530382655584, 0.176795809007814, 0.060310253781676,
	0.31484578272751, 0.146810627367376, 0.0628804433014665,
	0.10484333107004, 0.269269937203966, 0.334614366845788,
	0.264327566086138, 0.476430402530905, 0.954407831713674,
	0.292588191733945, 0.820185941055982, 0.800810910512549,
	0.259212208736521, 0.404729444075432, 0.742845270762444,
	0.47288595927547, 0.829338451370127, 0.971328329171531,
	0.92029402745014, 0.544243289524811, 0.840123135946975,
	0.351696919494916, 0.969196552715403, 0.406499583422413,
	0.29666399706705, 0.67883388679569, 0.156984244484207,
	0.152108402156724, 0.350192598762412, 0.238750000928182,
	0.587758585597186, 0.22486143436954, 0.266754888566773,
	0.60121706210079, 0.132452114236727, 0.0825898169904598,
	0.937056760726044, 0.482459799706223, 0.407488755034649,
	0.456621392813172, 0.230855833154955, 0.681169188125796,
	0.812853783458721, 0.481564203962133, 0.771775912520233,
	0.652684410419059, 0.840377647492318, 0.513286599743889,
	0.425801145512487 ); # 100 random values
@v = ( 6, 7, 3, 3, 7, 1, 8, 3, 2, 0, 6, 0, 5, 3, 3, 8, 7, 2, 7, 9, 2, 7, 4, 6,
	0, 6, 3, 1, 5, 2, 4, 5, 8, 3, 8, 7, 8, 1, 4, 9, 4, 6, 3, 1, 4, 0, 4, 4,
	0, 3, 8, 6, 0, 3, 4, 8, 0, 7, 3, 9, 3, 2, 3, 7, 6, 9, 0, 9, 2, 3, 3, 0,
	3, 5, 3, 6, 0, 1, 8, 1, 5, 4, 1, 7, 4, 7, 1, 9, 8, 7, 8, 1, 1, 8, 5, 1,
	3, 6, 4, 4 ); # 100 random bins
$x = pdl( @u );
$x = $x->setbadif( $x < .5 );
$y = indx( @v );

#
$expected = apply( $x, $y, $N, \&ngood )->convert( indx );
$got = icount( iter $x, $y, $N );
is_pdl $got, $expected, "cross-check icount() with ngood()";
$expected = apply( $x, $y, $N, \&sum );
$got = isum( iter $x, $y, $N );
is_pdl $got, $expected, "cross-check isum() with sum()";
$expected = apply( $x, $y, $N, \&max );
$got = imax( iter $x, $y, $N );
is_pdl $got, $expected, "cross-check imax() with max()";
$expected = apply( $x, $y, $N, \&min );
$got = imin( iter $x, $y, $N );
is_pdl $got, $expected, "cross-check imin() with min()";
$expected = apply( $x, $y, $N, sub { ($_[0]->stats)[0] } );
$got = iavg( iter $x, $y, $N );
is_pdl $got, $expected, "cross-check iavg() with stats()";
# the docs of `stats' are actually wrong on this one:
# the population rms is in [1], and the rms is in [6]
$expected = apply( $x, $y, $N, sub { ($_[0]->stats)[6] } );
$got = istddev( iter $x, $y, $N );
is_pdl $got, $expected, "cross-check istddev() with stats()";

#
#
#
note 'CONCATENATION';

{
	my $u0 = pdl( -18.3183390661739, 27.3974706788376, 35.7153786154491,
		47.8258388108234, -35.1588200253218, 26.4152568315506 ); # 6 random values [-50:50]
	my $v0 = indx( 4, 4, 8, 1, 5, 0 ); # 6 random bins [0:9]
	my $u1 = pdl( -49.573940365601, -5.71788528168433 ); # 2 random values [-50:50]
	my $v1 = indx( 6, 5 ); # 2 random bins [0:9]
	my $u2 = pdl( 13.9010951470269, -26.6426081230296, -20.4758828884117,
		-47.0451825792392, 6.76251455434169, 25.0398394482954,
		-14.1263729818995, -34.3005011256633, 11.4501997177783,
		14.2397334136742 ); # 10 random values [-50:50]
	my $v2 = indx( 8, 6, 5, 1, 2, 9, 9, 5, 9, 0 ); # 10 random bins [0:9]
	my $u3 = pdl( 29.4897695519602, -12.8522886035878, 46.9800168006543,
		47.5442131843106, -48.242720133063, -49.9047087352846 ); # 6 random values [-50:50]
	my $v3 = indx( 4, 1, 4, 2, 0, 4 ); # 6 random bins [0:9]
	my $u4 = pdl( 33.9285663707713, -19.4440970026509, 25.3297021599046,
		8.22183510796357, -31.2812362886149, -22.397819555157,
		-33.5881440926578, -46.7164828941616, -16.4592034011449,
		-10.2272980921985, -25.3017491996424 ); # 11 random values [-50:50]
	my $v4 = indx( 1, 0, 1, 5, 2, 0, 4, 0, 4, 2, 6 ); # 11 random bins [0:9]
	my $N = 35;
	my $u = $u0->append( $u1 )->append( $u2 )->append( $u3 )->append( $u4 );
	my $v = $v0->append( $v1 )->append( $v2 )->append( $v3 )->append( $v4 );
	cmp_ok( $N, '>', 0, 'there are values to test' );
	ok( $u->nelem == $N && $v->nelem == $N, 'number of values is consistent' );
	for my $class ( __PACKAGE__->actions ) {
		# CodeRef is not supposed to be able to concatenate
		next if $class eq 'PDL::NDBin::Action::CodeRef';
		my $obj = $class->new( N => $N );
		$obj->process( iter $u0, $v0, $N );
		$obj->process( iter $u1, $v1, $N );
		$obj->process( iter $u2, $v2, $N );
		$obj->process( iter $u3, $v3, $N );
		$obj->process( iter $u4, $v4, $N );
		my $got = $obj->result;
		$obj = $class->new( N => $N );
		$obj->process( iter $u, $v, $N );
		my $expected = $obj->result;
		is_pdl $got, $expected, "repeated invocation of $class equal to concatenation";
	}
}

{
	my $u0 = pdl( -44.7319945183754, 2.14679136319411, -101,
		32.2078360467891, 2.42312479183653, 24.961636154341,
		16.7449041152423, -101, 15.135123983227, 18.8232267311516,
		-15.3718944013033, 17.2185903975429 )->inplace->setvaltobad( -101 ); # 12 random values [-50:50]
	my $v0 = indx( 8, 0, 7, 5, 4, 9, 6, 1, 6, 7, 7, 5 ); # 12 random bins [0:9]
	my $u1 = pdl( -101, 22.876731972822, 22.0445472500778,
		-26.5999303520772, 27.1019424052675, -26.3532958054284, -101,
		-29.0518405732623, 23.9856347894982, -29.1397313934237,
		7.3252320197863, -27.4562734240643 )->inplace->setvaltobad( -101 ); # 12 random values [-50:50]
	my $v1 = indx( 8, 1, 2, 6, 9, 5, 5, 7, 5, 4, 5, 2 ); # 12 random bins [0:9]
	my $u2 = pdl( 40.4673256586715, -101, -30.3275242788303, -101,
		39.7762903332339, -38.4575329560239, 1.74879500859113,
		-4.78760502460922 )->inplace->setvaltobad( -101 ); # 8 random values [-50:50]
	my $v2 = indx( 7, 7, 3, 9, 7, 3, 2, 2 ); # 8 random bins [0:9]
	my $u3 = pdl( -28.3032696453798, -101, -39.0345665405043,
		30.4407977872174, -101, 20.1915655828689, -38.1173555823768,
		-38.3656423025752, -5.98602407355919, -31.3445025843915,
		2.0134617981693, -26.869783026164 )->inplace->setvaltobad( -101 ); # 12 random values [-50:50]
	my $v3 = indx( 1, 8, 9, 6, 8, 8, 5, 2, 3, 6, 1, 4 ); # 12 random bins [0:9]
	my $u4 = pdl( 34.9733702362666, -101, -101, -101, 38.7278135049009,
		0.494848736214237, 25.3478221389223 )->inplace->setvaltobad( -101 ); # 7 random values [-50:50]
	my $v4 = indx( 4, 1, 2, 3, 1, 5, 8 ); # 7 random bins [0:9]
	my $N = 51;
	my $u = $u0->append( $u1 )->append( $u2 )->append( $u3 )->append( $u4 );
	my $v = $v0->append( $v1 )->append( $v2 )->append( $v3 )->append( $v4 );
	cmp_ok( $N, '>', 0, 'there are values to test' );
	ok( $u->nelem == $N && $v->nelem == $N, 'number of values is consistent' );
	for my $class ( __PACKAGE__->actions ) {
		# CodeRef is not supposed to be able to concatenate
		next if $class eq 'PDL::NDBin::Action::CodeRef';
		my $obj = $class->new( N => $N );
		$obj->process( iter $u0, $v0, $N );
		$obj->process( iter $u1, $v1, $N );
		$obj->process( iter $u2, $v2, $N );
		$obj->process( iter $u3, $v3, $N );
		$obj->process( iter $u4, $v4, $N );
		my $got = $obj->result;
		$obj = $class->new( N => $N );
		$obj->process( iter $u, $v, $N );
		my $expected = $obj->result;
		is_pdl $got, $expected, "repeated invocation of $class equal to concatenation (bad values present)";
	}
}
