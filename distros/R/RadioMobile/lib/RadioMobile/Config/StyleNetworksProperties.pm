package RadioMobile::Config::StyleNetworksProperties;

our $VERSION    = '0.01';

use strict;
use warnings;

use Data::Dumper;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

use constant ITEMS	=> qw/drawRed rxYellow drawYellow rxGreen drawGreen drawBg twoRay twoRayType/;

__PACKAGE__->valid_params ( map {$_ => {type => SCALAR, default => 1, optional => 1}} (ITEMS));
use Class::MethodMaker [scalar => [ITEMS]];

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	# only twoRayType, rxGreen, rxYellow defaults are wrong
	$s->rxYellow(-3);
	$s->rxGreen(3);
	$s->twoRayType("normal");
	return $s;
}

sub dump {
	my $s	= shift;
	my $ret = "{\n";
	$ret .= join("\n", map {sprintf("\t%-12s=> ",$_) . $s->$_ . ","} (ITEMS));
	$ret .= "\n}\n";
	return $ret;
}

1;

__END__
