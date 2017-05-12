package RadioMobile::UnitsAzimutDirectionParser;

use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

our $VERSION    = '0.11';

__PACKAGE__->valid_params( 
							parent	=> {isa => 'RadioMobile'},
);

use Class::MethodMaker [ scalar => [qw/parent/] ];

=head1 NAME

RadioMobile::UnitsAzimutDirectionParser

=head1 DESCRIPTION

This module parse the azimut of every antenna in every networks.
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

the azimut is a short unsigned integer identifing it's value power by ten
If it's value is greater than 10.000, it's not a azimut value but it's the
direcion by unit which index is the field value - 10000

=cut

sub parse {
	my $s = shift;
	my $f = $s->parent->bfile;
	my $h = $s->parent->header;
	my $n = $s->parent->netsunits;

	my $skip   = 'x[' . ($h->networkCount-1)*2 .  ']';
	my $b = $f->get_bytes( 2 * $h->unitCount * $h->networkCount);
	foreach my $idxNet (0..$h->networkCount-1) {
		my $format = 'x[' . $idxNet * 2  . '](S' .  $skip . ')' . ($h->unitCount-1) .  'S';
		my @azimut = unpack($format,$b);
		foreach my $idxUnit (0..$h->unitCount-1) {
			my $unit = $n->at($idxNet,$idxUnit);
			my $azimut = $azimut[$idxUnit];
			if ($azimut > 10000) {
				$unit->direction($azimut - 10000);
	            $unit->azimut(0);
			} else {
				$unit->azimut($azimut/10);
				$unit->direction('');
			}
		}
	}
}
sub write {
	my $s = shift;
	my $f = $s->parent->bfile;
	my $h = $s->parent->header;
	my $n = $s->parent->netsunits;

	foreach my $idxUnit (0..$h->unitCount-1) {
		foreach my $idxNet (0..$h->networkCount-1) {
			my $unit = $n->at($idxNet,$idxUnit);
			if ($unit->direction eq '' || $unit->direction == 0) {
				$f->put_bytes(pack('S',$unit->azimut*10));
			} else {
				$f->put_bytes(pack('S',$unit->direction+10000));
			}
		}
	}
}


1;

__END__
