#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;use lib "$FindBin::RealBin/../lib";use lib "$FindBin::RealBin/../thirdparty/lib/perl5"; # LIBDIR


use Mojolicious::Commands;

# Start command line interface for application
Mojolicious::Commands->start_app('<%= ${class} %>');
