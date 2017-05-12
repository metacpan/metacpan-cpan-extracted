package RadioMobile::UnitsHeightParser;

use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

our $VERSION    = '0.10';

__PACKAGE__->valid_params( 
							bfile	=> {isa => 'File::Binary'},
							header => {isa => 'RadioMobile::Header'},
							netsunits => {isa => 'RadioMobile::NetsUnits'},
);

use Class::MethodMaker [ scalar => [qw/header netsunits bfile/] ];

=head1 NAME

RadioMobile::UnitsHeightParser

=head1 DESCRIPTION

This module parse the height of every units in every network. If height is 0
then default system height has taken
It update the RadioMobile::NetsUnits object args passed in new invoke.

=head1 METHODS

=head2 new()

Parameters:

    bfile     => {isa => 'File::Binary'},
    header    => {isa => 'RadioMobile::Header'},
    netsunits => {isa => 'RadioMobile::NetsUnits'}

=cut

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	return $s;
}

=head2 parse()

This method read the .net file in bfile and exctract 
size $header->networkCount * $header->unitCount * 4 bytes
Given A,B,C... units and 1,2,3 Network so A1 is a float 
indicate the height of unit A in network 1 
It's structure is 
A1 A2 A3 ... B1 B2 B3 ... C1 C2 C3 ...

=cut

sub parse {
	my $s = shift;
	my $f = $s->bfile;
	my $h = $s->header;
	my $n = $s->netsunits;

	my $skip   = 'x[' . ($h->networkCount-1)*4 .  ']';
	my $b = $f->get_bytes( 4 * $h->unitCount * $h->networkCount);
	foreach my $idxNet (0..$h->networkCount-1) {
		my $format = 'x[' . $idxNet * 4  . '](f' .  $skip . ')' . ($h->unitCount-1) .  'f';
		my @height = unpack($format,$b);
		foreach my $idxUnit (0..$h->unitCount-1) {
			$n->at($idxNet,$idxUnit)->height($height[$idxUnit]);
		}
	}
}

sub write {
	my $s = shift;
	my $f = $s->bfile;
	my $h = $s->header;
	my $n = $s->netsunits;
	foreach my $idxUnit (0..$h->unitCount-1) {
		foreach my $idxNet (0..$h->networkCount-1) {
			$f->put_bytes(pack("f",$n->at($idxNet,$idxUnit)->height));
		}
	}
	
}

1;

__END__
