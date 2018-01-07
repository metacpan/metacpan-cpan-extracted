#!/usr/bin/env perl

use Test::Most tests => 1;

use Renard::Incunabula::Devel::TestHelper;

subtest "TestHelper class methods" => sub {
	can_ok 'Renard::Incunabula::Devel::TestHelper', 'test_data_directory';
};

done_testing;
