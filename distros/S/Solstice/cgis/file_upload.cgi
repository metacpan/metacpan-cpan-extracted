#!/usr/bin/perl

use 5.006_000;
use strict;
use warnings;

use Solstice::Controller::Resource::File::Upload;

my $controller = Solstice::Controller::Resource::File::Upload->new();

my $view = $controller->getView();
$view->sendHeaders();
Solstice::Server->new()->printHeaders();
$view->printData();
