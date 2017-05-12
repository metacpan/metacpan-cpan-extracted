package RadioMobile::Unit;

use strict;
use warnings;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

use File::Binary;

our $VERSION    = '0.10';

# UNIT STRUCTURE - Len 44 bytes
# LON               ([f] single-precision float - VB Single type - 4 bytes),
# LAT               ([f] single-precision float - VB Single type - 4 bytes),
# H                 ([f] single-precision float - VB Single type - 4 bytes),
# ENABLED           ([s] signed short - VB Integer type - 2 bytes),
# TRANSPARENT       ([s] signed short - VB Integer type - 2 bytes),
# FORECOLOR         ([l] signed long - VB Integer type - 4 bytes),
# BACKCOLOR         ([l] signed long - VB Integer type - 4 bytes),
# NAME              ([A] ASCII string - VB String*20 - 20 bytes),
use constant LEN	=> 44;
use constant PACK	=> 'fffssllA20';
use constant ITEMS	=> qw/lon lat h enabled transparent forecolor 
							backcolor name icon description/;
use constant DEFAULTS => (0,0,0,1,0,16777215,0,'',1,'');

__PACKAGE__->valid_params ( map {(ITEMS)[$_] =>{type=>SCALAR, default=> (DEFAULTS)[$_]}} (0..(ITEMS)-1));
use Class::MethodMaker [scalar => [ITEMS,'idx']];

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	return $s;
}

sub parse {
	my $s	 	= shift;
	my $f	  	= shift;
	my @struct 	= unpack(PACK,$f->get_bytes(LEN));
	# meno2 perche' description non sta qui
	map {$s->{(ITEMS)[$_]} = $struct[$_]} (0..(ITEMS)-2);
}

sub write {
	my $s	 	= shift;
	my $f	  	= shift;
	$f->put_bytes(pack(PACK, map ($s->{(ITEMS)[$_]},(0..(ITEMS)-1))));
}

sub dump {
	my $s	= shift;
	return Data::Dumper::Dumper($s->dump_parameters);
}

1;

__END__
