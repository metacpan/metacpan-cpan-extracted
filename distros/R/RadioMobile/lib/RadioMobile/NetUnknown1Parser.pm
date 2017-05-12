package RadioMobile::NetUnknown1Parser;

use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

our $VERSION    = '0.10';

__PACKAGE__->valid_params( parent => { isa  => 'Class::Container'} ) ;
use Class::MethodMaker [ scalar => [qw/parent/] ];

=head1 NAME

RadioMobile::NetUnknown1Parser

=head1 DESCRIPTION

This module parse an unknown structure of 8 byte for every network 
after StyleNetworksProperties
It updates the RadioMobile::Network in RadioMobile::Networks

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
	my $l = $s->parent->header->networkCount;
	my $o = $s->parent->nets;

	my $b = $f->get_bytes(8 * $l);
	my @u = unpack("H16" x $l,$b);

 	foreach (0..$l-1) {
		$o->at($_)->unknown1($u[$_]);
	}
}

sub write {
	my $s = shift;
	my $f = $s->parent->bfile;
	my $l = $s->parent->header->networkCount;
	my $o = $s->parent->nets;

 	foreach (0..$l-1) {
		$f->put_bytes(pack("H16",$o->at($_)->unknown1));
	}
}

1;

__END__
