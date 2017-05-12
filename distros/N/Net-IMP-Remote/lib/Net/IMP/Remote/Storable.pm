package Net::IMP::Remote::Storable;

use strict;
use warnings;
use Net::IMP::Remote::Protocol;
use Net::IMP qw(:DEFAULT :log);
use Net::IMP::Debug;
use Net::IMP::Remote::DualvarMapping;
use Storable ();

my $wire_version = 0x00000001;

sub new {
    bless {}, shift;
}

sub buf2rpc {
    my ($self,$rdata) = @_;
    decode:
    return if length($$rdata)<6;
    my ($len) = unpack("x2L",$$rdata);
    return if length($$rdata) - 6 < $len;
    my ($op,$args) = unpack("SL/a*",$$rdata);
    substr($$rdata,0,$len+6,'');
    $args = Storable::thaw($args);
    if ( $op == IMPRPC_SET_VERSION ) {
	die "wrong version $args->[0], can do $wire_version only"
	    if $args->[0] != $wire_version;
	return if $$rdata eq '';
	goto decode;
    } 
    return rpc_i2d([$op,@$args]);
}

sub rpc2buf {
    my ($self,$rpc) = @_;
    my ($op,@args) = @{ rpc_d2i($rpc) };
    return pack("SL/a*",$op,Storable::nfreeze(\@args));
}

sub init { 
    my ($self,$side) = @_;
    return if $side == 0;
    $self->rpc2buf([IMPRPC_SET_VERSION,$wire_version]) 
}

1;
