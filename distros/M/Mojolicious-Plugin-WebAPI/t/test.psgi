#!/usr/bin/env perl

use FindBin;
BEGIN { unshift @INC, "$FindBin::Bin/lib", "$FindBin::Bin/../lib" }

# Start command line interface for application

require Mojolicious::Commands;
Mojolicious::Commands->start_app('ApiTest');
