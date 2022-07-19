package Net::LibNFS::X::NFSError;

use strict;
use warnings;

use parent qw( Net::LibNFS::X::Base );

sub new {
    my ( $class, $from_func, $errno, $errstr, @props_kv ) = @_;

    return $class->SUPER::new(
        "$from_func failed (code=$errno): $errstr",
        from => $from_func,
        errno => $errno,
        error_string => $errstr,
        @props_kv,
    );
}

1;

