package Praxo::Core;

use strict;
use warnings;

our $VERSION = '0.1.1';
our $SPEC_VERSION = '0.2.0';

sub version {
    return $VERSION;
}

sub spec_version {
    return $SPEC_VERSION;
}

1;
