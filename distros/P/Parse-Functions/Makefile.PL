use 5.008005;
use strict;

use inc::Module::Install 1.06;

# Configure-time dependencies MUST be done first.
# This version ensures that we have a new MakeMaker that
# WON'T load modules to determine the version.
configure_requires 'ExtUtils::MakeMaker' => '6.52';

name 'Parse-Functions';
license 'perl';
author 'Gabor Szabo C<szabgab@cpan.org>';
all_from 'lib/Parse/Functions.pm';
requires 'perl' => '5.008005';

# General dependencies
test_requires 'Test::More'        => '0.88';

no_index 'directory' => qw{ t xt eg share inc privinc };
homepage 'http://padre.perlide.org/';
bugtracker 'https://github.com/PadreIDE/Parse-Functions/issues';
repository 'https://github.com/PadreIDE/Parse-Functions';

WriteAll;

