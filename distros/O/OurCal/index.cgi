#!/usr/local/bin/perl  -w

use lib 'lib';
use CGI::Carp qw(fatalsToBrowser);
use strict;
use OurCal;
use OurCal::Config;
use OurCal::Handler::CGI;
use OurCal::View;


$|++;

my $config    = OurCal::Config->new( file => 'ourcal.conf' );
my $handler   = OurCal::Handler::CGI->new( config => $config );
my $cal       = OurCal->new( date => $handler->date, user => $handler->user, config => $config );
my $view      = OurCal::View->load_view($handler->view, handler => $handler, config => $config->config, calendar => $cal); 


print $handler->header($view->mime_type);
print $view->handle();

