#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More;

BEGIN {
    use_ok('Prancer');
    use_ok('Prancer::Core');
    use_ok('Prancer::Config');
    use_ok('Prancer::Plugin');
    use_ok('Prancer::Request');
    use_ok('Prancer::Request::Upload');
    use_ok('Prancer::Response');
    use_ok('Prancer::Session');
    use_ok('Prancer::Session::State::Cookie');
    use_ok('Prancer::Session::Store::Memory');
    use_ok('Prancer::Session::Store::Storable');
};

done_testing();
