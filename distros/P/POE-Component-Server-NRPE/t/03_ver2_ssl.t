use Test::More;

plan skip_all => 'MSWin32 does not have a proper fork()' if $^O eq 'MSWin32';

plan tests => 5;

use_ok( 'POE::Component::Server::NRPE' );

use Socket;
use POE qw(Wheel::SocketFactory Filter::Stream Component::Client::NRPE);

my $port = 5666;
my $nrped;

my $pid = fork;
die "Unable to fork: $!" unless defined $pid;

####################################################################
if ($pid)  # we are parent
{

    # stop kernel from griping
    ${$poe_kernel->[POE::Kernel::KR_RUN]} |=
      POE::Kernel::KR_RUN_CALLED;

    diag("$$: Sleep 5...");
    sleep 5;
    diag("continue");

    POE::Session->create(
	inline_states => {
		_start => sub {
        $poe_kernel->sig_child( $pid, '_dummy' );
  		  POE::Component::Client::NRPE->check_nrpe(
			host  => '127.0.0.1',
			port  => $port,
			event => '_response',
			version => 2,
			usessl => 1,
			context => { thing => 'moo' },
  		  );
		  return;
		},
		_response => sub {
  		  my ($kernel,$heap,$res) = @_[KERNEL,HEAP,ARG0];
  		  cmp_ok( $res->{context}->{thing}, 'eq', 'moo', 'Context data was okay' );
  		  cmp_ok( $res->{version}, 'eq', '2', 'Response version' );
        TODO: {
          local $TODO = 'There is a race condition of sorts. Man, I hate SSL';
  		    cmp_ok( $res->{result}, 'eq', '0', 'The result code was okay' );
  		    cmp_ok( $res->{data}, 'eq', 'NRPE v2.8.1', 'And the data was cool' )
			      or diag("Got '$res->{data}', expected 'NRPE v2.8.1'\n");
        }
  		  return;
		},
    _dummy => sub {
        my( $heap, $sig, $pid, $exit_val, $details ) = @_[ HEAP, ARG0..ARG3 ];
        diag( "$$: Child $pid exited" );
    },
	},
    );

    #$poe_kernel->run();
}

####################################################################
else  # we are the child
{

    # stop kernel from griping
    ${$poe_kernel->[POE::Kernel::KR_RUN]} |=
      POE::Kernel::KR_RUN_CALLED;

  $nrped = POE::Component::Server::NRPE->spawn(
	address => '127.0.0.1',
	port => $port,
	version => 2,
	usessl => 1,
	verstring => 'NRPE v2.8.1',
	options => { trace => 0 },
  );


  POE::Session->create(
	inline_states => {
		_start => sub {
		  $poe_kernel->delay( '_timeout', 10 );
		  return;
		},
		_timeout => sub {
		  $nrped->shutdown();
		  return;
		},
	},
  );

  #$poe_kernel->run();
}

$poe_kernel->run();
exit 0;
