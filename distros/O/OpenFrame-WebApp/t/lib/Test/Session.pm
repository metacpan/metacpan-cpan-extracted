package Test::Session;

use base qw( OpenFrame::WebApp::Session );

OpenFrame::WebApp::Session->types->{test} = __PACKAGE__;

1;
