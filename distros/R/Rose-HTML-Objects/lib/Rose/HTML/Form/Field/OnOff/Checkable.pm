package Rose::HTML::Form::Field::OnOff::Checkable;

use strict;

use base 'Rose::HTML::Form::Field::OnOff';

our $VERSION = '0.606';

__PACKAGE__->add_required_html_attrs(
{
  value => 'on',
});

sub checked
{
  my($self) = shift;

  if(@_)
  {
    $self->is_cleared(0);

    $self->{'checked'} = 
      $self->html_attr(checked => $_[0] ? 1 : (defined $_[0] ? 0 : undef));

    if((my $parent = $self->parent_field) && $self->auto_invalidate_parent)
    {
      $parent->invalidate_value;
    }

    return $self->{'checked'};
  }

  return 0  if($self->is_cleared);
  return defined $self->{'checked'} ? $self->{'checked'} : $self->default_value;
}

*input_value = \&checked;

sub is_checked { shift->checked ? 1 : 0 }

sub is_on { shift->is_checked }

sub value { shift->html_attr('value', @_) }

sub clear
{
  my($self) = shift;

  $self->checked(0);
  $self->error(undef);
  $self->is_cleared(1);
}

sub reset
{
  my($self) = shift;

  $self->checked(undef);
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
      $self->checked(undef);
    }
  }

  return $self->{'_hidden'};
}

1;
