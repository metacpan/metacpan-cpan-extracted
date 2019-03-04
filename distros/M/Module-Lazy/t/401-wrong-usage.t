#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

require Module::Lazy; # no use!

lives_ok {
    Module::Lazy->import;
} "Empty usage does nothing";

throws_ok {
    Module::Lazy->import(foo => 42);
} qr([Uu]sage.*Module::Lazy.*Module::Name), "No extra arguments";

done_testing;
