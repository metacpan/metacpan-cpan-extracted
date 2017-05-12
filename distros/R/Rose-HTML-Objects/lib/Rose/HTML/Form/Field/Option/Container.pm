package Rose::HTML::Form::Field::Option::Container;

use strict;

use Carp();

use base 'Rose::HTML::Form::Field::Group::OnOff';

use Rose::HTML::Form::Field::Group;

require Rose::HTML::Form::Field::Option;
require Rose::HTML::Form::Field::OptionGroup;

our $VERSION = '0.606';

sub _item_class       { shift->object_type_class_loaded('option') }
sub _item_group_class { shift->object_type_class_loaded('option group') }
sub _item_name        { 'option' }
sub _item_name_plural { 'options' }

*options               = \&Rose::HTML::Form::Field::Group::items;
*options_localized     = \&Rose::HTML::Form::Field::Group::items_localized;
*option                = \&Rose::HTML::Form::Field::Group::OnOff::item;
*option_group          = \&Rose::HTML::Form::Field::Group::OnOff::item_group;
*visible_options       = \&Rose::HTML::Form::Field::Group::visible_items;

*add_options           = \&Rose::HTML::Form::Field::Group::add_items;
*add_option            = \&add_options;
*add_options_localized = \&Rose::HTML::Form::Field::Group::add_items_localized;
*add_option_localized  = \&add_options_localized;

*add_options_localized = \&Rose::HTML::Form::Field::Group::add_items_localized;
*add_option_localized  = \&Rose::HTML::Form::Field::Group::add_item_localized;

*choices           = \&options;
*choices_localized = \&options_localized;

*_args_to_items = \&Rose::HTML::Form::Field::Group::_args_to_items;

*show_all_options = \&Rose::HTML::Form::Field::Group::show_all_items;
*hide_all_options = \&Rose::HTML::Form::Field::Group::hide_all_items;

*delete_option  = \&Rose::HTML::Form::Field::Group::delete_item;
*delete_options = \&Rose::HTML::Form::Field::Group::delete_items;

*delete_option_group  = \&Rose::HTML::Form::Field::Group::delete_item_group;
*delete_option_groups = \&Rose::HTML::Form::Field::Group::delete_item_groups;

sub html_element  { 'select' }
sub xhtml_element { 'select' }

#sub name { shift->html_attr('name', @_) }

sub is_flat_group { 0 }

sub is_empty 
{
  no warnings 'uninitialized';
  return (grep { /\S/ } shift->internal_value) ? 0 : 1;
}

sub children
{
  my($self) = shift;
  Carp::croak "Cannot set children() for an option container ($_[0]).  Use options() instead."  if(@_);  
  return $self->options;
}

sub push_children    { shift->add_items(@_) }
sub push_child       { shift->add_item(@_) }

sub pop_children     { shift->pop_items(@_) }
sub pop_child        { shift->pop_item(@_) }

sub shift_children   { shift->add_items(@_) }
sub shift_child      { shift->add_item(@_) }

sub unshift_children { shift->unshift_items(@_) }
sub unshift_child    { shift->unshift_item(@_) }

sub child
{
  my($self, $index) = @_;
  my $items = $self->items || [];
  return $items->[$index];
}

sub delete_child_at_index
{
  my($self) = shift;
  Carp::croak "Missing array index"  unless(@_);
  my $items = $self->items || [];
  no warnings;
  splice(@$items, $_[0], 1);
}

sub html_field
{
  my($self) = shift;

  my $html;

  if($self->apply_error_class && defined $self->error)
  {
    my $class = $self->html_attr('class');
    $self->html_attr(class => $class ? "$class error" : 'error');
    $html = $self->start_html . "\n" . 
            join("\n", map { $_->html_field } $self->visible_items) . "\n" .
            $self->end_html;
    $self->html_attr(class => $class);
    return $html;
  }
  else
  {
    return $self->start_html . "\n" . 
           join("\n", map { $_->html_field } $self->visible_items) . "\n" .
           $self->end_html;
  }
}

sub xhtml_field
{
  my($self) = shift;

  my $xhtml;

  if($self->apply_error_class && defined $self->error)
  {
    my $class = $self->html_attr('class');
    $self->html_attr(class => $class ? "$class error" : 'error');
    $xhtml = $self->start_xhtml . "\n" . 
             join("\n", map { $_->xhtml_field } $self->visible_items) . "\n" .
             $self->end_xhtml;
    $self->html_attr(class => $class);
    return $xhtml;
  }
  else
  {
    return $self->start_xhtml . "\n" . 
           join("\n", map { $_->xhtml_field } $self->visible_items) . "\n" .
           $self->end_xhtml;
  }
}

# sub html_field
# {
#   my($self) = shift;
#   $self->contents("\n" . join("\n", map { $_->html_field } $self->visible_options) . "\n");
#   return $self->_html_tag(@_);
# }
# 
# sub xhtml_field
# {
#   my($self) = shift; 
#   $self->contents("\n" . join("\n", map { $_->xhtml_field } $self->visible_options) . "\n");
#   return $self->_xhtml_tag(@_);
# }

sub input_value
{
  my($self) = shift;

  if(@_ && (@_ > 1 || (ref $_[0] eq 'ARRAY' && @{$_[0]} > 1)) && !$self->multiple)
  {
    Carp::croak "Attempt to select multiple values in a non-multiple " . ref($self);
  }

  my $values = $self->SUPER::input_value(@_);

  Carp::croak "Non-multiple ", ref($self), " has multiple values: ", join(', ', @$values)
    if(@$values > 1 && !$self->multiple);

  return wantarray ? @$values : $values;
}

sub hidden_fields
{
  my($self) = shift;

  my @hidden;

  foreach my $item ($self->items)
  {
    if(defined $item->internal_value)
    {
      # Derek Watson suggests this conditional modifier, but
      # I've yet to see the error is works around...
      $hidden[-1]->name($self->name)
        if(push(@hidden, $item->hidden_field));
    }
  }

  return (wantarray) ? @hidden : \@hidden;
}

sub hidden
{
  my($self) = shift;

  if(@_)
  {
    if($self->{'_hidden'} = shift(@_) ? 1 : 0)
    {
      foreach my $option ($self->options)
      {
        $option->selected(undef);
      }
    }
  }

  return $self->{'_hidden'};
}

sub hide { shift->hidden(1) }
sub show { shift->hidden(0) }

1;

