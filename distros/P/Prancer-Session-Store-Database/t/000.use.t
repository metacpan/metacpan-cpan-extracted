#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More;

BEGIN {
    use_ok('Prancer::Session::Store::Database');
    use_ok('Prancer::Session::Store::Database::Driver');
    use_ok('Prancer::Session::Store::Database::Driver::Mock');
    use_ok('Prancer::Session::Store::Database::Driver::MySQL');
    use_ok('Prancer::Session::Store::Database::Driver::Pg');
    use_ok('Prancer::Session::Store::Database::Driver::SQLite');
};

done_testing();

