package Object::Remote::Role::LogForwarder;

use Moo::Role;

has enable_forward => ( is => 'rw', default => sub { 1 } );
has _forward_destination => ( is => 'rw' );
#lookup table for package names that should not
#be forwarded across Object::Remote connections
has _forward_stop => ( is => 'ro', required => 1, default => sub { {} } );

after _deliver_message => sub {
#  my ($self, $level, $generator, $args, $metadata) = @_;
  my ($self, %message_info) = @_;
  my $package = $message_info{caller_package};
  my $destination = $self->_forward_destination;
  our $reentrant;

  if (defined $message_info{object_remote}) {
    $message_info{object_remote} = { %{$message_info{object_remote}} };
  }

  $message_info{object_remote}->{forwarded} = 1;

  return unless $self->enable_forward;
  return unless defined $destination;
  return if $self->_forward_stop->{$package};

  if (defined $reentrant) {
    warn "log forwarding went reentrant. bottom: '$reentrant' top: '$package'";
    return;
  }

  local $reentrant = $package;

  eval { $destination->_deliver_message(%message_info) };

  if ($@ && $@ !~ /^Attempt to use Object::Remote::Proxy backed by an invalid handle/) {
    die $@;
  }
};

sub exclude_forwarding {
  my ($self, $package) = @_;
  $package = caller unless defined $package;
  $self->_forward_stop->{$package} = 1;
}

1;
