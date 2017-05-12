package Net::IMP::Remote::Sereal;

use strict;
use warnings;
use Net::IMP::Remote::Protocol;
use Net::IMP qw(:DEFAULT :log);
use Net::IMP::Debug;
use Net::IMP::Remote::DualvarMapping;
use Sereal::Encoder 0.36;
use Sereal::Decoder 0.36;

my $wire_version = 0x00000001;

sub new {
    bless {
	encoder => Sereal::Encoder->new,
	decoder => Sereal::Decoder->new({ incremental => 1 }),
    }, shift;
}

sub buf2rpc {
    my ($self,$rdata) = @_;
    decode:
    my $out = undef;
    eval { $self->{decoder}->decode( $$rdata, $out ) } or return;
    return if ! $out;
    if ( $out->[0] == IMPRPC_SET_VERSION ) {
	die "wrong version $out->[1], can do $wire_version only"
	    if $out->[1] != $wire_version;
	return if $$rdata eq '';
	goto decode;
    } 
    return rpc_i2d($out);
}

sub rpc2buf {
    my ($self,$rpc) = @_;
    $self->{encoder}->encode(rpc_d2i($rpc))
}

sub init { 
    my ($self,$side) = @_;
    return if $side == 0;
    $self->rpc2buf([IMPRPC_SET_VERSION,$wire_version]) 
}

1;
