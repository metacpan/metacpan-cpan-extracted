package Rose::HTML::Form::Field::OnOff;

use strict;

use base 'Rose::HTML::Form::Field::Input';

use Rose::HTML::Form::Constants qw(FF_SEPARATOR);

our $VERSION = '0.606';

use Rose::Object::MakeMethods::Generic
(
  boolean => 'hidden',
);

__PACKAGE__->add_required_html_attrs(
{
  value => 'on',
});

sub value { shift->html_attr('value', @_) }

sub value_label { $_[0]->is_on ? $_[0]->label : undef }

sub internal_value { $_[0]->is_on ? $_[0]->html_attr('value') : undef }
sub output_value   { $_[0]->is_on ? $_[0]->html_attr('value') : undef }

sub hide { shift->hidden(1) }
sub show { shift->hidden(0) }

sub group_context_name
{
  my($self) = shift;
  my $parent_group = $self->parent_group or return;
  my $name = $parent_group->fq_name or return;
  return $name;
}

sub fq_name
{
  my($self) = shift;

  my $name = $self->group_context_name;
  $name = $self->local_name  unless(defined $name);

  return join(FF_SEPARATOR, grep { defined } $self->form_context_name, 
                                             $self->field_context_name,
                                             $name);
}

my $sep = FF_SEPARATOR;

sub fq_moniker
{
  my($self) = shift;

  my $name = $self->group_context_name;

  if(defined $name)
  {
    my $moniker = $self->local_moniker;
    $name =~ s/(?:^|\Q$sep\E)[^$sep]+$/$moniker/o;
  }
  else { $name = $self->local_moniker }

  return join(FF_SEPARATOR, grep { defined } $self->form_context_name,
                                             $self->field_context_name, 
                                             $name);
}

1;
