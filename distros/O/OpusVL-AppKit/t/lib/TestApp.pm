package TestApp;

use strict;
use warnings;

our $VERSION = '0.3';

use TestApp::Builder;

TestApp::Builder->new( appname => __PACKAGE__, version => $VERSION )->bootstrap;


1;
