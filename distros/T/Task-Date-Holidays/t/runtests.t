#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../t", "$Bin/t";

use Test::Class::Date::Holidays;

Test::Class->runtests();
