#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../t/lib";
use lib "$Bin/../lib";

# To test a minimal mod_perl handler.

use Plack::App::FakeApache;

Plack::App::FakeApache->new(
    handler    => 'DumbHandler',
    dir_config => {},
    request_class => 'TestRequest',
)->to_app;
