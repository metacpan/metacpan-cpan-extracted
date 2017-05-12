package Net::WAMP::X::NoSuchRegistration;

use strict;
use warnings;

use parent 'X::Tiny::Base';

sub _new {
    my ($class, $realm, $registration) = @_;

    return $class->SUPER::_new(
        "The realm “$realm” has no registration with ID “$registration”.",
        realm => $realm,
        registration => $registration,
    );
}

1;
