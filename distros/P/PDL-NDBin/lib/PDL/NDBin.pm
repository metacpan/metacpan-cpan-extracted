package PDL::NDBin;
# ABSTRACT: Multidimensional binning & histogramming
$PDL::NDBin::VERSION = '0.018';
use strict;
use warnings;
use Exporter;
use List::Util qw( reduce );
use List::MoreUtils qw( pairwise );
use Math::Round qw( nlowmult nhimult );
use PDL::Lite;		# do not import any functions into this namespace
use PDL::NDBin::Iterator;
use PDL::NDBin::Actions_PP;
use PDL::NDBin::Utils_PP;
use Log::Any qw( $log );
use Data::Dumper;
use UUID::Tiny qw( :std );
use POSIX qw( ceil );
use Params::Validate qw( validate validate_pos validate_with ARRAYREF CODEREF HASHREF SCALAR );
use Carp;
use Class::Load qw( load_class );


our @ISA = qw( Exporter );
our @EXPORT = qw( );
our @EXPORT_OK = qw( ndbinning ndbin );
our %EXPORT_TAGS = ( all => [ qw( ndbinning ndbin ) ] );

# the list of valid keys
my %valid_key = map { $_ => 1 } qw( axes vars );


my @axis_params = qw( max min n round step grid );
my ( %axis_params, %axis_flags );
@axis_params{@axis_params} = (1) x @axis_params;
@axis_flags{@axis_params} = map { 1<<$_ } 0..@axis_params-1;

my %axis_allowed =
    map { reduce( sub { $a | $b }, 0, @axis_flags{@$_} ) => 1 }
        [ ],
	[ qw( n ) ],
	[ qw( min ) ],
	[ qw( max ) ],
        [ qw( step ) ],
	[ qw( min step ) ],
	[ qw( max step ) ],
	[ qw( min n ) ],
	[ qw( max n ) ],
	[ qw( round n ) ],
	[ qw( round step ) ],
	[ qw( n step ) ],
	[ qw( n step round ) ],
	[ qw( min n step ) ],
	[ qw( max n step ) ],
	[ qw( min max n ) ],
	[ qw( min max step ) ],
        [ qw( grid ) ];

sub add_axis
{
	my $self = shift;
	my %params = validate( @_, {
			max   => 0,
			min   => 0,
			n     => 0,
			name  => 1,
			pdl   => 0,
			round => 0,
			step  => 0,
			grid  => 0,
		} );
	$log->tracef( 'adding axis with specs %s', \%params );

	my $pmask = reduce { $a | ($b||0) } 0, @axis_flags{ keys %params };
	croak( "inconsistent or incomplete parameters: ", keys %params )
	    unless $axis_allowed{ $pmask };

	push @{ $self->{axes} }, \%params;
}


sub add_var
{
	my $self = shift;
	my %params = validate( @_, {
			action => { type => CODEREF | HASHREF | SCALAR },
			name   => 1,
			pdl    => 0,
		} );
	$log->tracef( 'adding variable with specs %s', \%params );
	push @{ $self->{vars} }, \%params;
}


sub new
{
	my $class = shift;
	my %params = validate( @_, {
			axes => { optional => 1, type => ARRAYREF },
			vars => { optional => 1, type => ARRAYREF },
		} );
	$log->debug( 'new: arguments = ' . Dumper \%params ) if $log->is_debug;
	my $self = bless { axes => [], vars => [] }, $class;
	# axes
	$params{axes} ||= [];		# be sure we can dereference
	my @axes = @{ $params{axes} };
	for my $axis ( @axes ) {
		my @pat = ( 1 );					# one mandatory argument
		if( @$axis > 1 ) { push @pat, (0) x (@$axis - 1) }	# followed by n-1 optional arguments
		my( $name ) = validate_pos( @$axis, @pat );
		shift @$axis; # remove name
		$self->add_axis( name => $name, @$axis );
	}
	# vars
	$params{vars} ||= [];		# be sure we can dereference
	my @vars = @{ $params{vars} };
	for my $var ( @vars ) {
		my( $name, $action ) = validate_pos( @$var, 1, 1 );
		$self->add_var( name => $name, action => $action );
	}
	return $self;
}


sub axes { wantarray ? @{ $_[0]->{axes} } : $_[0]->{axes} }
sub vars { wantarray ? @{ $_[0]->{vars} } : $_[0]->{vars} }

sub _make_instance_hashref
{
	my %params = validate_with(
		params => \@_,
		spec   => {
			N       => 1,
			class   => 1,
			coderef => 0,
		},
		allow_extra => 1,
	);
	my $short_class = delete $params{class};
	my $full_class = substr( $short_class, 0, 1 ) eq '+'
		? substr( $short_class, 1 )
		: "PDL::NDBin::Action::$short_class";
	load_class( $full_class );
	return $full_class->new( %params );
}

sub _make_instance
{
	my %params = validate( @_, {
			action => 1,
			N      => 1,
		} );
	if( ref $params{action} eq 'CODE' ) {
		return _make_instance_hashref(
			class   => '+PDL::NDBin::Action::CodeRef',
			N       => $params{N},
			coderef => $params{action},
		);
	}
	elsif( ref $params{action} eq 'HASH' ) {
		return _make_instance_hashref(
			%{ $params{action} },
			N => $params{N},
		);
	}
	else {
		return _make_instance_hashref(
			class => $params{action},
			N     => $params{N},
		);
	}
}


sub feed
{
	my $self = shift;
	my %pdls = @_;
	while( my( $name, $pdl ) = each %pdls ) {
		for my $v ( $self->axes, $self->vars ) {
			$v->{pdl} = $pdl if $v->{name} eq $name;
		}
	}
}

sub _check_all_pdls_present
{
	my $self = shift;
	my %warned_for;
	for my $v ( $self->axes, $self->vars ) {
		next if defined $v->{pdl};
		next if $v->{action} eq 'Count'; # those variables don't need data
		my $name = $v->{name};
		next if $warned_for{ $name };
		$log->error( "no data for $name" );
		$warned_for{ $name }++;
	}
}

sub _check_pdl_length
{
	my $self = shift;
	# checking whether the lengths of all axes and variables are equal can
	# only be done here (in a loop), and not in autoscale_axis()
	my $length;
	for my $v ( $self->axes, $self->vars ) {
		$length = $v->{pdl}->nelem unless defined $length;
		# variables don't always need a pdl, or may be happy with a
		# null pdl; let the action figure it out.
		# note that the test isempty() is not a good test for null
		# pdls, but until I have a better one, this will have to do
		next if $v->{action} && ( ! defined $v->{pdl} || $v->{pdl}->isempty );
		if( $v->{pdl}->nelem != $length ) {
			croak( join '', 'number of elements (',
				$v->{pdl}->nelem, ") of '$v->{name}'",
				" is different from previous ($length)" );
		}
	}
}


sub autoscale_axis
{
	my $axis = shift;
	# return early if step, min, and n have already been calculated
	if( defined $axis->{step} && defined $axis->{min} && defined $axis->{n} ) {
		$log->tracef( 'step, min, n already calculated for %s; not recalculating', $axis );
		return;
	}
	# first get & sanify the arguments
	croak( 'need coordinates' ) unless defined $axis->{pdl};
	# return if axis is empty
	if( $axis->{pdl}->isempty ) {
		$axis->{n} = 0;
		return;
	}

	# return early if a grid has been supplied
	if( defined $axis->{grid} ) {

	        $axis->{grid} = PDL::Core::topdl( $axis->{grid} );
	        croak( "grid supplied for %s must be one-dimensional with at least two elements", $axis )
		  if $axis->{grid}->nelem < 2 || $axis->{grid}->ndims > 1;
		_validate_grid( $axis->{grid} );
		# number of bins is one less than number of bin edges
		$axis->{n} = $axis->{grid}->nelem - 1;
		$log->tracef( 'grid supplied for %s; no need to autoscale', $axis );
		return;
	}


	$axis->{min} = $axis->{pdl}->min unless defined $axis->{min};


	$axis->{max} = $axis->{pdl}->max unless defined $axis->{max};
	if( defined $axis->{round} and $axis->{round} > 0 ) {
		$axis->{min} = nlowmult( $axis->{round}, $axis->{min} );
		$axis->{max} = nhimult(  $axis->{round}, $axis->{max} );
	}
	croak( 'max < min is invalid' ) if $axis->{max} < $axis->{min};
	if( $axis->{pdl}->type >= PDL::float ) {
		croak( 'cannot bin with min = max' ) if $axis->{min} == $axis->{max};
	}
	# calculate the range
	# for floating-point data, we need to augment the range by 1 unit - see
	# the discussion under IMPLEMENTATION NOTES for more details
	my $range = $axis->{max} - $axis->{min};
	if( $axis->{pdl}->type < PDL::float ) {
		$range += 1;
	}
	# if step size has been supplied by user, check it
	if( defined $axis->{step} ) {
		croak( 'step size must be > 0' ) unless $axis->{step} > 0;
		if( $axis->{pdl}->type < PDL::float && $axis->{step} < 1 ) {
			croak( "step size = $axis->{step} < 1 is not allowed when binning integral data" );
		}
	}
	# number of bins I<n>
	if( defined $axis->{n} ) {
		croak( 'number of bins must be > 0' ) unless $axis->{n} > 0;
		croak( 'number of bins must be integral' ) if ceil( $axis->{n} ) - $axis->{n} > 0;
	}
	else {
		if( defined $axis->{step} ) {
			# data range and step size were verified above,
			# so the result of this calculation is
			# guaranteed to be > 0
			$axis->{n} = ceil( $range / $axis->{step} );
		}
		else {
			# if neither number of bins nor step size is defined,
			# use some reasonable default (which used to be the
			# behaviour of hist() in versions of PDL inferior to
			# 2.4.12) (see F<Basic.pm>)
			$axis->{n} = $axis->{pdl}->nelem > 100 ? 100 : $axis->{pdl}->nelem;
		}
	}
	# step size I<step>
	# if we get here, the data range is certain to be larger than
	# zero, and I<n> is sure to be defined and valid (either
	# because it was supplied explicitly and verified to be valid,
	# or because it was calculated automatically)
	if( ! defined $axis->{step} ) {
		# result of this calculation is guaranteed to be > 0
		$axis->{step} = $range / $axis->{n};
		if( $axis->{pdl}->type < PDL::float ) {
			croak( 'there are more bins than distinct values' ) if $axis->{step} < 1;
		}
	}
}


sub autoscale
{
	my $self = shift;
	$self->feed( @_ );
	$self->_check_all_pdls_present;
	$self->_check_pdl_length;
	autoscale_axis( $_ ) for $self->axes;
}


sub labels
{
	my $self = shift;
	$self->autoscale( @_ );
	my @list = map {
		my $axis = $_;

		if ( defined $axis->{grid} ) {

		     [ map {
			      { range => [ $axis->{grid}->at($_), $axis->{grid}->at($_+1) ] }
		           } 0..$axis->{grid}->nelem -2
		     ]

		}

		else {

			my ( $pdl, $min, $step ) = @{ $axis }{ qw( pdl min step ) };
			[ map {
				{ # anonymous hash
					range => $pdl->type() >= PDL::float()
						? [ $min + $step*$_, $min + $step*($_+1) ]
						: $step > 1
							? [ nhimult( 1, $min + $step*$_ ), nhimult( 1, $min + $step*($_+1) - 1 ) ]
							: $min + $step*$_
				}
			} 0 .. $axis->{n}-1 ];

	    }

	} $self->axes;

	return wantarray ? @list : \@list;
}


sub process
{
	my $self = shift;

	# sanity check
	croak( 'no axes supplied' ) unless @{ $self->axes };
	# default action, when no variables are given, is to produce a histogram
	$self->add_var( name => 'histogram', action => 'Count' ) unless @{ $self->vars };

	#
	$self->autoscale( @_ );

	# process axes
	my $idx = 0;		# flattened bin number
	my @n;			# number of bins in each direction
	# find the last axis and flatten all axes into one dimension, working
	# our way backwards from the last to the first axis
	for my $axis ( reverse $self->axes ) {
	        if ( $log->is_debug ) {
		    $log->debug( 'input (' . $axis->{pdl}->info . ') = ' . $axis->{pdl} );
		    if ( ! defined $axis->{grid} ) {
			$log->debug( "bin with parameters step=$axis->{step}, min=$axis->{min}, n=$axis->{n}" );
		    }
		    else {
			$log->debug( "bin with parameters grid=$axis->{grid}" );
		    }
		}
		croak( 'I cannot bin unless n > 0' ) unless $axis->{n} > 0;
		unshift @n, $axis->{n};			# remember that we are working backwards!
		if ( defined $axis->{grid} ) {
		    $idx = $axis->{pdl}->_flatten_into_grid( $idx, $axis->{grid} );
		}
		else {
		    $idx = $axis->{pdl}->_flatten_into( $idx, $axis->{step}, $axis->{min}, $axis->{n} );
		}
	}
	$log->debug( 'idx (' . $idx->info . ') = ' . $idx ) if $log->is_debug;
	$self->{n} = \@n;

	my $N = reduce { $a * $b } @n; # total number of bins
	croak( 'I need at least one bin' ) unless $N;
	my @vars = map $_->{pdl}, $self->vars;
	$self->{instances} ||= [ map { _make_instance( N => $N, action => $_->{action} ) } $self->vars ];

	#
	{
		local $Data::Dumper::Terse = 1;
		$log->trace( 'process: $self = ' . Dumper $self );
	}

	# now visit all the bins
	my $iter = PDL::NDBin::Iterator->new( bins => \@n, array => \@vars, idx => $idx );
	$log->debug( 'iterator object created: ' . Dumper $iter );
	while( $iter->advance ) {
		my $i = $iter->var;
		$self->{instances}->[ $i ]->process( $iter );
	}

	return $self;
}


sub output
{
	my $self = shift;
	return unless defined wantarray;
	unless( defined $self->{result} ) {
		# reshape output
		my $n = $self->{n};
		my @output = map { $_->result } @{ $self->{instances} };
		for my $pdl ( @output ) { $pdl->reshape( @$n ) }
		if( $log->is_debug ) { $log->debug( 'output: output (' . $_->info . ') = ' . $_ ) for @output }
		$self->{result} = { pairwise { $a->{name} => $b } @{ $self->vars }, @output };
		if( $log->is_debug ) { $log->debug( 'output: result = ' . Dumper $self->{result} ) }
	}
	return wantarray ? %{ $self->{result} } : $self->{result};
}


sub _consume (&\@)
{
	my ( $f, $list ) = @_;
	for my $i ( 0 .. $#$list ) {
		local *_ = \$list->[$i];
		if( not $f->() ) { return splice @$list, 0, $i }
	}
	# If we get here, either the list is empty, or all values in the list
	# meet the condition. In either case, splicing the entire list does
	# what we want.
	return splice @$list;
}

sub _expand_axes
{
	my ( @out, $hash, @num );
	while( @_ ) {
		if( eval { $_[0]->isa('PDL') } ) {
			# a new axis; push the existing one on the output list
			push @out, $hash if $hash;
			$hash = { pdl => shift };
		}
		elsif( ref $_[0] eq 'HASH' ) {
			# the user has supplied a hash directly, which may or
			# may not yet contain a key-value pair pdl => $pdl
			$hash = { } unless $hash;
			push @out, { %$hash, %{ +shift } };
			undef $hash; # do not collapse consecutive hashes into one, too confusing
		}
		elsif( @num = _consume { /^[-+]?(\d+(\.\d*)?|\.\d+)([Ee][-+]?\d+)?$/ } @_ ) {
			croak( 'no axis given' ) unless $hash;
			croak( "too many arguments to axis in `@num'" ) if @num > 3;
			# a series of floating-point numbers
			$hash->{min}  = $num[0] if @num > 0;
			$hash->{max}  = $num[1] if @num > 1;
			$hash->{step} = $num[2] if @num > 2;
		}
		#elsif( @num = ( $_[0] =~ m{^((?:\d+(?:\.\d*)?|\.\d+)(?:[Ee][-+]?\d+)?/)+$}g ) and shift ) {
		#	DOES NOT WORK YET - TODO
		#	print "GMT-style axis spec found! (@num)\n";
		#	croak( 'no axis given' ) unless $hash;
		#	croak( "too many arguments to axis in `@num'" ) if @num > 3;
		#	# a string specification of the form 'min/max/step', a la GMT
		#	$hash->{min}  = $num[0] if @num > 0;
		#	$hash->{max}  = $num[1] if @num > 1;
		#	$hash->{step} = $num[2] if @num > 2;
		#}
		else {
			croak( "while expanding axes: invalid argument at `@_'" );
		}
	}
	push @out, $hash if $hash;
	return @out;
}


sub _random_name { create_uuid( UUID_RANDOM ) }


sub ndbinning
{
	#
	my $binner = __PACKAGE__->new;

	# leading arguments are axes and axis specifications
	#
	# PDL overloads the `eq' and `ne' operators; by checking for a PDL
	# first, we avoid (invalid) comparisons between piddles and strings in
	# the `grep'
	my @leading = _consume { eval { $_->isa('PDL') } || ! $valid_key{ $_ } } @_;

	# consume and process axes
	# axes require three numerical specifications following it
	while( @leading > 3 && eval { $leading[0]->isa('PDL') } && ! grep ref, @leading[ 1 .. 3 ] ) {
		my( $pdl, $step, $min, $n ) = splice @leading, 0, 4;
		$binner->add_axis( name => _random_name, pdl => $pdl, step => $step, min => $min, n => $n );
	}
	if( @leading ) { croak( "error parsing arguments in `@leading'" ) }

	# remaining arguments are key => value pairs
	my $args = { @_ };
	my @invalid_keys = grep ! $valid_key{ $_ }, keys %$args;
	croak( "invalid key(s) @invalid_keys" ) if @invalid_keys;

	# axes
	$args->{axes} ||= [];
	my @axes = @{ $args->{axes} };
	for my $axis ( @axes ) {
		my $pdl = shift @$axis;
		$binner->add_axis( name => _random_name, pdl => $pdl, @$axis );
	}

	# variables
	$args->{vars} ||= [];
	for my $var ( @{ $args->{vars} } ) {
		if( @$var == 2 ) {
			my( $pdl, $action ) = @$var;
			$binner->add_var( name => _random_name, pdl => $pdl, action => $action );
		}
		else { croak( "wrong number of arguments for var: @$var" ) }
	}

	#
	$binner->process;
	my $output = $binner->output;
	my @result = map $output->{ $_->{name} }, @{ $binner->vars };
	return wantarray ? @result : $result[0];
}


sub ndbin
{
	#
	my $binner = __PACKAGE__->new;

	# leading arguments are axes and axis specifications
	#
	# PDL overloads the `eq' and `ne' operators; by checking for a PDL
	# first, we avoid (invalid) comparisons between piddles and strings in
	# the `grep'
	if( my @leading = _consume { eval { $_->isa('PDL') } || ! $valid_key{ $_ } } @_ ) {
		my @axes = _expand_axes( @leading );
		$binner->add_axis( name => _random_name, %$_ ) for @axes;
	}

	# remaining arguments are key => value pairs
	my $args = { @_ };
	my @invalid_keys = grep ! $valid_key{ $_ }, keys %$args;
	croak( "invalid key(s) @invalid_keys" ) if @invalid_keys;

	# axes
	$args->{axes} ||= [];
	my @axes = @{ $args->{axes} };
	for my $axis ( @axes ) {
		my $pdl = shift @$axis;
		$binner->add_axis( name => _random_name, pdl => $pdl, @$axis );
	}

	# variables
	$args->{vars} ||= [];
	for my $var ( @{ $args->{vars} } ) {
		if( @$var == 2 ) {
			my( $pdl, $action ) = @$var;
			$binner->add_var( name => _random_name, pdl => $pdl, action => $action );
		}
		else { croak( "wrong number of arguments for var: @$var" ) }
	}

	$binner->process;
	my $output = $binner->output;
	my @result = map $output->{ $_->{name} }, @{ $binner->vars };
	return wantarray ? @result : $result[0];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PDL::NDBin - Multidimensional binning & histogramming

=head1 VERSION

version 0.018

=head1 SYNOPSIS

	# OBJECT-ORIENTED INTERFACE (PREFERRED INTERFACE)

	# create object
	# e.g, compute average elevation in boxes of 2x2
	# no data required at this point
	my $binner = PDL::NDBin->new(
		axes => [ [ 'x', min => 0, max => 10, step => 2 ],
		          [ 'y', min => 0, max => 10, step => 2 ] ],
		vars => [ [ 'elevation', 'Avg' ] ],
	);
	# or any sort of computation:
	#   elevation => sub { (shift->selection->stats)[2] }   # median
	#   elevation => sub { shift->selection->min }          # minimum
	#   elevation => \&user_defined_function                # anything

	# feed and process data
	my( $x, $y, $z ) = get_data();
	$binner->feed( x => $x, y => $y, elevation => $z );
	$binner->process;

	# or feed and process in one step
	$binner->process( x => $x, y => $y, elevation => $z );

	# output
	my $average_elevation = $binner->output->{ elevation };

	# or as a hash
	my %results = $binner->output;
	print $results{ elevation }, "\n";

	# WRAPPER FUNCTIONS

	# bin the values
	#    pdl( 1,1,2 )
	# in 3 bins with a width of 1, starting at 0:
	my $histogram = ndbinning( pdl( 1,1,2 ), 1, 0, 3 );
	# returns the one-dimensional histogram
	#    indx( 0,2,1 )

	# bin the values
	$x = pdl( 1,1,1,2,2 );
	$y = pdl( 2,1,1,1,1 );
	# along two dimensions, with 3 bins per dimension:
	my $histogram = ndbinning( $x => (1,0,3),
	                           $y => (1,0,3) );
	# returns the two-dimensional histogram
	#    indx( [0,0,0],
	#          [0,2,2],
	#          [0,1,0] )

=head1 DESCRIPTION

In scientific (and other) applications, it is frequently necessary to classify
a series of values in a number of bins. For instance, particles may be
classified according to particle size in a number of bins of, say, 0.01 mm
wide, yielding a histogram. Or, to take an example from my own work: satellite
measurements taken all over the globe must often be classified in
latitude/longitude boxes for further processing.

L<PDL> has a dedicated function to make histograms, hist(). To create a
histogram of particle size from 0 mm to 10 mm, in bins of 0.1 mm, you would
write:

	my $histogram = hist $particles, 0, 10, 0.1;

This will count the number of particles in every bin, yielding the 100 counts
that form the histogram. But what if you wanted to perform other computations
on the values in the bins? It is actually not that difficult to perform the
binning by hand. The key is to associate a bin number with every data value.
With fixed-size bins of 0.1 mm wide, that is accomplished with

	my $bin_numbers = PDL::indx( $particles/0.1 );

(Note that the formulation above does not take care of data beyond 10 mm, but
PDL::NDBin does.) We now have two arrays of data: the actual particle sizes in
$particles, and the bin numbers associated with every data value in
$bin_numbers. The histogram could now be produced with the following loop, $N
being 100:

	my $histogram = zeroes( indx, $N );
	for my $bin ( 0 .. $N-1 ) {
		my $want = which( $bin_numbers == $bin );
		$histogram->set( $bin, $want->nelem );
	}

But, once we have the indices of the data values corresponding to any bin, it
is a small matter to extend the loop to actually extract the data values in the
bin. A user-supplied subroutine can then be invoked on the values in every bin:

	my $output = zeroes( indx, $N )->setbadif( 1 );
	for my $bin ( 0 .. $N-1 ) {
		my $want = which( $bin_numbers == $bin );
		my $selection = $particles->index( $want );
		my $value = eval { $coderef->( $selection ) };
		if( defined $value ) { $output->set( $bin, $value ) }
	}

(This is how early versions of PDL::NDBin were implemented.) The user
subroutine could do anything with the values in the currently selected bin,
$selection, including counting the number of elements. But the subroutine could
also output the data to disk, or to a plot. Or the data could be collected to
perform a regression. Anything that can be expressed with a subroutine, can now
easily be plugged into this core loop.

This basic idea can even be extended by noticing that it is also possible to do
multidimensional binning with the same core loop. The solution is to 'flatten'
the bins, much like C and Perl flatten multidimensional arrays to a
one-dimensional array in memory. So, you could perfectly bin satellite data
along both latitude and longitude:

	my( $latitude, $longitude ); # somehow get these data as 1-D vars
	my $flattened = 0;
	for my $var ( $latitude, $longitude ) {
		my $bin_numbers = indx( ($var - $min)/$step );
		$bin_numbers->inplace->clip( 0, $n-1 );
		$flattened = $flattened * $n + $bin_numbers;
	}

$flattened now contains pseudo-one-dimensional bin numbers, and can be used
in the core loop shown above.

I've left out many details to illustrate the idea. The basic idea is very
simple, but the implementation does get a bit messy when multiple variables are
binned in multiple dimensions, with user-defined actions. Of course, ideally,
you'd like this to be very performant, so you can handle several millions of
data values without hitting memory constraints or running out of time.
PDL::NDBin is there to handle the details for you, so you can write

	my $average_flux = ndbin( $longitude, min => -70, max => 70, step => 20,
	                          $latitude,  min => -70, max => 70, step => 20,
	                          vars => [ [ $flux => 'Avg' ] ] );

to obtain the average of the flux, binned in boxes of 20x20 degrees latitude
and longitude.

The rest of the documentation goes into more detail on the methods and
implementation. You may also want to check out the examples (see L<EXAMPLES>),
or the comparison of PDL::NDBin with alternative solutions on CPAN (see L<SEE
ALSO> and further).

Please note that, although I do not anticipate major API changes, the interface
and implementation are subject to change.

=head1 64-BIT SUPPORT

PDL::NDBin will now install fine on recent PDL versions (2.007 or later) with
64-bit support. However, 64-bit support has not been tested very well (yet).

Note that PDL::NDBin should continue to work with earlier versions of PDL. In
that case, the I<indx> type does not exist, and you should mentally replace it
with I<long> in the documentation.

=head1 METHODS

=head2 add_axis()

Add an axis to the current object, with optional axis specifications. The
argument list must be a list of key-value pairs. The name of the axis is
mandatory.

	$self->add_axis( name => 'longitude', min => -70, max => 70, n => 14 );

Axes may be binned either on a uniformly spaced grid or on a user-provided grid.
If no specifications are given, data will be binned on a uniformly spaced grid
automatically derived from the data.

Uniformly spaced grids are specified via a subset of the C<min>,
C<max>, C<step>, C<n>, and C<round> parameters, while the user
provided grid is specified via the C<grid> parameter. Only specify the
subset of parameters which exactly determines the grid.  For example:

  min max n
  min step n
  max step n
  step n round
  grid

The following axis specifications are available:

=over 4

=item name

The name of this axis.

=item min

The lowest value of the first bin. Values below this minimum will be binned in
the first bin. Optional; will be determined from the actual minimum value in
the data if not supplied.

=item max

The highest value of the last bin. Values above this maximum will be binned in
the last bin. Optional; will be determined from the actual maximum value in the
data if not supplied.

=item step

The width of the bins. Currently only a fixed step size is allowed, which means
that all the bins have equal width. Optional; will be determined from the data
range and the number of bins if not supplied.

=item n

The number of bins. Optional; will be determined from the data range and the
step size if not supplied. If the step size is not supplied, I<n> will be set
to the number of data values, or to 100, whichever is smaller.

=item round

Round I<min> and I<max> to the nearest multiple of this value.

=item grid

Either a piddle or a reference to an array containing the values of the
bin I<boundaries>.  The first and lest elements specify the minimum
and maximum bin values, while the intermediate elements specify the common
boundaries.  A bin is I<inclusive> of its lower bound
and I<exclusive> of its upper bound. For example, the following set of
bins

  0 <= v < 1
  1 <= v < 3
  3 <= v < 9

is represented via

  grid => [ 0, 1, 3, 9 ]

=back

=head2 add_var()

Add a variable to the current object. The argument list must be a list of
key-value pairs. The name of the variable and the action are both mandatory.

	$self->add_var( name => 'flux', action => 'Avg' );

The following variable specifications are available:

=over 4

=item name

The name of this variable.

=item action

The action to perform on this variable. May be either a code reference (a
reference to a named or anonymous subroutine), a class name, or a hash
reference. (See I<Actions> under L<IMPLEMENTATION NOTES> for more details.)

=back

The action classes that are available as of PDL::NDBin v0.011 are:

=over 4

=item *

L<PDL::NDBin::Action::Avg>

=item *

L<PDL::NDBin::Action::Count>

=item *

L<PDL::NDBin::Action::Max>

=item *

L<PDL::NDBin::Action::Min>

=item *

L<PDL::NDBin::Action::StdDev>

=item *

L<PDL::NDBin::Action::Sum>

=back

They provide optimized implementations, coded in C, for the corresponding
operations. The class names may be abbreviated to the part after the last
C<::>.

=head2 new()

Construct a PDL::NDBin object. The argument list must be a list of key-value
pairs. No arguments are required, but you will want to add at least one axis
eventually to do meaningful work.

	my $obj = PDL::NDBin->new( axes => [ [ 'x', min => -1, max => 1, step => .1 ],
	                                     [ 'y', min => -1, max => 1, step => .1 ] ],
	                           vars => [ [ 'F', 'Count' ] ] );

The accepted keys are the following:

=over 4

=item C<axes>

Specifies the axes along which to bin. The axes are supplied as an arrayref
containing anonymous arrays, one per axis, as follows:

	axes => [
	          [ $name1, $key11 => $value11, $key12 => $value12, ... ],
	          [ $name2, $key21 => $value21, $key22 => $value22, ... ],
	          ...
	        ]

Only the name is required. All other specifications are optional and will be
determined automatically as required. For a list of allowed axis
specifications, consult add_axis(). Note that you cannot specify all
specifications at the same time, because some may conflict.

At least one axis will eventually be required, although it needn't be specified
at constructor time, and can be added later with add_axis(), if desired.

=item C<vars>

Specifies the values to bin. The variables are supplied as an arrayref
containing anonymous arrays, one per variable, as follows:

	vars => [
	          [ $name1 => $action1 ],
	          [ $name2 => $action2 ],
	          ...
	        ]

Here, both the name and the action are required. In order to produce a
histogram, supply C<'Count'> as the action.

No variables are required (an I<n>-dimensional histogram is produced if no
variables are supplied), but they can be specified at constructor time, or at a
later time with add_var() if desired.

=back

=head2 axes()

Retrieve the axes. Returns a list in list context, and an array reference in
scalar context.

=head2 vars()

Retrieve the variables. Returns a list in list context, and an array reference
in scalar context.

=head2 feed()

Set the piddles that will eventually be used for the axes and variables.
Arguments must be specified as key-value pairs, the keys being the name, and
the values being the piddle for every piddle that is to be set.

	$binner->feed( latitude => $latitude, longitude => $longitude );

Note that not all piddles need be set in one call. This function can be called
repeatedly to set all piddles. This can be very useful when data must be read
from disk, as in the following example (assuming $nc is an object that reads
data from disk):

	my $binner = PDL::NDBin->new( axes => [ [ x => ... ], [ y => ... ] ] );
	for my $f ( 'x', 'y' ) { $binner->feed( $f => $nc->get( $f ) ) }
	$binner->process;

=head2 autoscale_axis()

Determine the following parameters for one axis automatically, if they have not
been supplied by the user: the step size, the lowest bin, and the number of
bins. Use whatever combination is needed of the specifications that have been
supplied by the user, and the data itself. Obviously, the piddles containing
the data must have been set before calling this subroutine. Details of the
automatic parameter calculation are given in the section on L<IMPLEMENTATION
NOTES> below.

It is not usually required to call this method, as it is called automatically
by autoscale().

=for comment # allow options the way histogram() and histogram2d() do, but
	# warn if a maximum has been given, because it is not possible
	# to honour four constraints
	if( defined $axis->{step} && defined $axis->{min} && defined $axis->{n} ) {
		if( defined $axis->{max} ) {
			my $warning = join '',
				'step size, minimum value and number of bins are given; ',
				'the given maximum value will be ignored';
			if( $axis->{pdl}->type < PDL::float ) {
				if( $axis->{max} != $axis->{min} + $axis->{n} * $axis->{step} - 1 ) {
					carp $warning;
				}
			}
			else {
				if( $axis->{max} != $axis->{min} + $axis->{n} * $axis->{step} ) {
					carp $warning;
				}
			}
		}
	}

=head2 autoscale()

Determine the following parameters for all axes automatically, if they have not
been supplied by the user: the step size, the lowest bin, and the number of
bins. It will use whatever combination is needed of the specifications that
have been supplied by the user, and the data itself. Obviously, the piddles
containing the data must have been set before calling this subroutine. For more
details on the autoscaling, consult autoscale_axis().

	$binner->autoscale( x => $x, y => $y, z => $z );

autoscale() accepts, but does not require, arguments. They must be key-value
pairs as for feed(), and indicate piddle data that must be fed into the object
prior to autoscaling. Note that the autoscaling applies to all axes, and not
only supplied as arguments.

It is not usually required to call this method, as it is called automatically
by process().

=head2 labels()

Return the labels for the bins as a list of lists of ranges.

=head2 process()

The core method. The actual piddles to be used for the axes and variables can
be supplied to this function, although the argument list can be empty if all
piddles have already been supplied. The argument list is the same as the one of
feed(), i.e., a list of key-value pairs specifying name and piddle.

	# if all piddles have already been set with feed()
	$binner->process();

process() returns $self for chained method calls.

=head2 output()

Return the output computed by the previous call(s) to process(). Each output
variable is reshaped to make the number of dimensions equal to the number of
axes, and the extent of each dimension equal to the number of bins along the
axis.

The return value in list context is a hash, the keys and values of which
correspond to the names and data of the variables. The return value in scalar
context is a reference to this hash. When no variables have been supplied, a
hash with a single key called I<histogram> is returned.

	my $result = $binner->output;
	print $result->{average};

Note that it is not possible to call process() after having called output(),
because the piddle data may have been reshaped.

=head2 _consume()

	_consume BLOCK LIST

Shift and return (zero or more) leading items from I<LIST> meeting the
condition in I<BLOCK>. Sets C<$_> for each item of I<LIST> in turn.

For internal use.

=head2 _random_name()

Generate a random, hopefully unique name for a pdl.

For internal use.

=head1 WRAPPER FUNCTIONS

PDL::NDBin provides the two functions ndbinning() and ndbin(), which are
(almost) drop-in replacements for histogram() and hist(), except that they
handle an arbitrary number of dimensions.

ndbinning() and ndbin() are actually wrappers around the object-oriented
interface of PDL::NDBin, and may be the most convenient way to work with
PDL::NDBin for simple cases. For more advanced usage, the object-oriented
interface may be required.

=head2 ndbinning()

Calculate an I<n>-dimensional histogram from one or more piddles. The
arguments must be specified (almost) like in histogram() and histogram2d().
That is, each axis must be followed by its three specifications I<step>, I<min>
and I<n>, being the step size, the minimum value, and the number of bins,
respectively. The difference with histogram2d() is that the axis specifications
follow the piddle immediately, instead of coming at the end.

	my $hist = ndbinning( $pdl1, $step1, $min1, $n1,
	                      $pdl2, $step2, $min2, $n2,
	                      ... );

Variables may be added using the same syntax as the constructor new():

	my $hist = ndbinning( $pdl1, ...,
	                      vars => [ [ $var1, $action1 ],
	                                [ $var2, $action2 ],
	                                ... ] );

If no variables are supplied, the behaviour of histogram() and histogram2d() is
emulated, i.e., an I<n>-dimensional histogram is produced. This function,
although more flexible than the former two, is likely slower. If all you need
is a one- or two-dimensional histogram, use histogram() and histogram2d()
instead. Note that, when no variables are supplied, the returned histogram is
of type I<indx> (or I<long> if your PDL doesn't have 64-bit support), in
contrast with histogram() and histogram2d(). The histogramming is achieved by
passing an action which simply counts the number of elements in the bin.

Unlike the output of output(), the resulting piddles are output as an array
reference, in the same order as the variables passed in. There are as many
output piddles as variables, and exactly one output piddle if no variables have
been supplied. The output piddles take the type of the variables. All values in
the output piddles are initialized to the bad value, so missing bins can be
distinguished from zero.

=head2 ndbin()

Calculate an I<n>-dimensional histogram from one or more piddles. The
arguments must be specified like in hist(). That is, each axis may be followed
by at most three specifications I<min>, I<max>, and I<step>, being the the
minimum value, maximum value, and the step size, respectively.

	my $hist = ndbin( $pdl1, $min1, $max1, $step1,
	                  $pdl2, $min2, $max2, $step2,
	                  ... );

Note that $min, $max, and $step may be omitted, and will be calculated
automatically from the data, as in hist(). Variables may be added using the
same syntax as the constructor new():

	my $hist = ndbin( $pdl1, ...,
	                  vars => [ [ $var1, $action1 ],
	                            [ $var2, $action2 ],
	                            ... ] );

If no variables are supplied, the behaviour of hist() is emulated, i.e., an
I<n>-dimensional histogram is produced. This function, although more flexible
than the other, is likely slower. If all you need is a one-dimensional
histogram, use hist() instead. Note that, when no variables are supplied, the
returned histogram is of type I<indx> (or I<long> if your PDL doesn't have
64-bit support), in contrast with hist(). The histogramming is achieved by
passing an action which simply counts the number of elements in the bin.

Unlike the output of output(), the resulting piddles are output as an array
reference, in the same order as the variables passed in. There are as many
output piddles as variables, and exactly one output piddle if no variables have
been supplied. The output piddles take the type of the variables. All values in
the output piddles are initialized to the bad value, so missing bins can be
distinguished from zero.

=head1 EXAMPLES

A few examples are included with this distribution, in the directory
F<examples/>.

=head2 Histogram and stem-and-leaf plot

The basic usage of PDL::NDBin is illustrated below by constructing a histogram.
Suppose we have a data table as follows (only the first 8 lines of data are
shown):

	# Prestige  Income  Education  Occupation
	97          76      97         Physician
	93          64      93         Professor
	92          78      82         Banker
	90          75      92         Architect
	90          64      86         Chemist
	90          80      100        Dentist
	89          76      98         Lawyer
	88          72      86         Civil engineer
	...

(The table is also included in the example files, and is taken from John Fox,
Applied Regression Analysis, Linear Models, and Related Methods, SAGE
Publications, Inc., 1997). We will now write a script to compute the histogram
of the I<Income> field, in bins of 10 units wide.

	use PDL;
	use PDL::NDBin;

Note that loading PDL::NBBin does not automatically export PDL to your
namespace, so you need to load PDL explicitly.

	my $binner = PDL::NDBin->new( axes => [ [ 'Income', min => 0, max => 100, step => 10 ] ],
	                              vars => [ [ 'Income', 'Count' ] ] );

First we build the object with a call to new(). Note that the same name can be
used in both axes and variables (in this case, I<Income>). I<step> signifies
the width of the bins. By associating the action I<Count> with I<Income>, we
will produce a histogram of the elements in I<Income>. (The action name is
actually the name of a class in the PDL::NDBin::Action namespace.)

	my( $prestige, $income, $education ) = rcols 'table';

Next, we read the data from the data file. The PDL function rcols() is very
convenient to read tabular data of the kind shown above.

	$binner->process( Income => $income );

The data is then 'fed' into the binning object, with a call to process(). Note
that you need to specify the name that was given in the constructor call in
order to associate the numerical data with the axis and variable.

	my %results = $binner->output;
	my $histogram = $results{Income};

We now recover the histogram with output(), which returns a hash with the
results, keyed by name (again the same name as used in the constructor). To
find the number of elements in the bin with 40 <= income < 50, for instance,
you could also use the following L<awk(1)> script:

	$2 >= 40 && $2 < 50 { cnt++ }
	END                 { print cnt }

Of course, for this very simple example, the histogram could as well be
calculated with the following built-in function of PDL:

	my $histogram = hist( $income, 0, 100, 10 );

If you'd rather print a stem-and-leaf plot, you could modify the constructor
call as follows:

	my $binner = PDL::NDBin->new( axes => [ [ 'Income', min => 0, max => 100, step => 10 ] ],
	                              vars => [ [ 'Income', \&stem_and_leaf_plot ] ] );

Now the action associated with $income is no longer I<Count> (which counts
the elements in each bin), but a reference to the user-supplied subroutine
stem_and_leaf_plot(). The latter could be implemented as shown below.

	sub stem_and_leaf_plot
	{
		my $iter = shift;
		my $bin  = $iter->bin;
		my @list = map { $_ % 10 } sort $iter->selection->list;
		printf "%d | %s\n", $bin, join '', @list;
	}

The only argument supplied to our callback stem_and_leaf_plot() is an object of
the type L<PDL::NDBin::Iterator>. This object is used to iterate over the bins
of the variable ($income). With the method bin(), we can recover the current
bin number. With selection(), we recover those elements of $income that fall in
the current bin. Those elements are then printed in a neat list (retaining only
the last digit).

To actually produce the stem-and-leaf plot, we still need to call

	$binner->process( Income => $income );

The result is the following neat diagram:

	0 | 77899
	1 | 245667
	2 | 1111299
	3 | 46
	4 | 12224788
	5 | 355
	6 | 02447
	7 | 2256668
	8 | 01
	9 |

Note that it is not necessary to call output(), as we are not interested in the
return value of stem_and_leaf_plot().

=head2 Local averaging of two-dimensional data

This is a slightly more complicated example, where PDL::NDBin is used to
average two-dimensional data in boxes of 1x1. Suppose you have elevation data
of a particular area in the form of (x,y)-located samples:

	# x     y  height
	0.3   6.1   870.0
	1.4   6.2   793.0
	2.4   6.1   755.0
	3.6   6.2   690.0
	5.7   6.2   800.0
	1.6   5.2   800.0
	...

(The data have been taken from Example 14 of the GMT Cookbook. You can find
more information on GMT under L<SEE ALSO>.) Note that the samples are not
distributed uniformly over the area. We want to compute the I<average>
elevation in boxes of 1 by 1, replacing multiple samples in any given box by
the mean of those samples (e.g., prior to computing a surface through these
points). When using the Generic Mapping Tools, you'd do it as follows:

	blockmean table -R0/7/0/7 -I1

How to do this with PDL::NDBin is shown below.

	use PDL;
	use PDL::NDBin;
	my( $x, $y, $z ) = rcols 'table';

As in the first example.

	my $binner = PDL::NDBin->new( axes => [ [ 'x', min=>-0.5, max=>7.5, step=>1 ],
	                                        [ 'y', min=>-0.5, max=>7.5, step=>1 ] ],
	                              vars => [ [ 'x', 'Avg' ],
	                                        [ 'y', 'Avg' ],
	                                        [ 'z', 'Avg' ] ] );

The constructor call specifies two axes for two-dimensional binning, and will
compute the average in each bin of three variables simultaneously: x- and
y-coordinate, and elevation ($z). We need to average the coordinates, as we
want to replace multiple points with a single, average point; that is why I<x>
and I<y> appear in the axes as well as in the variables.

To produce a table with averaged data, proceed (roughly) like in the first
example:

	$binner->process( x => $x, y => $y, z => $z );
	my %results = $binner->output;
	my @avg = map { $_->flat } @results{ qw/x y z/ };
	wcols @avg;

wcols() is the inverse of rcols() and will print out the data in tabular
format.

=head2 Average and standard deviation of sampled satellite data

The next example shows how to deal with large data volumes. Suppose you have
the following data:

	#  longitude        latitude        albedo        flux     windspeed
	-28.5789718628  -17.6553726196  0.0973502323031   84.5   7.1533331871
	-12.5770769119  -20.5219345093  0.094131320715    81     6.69999980927
	-16.9122467041    1.0953686237  0.0729057863355   87.25  6.04666662216
	-16.2659015656  -11.5013151169  0.0838633701205   89     8.14666652679
	  0.3412319422  -27.6491680145  0.151734098792    78.75  6.48000001907
	-32.6132278442   39.7315559387  0.128813564777   104.5   6.19333314896
	-33.4954719543   33.6763381958  0.0628560185432   80     5.28666687012
	 11.4981594086   35.1409721375  0.0674269720912   84.25  5.2266664505
	 ...

The data are actual satellite data obtained with the GERB instrument
(L<http://gerb.oma.be>). The data are located by longitude, latitude, and the
task at hand is to assign each sample to boxes of I<m> degrees longitude by
I<n> degrees latitude, and then to average all samples belonging to any given
box, as well as computing the standard deviation. An example of this kind of
binning in Python is shown
L<here|http://www.scipy.org/Cookbook/Matplotlib/Gridding_irregularly_spaced_data>.
In L<awk(1)>, you could compute the average flux in the box bounded by -60 <
longitude < -20 and -60 < latitude < -20 as follows:

	$1 > -60 && $1 < -20 && $2 > -60 && $2 < -20 { sum += $4; cnt++ }
	END { print sum/cnt }

For the purpose of this example, the data sets have been stripped down very
much, and the number of lat/lon boxes has been reduced greatly. A variant of
this script is used to bin and average the samples for a complete month of
data, totalling around 4GB of input data and more than 60 million samples.

The constructor call is

	my $binner = PDL::NDBin->new( axes => [ [ longitude => min => -60, max => 60, step => 40 ],
	                                        [ latitude  => min => -60, max => 60, step => 40 ] ],
	                              vars => [ [ avg    => 'Avg'    ],
	                                        [ stddev => 'StdDev' ],
	                                        [ count  => 'Count'  ] ] );

In an application, a large volume of data would likely be spread over multiple
data files. Suppose that the data are distributed over a number of F<.txt>
files (in a real application, a binary format would be preferred over plain
text). The following loop then processes all files without loading the entire
data volume into memory:

	for my $file ( glob '??.txt' ) {
		my( $longitude, $latitude, $albedo, $flux, $windspeed ) = rcols $file;
		$binner->process( longitude => $longitude,
		                  latitude  => $latitude,
		                  avg       => $flux,
		                  stddev    => $flux,
		                  count     => $flux );
	}

Note how the data are read from disk and immediately processed. After the call
to process(), the data are no longer required, and can be discarded! The
actions I<Avg>, I<StdDev> and I<Count> (and also I<Sum> which is not shown in
this example) keep an internal state which allows them to 'chain' multiple
calls to process(). Note how the same variable $flux is fed three times to
three different actions in order to obtain its average, standard deviation, and
count, respectively.

The results are recovered as usual with

	my %results = $binner->output;
	print "Average flux:\n", $results{avg}, "\n";
	print "Standard deviation of flux:\n", $results{stddev}, "\n";
	print "Number of observations per bin:\n", $results{count}, "\n";

Another point to note in this example is that the optimized action classes
I<Avg> (and similar) are required for performance when processing large volumes
of data. The average could in principle also be computed with a coderef:

	avg => sub { shift->selection->avg }

Although the result will be the same, the computation will be much slower,
since the call to selection() is very time-consuming.

=head1 IMPLEMENTATION NOTES

=head2 Lowest and highest bin

All data equal to or less than the minimum (either supplied or automatically
determined) will be binned in the lowest bin. All data equal to or larger than
the maximum (either supplied or automatically determined) will be binned in the
highest bin. This is a slight asymmetry, as all other bins contain their lower
bound but not their upper bound. However, it does the right thing when binning
floating-point data.

=head2 Flattening multidimensional bin numbers

In PDL, the first dimension is the contiguous dimension, so we have to work
back from the last axis to the first when building the flattened bin number.

Here are some examples of flattening multidimensional bins into one dimension:

	(i) = i
	(i,j) = j*I + i
	(i,j,k) = (k*J + j)*I + i = k*J*I + j*I + i
	(i,j,k,l) = ((l*K + k)*J + j)*I + i = l*K*J*I + k*J*I + j*I + i

=head2 Actions

You are required to supply an action with every variable. An action can be a
code reference (i.e., a reference to a subroutine, or an anonymous subroutine),
the name of a class that implements the methods new(), process() and result(),
or a hash reference.

The actions will be called in the order they are given for each bin, before
proceeding to the next bin. You can depend on this behaviour, for instance,
when you have an action that depends on the result of a previous action within
the same bin.

=head3 Code reference

In case the action specifies a code reference, this subroutine will be called
with the following argument:

	$coderef->( $iterator )

$iterator is an object of the class PDL::NDBin::Iterator, which will have been
instantiated for you. Important to note is that the action will be called for
every bin, with the given variable. The iterator must be used to retrieve
information about the current bin and variable. With $iterator->selection(),
for instance, you can access the elements that belong to this variable and this
bin.

=head3 Class name

In case the action specifies a class name, an object of the class will be
instantiated with

	$object = $class->new( $N )

where $N signifies the total number of bins. The variables will be processed by
calling

	$object->process( $iterator )

where $iterator again signifies an iterator object. Results will be collected
by calling

	$object->result

The object is responsible for correct bin traversal, and for storing the result
of the operation. The class must implement the three methods.

When supplying a class instead of an action reference, it is possible to
compute multiple bins at once in one call to process(). This can be much more
efficient than calling the action for every bin, especially if the loop can be
coded in XS.

=head3 Hash reference

Specifying a hash reference is the same as specifying a class name, except that
it allows you to pass additional parameters to the action class constructor.
For instance, the specification

	variable => { class => 'Avg', type => float }

is almost the same as

	variable => 'Avg',

but with the type of the output piddle set to I<float>. This specification will
be translated to the following constructor call:

	PDL::NDBin::Action::Avg->new( N => $N, type => float )

=head3 Exceptions in actions

There is no protection from exceptions raised in actions, i.e., exceptions in
actions will be propagated to the package that calls PDL::NDBin. This feature
protects you from typos inside the action:

	my $binner = PDL::NDBin->new(
		axes => [ ... ],
		vars => [ [ variable => sub { shift->selection->avearge } ] ]
	);

In this example, average() is misspelled. If the action were executed in an
C<eval> block, the typo would go unnoticed, and all values of the output piddle
would be undefined. If you want to trap exceptions in actions, use a wrapper
action defined as follows:

	variable => sub {
		my $iter = shift;
		eval { $your_action->( $iter ) };
	}

=head2 Iteration strategy

By default, ndbin() will loop over all bins, and create a piddle per bin
holding only the values in that bin. This piddle is accessible to your actions
via the iterator object. This ensures that every action will only see the data
in one bin at a time. You need to do this when, e.g., you are taking the
average of the values in a bin with the standard PDL function avg(). However,
the selection and extraction of the data is time-consuming. If you have an
action that knows how to deal with indirection, you can do away with the
selection and extraction. Examples of such actions are:
PDL::NDBin::Action::Count, PDL::NDBin::Action::Sum, etc. They take the original
data and the flattened bin numbers and produce an output piddle in one step.

Note that empty bins are not skipped. If you want to use an action that cannot
handle empty piddles (e.g., PDL method min()), you can wrap the action as
follows to skip empty bins:

	variable => sub {
		my $iter = shift;
		return unless $iter->want->nelem;
		$your_action->( $iter );
	}

Remember that returning I<undef> from the action will not fill the current bin.
Note that the evaluation of C<< $iter->want >> entails a performance penalty,
even if the bin is empty and not processed further.

=head2 Automatic axis parameter calculation

(Note that if the user defines a binning scheme via the C<grid>
parameter, no axis parameter calculations are performed.)

=head3 Range

The range, when not given explicitly, is calculated from the data by calling
min() and max() on the data. An exception will be thrown if the data range is
zero. autoscale_axis() honours the I<round> key to round bin boundaries to the
nearest multiple of I<round>.

=head3 Number of bins

The number of bins I<n>, when not given explicitly, is determined
automatically. If the step size is defined and positive, the number of bins is
calculated from the range and the step size as discussed below. If neither the
number of bins, nor the step size have been supplied by the user, the number of
bins is taken equal to the number of data values, or equal to 100, whichever is
smaller.

The calculation of the number of bins is based on the formula

	n = range / step

but needs to be modified. First, I<n> calculated in this way may well be
fractional. When I<n> is ultimately used in the binning, it is converted to
integral type by truncating. To have sufficient bins, I<n> must be rounded up
to the next integer. Second, the computation of I<n> is and should be different
for floating-point data and integral data.

For floating-point data, I<n> is calculated as follows:

	n = ceil( range / step )

The calculation is slightly different for integral data. When binning an
integral number, say 4, it really belongs in a bin that spans the range 4
through 4.99...; to bin a list of data values with, say, I<min> = 3 and I<max>
= 8, we must consider the range to be 9-3 = 6. A step size of 3 would yield 2
bins, one containing the values (3, 4, 5), and another containing the values
(6, 7, 8). The correct formula for calculating the number of bins for integral
data is therefore

	n = ceil( (range+1) / step )

The modified formula for integral data values leads to more natural results, as
the following example shows:

	my $data = short( 1, 2, 3, 4 );
	my( $min, $max, $step ) = ( 1, 4, 1 );

	print ndbin( $data, $min, $max, $step );
	# prints [1 1 1 1], as expected

	print scalar hist( $data, $min, $max, $step );
	# prints [1 1 2] at the time of writing (PDL v2.4.11)

=head3 Step size

The step size, when not given explicitly, is determined from the range and the
number of bins I<n> as follows:

	step = range / n

for floating-point data, and

	step = (range+1) / n

for integral data.

The step size may have a fractional part, even for integral data. The step size
must not be less than one, however. If this happens, there are more bins than
distinct numbers in the data, and the function will abort.

Note that when the number of I<n> is not given either, a default value is
substituted for it by PDL::NDBin, as described above.

=head1 TIPS & TRICKS

=head2 Find the total number of bins

	use List::Util 'reduce';
	my $binner = PDL::NDBin->new( axes => [ [ 'x', ... ], [ 'y', ... ] ] );
	$binner->autoscale( x => $x, y => $y );
	my $N = reduce { our $a * our $b } map { $_->{n} } $binner->axes;

=head2 Hook a progress bar to PDL::NDBin

For long-running computations, you may want to hook a progress bar to
PDL::NDBin. There is an example in the F<examples/> directory, but here is the
gist:

	use List::Util 'reduce';
	use Term::ProgressBar::Simple;

	my $progress;
	my $binner = PDL::NDBin->new(
		axes => [ [ 'x', ... ], [ 'y', ... ] ],
		vars => [ ...,
		          [ 'dummy' => sub { $progress++; return } ] ]
	);
	$binner->autoscale( x     => $x,
	                    y     => $y,
	                    dummy => null );
	my $N = reduce { our $a * our $b } map { $_->{n} } $binner->axes;
	$progress = Term::ProgressBar::Simple->new( $N );
	$binner->process();

Note that, although we don't care about the return value of the anonymous sub
associated with I<dummy>, Term::ProgressBar::Simple doesn't like being returned
from a function. (Hence the I<return>.)

=head1 SEE ALSO

=over 4

=item *

The PDL::NDBin::Action:: namespace

=item *

The L<PDL> documentation

=back

There are a few histogramming modules on CPAN:

=over 4

=item *

L<PDL::Basic> offers the histogramming functions hist(), whist()

=item *

L<PDL::Primitive> offers the histogramming functions histogram(),
histogram2d(), whistogram(), whistogram2d()

=item *

L<Math::GSL::Histogram> and L<Math::GSL::Histogram2D>

=item *

L<Math::Histogram>

=item *

L<Math::SimpleHisto::XS>

=back

Other tools:

=over 4

=item *

L<awk(1)> is a fantastic tool that can be used to do many tasks like gridding
or averaging with very concise scripts. Working with very large data volumes in
plain text can be a bit slow, though.

=item *

The L<Generic Mapping Tools|http://gmt.soest.hawaii.edu> (written in C) are
focused on creating high-quality graphics but can also be used for tasks like
gridding, local averaging, and more.

=back

The following sections give a detailed overview of features, limitations, and
performance of PDL::NDBin and related distributions on CPAN.

=head1 FEATURES AND LIMITATIONS

The following table gives an overview of the features and limitations of
PDL::NDBin and related distributions on CPAN:

	+---------------------------------------------------+---------+--------+--------+-----------+----------+
	| Feature                                           | MGH     | MH     | MSHXS  | PDL       | PND      |
	+---------------------------------------------------+---------+--------+--------+-----------+----------+
	| Allows piecewise data processing                  | -       | -      | -      | -         | X        |
	| Allows resampling the histogram                   | -       | -      | X      | X         | -        |
	| Automatic parameter calculation based on the data | -       | -      | -      | X         | X        |
	| Bad value support                                 | -       | -      | -      | X         | X        |
	| Can bin multiple variables at once                | -       | -      | -      | -         | X        |
	| Core implementation                               | C       | C      | C      | C         | C/Perl   |
	| Define and use callbacks to apply to the bins     | -       | -      | -      | -         | Perl+C   |
	| Facilities for data structure serialization       | X       | X      | X      | X         | -        |
	| Has overflow and underflow bins by default        | -       | X      | X      | -         | -        |
	| Interface style                                   | Proc.   | OO     | OO     | Proc.     | OO+Proc. |
	| Maximum number of dimensions                      | 2       | N      | 1      | 2         | N        |
	| Native data type                                  | Scalars | Arrays | Arrays | Piddles   | Piddles  |
	| Performance                                       | Low     | Medium | High   | Very high | High     |
	| Support for weighted histograms                   | X       | X      | X      | X         | -        |
	| Uses PDL threading                                | -       | -      | -      | X         | -        |
	| Variable-width bins                               | X       | X      | X      | -         | X        |
	+---------------------------------------------------+---------+--------+--------+-----------+----------+

	  MGH   = Math::GSL 0.26 (Math::GSL::Histogram and Math::GSL::Histogram2D)
	  MH    = Math::Histogram 1.03
	  MSHXS = Math::SimpleHisto::XS 1.28
	  PDL   = PDL 2.4.11
	  PND   = PDL::NDBin 0.017

An explanation and discussion of each of the features is provided below.

=over 4

=item Allows piecewise data processing

The ability to process data piecewise means that the input data (i.e., the data
points) required to produce the output (e.g., a histogram) do not have to be
fed all at once. Instead, the input data can be fed in chunks of any size. The
resulting output is of course identical, whether the input data be fed
piecewise or all at once. However, the input data do not have to fit in memory
all at once, which is very useful when dealing with very large data sets.

An example may help to understand this feature. Suppose you want to calculate
the monthly mean cloud cover over an area of the globe, in boxes of 1 by 1
degree. The total amount of cloud cover data is too large to fit in memory, but
fortunately, the data are spread of several files, one by day. With PDL::NDBin,
you can do the following:

	my $binner = PDL::NDBin->new(
		axes => [[ 'latitude',    min => -60, max => 60, step => 1 ],
		         [ 'longitude',   min => -60, max => 60, step => 1 ]],
		vars => [[ 'cloud_cover', 'Avg' ]],
	);
	for my $file ( @all_files ) {
		# suppose $file contains the geolocated cloud cover data for
		# one day of the month
		my $lat = $file->read( 'latitude' );
		my $lon = $file->read( 'longitude' );
		my $cc  = $file->read( 'cloud_cover' );
		$binner->process( latitude    => $lat,
		                  longitude   => $lon,
		                  cloud_cover => $cc );
	}
	my $avg = $binner->output->{cloud_cover};

In this example, only the data of a single day have to be kept in memory. The
$binner object keeps a running average of the data, and retains the proper
counts until the output $avg must be generated.

Only PDL::NDBin offers this feature. It can be simulated with other libraries
for histograms, as long as histograms can be added together. PDL::NDBin extends
the feature of piecewise data processing to sums, averages, and standard
deviations.

=item Allows resampling the histogram

To resample a histogram means to put in a histogram of I<N> bins, the data that
were originally in a histogram of I<M> bins, where I<N> and I<M> are different.

Only Math::SimpleHisto::XS and PDL support this feature. In PDL, the function
is known as rebin() (to be found in L<PDL::ImageND>).

=item Automatic parameter calculation based on the data

If a minimum bin, maximum bin, or step size are not supplied, PDL and
PDL::NDBin will calculate them from the data. Other libraries require the user
to specify them manually.

=item Bad value support

Bad value support, when it is present, allows to distinguish missing or invalid
data from valid data. The missing or invalid data are excluded from the
processing. Only the PDL-based libraries PDL and PDL::NDBin support bad values.

=item Can bin multiple variables at once

When data is co-located, e.g., cloud cover, cloud phase, and cloud optical
thickness on a latitude-longitude grid, some time can be saved by binning the
cloud variables together. Once the bin number has been determined for the given
latitude and longitude, it can be reused for all cloud variables. This is
marginally faster than binning the cloud variables separately. Only PDL::NDBin
supports this feature.

=item Core implementation

Math::GSL::Histogram is a wrapper around the GSL library, which is written in
C.

Math::Histogram is a wrapper around an I<N>-dimensional histogramming library
written in C.

Math::SimpleHisto::XS, by the same author as Math::Histogram, is implemented in
C.

The core histogramming functions of PDL are implemented in C.

The core loops of PDL::NDBin are implemented partly in Perl, partly in C.

=item Define and use callbacks to apply to the bins

PDL::NDBin can handle any type of calculation on the values in the bins that
you can express in Perl or C, not only counting the number of elements in order
to produce a histogram. At the time of writing (version 0.008), PDL::NDBin
supports counting, summing, averaging, and taking the standard deviation of the
values in each bin. Additionally, Perl or C subroutines can be defined and used
to perform any operation on the values in each bin.

This feature, arguably the most important feature of PDL::NDBin, is not found
in other modules.

=item Facilities for data structure serialization

Serialization is the process of storing a histogram to disk, or retrieving it
from disk. Math::GSL::Histogram, Math::Histogram, Math::SimpleHisto::XS, and
PDL all have built-in support for serialization. PDL::NDBin doesn't, but the
serialization facilities of PDL can be used to store and retrieve data. (I
usually store computed data in netCDF files with L<PDL::NetCDF>.)

=item Has overflow and underflow bins by default

Data lower than the lowest range of the first bin, or higher than the highest
range of the last bin, are treated differently in different modules.

Math::GSL::Histogram ignores out-of-range values.

Math::Histogram and Math::SimpleHisto::XS have overflow bins, i.e., by default
they create more bins than you define. These so-called overflow bins are
situated at either end of every dimension. Out-of-range values end up in the
overflow bins.

The histogramming functions of PDL, and PDL::NDBin, store low out-of-range
values in the first bin, and high out-of-range values in the last bin.

To ignore out-of-range values with PDL::NDBin, define an additional bin at
either end of every dimension, and disregard the values in these additional
bins.

To simulate overflow and underflow bins with PDL::NDBin, define an additional
bin at either end of every dimension.

=item Interface style

I<Proc.> means that the module has a procedural interface. I<OO> means that the
module has an object-oriented interface. PDL::NDBin has both. Which interface
you should use is largely a matter of preference, unless you want to use
advanced features such as piecewise data feeding, which require the
object-oriented interface.

Math::GSL::Histogram has a somewhat awkward interface, requiring the user to
explicitly deallocate the data structure after use.

=item Maximum number of dimensions

The maximum number of dimensions that can be processed. Math::Histogram and
PDL::NDBin can handle an arbitrary number of dimensions.

=item Native data type

Obviously, deep down, all data values are just C scalars. By 'native data type'
is meant the data type used to communicate with the library in the most
efficient way.

At the time of writing (Math::GSL version 0.27), Math::GSL::Histogram did not
have a facility to enter multiple data points at once. It accepts only Perl
scalars, and requires the user to input the data points one by one. Similarly,
to produce the final histogram, the bins must be queried one by one.

Math::Histogram and Math::SimpleHisto::XS accept Perl arrays filled with values
(although they also accept data points one by one as Perl scalars). Passing
large amounts of data in an array is generally more efficient than passing the
data points one by one as scalars.

PDL and PDL::NDBin operate on piddles only, which are memory-efficient, packed
data arrays. This could be considered both an advantage and a disadvantage. The
advantage is that the piddles can be operated on very efficiently in C. The
disadvantage is that PDL is required!

=item Performance

In the next section (see L<PERFORMANCE>), the performance of all modules is
examined in detail.

=item Support for weighted histograms

In a weighted histogram, data points contribute by a fractional amount (or
weight) between 0 and 1. All libraries, except PDL::NDBin, support weighted
histograms. In PDL::NDBin, the weight of all data points is fixed at 1.

=item Uses PDL threading

In PDL, threading is a technique to automatically loop certain operations over
an arbitrary number of dimensions. An example is the sumover() operation, which
calculates the row sum. It is defined over the first dimension only (i.e., the
rows in PDL), but it will be looped automatically over all remaining
dimensions. If the piddle is three-dimensional, for instance, sumover() will
calculate the sum in every row of every matrix.

Threading is supported by the PDL functions histogram(), whistogram(), and
their two-dimensional counterparts, but not by hist() or whist(). PDL::NDBin
does not (yet) support threading.

=item Variable-width bins

In a histogram with variable-width bins, the width of the bins needn't be
equal. This feature can be useful, for example, to construct bins on a
logarithmic scale. Math::GSL, Math::Histogram, and Math::SimpleHisto::XS
support variable-width bins; PDL does not, and is limited to fixed-width bins.

Since version 0.017, PDL::NDBin supports variable-width bins if a piddle or
Perl array containing the bin boundaries is passed in via the I<grid> parameter
to axis specifications.

=back

=head1 PERFORMANCE

=head2 One-dimensional histograms

This section aims to give an idea of the performance of PDL::NDBin. Some of the
most important features of PDL::NDBin aren't found in other modules on CPAN.
But there are a few histogramming modules on CPAN, and it is interesting to
examine how well PDL::NDBin does in comparison.

I've run a number of tests with PDL version 0.008 on a laptop with an Intel i3
CPU running at 2.40 GHz, and on a desktop with an Intel i7 CPU running at 2.80
GHz and fast disks. The following table, obtained with 100 bins and a data file
of 2 million data points, shows typical results on the laptop:

	Benchmark: timing 50 iterations of MGH, MH, MSHXS, PND, hist, histogram...
	       MGH: 42 wallclock secs (42.48 usr +  0.05 sys = 42.53 CPU) @  1.18/s (n=50)
	        MH:  6 wallclock secs ( 5.53 usr +  0.00 sys =  5.53 CPU) @  9.04/s (n=50)
	     MSHXS:  2 wallclock secs ( 2.21 usr +  0.01 sys =  2.22 CPU) @ 22.52/s (n=50)
	       PND:  2 wallclock secs ( 1.40 usr +  0.00 sys =  1.40 CPU) @ 35.71/s (n=50)
	      hist:  1 wallclock secs ( 1.09 usr +  0.00 sys =  1.09 CPU) @ 45.87/s (n=50)
	 histogram:  1 wallclock secs ( 1.08 usr +  0.00 sys =  1.08 CPU) @ 46.30/s (n=50)

	Relative performance:
	            Rate       MGH        MH     MSHXS       PND      hist histogram
	MGH       1.18/s        --      -87%      -95%      -97%      -97%      -97%
	MH        9.04/s      669%        --      -60%      -75%      -80%      -80%
	MSHXS     22.5/s     1816%      149%        --      -37%      -51%      -51%
	PND       35.7/s     2938%      295%       59%        --      -22%      -23%
	hist      45.9/s     3802%      407%      104%       28%        --       -1%
	histogram 46.3/s     3838%      412%      106%       30%        1%        --

From this test and other tests, it can be concluded that PDL::NDBin (shown as
'PND' in the table) is, roughly speaking,

=over 4

=item 1. faster than Math::GSL::Histogram (shown as MGH in the table)

Although this module is actually a wrapper around the C library GSL, the
performance is rather low. The process of getting a large number of data points
into Math::GSL::Histogram's data structures is inefficient, as the data points
have to be input one by one.

=item 2. faster than Math::Histogram (shown as MH)

This library wraps another multidimensional histogramming library written in C.
It allows inputting multiple data points at once. It is quite a bit faster than
Math::GSL::Histogram, but does not offer the raw performance of PDL or
Math::Histogram's cousin Math::SimpleHisto::XS.

=item 3. faster than Math::SimpleHisto::XS (shown as MSHXS)

Math::SimpleHisto::XS, by the same author as Math::Histogram, is similar to the
latter library, but implemented in XS for speed, and limited to one-dimensional
histograms. It is slower than PDL::NDBin.

=item 4. slower than PDL

PDL's built-in functions hist() and histogram() are, on average, the fastest
functions. Given that the core of these routines runs entirely in C, this is
not very surprising. The PDL functions have very low overhead and are very
memory-efficient.

=back

Note that, in the tests, various data conversions between piddles and ordinary
Perl arrays were required. The timings exclude these conversions, and count
only the time required to produce a histogram from the "natural" data
structure, i.e. piddles for PDL-based modules, and ordinary Perl arrays for the
other modules.

Note also that the histograms produced by the different methods were verified
to be equal.

=head2 Two-dimensional histograms

Similar conclusions are obtained for two-dimensional histograms. The following
table shows results on the laptop for 2 million data points with 100 bins:

	Benchmark: timing 50 iterations of MGH2d, PND2d, histogram2d...
	      MGH2d: 52 wallclock secs (51.38 usr +  0.36 sys = 51.74 CPU) @  0.97/s (n=50)
	      PND2d:  3 wallclock secs ( 2.46 usr +  0.03 sys =  2.49 CPU) @ 20.08/s (n=50)
	histogram2d:  2 wallclock secs ( 2.19 usr +  0.00 sys =  2.19 CPU) @ 22.83/s (n=50)

	Relative performance:
	               Rate       MGH2d       PND2d histogram2d
	MGH2d       0.966/s          --        -95%        -96%
	PND2d        20.1/s       1978%          --        -12%
	histogram2d  22.8/s       2263%         14%          --

(It was not possible to run the test with Math::Histogram to completion.)

=head2 Scaling w.r.t. number of data points

Performance figures for a few tests on a particular machine don't say much. As
PDL::NDBin is intended to handle large amounts of data, it is important to
check how well PDL::NDBin's performance scales as the problem size increases.

The first and most obvious way in which a problem may be 'large', is the number
of data points. If a given method cannot process a large number of data points,
or can only do so with increased effort, it is not suitable for large problems.
How large that is, depends on the application, but in the field of satellite
data retrieval (where I work), 33 million data points is not exceptional at all
(but it is the largest size I could test). In this section, we examine how well
PDL::NDBin's performance scales with the number of data points, and compare
with alternative modules.

The following table shows timing data on the laptop for 100 bins, but with a
variable number of data points:

	+-----------+------------+----------+-------+------------+---------------+
	| method    |   # points | CPU time |     n | time/iter. | time/i./point |
	|           |            |      (s) |       |       (ms) |          (ns) |
	+-----------+------------+----------+-------+------------+---------------+
	| MGH       |     66,398 |    38.84 | 1,500 |     25.893 |       389.972 |
	| MGH       |  2,255,838 |    43.06 |    50 |    861.200 |       381.765 |
	+-----------+------------+----------+-------+------------+---------------+
	| MH        |     66,398 |     6.21 | 1,500 |      4.140 |        62.351 |
	| MH        |  2,255,838 |     5.65 |    50 |    113.000 |        50.092 |
	+-----------+------------+----------+-------+------------+---------------+
	| MSHXS     |     66,398 |     2.11 | 1,500 |      1.407 |        21.185 |
	| MSHXS     |  2,255,838 |     2.26 |    50 |     45.200 |        20.037 |
	+-----------+------------+----------+-------+------------+---------------+
	| PND       |     66,398 |     1.79 | 1,500 |      1.193 |        17.972 |
	| PND       |  2,255,838 |     1.38 |    50 |     27.600 |        12.235 |
	| PND       | 33,358,558 |     2.28 |     5 |    456.000 |        13.670 |
	+-----------+------------+----------+-------+------------+---------------+
	| histogram |     66,398 |     0.99 | 1,500 |      0.660 |         9.940 |
	| histogram |  2,255,838 |     1.12 |    50 |     22.400 |         9.930 |
	| histogram | 33,358,558 |     1.65 |     5 |    330.000 |         9.893 |
	+-----------+------------+----------+-------+------------+---------------+

Note that the tests couldn't be run with Math::GSL::Histogram, Math::Histogram,
and Math::SimpleHisto::XS on the largest data file (33 million points), due to
insufficient memory.

The methods show a linear increase in time per iteration with the number of
data points, which translates to a fixed time per iteration per data point.
This is the desired behaviour: it guarantees that the effort required to
produce a histogram does not increase faster than the problem size. Every
method examined here displays this behaviour.

Something else to note is the higher CPU time per iteration per data point of
PDL::NDBin for small data files, although there is also a hint of this effect
in the results for Math::Histogram. For large data files, the time per
iteration per data point is more or less constant. This effect is not fully
understood, but may indicate high overhead or start-up cost.

The results suggest that PDL::NDBin scales well with the number of data points,
and that it is therefore well suited for large data. PDL::NDBin and histogram()
(and hist()) are currently the only methods that allow processing very large
data files.

=head2 Scaling w.r.t. number of bins

The number of data points may not be the only way in which a problem may be
'large' or hard. The number of bins may also be high. In applications with
satellite data, for instance, a latitude/longitude grid with a resolution of
only 5 degrees already yields more than 2000 bins, and raising the resolution
to 1 degree yields approximately 64,000 bins.

Most of the methods depend in some way on the number of bins. If the execution
time depends to a significant extent on the number of bins, the method is not
suitable for large numbers of bins. In this section, we examine how well
PDL::NDBin's performance scales with the number of bins, and compare with
alternative modules.

The following table shows timing data on the laptop for 2 million data points,
with a variable number of bins:

	+-----------+-----------+----------+----+------------+
	| method    |    # bins | CPU time |  n | time/iter. |
	|           |           |      (s) |    |       (ms) |
	+-----------+-----------+----------+----+------------+
	| MGH       |        10 |    42.57 | 50 |    851.400 |
	| MGH       |        50 |    42.35 | 50 |    847.000 |
	| MGH       |       100 |    42.53 | 50 |    850.600 |
	| MGH       |     1,000 |    43.06 | 50 |    861.200 |
	| MGH       |    10,000 |    42.96 | 50 |    859.200 |
	| MGH       |   100,000 |    46.60 | 50 |    932.000 |
	| MGH       | 1,000,000 |    78.75 | 50 |   1575.000 |
	+-----------+-----------+----------+----+------------+
	| MH        |        10 |     5.53 | 50 |    110.600 |
	| MH        |        50 |     5.51 | 50 |    110.200 |
	| MH        |       100 |     5.53 | 50 |    110.600 |
	| MH        |     1,000 |     5.65 | 50 |    113.000 |
	+-----------+-----------+----------+----+------------+
	| MSHXS     |        10 |     2.26 | 50 |     45.200 |
	| MSHXS     |        50 |     2.21 | 50 |     44.200 |
	| MSHXS     |       100 |     2.22 | 50 |     44.400 |
	| MSHXS     |     1,000 |     2.26 | 50 |     45.200 |
	| MSHXS     |    10,000 |     2.30 | 50 |     46.000 |
	| MSHXS     |   100,000 |     2.65 | 50 |     53.000 |
	| MSHXS     | 1,000,000 |     6.22 | 50 |    124.400 |
	+-----------+-----------+----------+----+------------+
	| PND       |        10 |     1.41 | 50 |     28.200 |
	| PND       |        50 |     1.40 | 50 |     28.000 |
	| PND       |       100 |     1.40 | 50 |     28.000 |
	| PND       |     1,000 |     1.38 | 50 |     27.600 |
	| PND       |    10,000 |     1.37 | 50 |     27.400 |
	| PND       |   100,000 |     1.40 | 50 |     28.000 |
	| PND       | 1,000,000 |     1.95 | 50 |     39.000 |
	+-----------+-----------+----------+----+------------+
	| histogram |        10 |     1.09 | 50 |     21.800 |
	| histogram |        50 |     1.09 | 50 |     21.800 |
	| histogram |       100 |     1.08 | 50 |     21.600 |
	| histogram |     1,000 |     1.12 | 50 |     22.400 |
	| histogram |    10,000 |     1.15 | 50 |     23.000 |
	| histogram |   100,000 |     1.21 | 50 |     24.200 |
	| histogram | 1,000,000 |     1.45 | 50 |     29.000 |
	+-----------+-----------+----------+----+------------+

Note that some data are missing because the associated test didn't run
successfully (e.g., segmentation fault).

The methods show more or less constant execution time per iteration,
independent of the number of bins. This is the desired behaviour: the overhead
of managing the bins does not dominate the execution time.

At high bin counts, however, execution time increases for almost all methods,
as there is always some amount of bookkeeping required proportional to the
number of bins. Except for Math::GSL::Histogram, the bookkeeping is not
prohibitive.

The results suggest that PDL::NDBin scales well with the number of bins up to
1,000,000, and that it is therefore well suited for large data.

=head1 BUGS

None reported.

=head1 TODO

As is probably obvious from this manual, there are quite a few areas where
PDL::NDBin can be improved. In particular:

=over 4

=item *

PDL:NDBin does not currently have a way to collect and return the values in a
bin as a list or piddle; this would be very useful for plotting or output.

=item *

PDL::NDBin does not currently support weighted histograms.

=item *

The documentation can be expanded and improved in a few places.

=item *

The axes should be refactored into objects instead of bare hashrefs, with
methods such as labels(), n(), step(), etc.

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item *

Diab Jerius <djerius@cfa.harvard.edu> implemented support for passing in a
user-defined piddle or array containing bin boundaries, effectively allowing
variable-width bins. Thanks Diab!

=back

=head1 AUTHOR

Edward Baudrez <ebaudrez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Edward Baudrez.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
