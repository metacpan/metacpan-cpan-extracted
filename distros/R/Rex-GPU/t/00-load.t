#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Rex::GPU');
use_ok('Rex::GPU::Detect');
use_ok('Rex::GPU::Detect::Sysfs');
use_ok('Rex::GPU::AMD');
use_ok('Rex::GPU::AMD::Hardware');
use_ok('Rex::GPU::AMD::Setup');
use_ok('Rex::GPU::AMD::Setup::Apt');
use_ok('Rex::GPU::AMD::Setup::Debian');
use_ok('Rex::GPU::AMD::Setup::RHEL');
use_ok('Rex::GPU::AMD::Setup::Ubuntu');
use_ok('Rex::GPU::NVIDIA');
use_ok('Rex::GPU::NVIDIA::Requirement');
use_ok('Rex::GPU::NVIDIA::VGPU');

done_testing;
