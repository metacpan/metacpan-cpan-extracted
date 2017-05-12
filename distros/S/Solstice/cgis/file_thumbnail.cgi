#!/usr/bin/perl

use 5.006_000;
use strict;
use warnings;

use Solstice::Server;
use Solstice::Controller::Resource::File::Download;

my $controller = Solstice::Controller::Resource::File::Download->new();

my $server = Solstice::Server->new();
my $view = $controller->getView();
$view->setIsThumbnail(1);
$view->setIsInline(1);
$view->sendHeaders();
Solstice::Server->new()->printHeaders();
$view->printData();
