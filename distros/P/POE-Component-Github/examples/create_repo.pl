use strict;
use warnings;
use POE qw(Component::Github);
use Getopt::Long;

my $login = $ENV{GITHUB_LOGIN};
my $token = $ENV{GITHUB_TOKEN};

my $repository;
my $description;
my $url;

GetOptions( 'login=s', \$login, 'token=s', \$token, 'repo=s', \$repository, 'desc=s', \$description, 'url=s', \$url )
	or die "W00t\n";

die "No authentication\n" unless $login and $token;
die "No options\n" unless $repository and $description and $url;

my $github = POE::Component::Github->spawn();

POE::Session->create(
  package_states => [
	'main' => [qw(_start _github)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  $poe_kernel->post( $github->get_session_id, 'repositories', 'create', 
	{ 
	   event => '_github', 
	   login => $login,
	   token => $token,
	   values => 
		{
			name        => $repository,
			description => $description,
			homepage    => $url,
			public	    => 1,
		},
	}, 
  );
  return;
}

sub _github {
  my ($kernel,$heap,$resp) = @_[KERNEL,HEAP,ARG0];
  use Data::Dumper;
  warn Dumper($resp);
  $github->yield( 'shutdown' );
  return;
}
