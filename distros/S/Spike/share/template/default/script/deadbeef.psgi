#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use DeadBeef::Site;

DeadBeef::Site->run;
