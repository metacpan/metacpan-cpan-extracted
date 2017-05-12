package RadioMobile::SystemAntennaParser;

use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

our $VERSION    = '0.10';

__PACKAGE__->valid_params( parent => { isa  => 'Class::Container'} ) ;
use Class::MethodMaker [ scalar => [qw/parent/] ];

=head1 NAME

RadioMobile::SystemAntennaParser

=head1 DESCRIPTION

This module parse the antenna of every system
It updates the RadioMobile::System in RadioMobile::Systems.

=head1 METHODS

=head2 new()

=cut

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	return $s;
}

=head2 parse()

Parse first a short integer set how much structure follows for
system antenna type ('' == omni.ant)

=cut

sub parse {
	my $s = shift;
	my $f = $s->parent->bfile;
	my $o = $s->parent->systems;

	my $b = $f->get_bytes(2);
	my $systemAntennaCount = unpack("s",$b);

 	foreach (0..$systemAntennaCount-1) {
		$b = $f->get_bytes(2);
		my $antennaStringLenght = unpack("s",$b);
		unless ($antennaStringLenght == 0) {
			$b = $f->get_bytes($antennaStringLenght);
			$o->at($_)->antenna(unpack("a" . $antennaStringLenght,$b));
		} else {
			$o->at($_)->antenna('');
		}
	}
}
sub write {
	my $s = shift;
	my $f = $s->parent->bfile;
	my $h = $s->parent->header;
	my $o = $s->parent->systems;

	$f->put_bytes(pack("s",$h->systemCount));
 	foreach (0..$h->systemCount-1) {
		my $antennaName = $o->at($_)->antenna;
		$f->put_bytes(pack('s',length($antennaName)));
		$f->put_bytes(pack('a' . length($antennaName),$antennaName));
	}
}

1;

__END__
