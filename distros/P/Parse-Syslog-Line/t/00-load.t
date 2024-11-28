#!perl

use FindBin;
use Test::More;

use lib "$FindBin::Bin/lib";
use test::Data;

diag( "Testing Parse::Syslog::Line $Parse::Syslog::Line::VERSION, Perl $], $^X" );
use_ok( 'Parse::Syslog::Line' );

my $tests = get_test_data();
is( ref $tests, 'HASH', "test::Data::get_tests() loads a hash" );
ok( keys %{$tests},     "test::Data::get_tests() loads tests!" );
done_testing;
