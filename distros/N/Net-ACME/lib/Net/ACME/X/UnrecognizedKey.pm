package Net::ACME::X::UnrecognizedKey;

use strict;
use warnings;

use parent qw( Net::ACME::X::HashBase );

sub new {
    my ($class, $pem) = @_;

    return $class->SUPER::new("Unrecognized private key:\n$pem");
}

1;
