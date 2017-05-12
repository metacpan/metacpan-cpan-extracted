#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Mutex;

{
    my $mutex = Mutex->new( impl => 'Channel' );

    is( $mutex->impl(), 'Channel', 'implementation name 1' );
}
{
    my $mutex = Mutex->new();

    is( $mutex->impl(), 'Channel', 'implementation name 2' );
}

done_testing;

