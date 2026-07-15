#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok('Mojolicious::Plugin::Fondation::OpenAPI');
can_ok('Mojolicious::Plugin::Fondation::OpenAPI', 'VERSION');

use_ok('Mojolicious::Plugin::Fondation::OpenAPI::Command::openapi');
can_ok('Mojolicious::Plugin::Fondation::OpenAPI::Command::openapi', 'VERSION');

done_testing;
