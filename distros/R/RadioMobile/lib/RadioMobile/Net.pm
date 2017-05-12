package RadioMobile::Net;

use strict;
use warnings;

use Data::Dumper;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

use File::Binary;

our $VERSION    = '0.10';

# NET STRUCTURE - Len 72 bytes
# MINFX				([f] single-precision float - VB Single type - 4 bytes),
# MAXFX				([f] single-precision float - VB Single type - 4 bytes),
# POL				([s] signed short - VB Integer type - 2 bytes),
# EPS				([f] single-precision float - VB Single type - 4 bytes),
# SGM				([f] single-precision float - VB Single type - 4 bytes),
# ENS				([f] single-precision float - VB Single type - 4 bytes),
# CLIMATE			([s] signed short - VB Integer type - 2 bytes),
# MDVAR				([s] signed short - VB Integer type - 2 bytes),
# TIME				([f] single-precision float - VB Single type - 4 bytes),
# LOCATION			([f] single-precision float - VB Single type - 4 bytes),
# SITUATION			([f] single-precision float - VB Single type - 4 bytes),
# HOPS				([s] signed short - VB Integer type - 2 bytes),
# TOPOLOGY			([s] signed short - VB Integer type - 2 bytes),
# NAME				([A] ASCII string - VB String*30 - 30 bytes),

use constant LEN	=> 72;
use constant PACK	=> 'ffsfffssfffssA30';
use constant ITEMS	=> qw/minfx maxfx pol eps sgm ens climate mdvar time location
							situation hops topology name unknown1/;
use constant DEFAULTS => qw/144 148 1 15 0.00499999988824129 301 5 0 50 50 70 0 256 Net1 0/;


__PACKAGE__->valid_params ( map {(ITEMS)[$_] =>{type=>SCALAR, default=> (DEFAULTS)[$_]}} (0..(ITEMS)-1));
use Class::MethodMaker [scalar => [ITEMS,'idx']];

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	return $s;
}

sub dump {
	my $s	= shift;
	return Data::Dumper::Dumper($s->dump_parameters);
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

sub reset {
	my $s	= shift;
	my $index = shift;
	map {$s->{(ITEMS)[$_]} = (DEFAULTS)[$_]} (0..(ITEMS)-1);
	$s->name(sprintf('Net%3.3s', $index));
}

1;

__END__
