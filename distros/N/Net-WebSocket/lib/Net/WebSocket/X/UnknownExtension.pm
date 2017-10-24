package Net::WebSocket::X::UnknownExtension;

use strict;
use warnings;

use parent qw( Net::WebSocket::X::Base );

sub _new {
    my ($class, $extension) = @_;

    my $disp_val = $extension;
    $disp_val = q<> if !defined $disp_val;

    return $class->SUPER::_new(
        "The server’s handshake included an unknown extension, “$disp_val”.",
        extension => $extension,
    );
}

1;
