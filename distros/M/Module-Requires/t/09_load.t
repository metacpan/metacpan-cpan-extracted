use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Module::Requires -autoload, 'ClassH';

is(export(), 'OK');

done_testing;
