use inc::Module::Install;
use strict;
use warnings;

name 'Sub-AliasedUnderscore';
all_from 'lib/Sub/AliasedUnderscore.pm';
license 'Perl';

build_requires 'ok';

WriteAll();
