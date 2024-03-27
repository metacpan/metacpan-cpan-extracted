#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More;
    if( $] < 5.020000 )
    {
        plan skip_all => 
          "signatures tests unsupported for perl below v5.20";
    }
    # use Nice::Try debug_file => './dev/debug_t_025_sub_token.pl', debug_code => 1, debug => 7, debug_dump => 1;
    use Nice::Try;
};

use strict;
use warnings;
use experimental 'signatures';
no warnings 'experimental';
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

SKIP:
{
    my $cnt = 0;
    my $sub2_name;
    my $sub2_failed = 0;
    my $proto_test;
    if( $] >= 5.022000 && $] <= 5.026003 )
    {
        # skip( "Skipping mixing prototype and signature for perl version between 5.22.0 and 5.26.3 as it was buggy.", 3 );
        $proto_test = <<'EOT';
sub callme ($name) :prototype($){
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
EOT
    }
    else
    {
        $proto_test = <<'EOT';
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
EOT
    }
    my $code = Nice::Try->implement( $proto_test );
    eval( $code );
    &callme('John');
    
    is( $sub2_name, 'John', 'subroutine with __SUB__ token' );
    is( $cnt, 1, 'repeat call -> 1' );
    ok( !$sub2_failed, 'has not reached the catch block' );
};

done_testing();

__END__

