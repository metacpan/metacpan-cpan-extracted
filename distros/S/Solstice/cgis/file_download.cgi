#!/usr/bin/perl

use 5.006_000;
use strict;
use warnings;

use Solstice::CGI;
use Solstice::Controller::Resource::File::Download;
use Solstice::Server;

my $controller = Solstice::Controller::Resource::File::Download->new();

my $view = $controller->getView();
$view->setIsInline(param('inline') ? 1 : 0);
$view->sendHeaders();
Solstice::Server->new()->printHeaders();
$view->printData();
