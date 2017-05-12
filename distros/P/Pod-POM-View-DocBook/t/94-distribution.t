#!/usr/bin/perl
# $Id: 94-distribution.t 4092 2009-02-24 17:46:48Z andrew $

use strict;

use Test::More;

use Cwd qw(abs_path);
use FindBin qw($Bin);

use lib ($Bin, "$Bin/../lib");

BEGIN {
    eval {
        require Test::Distribution;
    };
    if($@) {
        plan skip_all => 'Test::Distribution not installed';
    }
    else {
        import Test::Distribution;
    }
}
