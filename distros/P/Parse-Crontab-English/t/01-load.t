#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    use_ok( 'Parse::Crontab' ) || warn "Parse::Crontab mus be installed";
}

{
    done_testing;
}
