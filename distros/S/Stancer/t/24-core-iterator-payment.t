#! /usr/bin/env perl

use 5.020;
use strict;
use warnings;

use lib './t/unit';
use Stancer::Core::Iterator::Payment::Test;

Test::Class->runtests;
