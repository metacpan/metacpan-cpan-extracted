#!/usr/bin/env perl

use strict;
use warnings;

use Tapper::Reports::Web;
my $or_app = Tapper::Reports::Web->psgi_app(@_);