package Module::Build::Pluggable::T1;
use strict;
use warnings;
use utf8;
use parent qw/Module::Build::Pluggable::Base/;

our $CONFIGURE_CALLED = 0;
sub HOOK_configure {
    ::note "CONFIGURE";
    $CONFIGURE_CALLED++;
}

our $BUILD_CALLED = 0;
sub HOOK_build {
    $BUILD_CALLED++;
}

1;

