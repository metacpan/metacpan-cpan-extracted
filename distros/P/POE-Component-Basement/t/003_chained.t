use Test::More tests => 8;
use POE;

BEGIN { use_ok( 'POE::Component::Basement' ); }

{
    package PCB::Test;
    use base qw/ POE::Component::Basement /;
    use POE;
    
    my %foo_of : ATTR( :get<foo> :set<foo> :init_arg<foo> );
    
    sub start : State( :inline<_start> :chained<sec> ) {
        Test::More::ok( 1, 'inline start' );
        return 17;
    }
    
    sub second : State( :package<sec> :next<third> ) {
        my ( $class, $last_ret ) = @_[OBJECT, ARG0];
        Test::More::is( $class, __PACKAGE__, 'package state' );
        Test::More::is( $last_ret, 17, 'correct return value' );
    }
    
    sub third : State( :object<third> ) {
        my ( $self, $last_ret ) = @_[OBJECT, ARG0];
        Test::More::ok( UNIVERSAL::isa( $self, 'UNIVERSAL' ), 'object state' );
        Test::More::is( $last_ret, 17, 'correct return value 2' );
    }
}

my $comp = PCB::Test->new({ foo => 23, aliases => 'shub-niggurath' });
ok( $comp, 'creation' );
is( $comp->get_foo, 23, 'accessor' );

POE::Kernel->run;