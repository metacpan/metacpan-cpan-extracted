#!perl

use strict;
use warnings;

use CGI::Application::Miril;

my $app = CGI::Application::Miril->new( PARAMS => { 
	miril_dir => 'example',
	site      => 'example.com',
});

$app->run
