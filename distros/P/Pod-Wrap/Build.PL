#!/usr/bin/perl
# $Id: Build.PL,v 1.2 2004/01/08 03:16:12 nothingmuch Exp $

use strict;
use warnings;

use Module::Build;

our $VERSION = 0.01;

Module::Build->new(
    module_name => 'Pod::Wrap',
    license => 'perl',
    requires => {
        'perl'              => '>= 5.6.0',
        'Text::Wrap'        => 0,
        'Pod::Parser'       => 0,
    },
    script_files => [ 'scripts/podwrap' ],
    create_makefile_pl => "traditional",
)->create_build_script;
