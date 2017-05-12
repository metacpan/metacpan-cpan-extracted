#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use Test::More;

BEGIN {
    use_ok('Prancer::Plugin::Database');
    use_ok('Prancer::Plugin::Database::Driver');
    use_ok('Prancer::Plugin::Database::Driver::Mock');
    use_ok('Prancer::Plugin::Database::Driver::SQLite');
    use_ok('Prancer::Plugin::Database::Driver::Pg');
    use_ok('Prancer::Plugin::Database::Driver::MySQL');
};

done_testing();

