package Net::RRP::Request::Timeout;

sub getName { 'Timeout' };

1;

package Net::RRP::Server;

use strict;
use Data::Dumper;

use Net::RRP::Codec;
use Net::RRP::Protocol;
use Error qw(:try);
use Net::RRP::Exception;
use Net::RRP::Exception::ServerError;
use Net::RRP::Exception::InvalidCommandSequence;
use Net::RRP::Response::n420;
use Net::RRP::Response::n200;

use Proc::Application::Daemon;
use base qw(Proc::Application::Daemon);

$Net::RRP::Server::VERSION = '0.1';

#                                      |
#                                      |
#                                      v
#                             +-----------------+   Timeout
#                             |   Waiting for   |-------------------+
#   Authentication Succeeded  |      Client     |                   |
#                   +---------|  Authentication | Authentication    |
#                   |         |      (PRE)      |-----+  Failed     |
#                   |         +-----------------+     |             |
#                   |                                 |             |
#                   V                                 V             |
#             +-----------+     Succeeded    +--------------------+ |
#             |Waiting for|<-----------------|    Waiting for     | |
#             |  Command  |----------+       |Authentication Retry| |
#             |   (WFC)   |  Timeout |       |       (WFR)        | |
#             +-----------+          |       +--------------------+ |
#                 |   ^              |           |         |        |
#                 |   |              |   Timeout |         | Failed |
#         Request V   |Response      |           |         |        |
#             +-----------+          |           V         V        V
#             | Executing |          |          +--------------------+
#             |  Command  |          +--------->|    Disconnected    |
#             |   (EXE)   |-------------------->|       (DIS)        |
#             +-----------+          QUIT       +--------------------+
#        PRE     Waiting for client connection and authentication
#        WFR     Waiting for authentication retry
#        WFC     Waiting for a command from an authenticated client
#        EXE     Executing a command
#        DIS     Disconnected


use constant INIT_STATE => 'PRE';
use constant DONE_STATE => 'DIS';
use constant STATES     => { PRE  => { Session  => { 1 => 'WFC', 0 => 'WFR' },
				       Quit     => { 1 => 'DIS', 0 => 'DIS' }, },
			     WFR  => { Session  => { 1 => 'WFC', 0 => 'DIS' },
				       Quit     => { 1 => 'DIS', 0 => 'DIS' }, },
			     WFC  => { Quit     => { 1 => 'DIS', 0 => 'DIS' },
				       Add      => { 1 => 'WFC', 0 => 'WFC' },
				       Check    => { 1 => 'WFC', 0 => 'WFC' },
				       Del      => { 1 => 'WFC', 0 => 'WFC' },
				       Describe => { 1 => 'WFC', 0 => 'WFC' },
				       Mod      => { 1 => 'WFC', 0 => 'WFC' },
				       Quit     => { 1 => 'DIS', 0 => 'DIS' },
				       Renew    => { 1 => 'WFC', 0 => 'WFC' },
				       Session  => { 1 => 'WFC', 0 => 'WFR' },
				       Status   => { 1 => 'WFC', 0 => 'WFC' },
				       Transfer => { 1 => 'WFC', 0 => 'WFC' } },
			     DIS => {}, # there are virtual states
			     EXE => {} };

use constant EXCEPTION_STATES => { 'PRE' => 'WFR',
				   'WFR' => 'DIS' };
sub setStates
{
    my $this = shift;
    $this->{states} = STATES;
}

sub getStates
{
    my $this = shift;
    return $this->{states};
}

sub execute
{
    warn "Net::RRP::Server::execute() must be overwriten at child class, return defaults n200 response";
    my $response = new Net::RRP::Response::n200 ();
    $response->setDescription ( "ok" );
    $response;
}

sub getHelloInfo
{
    warn "Net::RRP::Server::getHelloInfo() must be overwriten at child class, return defaults";
    ( registryName => "RU",
      version      => '1.1.0',
      buildDate    => 'Mon Jun 19 14:04:00 MSK 2000' );
}

sub _logException
{
    my ( $this, $exception ) = @_;
    $this->Log ( 'debug', "$$: file " . $exception->file . " line " . $exception->line );
    $this->Log ( 'debug', "$$: trace " . $exception->stacktrace );
    $this->Log ( 'debug', "$$: catch exception $exception with code " . $exception->value() ) if $exception->value();
    $this->Log ( 'debug', "$$: exception object " . Data::Dumper->Dump ( [ $exception->object ], [ 'exception information' ] ) ) if $exception->object;
}

sub getProtocol
{
    my $this = shift;
    $this->{protocol};
}

sub handler
{
    my $this = shift;

    my $socket = $this->socket();
    $this->Log ( 'notice', "$$: connecttion from: %s", $socket->peerhost );

    $this->setStates ();

    my $protocol   = new Net::RRP::Protocol ( socket => $socket );
    $protocol->sendHello ( $this->getHelloInfo() );
	
    my $state  = INIT_STATE;
    my $states = $this->getStates ();

    $this->{protocol} = $protocol;

    while ( 1 )
    {
	my $response;

	$this->Log ( 'debug', "$$: rrp state at start: $state" );

	try
	{
	    #local $Error::Debug = 1 if $this->{options}->{debug};
            my $subState = undef;
            my $request  = undef;
	    my $prevState;

	    try
	    {
		$prevState = $state;

 		my $requestBuffer = $protocol->_getLinesFromSocket();
		$request = $protocol->{codec}->decodeRequest ( $requestBuffer );
		#$request = $protocol->getRequest ();
		$this->Debug ( "rrp request buffer is\n$requestBuffer" );

		my $requestName = $request->getName();
		$this->Log ( 'notice', "$$: get %s request", $requestName );
                $subState = $states->{ $state }->{ $requestName };
		throw Net::RRP::Exception::InvalidCommandSequence () unless $subState;
		$state = 'EXE';
		$response = $this->execute ( $request );
		$state = $subState->{ $request->isSuccessResponse ( $response ) || 0 };
	    }
	    catch Net::RRP::Exception with
	    {
		my $exception = shift;
		$this->_logException ( $exception );
		last if ( $exception->isa ( 'Net::RRP::Exception::IOError') );
		$response = Net::RRP::Response->newFromException ( $exception );
                $this->Log ( 'debug',  "$$: rrp state before exception: $state" );
		if ( $subState )
		{
		    $state = $subState->{ $request->isSuccessResponse ( $response ) || 0 };
		}
		else
		{
		    my $checkState = EXCEPTION_STATES->{ $prevState };
		    $state = $checkState ? $checkState : $prevState;
		}
                $this->Log ( 'debug',  "$$: rrp state after exception: $state" );
	    };

	}
	otherwise
	{
	    my $exception = shift;
            $this->_logException ( $exception );
	    $response = new Net::RRP::Response::n420;
	    $response->setDescription ( 'internal server error' );
	    $state = DONE_STATE;
	};

	$this->Log ( 'notice', "$$: send response: %s", $response->getCode );
	$this->Log ( 'debug',  "$$: rrp state at end: $state" );

	$protocol->sendResponse ( $response );

	last if $state eq DONE_STATE;
    }

    $this->Log ( 'notice', "$$: done connection" );
}

__END__

base class for all Net::RRP::Server classes
