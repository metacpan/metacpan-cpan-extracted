#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Protocol::IR::Code');
use_ok('Protocol::IR::Converter');
use_ok('Protocol::IR::Format::CSV');
use_ok('Protocol::IR::Format::Mode2');
use_ok('Protocol::IR::Format::Pronto');
use_ok('Protocol::IR::Format::Tasmota');
use_ok('Protocol::IR::Format::Wig');
use_ok('Protocol::IR::Proto::JVC');
use_ok('Protocol::IR::Proto::JVC48');
use_ok('Protocol::IR::Proto::MWM');
use_ok('Protocol::IR::Proto::NEC');
use_ok('Protocol::IR::Proto::NEC2');
use_ok('Protocol::IR::Proto::NEC48');
use_ok('Protocol::IR::Proto::NEC482');
use_ok('Protocol::IR::Proto::NECX1');
use_ok('Protocol::IR::Proto::NECX2');
use_ok('Protocol::IR::Proto::SAMSUNG');
use_ok('Protocol::IR::Proto::SAMSUNG20');
use_ok('Protocol::IR::Proto::SAMSUNG36');

done_testing;
