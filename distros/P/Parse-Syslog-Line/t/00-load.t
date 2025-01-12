#!perl

use v5.16;
use warnings;

use FindBin;
use Test::More;

use lib "$FindBin::Bin/lib";
use test::Data;

use_ok( 'Parse::Syslog::Line' );
diag( "Testing Parse::Syslog::Line $Parse::Syslog::Line::VERSION, Perl $], $^X" );

my $tests = get_test_data();
is( ref $tests, 'HASH', "test::Data::get_tests() loads a hash" );
ok( keys %{$tests},     "test::Data::get_tests() loads tests!" );
done_testing;
