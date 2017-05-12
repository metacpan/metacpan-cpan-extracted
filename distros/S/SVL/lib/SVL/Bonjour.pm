package SVL::Bonjour;
use strict;
use warnings;
use base qw(Class::Accessor::Chained::Fast);
use Net::Rendezvous;
use Net::Rendezvous::Publish;
use Sys::Hostname;
use Sys::HostIP;
__PACKAGE__->mk_accessors(qw(res peers));

my $publisher = Net::Rendezvous::Publish->new
  or die "couldn't make a Responder object";

my $hostname = hostname;
my ($host) = split /\./, $hostname;
my $hostip = hostip;
my $repository = "$ENV{USER}-$host\'s svk repository";

my $old_repos = "";
my $service;

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new();
  $self->res(Net::Rendezvous->new('svl'));
  return $self;
}

sub discover {
  my $self = shift;
  $self->res->discover();

  my @objects;
  foreach my $entry ($self->res->entries) {
    my $peer = SVL::Bonjour::Peer->new();
    $peer->address($entry->address);
    $peer->port($entry->port);
    my %attrs = $entry->all_attrs;
    $peer->svnport($attrs{svnport});
    my @shares;
    foreach my $attr (sort keys %attrs) {
      next unless $attr =~ /^svl\d+$/;
      push @shares, SVL::Share->parse($attrs{$attr});
    }
    $peer->shares(\@shares);
    my $name = $entry->name;
    $name =~ s/\\(0\d\d)/chr($1)/eg;
    $peer->name($name);
    push @objects, $peer;
  }
  $self->peers(\@objects);
  return $self;
}

sub publish {
  my ($self, $shares) = @_;
  my $repos = "";
  my $i = 0;
  foreach my $share (@$shares) {
    $repos .= "svl" . $i++ . "=" . $share->dump . "\x{1}";
  }
  $repos ||= "\x{1}";
  if ($repos ne $old_repos) {
    $old_repos = $repos;
    $service->stop if $service;
    $service = $publisher->publish(
      name   => $repository,
      type   => '_svl._tcp',
      port   => $SVL::SVL_PORT,
      domain => 'local',

      # why oh why \x{1}
      txt => "svnport=$SVL::SVNSERVE_PORT\x{1}${repos}we hate software",
    );
  }
}

sub step {
  my ($self, $step) = @_;
  $publisher->step($step);
}

sub match_peer_name {
  my $self = shift;
  my $host = shift;
  my @candidates;
  foreach my $peer (@{ $self->peers }) {
    for my $share (@{ $peer->shares }) {
      push @candidates, $peer
        if grep { $host eq $_ } @{$share->tags};
    }
  }
  if (@candidates == 0) {
    die "No candidates found for root '$host'";
  } elsif (@candidates > 1) {
    print "Too many matching peers for $host:\n";
    print "\t" . $_->name . "\n" for (@candidates);
    exit;
  }
  my $peer = $candidates[0];
  return $peer;
}

package SVL::Bonjour::Peer;
use strict;
use warnings;
use base qw(Class::Accessor::Chained::Fast);

__PACKAGE__->mk_accessors(qw(name port address svnport shares));

1;
