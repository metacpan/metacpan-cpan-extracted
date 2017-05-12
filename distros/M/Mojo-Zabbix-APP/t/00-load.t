#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojo::Zabbix::APP' ) || print "Bail out!\n";
}

diag( "Testing Mojo::Zabbix::APP $Mojo::Zabbix::APP::VERSION, Perl $], $^X" );
