use Test::More tests => 4;

BEGIN { use_ok( 'POE::Component::Basement' ); }

{   package PCB::Test;
    use base qw/ POE::Component::Basement /;
    use POE;
    
    sub start : State( :inline<_start> :chained<ok1> :error<err1> ) {
        return 474;
    }
    sub err1 : State( :inline<err1> ) { 
        Test::More::ok(0, 'wrong method, no error') 
    }
    
    sub second : State( :inline<ok1> :chained<ok2> :error<err2> ) {
        my $DAaTh = $_[ARG0];
        Test::More::is( $DAaTh, 474, 'return value' );
        die "IA! IA! CTHULHU FTHAGN!\n";
    }
    sub ok2 : State( :inline<ok2> ) { 
        Test::More::ok(0, 'wrong method, error') 
    }
    sub err2 : State( :inline<err2> ) {
        my $errmsg = $_[ARG0];
        Test::More::ok( $errmsg =~ /cthulhu/i, 'error message' );
    }
}

my $x = new PCB::Test({ aliases => 'choronzon' });
ok( $x, 'creation' );

POE::Kernel->run;