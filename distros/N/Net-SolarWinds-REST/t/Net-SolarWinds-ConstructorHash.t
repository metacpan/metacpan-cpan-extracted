
use Test::More;
use strict;
use warnings;
use IO::Scalar;

use_ok('Net::SolarWinds::ConstructorHash');
use_ok('Net::SolarWinds::Log');

{

    package TestMe;
    use strict;
    use warnings;
    use base qw(Net::SolarWinds::ConstructorHash);

}

{

    package MyTest;
    use strict;
    use warnings;
    use base qw(Net::SolarWinds::ConstructorHash);

    sub new {
        my ( $class, %args ) = @_;

        return $class->SUPER::new( default => 'value', %args );
    }
}

isa_ok( new TestMe, 'TestMe', 'Construct TestMe without any arguments' );

my %t = ( log => undef, _shutdown => 0 );
is_deeply( new TestMe( 1 => 2 ), { 1 => 2, %t }, 'make sure we get the arguments we pass in' );

isa_ok( new MyTest, 'MyTest', 'construct MyTest without any arguments' );

is_deeply( new MyTest, { qw(default value), %t }, 'default value SUPER::new check' );
is_deeply( new MyTest( default => 1 ), { qw(default 1), %t }, 'overload value SUPER::new check' );
is_deeply( new MyTest( default => 1, 2, 2 ), { qw(default 1 2 2), %t }, 'Overload value SUPER::new check and add data' );

{
    my $string='';
    my $fh=new IO::Scalar(\$string);
    my $log=new Net::SolarWinds::Log(fh=>$fh);
    my $obj = MyTest->new(log=>$log);

    ok( !$obj->is_shutdown, 'default object state should not be in shutdown' );
    ok( $obj->set_shutdown, 'set shutdown should return true' );

    ok( $obj->is_shutdown, 'object should be in shutdown state' );
    can_ok($obj,qw(get_log set_log log_info log_error log_always log_debug log_die));

    sub  {eval { $obj->log_die("This is a test") } }->();

    ok($@,"Should have been fatal");

}

{
    my $obj = MyTest->new();

    ok( !$obj->is_shutdown, 'default object state should not be in shutdown' );
    ok( $obj->set_shutdown, 'set shutdown should return true' );

    ok( $obj->is_shutdown, 'object should be in shutdown state' );

    sub  {eval { $obj->log_die("This is a test") } }->();

    ok($@,"Should have been fatal");

}

done_testing;
