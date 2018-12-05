#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use MySQL::Workbench::Parser;

my $parser = MySQL::Workbench::Parser->new(
    file => __FILE__,
);


dies_ok { $parser->tables } "can't read file";

done_testing();
