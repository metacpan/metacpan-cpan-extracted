#!/usr/bin/perl
use strict;
use warnings;

use Plack::Util;
use Plack::Loader;
my $app = Plack::Util::load_psgi("app.psgi");
Plack::Loader->auto->run($app);
