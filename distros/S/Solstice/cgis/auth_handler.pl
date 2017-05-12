#!/usr/bin/perl

use 5.006_000;
use strict;
use warnings;

use Solstice::Controller::Application::Auth;

Solstice::Controller::Application::Auth->new()->processAuthentication();

