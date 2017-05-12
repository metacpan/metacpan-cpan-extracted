use strict;
use warnings;
use Getopt::Long;
use POE qw(Component::CPAN::Mirror::Multiplexer);

my $port = 8080;
GetOptions('port=i',\$port) or die;

POE::Session->create(
  package_states => [
    main => [qw(_start _request)],
  ],
);

$poe_kernel->run();
exit 0;

sub _start {
  my ($kernel,$heap) = @_[KERNEL,HEAP];
  $heap->{httpd} = POE::Component::CPAN::Mirror::Multiplexer->new( 
    port => $port,
    postback => $_[SESSION]->postback( '_request' ),
  );
  return;
}

sub _request {
  my ($req,$info) = @{ $_[ARG1] };
  warn $req->as_string;
  return;
}
