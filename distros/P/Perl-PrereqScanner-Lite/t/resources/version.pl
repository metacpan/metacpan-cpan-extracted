#!/usr/bin/env perl

use strict;
use warnings;

use POSIX;
use Fnctrl;
use Carp;

POSIX->VERSION(1);
Fnctrl->VERSION(1.00);
Carp->VERSION(v1.0.0);
Cwd->VERSION(1000); # <= should be ignored
