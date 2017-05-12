package Rose::HTML::Form::Field::OnOff::Selectable;

use strict;

use base 'Rose::HTML::Form::Field::OnOff';

our $VERSION = '0.606';

__PACKAGE__->required_html_attr_value
(
  value => '',
);

sub selected
{
  my($self) = shift;

  if(@_)
  {
    $self->is_cleared(0);
    return $self->{'selected'} = 
      $self->html_attr(selected => $_[0] ? 1 : (defined $_[0] ? 0 : undef));
  }

  return 0  if($self->is_cleared);

  return defined $self->{'selected'} ? $self->{'selected'} : $self->default_value;
}

*input_value = \&selected;

sub is_selected { shift->selected ? 1 : 0 }

sub is_on { shift->is_selected }

sub clear
{
  my($self) = shift;

  $self->selected(0);
  $self->error(undef);
  $self->is_cleared(1);
}

sub reset
{
  my($self) = shift;

  $self->selected(undef);
  $self->error(undef);
  $self->is_cleared(0);
  return 1;
}

sub hidden
{
  my($self) = shift;

  if(@_)
  {
    if($self->{'_hidden'} = shift(@_) ? 1 : 0)
    {
      $self->selected(undef);
    }
  }

  return $self->{'_hidden'};
}

1;
