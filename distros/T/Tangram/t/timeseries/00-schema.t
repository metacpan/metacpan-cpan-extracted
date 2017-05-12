#!/usr/bin/perl -w

BEGIN { $Tangram::TRACE = \*STDERR }

use strict;
use lib "t/timeseries";

use Prerequisites;

use Test::More tests => 2;

TimeSeries->deploy;
ok("TimeSeries database deployed succesfully");

TimeSeries->retreat;
ok("TimeSeries database retreated succesfully");
