use Sys::Hostname;
use Test::More tests => 5;
use Net::Rendezvous::Publish;

my $type  = "_madeup._tcp.";
my $name  = "$class $type $$";
diag( "using service name '$name'" );

my $session = Net::Rendezvous::Publish->new( backend => $class );
ok( $session,  "Created a session" );

spin();

my $service = $session->publish( type => $type,
                                 port => 80,
                                 name => $name );
ok( $service, "Published a service" );
is( $service->published, undef, "Don't know if it's been acked yet" );

spin();

ok( $service->published, "Time has passed, and now it is" );

print "# stopping service\n";
$service->stop;

spin();

ok( !$service->published, "service thinks it isn't published" );

# handle some events
sub spin {
    $session->step( 0.1 ) for 1..20;
}

1;
