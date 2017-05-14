package PingCommon;

use strict;
use warnings;

use constant SERVICE_NAME => 'com.trolltech.QtDBus.PingExample';

require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw( SERVICE_NAME );

1;
