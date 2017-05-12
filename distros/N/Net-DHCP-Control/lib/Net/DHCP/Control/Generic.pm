
# I'm an abstract base class

package Net::DHCP::Control::Generic;
use Net::DHCP::Control::ServerHandle;
use Net::DHCP::Control ':DEFAULT', 'TP_UNSPECIFIED';

%OPTS =
  (new => { host => '127.0.0.1',
            port => scalar(Net::DHCP::Control::DHCP_PORT()),
            key_name => undef,
            key_type => undef,
            key => undef,
            attrs => {},
            handle => undef,
            handle_factory => 'Net::DHCP::Control::ServerHandle',
            callback => undef,
            callback_data => undef,
          },
  );

# Initialize the dhcpctl library when this module is loaded
Net::DHCP::Control::initialize();

sub croak {
  require Carp;
  *croak = \&Carp::croak;
  shift;
  for (@_) {
    s/%ERR/$Net::DHCP::Control::STATUS/g;
  }
  goto &croak;
}

sub new {
  my ($base, %opts) = @_;
  my $class = ref $base || $base;

  $base->validate_options(\%opts);

  my $authenticator;
  my $handle = delete($opts{handle}) 
    || $opts{handle_factory}->new($opts{handle_factory}->select_opts(\%opts, 'new'))
      || return;
  my $objkind = $ {"$class\::KIND"} 
    or $base->croak("Missing $class\::KIND variable; aborting");
  my $object = Net::DHCP::Control::new_object($handle, $objkind)
    or return;
  if ($opts{callback}) {
    Net::DHCP::Control::set_callback($object, $opts{callback}, $opts{callback_data})
        or return;
  }

  my $self = { OBJ => $object,
               KIND => $objkind,
               HANDLE => $handle,
               OPTS => \%opts,
               AUTH => $authenticator,
               CLASS => $class,
             };

  while (my ($name, $val) = each %{$opts{attrs}}) {
    my $type = $class->typeof_attr($name) || TP_UNSPECIFIED;
    Net::DHCP::Control::set_value($object, $name, $val, $type);
  }

  Net::DHCP::Control::open_object($object, $handle) or return;
  unless ($opts{callback}) {
    Net::DHCP::Control::wait_for_completion($object) or return;
  }

  bless $self => $class;
}


for my $key (qw(obj kind handle opts auth class lazy)) {
  my $methname = $key;
  *$methname = sub { $_[0]->{uc $methname} };
}

sub get {
  my ($self, $name, $type) = @_;
  $type ||= $self->typeof_attr($name);
  my $z = Net::DHCP::Control::get_value($self->obj, $name, $type);
  $z;
}


sub refresh {
  my ($self) = @_;
  Net::DHCP::Control::object_refresh($self);
}

sub set {
  my ($self, $name, $value, $type) = @_;
  $type ||= $self->typeof_attr($name);
  Net::DHCP::Control::set_value($self->obj, $name, $value, $type) or return;
  return 1 if $self->lazy;
  $self->update;
}

sub update {
  my $self = shift;
  Net::DHCP::Control::object_update($self->handle, $self->obj) or return;
  Net::DHCP::Control::wait_for_completion($self->obj) or return;
}

sub typeof_attr {
  my ($self, $name) = @_;
  my $class = ref $self ? $self->class : $self;
  $ {"$class\::ATTRS"}{$name};
}

sub attrs {
  my ($self, $name) = @_;
  my $class = ref $self ? $self->class : $self;
  keys % {"$class\::ATTRS"};
}

# return all available information about an object as a hash
sub get_all {
  my $self = shift;
  my %result;
  for my $attr ($self->attrs) {
    $result{$attr} = $self->get($attr);
  }
  %result;
}

sub validate_options {
  my $base = shift;
  my $class = ref $base || $base;
  my $meth = (caller(1))[3];    # Subroutine name
  $meth =~ s/.*:://;
  my $op = shift;
  my $ok = do { no strict 'refs'; $ {"$class\::OPTS"}{$meth} };
    
  my @EXTRA;
  for my $k (keys %$op) {
    unless (exists $ok->{$k}) {
      push @EXTRA, $k;
    }
  }
  if (@EXTRA) {
    my $options = @EXTRA > 1 ? 'options' : 'option';
    $class->croak("Unknown $options '@EXTRA' to method $class\::$meth");
  }

  my @MISSING;
  for my $k (keys %$ok) {
    my $default_value = $ok->{$k};
    my $is_required =  defined($default_value)
      && $default_value eq "REQUIRED";
    if (not exists $op->{$k}) {
      if ($is_required) {
        push @MISSING, $k;
      } else {
        $op->{$k} = $default_value;
      }
    }
  }
  if (@MISSING) {
    my $options = @MISSING > 1 ? 'options' : 'option';
    $class->croak("Mandatory $options '@MISSING' missing in call to method $class\::$meth");
  }

}

sub select_opts {
  my ($self, $opts, $meth) = @_;
  my $class = ref $self || $self;
  my $ok = do { no strict 'refs'; $ {"$class\::OPTS"}{$meth} };
  my %selected;
  for my $k (keys %$ok) {
    $selected{$k} = $opts->{$k};
  }
  %selected;
}

sub DESTROY {
  my $handle = $_[0]{OBJ};
  if ($handle) {
    Net::DHCP::Control::deallocate($handle);
  }
}

1;
