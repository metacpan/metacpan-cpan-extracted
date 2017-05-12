use strict;
use warnings;
use Test::More;

BEGIN {
    eval 'use MooseX::Declare (); use Test::NoWarnings;';
    plan skip_all => 'MooseX::Declare and Test::NoWarnings required'
        if $@;
}

BEGIN {
    plan tests => 2;
}

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('MXD');
