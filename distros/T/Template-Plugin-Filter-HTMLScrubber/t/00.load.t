#!perl -T

use Test::Base;

plan tests => 1;

use_ok('Template::Plugin::Filter::HTMLScrubber');

diag( "Testing Template::Plugin::Filter::HTMLScrubber $Template::Plugin::Filter::HTMLScrubber::VERSION" );
