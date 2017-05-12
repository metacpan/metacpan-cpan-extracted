package Net::WAMP::X::NoSuchSubscription;

use strict;
use warnings;

use parent 'X::Tiny::Base';

sub _new {
    my ($class, $realm, $subscription) = @_;

    return $class->SUPER::_new(
        "The realm “$realm” has no subscription with ID “$subscription”.",
        realm => $realm,
        subscription => $subscription,
    );
}

1;
