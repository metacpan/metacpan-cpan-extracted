package Net::WebSocket::Base::ReadString;

use strict;
use warnings;

use Net::WebSocket::X ();

sub new {
    my ($class, $str_sr) = @_;

    return bless { _sr => $str_sr }, $class;
}

sub _read {
    my ($self, $len) = @_;

    die "Useless zero read!" if $len == 0;

    return substr( ${ $self->{'_sr'} }, 0, $len, q<> );
}

1;
