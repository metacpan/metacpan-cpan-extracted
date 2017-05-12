use strict;
use inc::Module::Install;

name        'Scalar-Defer';
all_from    'lib/Scalar/Defer.pm';

requires    'Class::InsideOut';
requires    'Exporter::Lite';

include_deps 'ok';
include_deps 'Test::More';

auto_install;
auto_provides;

sign;
WriteAll;

warn "\n\n\n".<<EOT."\n" if $] == 5.008009;
************************************************************
WARNING: Performance under perl 5.8.9 can be extremely poor,
due to bad interactions between overload and bless.  You may
wish to consider upgrading to a more recent version of perl
if the performance of Scalar::Defer is important.
************************************************************
EOT
