package MooseX::RememberHistory::Trait::Attribute;
{
  $MooseX::RememberHistory::Trait::Attribute::VERSION = '0.001';
}

use Moose::Role;

has 'history_getter' => (
  isa => 'Str',
  is  => 'ro',
  lazy => 1,
  builder => '_history_name',
);

sub _history_name {
  my $attr = shift;
  my $name = $attr->name;
  return $name . '_history';
}

around 'install_accessors' => sub { 
  my $orig = shift;
  my $attr = shift;

  my $class = $attr->associated_class;
  my $hist_name = $attr->history_getter;

  #add history holder
  $class->add_attribute(
    $hist_name => (
      is => 'rw',
      isa => 'ArrayRef',
      default => sub { [] },
    ),
  );

  $attr->$orig(@_);

  # sync history on first access
  $class->add_around_method_modifier($hist_name, sub{
    my $orig = shift;
    my $self = shift;
    my $history = $self->$orig(@_);
    unless (@$history) {
      my $old_val = $attr->get_value($self);
      push @$history, $old_val if defined $old_val;
    }
    return $history;
  });

  # push on to history on write
  my $writer_name = $attr->get_write_method;
  $class->add_before_method_modifier($writer_name, sub{
    my ($self, $value) = @_;
    return unless defined $value;
    my $history = $self->can($hist_name)->($self);
    push @$history, $value;
  });
};

1;

