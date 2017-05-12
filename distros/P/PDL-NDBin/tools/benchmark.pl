# benchmark PDL::NDBin

use strict;
use warnings;
use blib;				# prefer development version of PDL::NDBin
use Benchmark qw( cmpthese timethese );
use Fcntl;
use PDL;
use PDL::NetCDF;
use PDL::NDBin qw( ndbinning );
use Path::Class;
use Getopt::Long::Descriptive;
use Text::TabularDisplay;
use Math::Histogram;
use Math::SimpleHisto::XS;
use Math::GSL::Histogram qw( :all );
use Math::GSL::Histogram2D qw( :all );

my( $opt, $usage ) = describe_options(
	'%c %o input_file [ input_file... ]',
	[ 'bins|b=i',       'how many bins to use along every dimension' ],
	[ 'functions|f=s',  'comma-separated list of functions to benchmark' ],
	[ 'iterations|i=i', 'how many iterations to perform (for better accuracy)' ],
	[ 'multi|m',        'engage multi-mode to process multiple files' ],
	[ 'old-flattening', 'use the old (pure-Perl) way of flattening' ],
	[ 'output|o',       'do output actual return value from functions' ],
	[ 'preload|p=s',    'comma-separated list of data fields to preload before running the benchmark' ],
	[],
	[ 'help', 'show this help screen' ],
);
print( $usage->text ), exit if $opt->help;
my $n = $opt->bins;
my %selected = map { $_ => 1 } split /,/ => $opt->functions;

#
my $file;
if( $opt->multi ) {
	@ARGV or die $usage;
}
else {
	$file = shift;
	defined( $file ) && -f $file or die $usage;
	@ARGV and die $usage;
}

# we're going to bin latitude and longitude from -70 .. 70
my( $min, $max, $step ) = ( -70, 70, 140/$n );

# this is our on-demand data loader:
my $nc = OnDemand->new( $file );

#
if( $opt->old_flattening ) {
	no warnings 'redefine';
	*PDL::_flatten_into = sub (;@) {
		my( $pdl, $idx, $step, $min, $n ) = @_;
		my $binned = PDL::indx( ($pdl - $min)/$step );
		$binned->inplace->clip( 0, $n-1 );
		$idx * $n + $binned
	} 
}

#
if( $opt->preload ) {
	print "Trying to preload data...\n";
	for my $preload ( split /,/ => $opt->preload ) {
		$nc->$preload;
		print "Loaded '$preload'.\n";
	}
	print "Preload done.\n";
}

#
my %functions = (
	# one-dimensional histograms
	hist         => sub { hist $nc->lat, $min, $max, $step },
	histogram    => sub { histogram $nc->lat, $step, $min, $n },
	want         => sub {
				my $binner = PDL::NDBin->new(
					axes => [[ lat => (step=>$step,min=>$min,n=>$n) ]],
					vars => [[ lat => sub { shift->want->nelem } ]] );
				$binner->process( lat => $nc->lat )->output->{lat}
			},
	# $iter->selection->nelem is bound to be slower than $iter->want->nelem, but the purpose here is to compare
	selection    => sub {
				my $binner = PDL::NDBin->new(
					axes => [[ lat => (step=>$step,min=>$min,n=>$n) ]],
					vars => [[ lat => sub { shift->selection->nelem } ]] );
				$binner->process( lat => $nc->lat )->output->{lat}
			},
	PND          => sub {
				my $binner = PDL::NDBin->new(
					axes => [[ lat => (step=>$step,min=>$min,n=>$n) ]],
					vars => [[ lat => 'Count' ]] );
				$binner->process( lat => $nc->lat )->output->{lat}
			},
	ndbinning    => sub { ndbinning $nc->lat, $step, $min, $n },
	MH           => sub {
				my @dimensions = ( Math::Histogram::Axis->new( $n, $min, $max ) );
				my $hist = Math::Histogram->new( \@dimensions );
				#$hist->fill( [ $_ ] ) for @{ $nc->lat_array };		# inefficient
				$hist->fill_n( $nc->lat_ref_array );
				[ map $hist->get_bin_content( [ $_ ] ), 1 .. $n ]
			},
	MSHXS        => sub {
				my $hist = Math::SimpleHisto::XS->new(
					min => $min,
					max => $max,
					nbins => $n );
				$hist->fill( $nc->lat_array );
				$hist->all_bin_contents
			},
	MGH          => sub {
				my $h = gsl_histogram_alloc( $n );
				gsl_histogram_set_ranges_uniform( $h, $min, $max );
				gsl_histogram_increment( $h, $_ ) for @{ $nc->lat_array };
				my $hist = [ map { gsl_histogram_get( $h, $_ ) } 0 .. $n-1 ];
				gsl_histogram_free( $h );
				$hist
			},

	# two-dimensional histograms
	histogram2d  => sub { histogram2d $nc->lat, $nc->lon, $step, $min, $n, $step, $min, $n },
	want2d       => sub {
				my $binner = PDL::NDBin->new(
					axes => [[ lat => (step=>$step,min=>$min,n=>$n) ], [ lon => (step=>$step,min=>$min,n=>$n) ]],
					vars => [[ lat => sub { shift->want->nelem } ]] );
				$binner->process( lat => $nc->lat, lon => $nc->lon )->output->{lat}
			},
	PND2d        => sub {
				my $binner = PDL::NDBin->new(
					axes => [[ lat => (step=>$step,min=>$min,n=>$n) ], [ lon => (step=>$step,min=>$min,n=>$n) ]],
					vars => [[ lat => 'Count' ]] );
				$binner->process( lat => $nc->lat, lon => $nc->lon )->output->{lat}
			},
	ndbinning2d  => sub { ndbinning $nc->lat, $step, $min, $n, $nc->lon, $step, $min, $n },
	MH2d         => sub {
				my @dimensions = (
					Math::Histogram::Axis->new( $n, $min, $max ),
					Math::Histogram::Axis->new( $n, $min, $max ),
				);
				my $hist = Math::Histogram->new( \@dimensions );
				$hist->fill_n( $nc->lat_lon_ref_array );
				[ map { my $j = $_; [ map $hist->get_bin_content( [ $_, $j ] ), 1 .. $n ] } 1 .. $n ]
			},
	MGH2d        => sub {
				my $h = gsl_histogram2d_alloc( $n, $n );
				gsl_histogram2d_set_ranges_uniform( $h, $min, $max, $min, $max );
				gsl_histogram2d_increment( $h, @$_ ) for @{ $nc->lat_lon_ref_array };
				my $hist = [ map { my $j = $_; [ map gsl_histogram2d_get( $h, $_, $j ), 0 .. $n-1 ] } 0 .. $n-1 ];
				gsl_histogram2d_free( $h );
				$hist
			},

	# average flux using either a coderef or a class (XS-optimized)
	coderef      => sub {
				my $binner = PDL::NDBin->new(
					axes => [[ lat => (step=>$step,min=>$min,n=>$n) ], [ lon => (step=>$step,min=>$min,n=>$n) ]],
					vars => [[ flux => sub { $_[0]->want->nelem ? shift->selection->avg : undef } ]] );
				$binner->process( lat => $nc->lat, lon => $nc->lon, flux => $nc->flux )->output->{flux}
			},
	class        => sub {
				my $binner = PDL::NDBin->new(
					axes => [[ lat => (step=>$step,min=>$min,n=>$n) ], [ lon => (step=>$step,min=>$min,n=>$n) ]],
					vars => [[ flux => 'Avg' ]] );
				$binner->process( lat => $nc->lat, lon => $nc->lon, flux => $nc->flux )->output->{flux}
			},

	# one-dimensional histograms by concatenating multiple data files
	'histogram_multi' =>
			sub {
				my $hist = zeroes( $n );
				for my $file ( @ARGV ) {
					my $nc = PDL::NetCDF->new( $file, { MODE => O_RDONLY } );
					my $lat = $nc->get( 'latitude' );
					$hist += histogram $lat, $step, $min, $n;
				}
				$hist
			},
	'PND_multi' =>
			sub {
				my $binner = PDL::NDBin->new(
					axes => [[ lat => (step=>$step,min=>$min,n=>$n) ]],
					vars => [[ lat => 'Count' ]] );
				for my $file ( @ARGV ) {
					my $nc = PDL::NetCDF->new( $file, { MODE => O_RDONLY } );
					my $lat = $nc->get( 'latitude' );
					$binner->process( lat => $lat );
				}
				$binner->output->{lat}
			},

	# two-dimensional histograms by concatenating multiple data files
	'histogram_multi2d' =>
			sub {
				my $hist = zeroes( $n, $n );
				for my $file ( @ARGV ) {
					my $nc = PDL::NetCDF->new( $file, { MODE => O_RDONLY } );
					my $lat = $nc->get( 'latitude' );
					my $lon = $nc->get( 'longitude' );
					$hist += histogram2d $lat, $lon, $step, $min, $n, $step, $min, $n;
				}
				$hist
			},
	'PND_multi2d' =>
			sub {
				my $binner = PDL::NDBin->new(
					axes => [[ lat => (step=>$step,min=>$min,n=>$n) ], [ lon => (step=>$step,min=>$min,n=>$n) ]],
					vars => [[ lat => 'Count' ]] );
				for my $file ( @ARGV ) {
					my $nc = PDL::NetCDF->new( $file, { MODE => O_RDONLY } );
					my $lat = $nc->get( 'latitude' );
					my $lon = $nc->get( 'longitude' );
					$binner->process( lat => $lat, lon => $lon );
				}
				$binner->output->{lat}
			},
);

my %output;
my $results = timethese( $opt->iterations,
			 { map  { my $f = $_; $_ => sub { $output{ $f } = $functions{ $f }->() } }
			   grep { $selected{ $_ } }
			   keys  %functions
			 } );
print "\nRelative performance:\n";
cmpthese( $results );
print "\n";

# Math::SimpleHisto::XS returns an arrayref: for a fair comparison, we need to
# convert the arrayref to a PDL after the benchmark
for my $key ( keys %output ) {
	my $val = $output{ $key };
	next if eval { $val->isa('PDL') };
	if( ref $val eq 'ARRAY' ) { $output{ $key } = pdl( $val ) }
}

if( $opt->output ) {
	print "Actual output:\n";
	while( my( $func, $out ) = each %output ) { printf "%20s: %s\n", $func, $out }
	print "\n";
}

print "Norm of difference between output piddles:\n";
my $table = Text::TabularDisplay->new( '', keys %output );
for my $row ( keys %output ) {
	my @elem = map { my $diff = eval { $output{ $row } - $output{ $_ } };
		         if( $@ ) { '??' }
			 else { $row eq $_ ? '-' : $diff->abs->max } } keys %output;
	$table->add( $row, @elem );
}
print $table->render, "\n";
my $nelem = eval { $nc->nelem };
if( defined $nelem ) {
	# reformat number by separating digits with commas
	# Perl Cookbook, 2nd Ed., p. 84 ;-)
	my $text = reverse $nelem;
	$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
	$nelem = scalar reverse $text;
}
else {
	$nelem = 'unknown';
}
print "($nelem data points)\n\n";

#
# a separate helper package implement on-demand loading of data
# and data structure conversion
#
package OnDemand;
use Fcntl;
use PDL::NetCDF;
use List::MoreUtils qw( pairwise );

sub new    { my $class = shift; bless { filename => $_[0] }, $class }
sub netcdf { my $self = shift; $self->{netcdf} ||= PDL::NetCDF->new( $self->{filename}, { MODE => O_RDONLY } ) }
sub lat    { my $self = shift; $self->{lat}    //= $self->netcdf->get( 'latitude'  ) }
sub lon    { my $self = shift; $self->{lon}    //= $self->netcdf->get( 'longitude' ) }
sub flux   { my $self = shift; $self->{flux}   //= $self->netcdf->get( 'gerb_flux' ) }
sub nelem  { my $self = shift; $self->lat->nelem }

# conversions to put the data in the structures required by external packages
sub lat_array         { my $self = shift; $self->{lat_array}         ||= [ $self->lat->list ] }
sub lon_array         { my $self = shift; $self->{lon_array}         ||= [ $self->lon->list ] }
sub lat_ref_array     { my $self = shift; $self->{lat_ref_array}     ||= [ map [ $_ ], @{ $self->lat_array } ] }
sub lon_ref_array     { my $self = shift; $self->{lon_ref_array}     ||= [ map [ $_ ], @{ $self->lon_array } ] }
sub lat_lon_ref_array { my $self = shift; $self->{lat_lon_ref_array} ||= [ pairwise { [ our $a, our $b ] } @{ $self->lat_array }, @{ $self->lon_array } ] }
