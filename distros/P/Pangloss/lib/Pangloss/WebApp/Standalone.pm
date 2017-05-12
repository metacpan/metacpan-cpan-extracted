package Pangloss::WebApp::Standalone;

use strict;
use warnings::register;

use File::Spec;
use HTTP::Daemon;
use Scalar::Util qw( weaken );

use base      qw( Pangloss::WebApp );
use accessors qw( port httpd connection old_dir );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.3 $ '))[2];

#------------------------------------------------------------------------------
# Object initialization

sub init_tfactory {
    my $self = shift;
    # we chdir PG_HOME below
    $self->config->{PG_TEMPLATE_DIR} = File::Spec->catdir(qw( . web ));
    $self->SUPER::init_tfactory(@_);
}

#------------------------------------------------------------------------------
# Standalone server

sub event_loop {
    my $self = shift;

    $self->old_dir( File::Spec->rel2abs(File::Spec->curdir) );

    sub sig_handler {
	no warnings;
	my $sig = shift;
	$self->emit( "\ncaught sig $sig...\n" );
	$self->quit(1);
    }

    local %SIG;
    $SIG{INT}  = \&handler;
    $SIG{HUP}  = \&handler;
    $SIG{QUIT} = \&handler;

    chdir( $self->config->{PG_HOME} ) if $self->config->{PG_HOME};

    my $httpd = HTTP::Daemon->new(
				  LocalPort => $self->port,
				  Reuse     => 1,
				 ) || die "error starting http daemon: $!";

    $self->httpd( $httpd );
    weaken( $httpd ); # make sure server goes away on quit()

    $self->emit( "server running at http://localhost:" . $self->port . "\n" );

    while (my $conn = $httpd->accept()) {
	$self->connection( $conn );
	while (my $request = $conn->get_request) {
	    $self->handle_request( $request );
	}
    }

    $self->quit(0);
}

sub handle_request {
    my $self    = shift;
    my $request = shift;

    my $prod = $self->SUPER::handle_request( $request );

    my $response = $self->controller->store->get('HTTP::Response');

    # TODO: error handling here...

    $self->connection->send_response( $response );
    $self->emit( "sent response (" . length($response->content)
		 . " characters)\n" );

    $self->connection->close;	# keep-alive is messing up in Safari :-/

    return $self;
}

sub quit {
    my $self = shift;
    my $code = shift || 0;
    $self->emit( "shutting down server.\n" );
    $self->app( undef )
         ->httpd( undef );
    if (my $old_dir = $self->old_dir) {
	$self->emit( "cd'ing back to $old_dir\n" );
	chdir( $old_dir );
    }
    CORE::exit $code;
}

1;
