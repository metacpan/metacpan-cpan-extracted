package PkgConfig::LibPkgConf::XS;

use strict;
use warnings;

our $VERSION = '0.07';

require XSLoader;
XSLoader::load('PkgConfig::LibPkgConf', $VERSION);

1;
