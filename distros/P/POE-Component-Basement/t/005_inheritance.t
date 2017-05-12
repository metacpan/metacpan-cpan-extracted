use Test::More tests => 6;

BEGIN { use_ok( 'POE::Component::Basement' ); }

{   package PCB::Test::First;
    use base qw/ POE::Component::Basement /;
    use POE;
    
    sub second : State( :package<second> ) {
        my $ret = $_[ARG0];
        Test::More::is( $ret, 23, 'chained' );
        POE::Kernel->yield( 'third', $ret );
    }
}

{   package PCB::Test::Second;
    use base qw/ PCB::Test::First /;
    use POE;

    sub forth : State( :package<forth> ) { 
        Test::More::diag( 'FORTH NOT OVERRIDDEN!' );
        Test::More::ok( 0 );
    }
    
    sub start : State( :inline<_start> :chained<second> )
      { Test::More::ok( 1, 'here' ); return 23 }
}

{   package PCB::Test::Third;
    use base qw/ PCB::Test::Second /;
    use POE;

    sub forth {
        Test::More::ok( 1, 'overridden' );
    }
    
    sub third : State( :object<third> :chained<forth> ) {
        my $ret = $_[ARG0];
        Test::More::is( $ret, 23, 'pass' );
        return 1;
    }
}

my $comp = PCB::Test::Third->new ({ aliases => 'barney' });
ok( $comp, 'creation' );

POE::Kernel->run;
