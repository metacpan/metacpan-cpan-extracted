package Protocol::DBus::Authn::Mechanism;

use strict;
use warnings;

use constant INITIAL_RESPONSE => ();
use constant AFTER_AUTH => ();
use constant AFTER_OK => ();

sub new { return bless {}, shift }

sub label {
    my $class = ref($_[0]) || $_[0];

    return substr( $class, 1 + rindex($class, ':') );
}

1;
