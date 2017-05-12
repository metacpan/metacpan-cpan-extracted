package Module::Build::Pluggable::Warn64Bit;

use strict;
use warnings;
use parent 'Module::Build::Pluggable::Base';

sub HOOK_build {
    my $self = shift;

    require PDL;
    PDL->import;

    warn <<'64BITWARNING' if defined(&PDL::indx);
== WARNING ================================================================
Building PDL::Opt::QP under a 64bit capable PDL. The module should work fine,
but it does not yet support 64bit sized piddles. If this causes problems or
you would like to see support for these large datasets, please contact the
author. The bug tracker and author's email address are included in the README.
===========================================================================
64BITWARNING

    return 1;
}

1;
