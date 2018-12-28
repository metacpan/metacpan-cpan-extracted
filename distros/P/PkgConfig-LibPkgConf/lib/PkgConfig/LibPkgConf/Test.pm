package PkgConfig::LibPkgConf::Test;

use strict;
use warnings;
use base qw( Exporter );
use PkgConfig::LibPkgConf::XS;

our $VERSION = '0.10';
our @EXPORT_OK = qw( send_error send_log );

1;
