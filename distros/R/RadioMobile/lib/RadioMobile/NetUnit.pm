package RadioMobile::NetUnit;

use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

our $VERSION    = '0.10';

use constant ITEMS  => qw/isIn role height azimut direction elevation/;
use constant DEFAULTS => qw/0 0 0 0 0 0/;

__PACKAGE__->valid_params(
							unit	=> { isa  => 'RadioMobile::Unit'},
							net	=> { isa  => 'RadioMobile::Net'},
							map {(ITEMS)[$_] =>{type=>SCALAR, default=> (DEFAULTS)[$_]}} (0..(ITEMS)-1),
);
__PACKAGE__->contained_objects(
	'unit'	=> 'RadioMobile::Unit',
	'net'	=> 'RadioMobile::Net',
);

use Class::MethodMaker [ scalar => [ITEMS,qw/unit net system/] ];

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	return $s;
}

sub dump {
	my $s	= shift;
	return Data::Dumper::Dumper($s->dump_parameters);
}

sub reset {
	my $s	= shift;
	map {$s->{(ITEMS)[$_]} = (DEFAULTS)[$_]} (0..(ITEMS)-1);

}

1;

__END__
