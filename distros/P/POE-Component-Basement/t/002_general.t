use Test::More tests => 6;
use POE;

BEGIN { use_ok( 'POE::Component::Basement' ); }

{
    package PCB::Test;
    use base qw/ POE::Component::Basement /;
    
    my %foo_of : ATTR( :get<foo> :set<foo> :init_arg<foo> );
    
    sub start : State( :inline<_start> ) {
        Test::More::ok( 1, 'inline start' );
        POE::Kernel->yield( 'sec' );
    }
    
    sub second : State( :package<sec> ) {
        my $class = $_[OBJECT];
        Test::More::is( $class, __PACKAGE__, 'package state' );
        POE::Kernel->yield( 'third' );
    }
    
    sub third : State( :object<third> ) {
        my $self = $_[OBJECT];
        Test::More::ok( UNIVERSAL::isa( $self, 'UNIVERSAL' ), 'object state' );
    }
}

my $comp = PCB::Test->new({ foo => 23, aliases => 'shub-niggurath' });
ok( $comp, 'creation' );
is( $comp->get_foo, 23, 'accessor' );

POE::Kernel->run;