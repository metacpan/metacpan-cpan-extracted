#!/usr/bin/perl

use strict;
use warnings;

use lib './t/lib';

use Test::More tests => 1;

use Test::Data::Split;

use File::Temp qw/tempdir/;

use IO::All qw/ io /;

use Test::Differences (qw( eq_or_diff ));

{
    eval {
        require DataSplitValidateHashTest2;
    };

    # TEST
    like(
        $@,
        qr/\AThe data contains the word 'Just'/,
        "Exception was thrown.",
    );
}
