package RadioMobile::UnitDescriptionParser;

use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

our $VERSION    = '0.10';

__PACKAGE__->valid_params( parent => { isa  => 'Class::Container'} ) ;
use Class::MethodMaker [ scalar => [qw/parent/] ];

=head1 NAME

RadioMobile::UnitDescriptionParser

=head1 DESCRIPTION

This module parse the long description of units as a structure of 2 bytes
with length of optionan long description string
It updates the RadioMobile::Unit in RadioMobile::Units

=head1 METHODS

=head2 new()

=cut

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	return $s;
}

=head2 parse()

Parse first a short integer set how much characters is long the
optional description of unit

=cut

sub parse {
	my $s = shift;
	my $f = $s->parent->bfile;
	my $o = $s->parent->units;

	my $b = $f->get_bytes(2);
	my $l = unpack("s",$b);

	foreach (0..$l-1) {
		$b = $f->get_bytes(2);
		my $descrLen = unpack("s",$b);
		unless ($descrLen == 0) {
			$b = $f->get_bytes($descrLen);
			my $description = unpack("a$descrLen", $b);
			$o->at($_)->description($description);
		}
	}
}

sub write {
	my $s = shift;
	my $f = $s->parent->bfile;
	my $h = $s->parent->header;
	my $o = $s->parent->units;

	$f->put_bytes(pack("s",$h->unitCount));

	foreach (0..$h->unitCount-1) {
		my $l = length($o->at($_)->description);
		$f->put_bytes(pack("s",$l));
		unless ($l == 0) { 
			$f->put_bytes(pack("a$l",$o->at($_)->description));
		}
	}
}

1;

__END__
