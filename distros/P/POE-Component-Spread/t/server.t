use POE;
use POE::Session;
use POE::Component::Spread;
use Data::Dumper;
use Test::More;

my $server = $ENV{'SPREAD_SERVER'};
my $group  = "PoCoSp$$";

if ($server) {
    plan tests => 4;
	POE::Component::Spread->new( 'spread' );
	
	POE::Session->create(
	    inline_states => {
	        _start => \&_start,
	        "${group}_regular" => \&get_message,
	    },
	);
	
	sub _start {
	    my $kernel = $_[KERNEL];
	    my $heap = $_[HEAP];
	    my $session = $_[SESSION];   

	    $kernel->alias_set('displayer');
		$poe_kernel->post( spread => connect => $server );
		$poe_kernel->post( spread => subscribe => $group );
		$poe_kernel->post( spread => publish => $group, 'hello' );
	}
	
	sub get_message {
        my $heap = $_[HEAP];
	    my $args = $_[ARG0];
        my $session = $_[SESSION];   
        my ($sender, $message, $type, $groups) = @$args;

        ok( $sender eq $heap->{private_name}, 'message from ourselves' );
        ok( $type & REGULAR_MESS, 'regular message' );
        ok( (grep /\Q$group/, @$groups), 'sent to the correct group' );
        ok( $message eq 'hello', 'got the right message back' );

        $poe_kernel->post( spread => 'disconnect' );
	}

	$poe_kernel->run();
} else { # no SPREAD_SERVER defined in %ENV
    plan skip_all => 'no server defined in %ENV';
}
