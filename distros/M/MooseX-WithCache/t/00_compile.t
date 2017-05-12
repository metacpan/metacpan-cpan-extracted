use strict;
use Test::More (tests => 1);

{
    package Hoge; # This is just a hack to silence Moose::Exporter
    Test::More::use_ok( "MooseX::WithCache" );
}