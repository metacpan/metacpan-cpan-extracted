package RadioMobile::System;

use strict;
use warnings;

use Data::Dumper;

use Class::Container;
use Params::Validate qw(:types);
use base qw(Class::Container);

use File::Binary;

our $VERSION    = '0.10';

# SYSTEM STRUCTURE - Len 50 bytes
# TX                ([f] single-precision float - VB Single type - 4 bytes),
# RX                ([f] single-precision float - VB Single type - 4 bytes),
# LOSS              ([f] single-precision float - VB Single type - 4 bytes),
# ANT               ([f] single-precision float - VB Single type - 4 bytes),
# H                 ([f] single-precision float - VB Single type - 4 bytes),
# NAME              ([A] ASCII string - VB String*30 - 30 bytes),

use constant LEN	=> 50;
use constant PACK	=> 'fffffA30';
use constant ITEMS	=> qw/tx rx loss ant h name cableloss antenna/;
use constant DEFAULTS => qw/10 -107 0.5 2 2 System1 0 omni.ant/;

__PACKAGE__->valid_params ( map {(ITEMS)[$_] =>{type=>SCALAR, default=> (DEFAULTS)[$_]}} (0..(ITEMS)-1));
use Class::MethodMaker [scalar => [ITEMS,'idx']];

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
	my $s	= shift;
	return Data::Dumper::Dumper($s->dump_parameters);
}

sub reset {
	my $s	= shift;
	my $index = shift;
	map {$s->{(ITEMS)[$_]} = (DEFAULTS)[$_]} (0..(ITEMS)-1);
	$s->name(sprintf('System%4.4s', $index));
}

1;

__END__
