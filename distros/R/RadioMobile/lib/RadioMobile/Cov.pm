package RadioMobile::Cov;

use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

use File::Binary;

our $VERSION    = '0.10';

# COVERAGE STRUCTURE - Len 74 bytes
# DMAX				([f] single-precision float - VB Single type - 4 bytes),
# THMIN				([f] single-precision float - VB Single type - 4 bytes),
# THMAX				([f] single-precision float - VB Single type - 4 bytes),
# THINC				([f] single-precision float - VB Single type - 4 bytes),
# ANTAZT			([f] single-precision float - VB Single type - 4 bytes),
# FILE				([A] ASCII string - VB String*20 - 20 bytes),
# TRESHOLD			([s] signed short - VB Integer type - 2 bytes),
# LEVEL				([f] single-precision float - VB Single type - 4 bytes),
# AREA				([S] unsigned short - VB Boolean - 2 bytes, non credo bool)
# CAREA				([l] signed long - VB Integer type - 4 bytes),
# CONTOUR			([S] unsigned short - VB Boolean - 2 bytes)
# CCONTOUR			([l] signed long - VB Integer type - 4 bytes),
# VHS				([f] single-precision float - VB Single type - 4 bytes),
# VHT				([f] single-precision float - VB Single type - 4 bytes),
# DMIN				([f] single-precision float - VB Single type - 4 bytes),
# VCOL				([l] signed long - VB Integer type - 4 bytes),
use constant LEN	=> 74;
use constant PACK	=> 'fffffA20sfSlSlfffl';
use constant ITEMS	=> qw/dmax thmin thmax thinc antazt file treshold level
							area carea contour ccontour vhs vht dmin vcol/;

__PACKAGE__->valid_params ( map {$_ => {type => SCALAR, default => 1}} (ITEMS));
use Class::MethodMaker [scalar => [ITEMS]];

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	return $s;
}

sub parse {
	my $s		= shift;
	my $f	  	= shift;
	my @struct 	= unpack(PACK,$f->get_bytes(LEN));
	map {$s->{(ITEMS)[$_]} = $struct[$_]} (0..(ITEMS)-1);
}

sub write {
	my $s	 	= shift;
	my $f	  	= shift;
	$f->put_bytes(pack(PACK, map ($s->{(ITEMS)[$_]},(0..(ITEMS)-1))));
}

sub dump {
	my $s   = shift;
	return Data::Dumper::Dumper($s->dump_parameters);
}
1;

__END__
