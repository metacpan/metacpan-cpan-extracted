package Protocol::DBus::Authn::Mechanism;

use strict;
use warnings;

use constant INITIAL_RESPONSE => ();
use constant AFTER_AUTH => ();

use constant on_rejected => ();

sub new {
    my $self = bless {}, shift;

    return $self;
}

sub label {
    my $class = ref($_[0]) || $_[0];

    return substr( $class, 1 + rindex($class, ':') );
}

1;
