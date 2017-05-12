#!/usr/bin/env perl
#
# $Id: 02pod.t,v 1.3 2007/05/04 07:33:34 hironori.yoshida Exp $
#
use strict;
use warnings;
use version; our $VERSION = qv('1.3.1');

use blib;
use English qw(-no_match_vars);
use Test::More;

if ( $ENV{TEST_POD} || $ENV{TEST_ALL} || !$ENV{HARNESS_ACTIVE} ) {
    eval {
        require Test::Pod;
        Test::Pod->import;
    };
    if ($EVAL_ERROR) {
        plan skip_all => 'Test::Pod required for testing POD';
    }
}
else {
    plan skip_all => 'set TEST_POD for testing POD';
}

all_pod_files_ok();
