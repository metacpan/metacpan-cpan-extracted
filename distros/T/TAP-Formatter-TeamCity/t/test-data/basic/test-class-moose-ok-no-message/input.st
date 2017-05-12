use strict;
use warnings;

use lib 't/lib';

use Test::Class::Moose::Runner;

use TAP::Formatter::TeamCity::Test::OKNoMessage;

Test::Class::Moose::Runner
    ->new(test_classes => [qw(TAP::Formatter::TeamCity::Test::OKNoMessage)])
    ->runtests;

