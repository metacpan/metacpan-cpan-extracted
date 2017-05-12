#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN
{
    # TEST
    use_ok('SVN::Pusher', "checking for loading of module");
}
