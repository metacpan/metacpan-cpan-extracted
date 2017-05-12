#!/usr/bin/env perl -w
use strict;
use warnings;
use Sys::Info qw(OSID);
use Data::Dumper;
use Test::More qw( no_plan );

ok( defined &OSID, 'OSID defined' );

ok( my $info = Sys::Info->new      , 'Sys::Info object is defined' );
ok( my $os   = $info->os           , 'OS object is defined'        );
ok( my $cpu  = $info->device('CPU'), 'CPU object is defined'       );

ok( defined $os->name  , 'OS object called with name'      );
ok( $cpu->identify || 1, 'CPU object called with identify' );

ok( defined $info->perl      , 'Able to call perl()'       );
ok( defined $info->perl_build, 'Able to call perl_build()' );
ok( defined $info->perl_long , 'Able to call perl_long()'  );
ok( $info->httpd || 1        , 'Able to call httpd()'      );
