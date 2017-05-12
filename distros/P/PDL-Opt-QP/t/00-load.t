#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use PDL::LiteF;
use PDL::Opt::QP;

ok( defined &{'ok'}, "ok" );
ok( defined &{'qpgen2'}, "qpgen2 exists" );
ok( defined &{'qp'}, "qp exists" );
ok( defined &{'qp_orig'}, "qp_orig exists" );

done_testing;
