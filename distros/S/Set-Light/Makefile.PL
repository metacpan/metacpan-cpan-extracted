
# We need at least Perl 5.6
require 5.006;
use strict;

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

name		'Set-Light';

# Get most of the details from the primary module
all_from	'lib/Set/Light.pm';

requires	'Array::RefElem'	=> 0;

build_requires	'Test::More'	=> 0.62;

license		'perl';

author		'Tels <nospam-abuse@bloodgate.com>';

# Generate the Makefile
WriteAll;
