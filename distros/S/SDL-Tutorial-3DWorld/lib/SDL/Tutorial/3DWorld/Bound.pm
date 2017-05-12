package SDL::Tutorial::3DWorld::Bound;

use 5.008;
use strict;
use warnings;
use Exporter   ();
use List::Util ();

use vars qw{ $VERSION @ISA @EXPORT };
BEGIN {
	$VERSION = '0.33';
	@ISA     = 'Exporter';
	@EXPORT  = qw{
		SPHERE_X
		SPHERE_Y
		SPHERE_Z
		SPHERE_R
		BOX_X1
		BOX_Y1
		BOX_Z1
		BOX_X2
		BOX_Y2
		BOX_Z2
	};
}

# We can mostly avoid these, but they do help document things
use constant +{
	map { $EXPORT[$_] => $_ } ( 0 .. $#EXPORT )
};





######################################################################
# Constructors

sub new {
	my $class = shift;
	return bless [ @_ ], $class;
}

sub box {
	shift->new(
		($_[3] + $_[0]) / 2,
		($_[4] + $_[1]) / 2,
		($_[4] + $_[2]) / 2,
		List::Util::max(
			$_[3] - $_[0],
			$_[4] - $_[1],
			$_[5] - $_[2],
		) / 2,
		@_,
	);
}

sub sphere {
	shift->new(
		@_,
		$_[0] - $_[3],
		$_[1] - $_[3],
		$_[2] - $_[3],
		$_[0] + $_[3],
		$_[1] + $_[3],
		$_[2] + $_[3],
	);
}

1;
