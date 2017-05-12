use strict;
use warnings;
use File::Spec;
use POE qw(Component::SmokeBox::Recent::FTP);

my $site = shift || die "You must provide a site parameter\n";
my $path = shift || '/';

POE::Session->create(
   package_states => [
	main => [qw(_start ftp_sockerr ftp_error ftp_data ftp_done)],
   ]
);

$poe_kernel->run();
exit 0;

sub _start {
  POE::Component::SmokeBox::Recent::FTP->spawn(
	address => $site,
	path    => File::Spec::Unix->catfile( $path, 'RECENT' )
  );
  return;
}

sub ftp_sockerr {
  warn join ' ', @_[ARG0..$#_];
  return;
}

sub ftp_error {
  warn "Error: '" . $_[ARG0] . "'\n";
  return;
}

sub ftp_data {
  print $_[ARG0], "\n";
  return;
}

sub ftp_done {
  warn "Transfer complete\n";
  return;
}
