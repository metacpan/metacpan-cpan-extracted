package Proc::Application::Daemon::httpd;

use Proc::Application::Daemon;
use base qw(Proc::Application::Daemon);

use HTTP::Daemon;
use HTTP::Status;

sub processSocketCreate
{
    my ( $this, $option, $params ) = @_;
    my %params = $this->_decodeOption ( $params );
    $this->{mainSocket} = new HTTP::Daemon ( Reuse  => 1,
					     Proto  => 'tcp',
					     Type   => SOCK_STREAM,
					     Listen => 10,
					     %params ) || die "Can't create HTTPD: $!";
}

sub requestHandler
{
    my ( $this, $request ) = @_;
}

sub connection
{
    my $this = shift;
    $this->socket;
}

sub handler
{
    my $this = shift;
    while ( 1 )
    {
	my $request;
	eval 
	{
	    local $SIG{ALRM} = sub { die "timeout get http request" };
	    alarm 15;
            $request = $this->connection->get_request;
            alarm 0;
        };
	die $@ if $@;
        $request || last;
        eval { $this->requestHandler ( $request ); };
	if ( $@ )
	{
	    $this->log->error ( $@ );
	    $this->connection->send_error( 500, "Server error" );
	}
    }
}

1;

__END__

