use strict;

package Salvation::Service::View::SimpleCache;

require Exporter;

our @ISA	 = ( 'Exporter' );

our @EXPORT	 = ( '&rsc_store',
		     '&rsc_retrieve',
		     '&rsc_exists' );

our @EXPORT_OK	 = @EXPORT;

our @EXPORT_TAGS = ( all => \@EXPORT );

our $VERSION	 = 1.00;

use Carp::Assert;

our $ZEE_CACHE   = {}; # Shared cache

sub new
{
	my $proto = shift;
	my $class = ( ref( $proto ) or $proto );

	return bless( {}, $class );
}

sub rsc_store
{
	__PACKAGE__ -> store( @_ );
}

sub rsc_retrieve
{
	__PACKAGE__ -> retrieve( @_ );
}

sub rsc_exists
{
	__PACKAGE__ -> exists( @_ );
}

sub store
{
	my $self = shift;

	assert( scalar( @_ ) == 3 );

	return $self -> __manip( @_ );
}

sub retrieve
{
	my $self = shift;

	assert( scalar( @_ ) == 2 );

	return $self -> __manip( @_ );
}

sub exists
{
	my ( undef, $ns, $dry ) = @_;

	return CORE::exists $Salvation::View::SimpleCache::ZEE_CACHE -> { join( '_', ( $ns, $dry ) ) };
}

sub __manip
{
	my $self = shift;
	my $col  = join( '_', ( shift, shift ) );
	my @args = @_;

	unshift @args, $col;

	return $self -> __cache( @args );
}

sub __cache
{
	my ( undef, $col, $val ) = @_;

	if( scalar( @_ ) > 2 )
	{
		$Salvation::View::SimpleCache::ZEE_CACHE -> { $col } = $val;
	}

	return $Salvation::View::SimpleCache::ZEE_CACHE -> { $col };
}

-1;

