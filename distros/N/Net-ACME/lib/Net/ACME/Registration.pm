package Net::ACME::Registration;

use strict;
use warnings;

use parent qw( Net::ACME::AccessorBase );

#Expand this as needed.
use constant _ACCESSORS => qw(
    agreement
    key
    terms_of_service
    uri
);

sub new {
    my ( $class, %opts ) = @_;

    #Silently (?) reject anything unfamiliar.
    %opts = map { ( $_ => $opts{$_} ) } _ACCESSORS();

    return $class->SUPER::new( %opts );
}

1;
