#!/usr/bin/env perl -w    # -*- cperl -*-
use strict;
use warnings;
use 5.014000;
use utf8;

use Test::More;

our $VERSION = 0.103;

BEGIN {
    if ( not $ENV{'RELEASE_TESTING'} ) {
        plan 'skip_all' => 'these tests are for release candidate testing';
    }
}

use Test::Kwalitee 'kwalitee_ok';
kwalitee_ok();
done_testing;
