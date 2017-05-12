package RadioMobile::SystemCableLossParser;

use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

our $VERSION    = '0.10';

__PACKAGE__->valid_params( parent => { isa  => 'Class::Container'} ) ;
use Class::MethodMaker [ scalar => [qw/parent/] ];

=head1 NAME

RadioMobile::SystemCableLossParser

=head1 DESCRIPTION

This module parse the cable loss of every system
It update the RadioMobile::System in RadioMobile::Systems.

=head1 METHODS

=head2 new()

=cut

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	return $s;
}

=head2 parse()

=cut

sub parse {
	my $s = shift;
	my $f = $s->parent->bfile;
	my $l = $s->parent->header->systemCount;
	my $o = $s->parent->systems;

	$b = $f->get_bytes( 4 * $l);
	my @lineLossPerMeter = unpack("f" . $l,$b);

	foreach (0..$l-1) {
		$o->at($_)->cableloss($lineLossPerMeter[$_]);
	}
}

sub write {
	my $s = shift;
	my $f = $s->parent->bfile;
	my $l = $s->parent->header->systemCount;
	my $o = $s->parent->systems;

	foreach (0..$l-1) {
		$f->put_bytes(pack('f',$o->at($_)->cableloss));
	}
}


1;

__END__
