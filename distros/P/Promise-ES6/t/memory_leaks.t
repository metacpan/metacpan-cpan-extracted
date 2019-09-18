#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;

use Promise::ES6;

use FindBin;
use lib "$FindBin::Bin/lib";
use MemoryCheck;

ok 1, 'dummy assertion';

{
    my ($res, $rej);
    my $p = Promise::ES6->new( sub { ($res, $rej) = @_ } )->catch( sub {  } );

    $rej->(123);
}

done_testing();
