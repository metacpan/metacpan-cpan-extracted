package RadioMobile::Header;

use strict;
use warnings;

use Data::Dumper;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

use File::Binary;

our $VERSION    = '0.01';

# HEADER STRUCTURE - Len 10 bytes
# VERSION 			([f] single-precision float - VB Single type - 4 bytes), 
# NETWORK ELEMENTS 	([s] signed short - VB Integer type - 2 bytes),
# UNIT ELEMENTS 	([s] signed short - VB Integer type - 2 bytes),
# SYSTEM ELEMENTS 	([s] signed short - VB Integer type - 2 bytes),

use constant LEN	=> 10;
use constant PACK	=> 'fsss';
use constant ITEMS	=> qw/version networkCount unitCount systemCount/;
use constant DEFAULTS => qw/4000 0 0 0/;

__PACKAGE__->valid_params ( map {$_ => {type => SCALAR, default => 1}} (ITEMS));
use Class::MethodMaker [scalar => [ITEMS]];

sub new {
	my $package = shift;
	my $s = $package->SUPER::new(@_);
	$s->_init;
	return $s;
}
sub parse {
	my $s		= shift;
	my $f	  	= $s->container->bfile;
	my @struct 	= unpack(PACK,$f->get_bytes(LEN));
	map {$s->{(ITEMS)[$_]} = $struct[$_]} (0..(ITEMS)-1);
}

sub write {
	my $s		= shift;
	my $f	  	= $s->container->bfile;
	$f->put_bytes(pack(PACK, map ($s->{(ITEMS)[$_]},(0..(ITEMS)-1))));
}

sub dump {
	my $s	= shift;
	return Data::Dumper::Dumper($s->dump_parameters);
}

sub _init {
	my $s	= shift;
	map {$s->{(ITEMS)[$_]} = (DEFAULTS)[$_]} (0..(ITEMS)-1);
}

1;

__END__
