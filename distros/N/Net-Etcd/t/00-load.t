#!perl

use Test::More tests => 1;

BEGIN {
    $ENV{PATH} = '/bin:/usr/bin';
    use_ok( 'Net::Etcd' ) || print "Bail out!
";
}

diag( "Testing Net::Etcd $Net::Etcd::VERSION, Perl $], $^X" );
