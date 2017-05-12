package PITA::Guest::Driver::Image::Test;

use 5.008;
use strict;
use File::Spec                 ();
use Probe::Perl                ();
use PITA::Image           0.60 ();
use PITA::Guest::Driver::Image ();

our $VERSION = '0.60';
our @ISA     = 'PITA::Guest::Driver::Image';

# The location of the support server
my $image_bin = File::Spec->rel2abs(
	File::Spec->catfile( 't', 'bin', 'pita-imagetest' )
);
unless ( -f $image_bin ) {
	Carp::croak("Failed to find the pita-imagetest script");
}

# To allow for testing, whenever we return a support server we
# need to keep a reference to it.
use vars qw{$LAST_SUPPORT_SERVER};
BEGIN {
	$LAST_SUPPORT_SERVER = undef;
}

sub support_server_new {
	my $self   = shift;
	my $server = PITA::Guest::Server::Process->new(
		Program => [
			Probe::Perl->find_perl_interpreter,
			$image_bin,
			'--injector',
			$self->injector_dir,
		],
		Hostname    => $self->support_server_addr,
		Port        => $self->support_server_port,
		Mirrors     => { },
		# http_result => $self->support_server_results,
		# http_startup_timeout  => 30,
		# http_activity_timeout => 60,
		# http_shutdown_timeout => 30,
	);

	# Save the reference to the support server
	$LAST_SUPPORT_SERVER = $server;

	return $server;
}

1;
