#!/usr/bin/perl -w

use strict;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# The name of your distribution
name            'SDL-App-FPS';

# Get most of the details from the primary module
all_from        'lib/SDL/App/FPS.pm';

requires
	'SDL'				=> '2.1.3',
	'Config::Simple'		=> '4.48',
	'Games::OpenGL::Font::2D'	=> '0.07',
	'Games::Console'		=> '0.04';

recommends      'Math::Fractal::Mandelbrot'   => 0.04;

build_requires  'Test::More'    => 0.42;

license         'gpl';          # v2.0 only

author          'Tels';

# Do not index these
no_index        directory       => 'examples';

libs		'-lSDL';

# Auto-install all dependencies from CPAN
auto_install;

# Generate the Makefile
WriteAll;
