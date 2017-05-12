package Test::Template;

use base qw( OpenFrame::WebApp::Template );

OpenFrame::WebApp::Template->types->{test} = __PACKAGE__;

sub default_processor { return {}; }
sub process_template  { return "processed"; }

1;

