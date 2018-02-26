#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../t/lib";
use lib "$Bin/../lib";

use Plack::App::FakeApache;

# To test a minimal mod_perl handler with overridden request class.

Plack::App::FakeApache->new(
    handler    => 'DumbHandler',
    dir_config => {},
)->to_app;
