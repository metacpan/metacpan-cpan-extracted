use strict;
use warnings;
use File::Spec;
use POE qw(Component::SmokeBox::Recent::HTTP);
use URI;

my $url = shift || die "You must provide a url parameter\n";

my $uri = URI->new( $url );

die "Unsupported scheme\n" unless $uri->scheme and $uri->scheme eq 'http';

$uri->path( File::Spec::Unix->catfile( $uri->path(), 'RECENT' ) );

POE::Session->create(
   package_states => [
	main => [qw(_start http_sockerr http_error http_timeout http_response)],
   ]
);

$poe_kernel->run();
exit 0;

sub _start {
  POE::Component::SmokeBox::Recent::HTTP->spawn(
	uri => $uri,
  );
  return;
}

sub http_sockerr {
  warn join ' ', @_[ARG0..$#_];
  return;
}

sub http_error {
  warn "Error: '" . $_[ARG0] . "'\n";
  return;
}

sub http_timeout {
  warn $_[ARG0], "\n";
  return;
}

sub http_response {
  my $http_response = $_[ARG0];
  print $http_response->as_string;
  return;
}
