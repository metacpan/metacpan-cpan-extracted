package MooX::InsideOut::Role::GenerateAccessor;
use Hash::Util::FieldHash::Compat qw(fieldhash);
use Sub::Quote qw(quotify);
use Moo::Role;

fieldhash our %FIELDS;

around generate_method => sub {
  my $orig = shift;
  my $self = shift;
  # would like a better way to disable XS
  local $Method::Generate::Accessor::CAN_HAZ_XS = 0;
  #TODO: add Storable hooks
  $self->$orig(@_);
};

sub _generate_simple_get {
  my ($self, $me, $name) = @_;
  my $name_str = quotify $name;
  $self->{captures}{'$MooX_InsideOut_FIELDS'} = \\%FIELDS;
  "\$MooX_InsideOut_FIELDS->{${me}}->{${name_str}}";
}

sub _generate_simple_has {
  my ($self, $me, $name) = @_;
  "exists " . $self->_generate_simple_get($me, $name);
}

sub _generate_simple_clear {
  my ($self, $me, $name) = @_;
  "delete " . $self->_generate_simple_get($me, $name);
}

sub _generate_core_set {
  my ($self, $me, $name, $spec, $value) = @_;
  $self->_generate_simple_get($me, $name) . " = ${value}";
}

sub _generate_xs {
  die "Can't generate XS accessors for inside out objects";
}

sub default_construction_string { '\(my $s)' }

1;
