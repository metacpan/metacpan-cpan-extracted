package Rose::HTML::Form::Field::Group::OnOff;

use strict;

use Carp();

use Rose::HTML::Util();

use base 'Rose::HTML::Form::Field::Group';

our $VERSION = '0.606';

our $Debug = undef;

sub resync_name
{
  my($self) = shift;

  $self->SUPER::resync_name();

  # Resync item names too
  my $name = $self->local_name;

  foreach my $item ($self->items)
  {
    $item->name($name);
  }
}

sub name
{
  my($self) = shift;

  if(@_)
  {
    $self->local_name(shift);

    my $name = $self->local_name;

    # All items in the group must have the same name
    foreach my $item ($self->items)
    {
      $item->name($name);
    }
  }

  my $name = $self->html_attr('name');

  # The name HTML attr will be an empty string if it's a required attr,
  # so use length() and not defined()
  no warnings 'uninitialized';
  unless(length $name)
  {
    return $self->html_attr('name', $self->fq_name);
  }

  return $name;
}

sub defaults
{
  my($self) = shift;

  if(@_)
  {
    if(@_ == 1 && ref $_[0] eq 'ARRAY')
    {
      $self->{'defaults'} = { map { $_ => 1 } @{$_[0]} };
    }
    elsif(defined $_[0])
    {
      $self->{'defaults'} = { map { $_ => 1 } @_ };
    }
    else
    {
      $self->{'defaults'} = { };
    }

    $self->init_items;
  }

  return (wantarray) ? sort keys %{$self->{'defaults'}} : [ sort keys %{$self->{'defaults'}} ];
}

*default        = \&defaults;
*default_value  = \&defaults;
*default_values = \&defaults;

sub default_values_hash { (wantarray) ? %{$_[0]->{'defaults'}} : $_[0]->{'defaults'} }

sub _args_to_items
{
  my($self) = shift;

  my $items = $self->SUPER::_args_to_items(@_);

  # All items in the group must have the same name
  foreach my $item (@$items)
  {
    $item->name($self->local_name);
    #$item->name($self->name);
  }

  return (wantarray) ? @$items : $items;
}

sub item
{
  my($self, $value) = @_;

  my $group_class = $self->_item_group_class;

  # Dumb linear search for now
  foreach my $item ($self->items)
  {
    if($item->isa($group_class))
    {
      foreach my $subitem ($item->items)
      {
        return $subitem  if($subitem->html_attr('value') eq $value);
      }
    }
    else
    {
      return $item  if($item->html_attr('value') eq $value);
    }
  }

  return undef;
}

sub item_group
{
  my($self, $label) = @_;

  my $group_class = $self->_item_group_class;

  # Dumb linear search for now
  foreach my $item ($self->items)
  {
    return  $item  if($item->isa($group_class) && $item->label eq $label);
  }

  return undef;
}

sub is_selected
{
  my($self, $value) = @_;

  # Dumb linear search for now
  foreach my $item ($self->items)
  {
    if($item->html_attr('value') eq $value && $item->internal_value)
    {
      return 1;
    }
  }

  return 0;
}

*is_checked = \&is_selected;

sub is_empty
{
  my($self) = shift;

  foreach my $item ($self->items)
  {
    return 0  if($item->is_on);
  }

  return 1;
}

sub add_values
{
  my($self) = shift;

  $self->input_value($self->internal_value, @_);
}

sub add_value { shift->add_values(@_) }

sub input_value
{
  my($self) = shift;

  my %values;

  if(@_)
  {
    $self->clear();
    $self->is_cleared(0);

    if(@_ == 1 && ref $_[0] eq 'ARRAY')
    {
      %values = map { $_ => 1 } @{$_[0]};
    }
    elsif(@_ && defined $_[0])
    {
      %values = map { $_ => 1 } @_;
    }

    unless(%values)
    {
      $self->clear();
      $self->is_cleared(0);
    }
    else
    {
      $self->{'values'} = \%values;
      $self->init_items;
    }

    if(my $parent = $self->parent_field)
    {
      if($parent->_is_full)
      {
        $parent->is_cleared(0);
      }

      if($self->auto_invalidate_parent)
      {
        $parent->invalidate_value;
      }
    }
  }
  else
  {
    if(keys %{$self->{'values'}})
    {
      my $group_class = $self->_item_group_class;

      foreach my $item ($self->items)
      {
        if($item->isa($group_class))
        {
          foreach my $value ($item->internal_value)
          {
            $values{$value} = 1;
          }
        }
        else
        {
          if($item->is_on)
          {
            $values{$item->html_attr('value')} = 1;
          }
        }
      }
    }
  }

  return (wantarray) ? sort keys %values : [ sort keys %values ];
}

sub value_labels
{
  my($self) = shift;

  my @labels;

  foreach my $value ($self->internal_value)
  {
    next  unless(defined $value);
    push(@labels, $self->item($value)->label);
  }

  return wantarray ? @labels : \@labels;
}

sub value_label 
{
  my($self) = shift;

  unless(@_)
  {
    return $self->value_labels->[0];
  }

  my $value = shift;

  # Dumb linear search for now
  foreach my $item ($self->items)
  {
    if($item->html_attr('value') eq $value)
    {
      return $item-label(@_)  if(@_);
      return ($item->label) ? $item->label : $value;
    }
  }

  return undef;
}

#sub value_label { shift->value_labels->[0] }

sub value  { shift->input_value(@_) }
sub values { shift->input_value(@_) }

sub is_on { Carp::croak "Override in subclass!" }

sub internal_value
{
  my($self) = shift;

  my @values;

  my $group_class = $self->_item_group_class;

  foreach my $item ($self->items)
  {
    if($item->isa($group_class))
    {
      push(@values, $item->internal_value)  if(defined $item->internal_value);
    }
    else
    {
      push(@values, $item->value)  if($item->is_on);
    }
  }

  @values = sort @values; # Makes tests easier to write... :-/

  return wantarray ? @values : \@values;
}

*output_value = \&internal_value;

sub input_values_hash { (wantarray) ? %{$_[0]->{'values'}} : $_[0]->{'values'} }

sub has_value
{
  my($self, $find_value) = @_;

  foreach my $value ($self->output_value)
  {
    return 1  if($value eq $find_value);
  }

  return 0;
}

sub init_items
{
  my($self) = shift;

  my $values = $self->input_values_hash || {};

  if(%$values)
  {
    my $group_class = $self->_item_group_class;

    foreach my $item ($self->items)
    {
      local $item->{'auto_invalidate_parent'} = $self->auto_invalidate_parent;

      if($item->isa($group_class))
      {
        foreach my $subitem ($item->items)
        {
          if(exists $values->{$subitem->html_attr('value')})
          {
            $subitem->input_value(1);
          }
          else
          {
            $subitem->input_value(0);
          }
        }
      }
      else
      {
        if(exists $values->{$item->html_attr('value')})
        {
          $item->input_value(1);
        }
        else
        {
          $item->input_value(0);
        }
      }
    }
  }
  elsif(!$self->is_cleared)
  {
    my $defaults = $self->default_values_hash;

    foreach my $item ($self->items)
    {
      my $value = $item->html_attr('value');

      if(defined $value && exists $defaults->{$value})
      {
        $item->default_value(1);
      }
      else
      {
        $item->default_value(0);
      }
    }
  }
}

1;
