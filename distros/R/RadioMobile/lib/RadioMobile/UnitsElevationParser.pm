package RadioMobile::UnitsElevationParser;

use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

our $VERSION    = '0.10';

__PACKAGE__->valid_params( 
							parent	=> {isa => 'RadioMobile'},
);

use Class::MethodMaker [ scalar => [qw/parent/] ];

=head1 NAME

RadioMobile::UnitsElevationParser

=head1 DESCRIPTION

This module parse the elevation of every antenna in every networks.
It update the RadioMobile::NetsUnits object args passed in new invoke.

=head1 METHODS

=head2 new()

Parameters:

    parent     => {isa => 'RadioMobile'},

=cut

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	return $s;
}

=head2 parse()

the elevation is a short unsigned integer identifing it's value power by ten

=cut

sub parse {
	my $s = shift;
	my $f = $s->parent->bfile;
	my $n = $s->parent->netsunits;

	# a short integer set how much network enabled in ElevationAngle
	my $b = $f->get_bytes(2);
	my $nc = unpack("s",$b);
	# a short integer set how much units enabled in ElevationAngle
	$b = $f->get_bytes(2);
	my $uc = unpack("s",$b);
	
	my $skip   = 'x[' . ($nc-1)*2 .  ']';

	$b = $f->get_bytes( 2 * $nc * $uc);
	foreach my $idxNet (0..$nc-1) {
		my $format = 'x[' . $idxNet * 2  . '](S' .  $skip . ')' . ($uc-1) .  'S';
		my @elevation = unpack($format,$b);
		foreach my $idxUnit (0..$uc-1) {
			my $unit = $n->at($idxNet,$idxUnit);
			my $elevation = $elevation[$idxUnit];
			$unit->elevation($elevation/10);
		}
	}
}

sub write {
	my $s = shift;
	my $f = $s->parent->bfile;
	my $n = $s->parent->netsunits;
	my $h = $s->parent->header;

	$f->put_bytes(pack('s',$h->networkCount));
	$f->put_bytes(pack('s',$h->unitCount));
	# a short integer set how much units enabled in ElevationAngle

	foreach my $idxUnit (0..$h->unitCount-1) {
		foreach my $idxNet (0..$h->networkCount-1) {
			my $unit = $n->at($idxNet,$idxUnit);
			$f->put_bytes(pack('S',$unit->elevation* 10));
		}
	}
}


1;

__END__
