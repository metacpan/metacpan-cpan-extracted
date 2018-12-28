package PkgConfig::LibPkgConf::XS;

use strict;
use warnings;

our $VERSION = '0.10';

require XSLoader;
XSLoader::load('PkgConfig::LibPkgConf', $VERSION);

1;
