package Net::ACME2::X::UnrecognizedKey;

use strict;
use warnings;

use parent qw( Net::ACME2::X::Generic );

sub new {
    my ($class, $pem) = @_;

    return $class->SUPER::new("Unrecognized private key:\n$pem");
}

1;
