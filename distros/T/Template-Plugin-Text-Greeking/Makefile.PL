use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/Template/Plugin/Text/Greeking.pm';

requires
    'UNIVERSAL::require'    => 0.13,
    'Template'              => 2.22,
    'Text::Greeking'        => 0.12,
    'Text::Greeking::zh_TW' => 1.0;

build_requires  'Test::More'        => '0.42';

WriteAll;


