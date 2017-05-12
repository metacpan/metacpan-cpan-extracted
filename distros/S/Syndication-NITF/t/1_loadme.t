#!/usr/bin/perl -w
use strict;
use Test;

BEGIN {
#    require "t/TestDetails.pm"; import TestDetails;
    plan tests => 1;

    $SIG{__WARN__} = sub {
       ok(0);
       exit;
    }
}

# Check that we compile without warnings.
use Syndication::NITF;
ok(1);
