package Reaction::UI::ViewPort::Field::Mutable::ChooseOne;

use Reaction::Class;
use Scalar::Util ();

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::ViewPort::Field';

with 'Reaction::UI::ViewPort::Field::Role::Mutable::Simple';
with 'Reaction::UI::ViewPort::Field::Role::Choices';
sub adopt_value_string {
  my ($self) = @_;
  my $value = $self->value_string;
  if(!defined($value) or !length $value) {
    $self->clear_value;
    return;
  }
  $value = $self->str_to_ident($value) if (!ref $value);
  my $attribute = $self->attribute;
  my $checked = $attribute->check_valid_value($self->model, $value);
  unless (defined $checked) {
    require Data::Dumper; 
    my $serialised = Data::Dumper->new([ $value ])->Indent(0)->Dump;
    $serialised =~ s/^\$VAR1 = //; $serialised =~ s/;$//;
    confess "${serialised} is not a valid value for ${\$attribute->name} on "
            ."${\$attribute->associated_class->name}";
  }
  $self->value($checked);
};

around _value_string_from_value => sub {
  my $orig = shift;
  my $self = shift;
  my $value = $self->$orig(@_);

# what's up with $value->{value} ?!
# and why are we calling obj_to_name here, shouldn't it be obj_to_str
#  return $self->obj_to_name($value->{value}) if Scalar::Util::blessed($value);
#  return $self->obj_to_name($value) if blessed $value;

  return $self->obj_to_str($value) if Scalar::Util::blessed($value);

  return "$value"; # force stringify. might work. probably won't.
};
sub is_current_value {
  my ($self, $check_value) = @_;
  return unless $self->_model_has_value;
  my $our_value = $self->value;
  return unless defined($our_value);
  $check_value = $self->obj_to_str($check_value) if ref($check_value);
  return $self->obj_to_str($our_value) eq $check_value;
};

__PACKAGE__->meta->make_immutable;


1;
