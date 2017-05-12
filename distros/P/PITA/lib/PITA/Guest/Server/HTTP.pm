package PITA::Guest::Server::HTTP;

# The HTTP server component of the support server

use 5.008;
use strict;
use File::Spec                      ();
use POE::Declare::HTTP::Server 0.05 ();

our $VERSION = '0.60';
our @ISA     = 'POE::Declare::HTTP::Server';

use POE::Declare {
	Mirrors     => 'Param',
	PingEvent   => 'Message',
	MirrorEvent => 'Message',
	UploadEvent => 'Message',
};





######################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(
		Mirrors => { },
		@_,
		Handler => sub {
			# Convert to a more convention form
			$_[0]->handler( $_[1]->request, $_[1] );
		},
	);

	# Check and normalize
	unless ( Params::Util::_HASH0($self->Mirrors) ) {
		die "Missing or invalid Mirrors param";
	}
	foreach my $route ( sort keys %{$self->Mirrors} ) {
		my $dir = File::Spec->rel2abs( $self->Mirrors->{$route} );
		unless ( -d $dir ) {
			die "Directory '$dir' for mirror '$route' does not exist";
		}
		$self->Mirrors->{$route} = $dir;
	}

	return $self;
}





######################################################################
# Main Methods

# Sort of half-assed Process compatibility for testing purposes
sub run {
	$_[0]->start;
	POE::Kernel->run;
	return 1;
}

# Wrapper for doing cleansing of the response
sub handler {
	my $self     = shift;
	my $response = $_[1];

	# Call the main handler
	$self->_handler(@_);

	# Add content length for all responses
	if ( defined $response->content ) {
		unless ( $response->header('Content-Length') ) {
			my $bytes = length $response->content;
			$response->header( 'Content-Length' => $bytes );
		}
	}

	return;
}

sub _handler {
	my $self     = shift;
	my $request  = shift;
	my $response = shift;
	my $path     = $request->uri->path;

	if ( $request->method eq 'GET' ) {
		# Handle a ping
		if ( $path eq '/' ) {
			$response->code(200);
			$response->header( 'Content-Type' => 'text/plain' );
			$response->content('200 - PONG');
			$self->PingEvent;
			return;
		}

		# Handle a mirror file fetch
		my $Mirrors = $self->Mirrors;
		foreach my $route ( sort keys %$Mirrors ) {
			my $escaped = quotemeta $route;
			next unless $path =~ /^$escaped(.+)$/;
			my $file = $1;
			my $root = $Mirrors->{$route};
			my $full = File::Spec->catfile( $root, $file );
			if ( -f $full and -r _ ) {
				# Load the file
				local $/ = undef;
				my $io = IO::File->new($full, 'r') or die "open: $full";
				$io->binmode;
				my $blob = $io->getline;

				# Send the file
				$response->code(200);
				$response->header('Content-Type' => 'application/x-gzip');
				$response->content($blob);
			} else {
				$response->code(404);
				$response->header('Content-Type' => 'text/plain');
				$response->content('404 - File Not Found');
			}

			# Report the mirror event
			$self->MirrorEvent( $route, $file, $response->code );

			return;
		}
	}

	if ( $request->method eq 'PUT' ) {
		# Send the upload message
		$self->UploadEvent( $path => \( $request->content ) );

		# Send a content-less ok to the client
		$response->code(204);
		$response->message('Upload received');

		return;
	}

	return;
}

compile;
