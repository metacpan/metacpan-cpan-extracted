package Rose::HTML::Form::Field::Collection;

use strict;

use Carp();
use Scalar::Util qw(refaddr);

use Rose::HTML::Form::Field::Hidden;

use base 'Rose::HTML::Object';

use Rose::HTML::Form::Constants qw(FF_SEPARATOR);

# Variables for use in regexes
our $FF_SEPARATOR_RE = quotemeta FF_SEPARATOR;

our $VERSION = '0.606';

#
# Object data
#

use Rose::Object::MakeMethods::Generic
(
  boolean => 'coalesce_hidden_fields',

  'scalar --get_set_init'  => 
  [
    'field_rank_counter',
  ],

  array =>
  [
    'before_prepare_hooks'     => {},
    'add_before_prepare_hooks' => { interface => 'push', hash_key => 'before_prepare_hooks' },

    'after_prepare_hooks'     => {},
    'add_after_prepare_hooks' => { interface => 'push', hash_key => 'after_prepare_hooks' },
    'clear_prepare_hooks'     => { interface => 'clear', hash_key => 'after_prepare_hooks' },
  ],
);

*add_before_prepare_hook    = \&add_before_prepare_hooks;
*add_after_prepare_hook     = \&add_after_prepare_hooks;

#
# Class methods
#

sub prepare
{
  my($self)  = shift;

  foreach my $hook ($self->before_prepare_hooks)
  {
    $hook->($self, @_);
  }

  my %args = @_;

  unless($args{'form_only'})
  {
    foreach my $field ($self->fields)
    {
      $field->prepare(@_);
    }
  }

  foreach my $form ($self->forms)
  {
    $form->prepare(form_only => 1, @_);
  }

  foreach my $hook ($self->after_prepare_hooks)
  {
    $hook->($self, @_);
  }
}

sub add_prepare_hook
{
  my($self) = shift;

  if(@_ == 1)
  {
    $self->add_before_prepare_hook(@_);
  }
  elsif(@_ == 2)
  {
    my $where = shift;

    unless($where eq 'before' || $where eq 'after')
    {
      Carp::croak "Illegal prepare hook position: $where";
    }

    my $method = "add_${where}_prepare_hook";

    no strict 'refs';
    $self->$method(@_);
  }
  else
  {
    Carp::croak "Incorrect number of arguments to add_prepare_hook()";
  }
}

sub prepare_hook
{
  my($self) = shift;
  $self->clear_prepare_hooks;
  $self->add_prepare_hook(@_);
}

BEGIN
{
  *add_field_type_classes  = \&Rose::HTML::Object::add_object_type_classes;
  *field_type_classes      = \&Rose::HTML::Object::object_type_classes;
  *field_type_class        = \&Rose::HTML::Object::object_type_class;
  *delete_field_type_class = \&Rose::HTML::Object::delete_object_type_class;
}

#
# Object methods
#

sub html
{
  my($self) = shift;

  no warnings 'uninitialized';

  if($self->has_children || !$self->is_self_closing)
  {
    return '<' . $self->html_element . $self->html_attrs_string . '>' . 
           join('', map 
           {
             $_->isa('Rose::HTML::Form::Field') ?
               '<div class="field-with-label">' . $_->html_label . 
               '<div class="field">' . $_->html . '</div></div>' :
               $_->html
           }
           $self->children) . 
           '</' . $self->html_element . '>';
  }

  return '<' . $self->html_element . $self->html_attrs_string . '>';
}

sub xhtml
{
  my($self) = shift;

  no warnings 'uninitialized';

  if($self->has_children || !$self->is_self_closing)
  {
    return '<' . $self->xhtml_element . $self->xhtml_attrs_string . '>' . 
           join('', map 
           {
             $_->isa('Rose::HTML::Form::Field') ?
               '<div class="field-with-label">' . $_->xhtml_label . 
               '<div class="field">' . $_->xhtml . '</div></div>' :
               $_->xhtml
           }
           $self->children) . 
           '</' . $self->xhtml_element . '>';
  }

  return '<' . $self->xhtml_element . $self->xhtml_attrs_string . ' />';
}

sub init_field_rank_counter { 1 }

sub increment_field_rank_counter
{
  my($self) = shift;
  my $rank = $self->field_rank_counter;
  $self->field_rank_counter($rank + 1);
  return $rank;
}

sub make_field
{
  my($self, $name, $value) = @_;

  return $value  if(UNIVERSAL::isa($value, 'Rose::HTML::Form::Field'));

  my($type, $args);

  if(ref $value eq 'HASH')
  {
    $type = delete $value->{'type'} or Carp::croak "Missing field type";
    $args = $value;
  }
  elsif(!ref $value)
  {
    $type = $value;
    $args = {};
  }
  else
  {
    Carp::croak "Not a Rose::HTML::Form::Field object or hash ref: $value";
  }

  my $class = ref $self || $self;

  my $field_class = $class->field_type_class($type) 
    or Carp::croak "No field class found for field type '$type'";

  unless($field_class->can('new'))
  {
    my $error;

    TRY:
    {
      local $@;
      eval "require $field_class";
      $error = $@;
    }

    Carp::croak "Failed to load field class $field_class - $error"  if($error);
  }

  # Compound fields require a name
  if(UNIVERSAL::isa($field_class, 'Rose::HTML::Form::Field::Compound'))
  {
    $args->{'name'} = $name;
  }

  return $field_class->new(%$args);
}

sub invalidate_field_caches
{
  my($self) = shift;

  $self->{'field_cache'} = {};
}

sub field
{
  my($self, $name, $field) = @_;

  if(@_ == 3)
  {
    unless(UNIVERSAL::isa($field, 'Rose::HTML::Form::Field'))
    {
      $field = $self->make_field($name, $field);
    }

    $field->local_moniker($name);

    if($self->isa('Rose::HTML::Form'))
    {
      $field->parent_form($self);
    }
    else
    {
      $field->parent_field($self);
    }

    $self->_clear_field_generated_values;

    unless(defined $field->rank)
    {
      $field->rank($self->increment_field_rank_counter);
    }

    return $self->{'fields'}{$name} = $self->{'field_cache'}{$name} = $field;
  }

  if($self->{'fields'}{$name})
  {
    return $self->{'fields'}{$name};
  }

  my $sep_pos;

  # Non-hierarchical name
  if(($sep_pos = index($name, FF_SEPARATOR)) < 0)
  {
    return undef; # $self->local_field($name, @_);
  }

  # Check if it's a local compound field  
  my $prefix = substr($name, 0, $sep_pos);
  my $rest   = substr($name, $sep_pos + 1);
  $field = $self->field($prefix);

  if(UNIVERSAL::isa($field, 'Rose::HTML::Form::Field::Compound'))
  {
    $field = $field->field($rest);
    return ($self->{'field_cache'}{$name} = $field)  if($field);
  }

  return undef;
}

sub find_parent_field
{
  my($self, $name) = @_;

  # Non-hierarchical name
  if(index($name, FF_SEPARATOR) < 0)
  {
    return $self->local_form($name) ? ($self, $name) : undef;
  }

  my $parent_form;

  while($name =~ s/^([^$FF_SEPARATOR_RE]+)$FF_SEPARATOR_RE//o)
  {
    my $parent_name = $1;
    last  if($parent_form = $self->local_form($parent_name));
  }

  return unless(defined $parent_form);
  return wantarray ? ($parent_form, $name) : $parent_form;
}

sub add_fields
{
  my($self) = shift;

  my @added_fields;

  @_ = @{$_[0]}  if(@_ == 1 && ref $_[0] eq 'ARRAY');

  while(@_)
  {
    my $arg = shift;

    if(UNIVERSAL::isa($arg, 'Rose::HTML::Form::Field'))
    {
      my $field = $arg;

      if(refaddr($field) eq refaddr($self))
      {
        Carp::croak "Cannot nest a field within itself";
      }

      $field->local_name($field->name);

      if($self->can('form') && $self->form($field->local_name))
      {
        Carp::croak "Cannot add field with the same name as an existing sub-form: ", 
                    $field->local_name;
      }

      unless(defined $field->rank)
      {
        $field->rank($self->increment_field_rank_counter);
      }

      $self->field($field->local_name => $field);
      push(@added_fields, $field);
    }
    else
    {
      my $field = shift;

      if($self->can('form') && $self->form($arg))
      {
        Carp::croak "Cannot add field with the same name as an existing sub-form: $arg";
      }

      if(UNIVERSAL::isa($field, 'Rose::HTML::Form::Field'))
      {
        if(refaddr($field) eq refaddr($self))
        {
          Carp::croak "Cannot nest a field within itself";
        }
      }
      else
      {
        $field = $self->make_field($arg, $field);
      }

      $field->local_moniker($arg);

      unless(defined $field->rank)
      {
        $field->rank($self->increment_field_rank_counter);
      }

      $self->field($arg => $field);
      push(@added_fields, $field);
    }
  }

  $self->_clear_field_generated_values;
  $self->resync_field_names;

  return  unless(defined wantarray);
  return wantarray ? @added_fields : $added_fields[0];
}

sub add_field { shift->add_fields(@_) }

sub compare_fields 
{
  my($self, $one, $two) = @_;
  no warnings 'uninitialized';
  $one->name cmp $two->name;
}

sub resync_field_names
{
  my($self) = shift;

  foreach my $field ($self->fields)
  {
    $field->resync_name;
    $field->resync_field_names  if($field->isa('Rose::HTML::Form::Field::Compound'));
    #$field->name; # Pull the new name through to the name HTML attribute
  }
}

sub children 
{
  Carp::croak "Cannot set children() for a pseudo-group ($_[0])"  if(@_ > 1);
  return wantarray ? shift->fields() : (shift->fields() || []);
}

sub field_value
{
  my($self, $name) = (shift, shift);

  my $field = $self->field($name) 
    or Carp::croak "No field named '$name' in $self";

  return $field->input_value(@_)  if(@_);
  return $field->internal_value;
}

*subfield_value = \&field_value;

sub subfield_names
{
  my($self) = shift;

  my @names;

  foreach my $field ($self->fields)
  {
    push(@names, $field->name, ($field->can('_subfield_names') ? $field->_subfield_names : ()));
  }

  return wantarray ? @names : \@names;
}

sub _subfield_names
{
  map { $_->can('subfield_names') ? $_->subfield_names : $_->name } shift->fields;
}

sub fields
{
  my($self) = shift;

  if(my $fields = $self->{'field_list'})
  {
    return wantarray ? @$fields : $fields;
  }

  my $fields = $self->{'fields'};

  $self->{'field_list'} = [ grep { defined } map { $fields->{$_} } $self->field_monikers ];

  return wantarray ? @{$self->{'field_list'}} : $self->{'field_list'};
}

sub fields_as_children
{
  my($self) = shift;

  Carp::croak "Cannot directly set children() for a ", ref($self), 
              ".  Use fields(), push_children(), pop_children(), etc."  if(@_);

  my @children;

  foreach my $field ($self->fields)
  {
    if($field->is_flat_group)
    {
      push(@children, $field->items);
    }
    else
    {
      push(@children, $field);
    }
  }

  return wantarray ? @children : \@children;
}

*immutable_children = \&fields_as_children;

sub num_fields
{
  my $fields = shift->fields;
  return $fields && @$fields ? scalar @$fields : 0;
}

sub field_monikers
{
  my($self) = shift;

  if(my $names = $self->{'field_monikers'})
  {
    return wantarray ? @$names : $names;
  }

  my @info;

  while(my($name, $field) = each %{$self->{'fields'}})
  {
    push(@info, [ $name, $field ]);
  }

  $self->{'field_monikers'} = 
    [ map { $_->[0] } sort { $self->compare_fields($a->[1], $b->[1]) } @info ];

  return wantarray ? @{$self->{'field_monikers'}} : $self->{'field_monikers'};
}

sub delete_fields 
{
  my($self) = shift;
  $self->_clear_field_generated_values;
  $self->{'fields'} = {};
  $self->field_rank_counter(undef);
  return;
}

sub delete_field
{
  my($self, $name) = @_;

  $name = $name->name  if(UNIVERSAL::isa($name, 'Rose::HTML::Form::Field'));

  $self->_clear_field_generated_values;

  delete $self->{'field_cache'}{$name};
  delete $self->{'fields'}{$name};
}

sub clear_fields
{
  my($self) = shift;

  foreach my $field ($self->fields)
  {
    $field->clear();
  }
}

sub reset_fields
{
  my($self) = shift;

  foreach my $field ($self->fields)
  {
    $field->reset();
  }
}

sub _clear_field_generated_values
{
  my($self) = shift;  
  $self->{'field_list'}  = undef;
  $self->{'field_monikers'} = undef;
  $self->invalidate_field_caches;

  # XXX: This is super-incestuous
  if(my $parent_form = $self->parent_form)
  {
    $parent_form->_clear_field_generated_values;
  }
}

sub hidden_field
{
  my($self) = shift;

  no warnings 'uninitialized';
  my $name = $self->fq_name;

  return 
    ref($self)->object_type_class_loaded('hidden')->new(
      name  => $name,
      value => $self->output_value);
}

sub hidden_fields
{
  my($self) = shift;

  my @hidden;

  if($self->coalesce_hidden_fields)
  {
    foreach my $field ($self->fields)
    {
      push(@hidden, $field->hidden_field);
    }
  }
  else
  {
    foreach my $field ($self->fields)
    {
      push(@hidden, $field->hidden_fields);
    }
  }

  return (wantarray) ? @hidden : \@hidden;
}

sub html_hidden_field
{
  my($self) = shift;

  if(defined $self->output_value)
  {
    return $self->hidden_field->html_field;
  }

  return $self->html_hidden_fields;
}

sub xhtml_hidden_field
{
  my($self) = shift;

  if(defined $self->output_value)
  {
    return $self->hidden_field->xhtml_field;
  }

  return $self->xhtml_hidden_fields;
}

sub html_hidden_fields
{
  my($self) = shift;

  my @html;

  foreach my $field ($self->hidden_fields(@_))
  {
    push(@html, $field->html_field);
  }

  return (wantarray) ? @html : join("\n", @html);
}

sub xhtml_hidden_fields
{
  my($self) = shift;

  my @xhtml;

  foreach my $field ($self->hidden_fields(@_))
  {
    push(@xhtml, $field->xhtml_field);
  }

  return (wantarray) ? @xhtml : join("\n", @xhtml);
}

1;
