use strict;
use warnings;
use Test::More;

use_ok('Rex::GPU');
use_ok('Rex::GPU::Detect');
use_ok('Rex::GPU::NVIDIA');
use_ok('Rex::GPU::NVIDIA::Requirement');
use_ok('Rex::GPU::NVIDIA::VGPU');

done_testing;
