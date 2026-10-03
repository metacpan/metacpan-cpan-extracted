#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN
{
    use_ok( 'Parse::Crontab::English' ) || print "Bail out!\n";
}

{
    diag( "Testing Parse::Crontab::English $Parse::Crontab::English::VERSION, Perl $], $^X" );
    done_testing;
}
