#!/usr/bin/perl

use Test;
BEGIN {
    plan tests => 1;
}
use POE qw( Component::Pool::DBI );

ok(defined POE::Component::Pool::DBI->can("new"));
