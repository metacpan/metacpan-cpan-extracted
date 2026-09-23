package PostCopyFailure;

use strict;
use warnings;

use Module::Build::SysPath;

no warnings 'redefine'; ## no critic (TestingAndDebugging::ProhibitNoWarnings)
*Module::Build::SysPath::_spc_rename = sub {
    die "injected post-copy SPc failure\n";
};

1;
