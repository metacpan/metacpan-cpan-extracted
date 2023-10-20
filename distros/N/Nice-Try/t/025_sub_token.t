#!perl
use strict;
use warnings;
use lib './lib';
use experimental 'signatures';
use Test::More qw( no_plan );
# use Nice::Try debug_dump => 1, debug_file => 'dev/test_026.pl', debug_code => 1, debug => 7;
use Nice::Try;
our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
# Issue #6 raised by Clay Fouts 
# <https://gitlab.com/jackdeguest/Nice-Try/-/issues/6>

my $sub1_failed = 0;
my $sub1_cnt = 0;
my $sub1_try = 0;
my $s = sub
{
    if( !shift( @_ ) )
    {
        diag( "Nothing received, returning now." ) if( $DEBUG );
        return;
    }
    $sub1_cnt++;
    
    try
    {
        diag( "Our anon sub is ", __SUB__ ) if( $DEBUG );
        __SUB__->(0);
        $sub1_try++;
        return;
    }
    catch( $e )
    {
        $sub1_failed++;
    }
};

$s->(1);
ok( $sub1_try, '__SUB__ token in anonymous subroutine' );
ok( !$sub1_failed, 'has not reached the catch block' );
is( $sub1_cnt, 1, 'repeat call -> 1' );

my $cnt = 0;
my $sub2_name;
my $sub2_failed = 0;

sub callme :prototype($) ($name){
    return if( $cnt );
    $sub2_name = $name;
    try
    {
        diag( "Our sub is ", __SUB__ ) if( $DEBUG );
        $cnt++;
        __SUB__->('Bob');
    }
    catch( $e )
    {
        $sub2_failed++;
    }
}

&callme('John');

is( $sub2_name, 'John', 'subroutine with __SUB__ token' );
is( $cnt, 1, 'repeat call -> 1' );
ok( !$sub2_failed, 'has not reached the catch block' );

done_testing();

__END__

