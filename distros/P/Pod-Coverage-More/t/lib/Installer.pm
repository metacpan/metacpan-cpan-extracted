package Installer;

# Installs a named sub into the package that loads it, as a class builder installs an accessor.

use 5.036;
use warnings FATAL => q{all};

use Sub::Util qw{set_subname};

sub import {
    my $caller = caller;
    no strict q{refs};
    *{"${caller}::helper"} = set_subname( "${caller}::helper", sub { return 1 } );
    return;
}

1;
