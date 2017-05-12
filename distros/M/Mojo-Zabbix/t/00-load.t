#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojo::Zabbix' ) || print "Bail out!\n";
}

diag( "Testing Mojo::Zabbix $Mojo::Zabbix::VERSION, Perl $], $^X" );
