package Tak::MetaService;

use Tak::WeakClient;
use Log::Contextual qw(:log);
use Moo;

with 'Tak::Role::Service';

has router => (is => 'ro', required => 1, weak_ref => 1);

sub handle_pid {
  return $$;
}

sub handle_ensure {
  my $self = shift;
  my ($name) = @_;
  return "Already have ${name}" if $self->router->services->{$name};
  $self->handle_register(@_);
}

sub handle_register {
  my ($self, $name, $class, %args) = @_;
  (my $file = $class) =~ s/::/\//g;
  require "${file}.pm";
  if (my $expose = delete $args{expose}) {
    %args = (%args, %{$self->_construct_exposed_clients($expose)});
  }
  my $new = $class->new(\%args);
  $self->router->register($name => $new);
  return "Registered ${name}";
}

sub _construct_exposed_clients {
  my ($self, $expose) = @_;
  my $router = $self->router;
  my %client;
  foreach my $name (keys %$expose) {
    local $_ = $expose->{$name};
    if (ref eq 'HASH') {
      $client{$name} = Tak::Client->new(
         service => Tak::Router->new(
           services => $self->_construct_exposed_clients($_)
         )
      );
    } elsif (ref eq 'ARRAY') {
      if (my ($svc, @rest) = @$_) {
        die "router has no service ${svc}"
          unless my $service = $router->services->{$svc};
        my $client_class = (
          Scalar::Util::isweak($router->services->{$svc})
            ? 'Tak::WeakClient'
            : 'Tak::Client'
        );
        $client{$name} = $client_class->new(service => $service)
                                      ->curry(@rest);
      } else {
        $client{$name} = Tak::WeakClient->new(service => $router);
      }
    } else {
      die "expose key ${name} was ".ref;
    }
  }
  \%client;
}

1;
