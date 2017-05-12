#!/usr/bin/perl
#

use Module::Build::PinwheelApp;
use strict;
use warnings;

# Create the Build script
my $build = Module::Build::PinwheelApp->new(
    dist_name => 'pinwheel-helloworld',
    dist_version => '0.0.1',
    dist_author => 'Pinwheel Development Team',
    dist_abstract => 'Pinwheel Example Application',
    license => 'perl',
    install_base => '/var/www/helloworld'
);

$build->create_build_script;

