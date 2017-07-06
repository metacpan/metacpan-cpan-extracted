#!perl

use 5.008001;

use strict;
use warnings FATAL => 'all';

use Test::More;
use Moo;

use_ok('MooX::Options') or BAIL_OUT("Couldn't load MooX::Options");
use_ok('MooX::Options::Role')
    or BAIL_OUT("Couldn't load MooX::Options::Role");
use_ok('MooX::Options::Descriptive')
    or BAIL_OUT("Couldn't load MooX::Options::Descriptive");
use_ok('MooX::Options::Descriptive::Usage')
    or BAIL_OUT("Couldn't load MooX::Options::Descriptive::Usage");

diag("Testing MooX::Options $MooX::Options::VERSION, Perl $], $^X");

done_testing();
