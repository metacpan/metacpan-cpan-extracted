package Rose::HTML::Form::Field;

use strict;

use Carp();
use Scalar::Util();

use Rose::HTML::Util();

use Rose::HTML::Label;
use Rose::HTML::Object::Errors qw(:field);
use Rose::HTML::Object::Messages qw(:field);

use base 'Rose::HTML::Object';

use constant HTML_ERROR_SEP  => "<br>\n";
use constant XHTML_ERROR_SEP => "<br />\n";

use Rose::HTML::Form::Constants qw(FF_SEPARATOR);

our $VERSION = '0.617';

#our $Debug = 0;

use Rose::HTML::Object::MakeMethods::Localization
(
  localized_message =>
  [
    qw(_error_label label description)
  ],
);

use Rose::Object::MakeMethods::Generic
(
  scalar => [ qw(rank type) ],

  boolean => [ qw(required is_cleared has_partial_value) ],
  boolean => 
  [
    trim_spaces => { default => 1 },
    empty_is_ok => { default => 0 },
  ],

  'scalar --get_set_init' => 
  [
    qw(html_prefix html_suffix html_error_separator xhtml_error_separator
       local_moniker apply_error_class)
  ],
);

__PACKAGE__->add_valid_html_attrs(qw(
  name
  value
  onblur
  onfocus
  accesskey
  tabindex
  autofocus
));

sub is_button { 0 }

*label_id = \&label_message_id;

sub error_label
{
  my($self) = shift;

  if(@_)
  {
    return $self->_error_label(@_);
  }

  my $label = $self->_error_label;

  no warnings 'uninitialized';
  return (defined $label) ? (length $label ? $label : undef) : $self->label;
}

sub error_label_id
{
  my($self) = shift;

  if(@_)
  {
    return $self->_error_label_message_id(@_);
  }

  my $label = $self->_error_label_message_id;

  no warnings 'uninitialized';
  return (defined $label) ? (length $label ? $label : undef) : $self->label;
}

sub init_apply_error_class { 1 }

sub auto_invalidate_parent
{
  my($self) = shift;

  if(@_)
  {
    return $self->{'auto_invalidate_parent'} = $_[0] ? 1 : 0;
  }

  return defined($self->{'auto_invalidate_parent'}) ? 
    $self->{'auto_invalidate_parent'} : 
    ($self->{'auto_invalidate_parent'} = 1);
}

sub invalidate_value
{
  $_[0]->{'input_value'} = undef;
  $_[0]->{'internal_value'} = undef;
  $_[0]->{'output_value'} = undef;
}

sub invalidate_output_value
{
  $_[0]->{'output_value'} = undef;
}

sub parent_group
{
  my($self) = shift; 

  if(@_)
  {
    if(ref $_[0])
    {
      Scalar::Util::weaken($self->{'parent_group'} = shift);
      return $self->{'parent_group'};
    }
    else
    {
      return $self->{'parent_group'} = shift;
    }
  }

  return $self->{'parent_group'};
}

sub parent_field
{
  my($self) = shift; 

  if(@_)
  {
    if(ref $_[0])
    {
      Scalar::Util::weaken($self->{'parent_field'} = shift);
      return $self->{'parent_field'};
    }
    else
    {
      return $self->{'parent_field'} = shift;
    }
  }

  return $self->{'parent_field'};
}

sub parent_form
{
  my($self) = shift; 

  if(@_)
  {
    if(ref $_[0])
    {
      Scalar::Util::weaken($self->{'parent_form'} = shift);
      return $self->{'parent_form'};
    }
    else
    {
      return $self->{'parent_form'} = shift;
    }
  }

  return $self->{'parent_form'};
}

sub field_depth
{
  my($self) = shift;

  my $parent = $self->parent_field || $self->parent_form;

  return 0  unless($parent);

  my $depth = 1;
  $depth++ while($parent = $parent->parent_field || $parent->parent_form);

  return $depth;
}

sub fq_name
{
  my($self) = shift;
  return join(FF_SEPARATOR, grep { defined } $self->form_context_name, 
                                             $self->field_context_name, 
                                             $self->local_name);
}

sub fq_moniker
{
  my($self) = shift;

  return join(FF_SEPARATOR, grep { defined } $self->form_context_name,
                                             $self->field_context_name, 
                                             $self->local_moniker);
}

sub init_local_moniker { shift->local_name }

sub form_context_name
{
  my($self) = shift;
  my $parent_form = $self->parent_form or return undef;
  return $parent_form->fq_form_name;
}

sub field_context_name
{
  my($self) = shift;
  my $parent_field = $self->parent_field or return undef;
  my $name = $parent_field->fq_name or return undef;
  return $name;
}

sub is_flat_group { 0 }

sub init_html_prefix { '' }
sub init_html_suffix { '' }

sub init_html_error_separator  { HTML_ERROR_SEP  }
sub init_xhtml_error_separator { XHTML_ERROR_SEP }

sub value
{
  my($self) = shift;

  if(@_)
  {
    return $self->input_value($self->html_attr('value', shift));
  }
  else
  { 
    return $self->html_attr('value');
  }
}

sub resync_name
{
  my($self) = shift;

  $self->html_attr('name', undef);
  $self->name  if($self->parent_field || $self->parent_form);
  #$self->name($self->fq_name);
}

sub local_name
{
  my($self) = shift;

  if(@_)
  {
    my $name = shift;

    no warnings 'uninitialized';
    if(index($name, FF_SEPARATOR) >= 0 && !$self->isa('Rose::HTML::Form::Field::Hidden'))
    {
      Carp::croak "Invalid local field name: $name";
    }

    my $old_name = $self->{'local_name'};
    $self->{'local_name'} = $name;    

    if(defined $old_name && $name ne $old_name)
    {
      if(my $parent_form = $self->parent_form)
      {
        $parent_form->delete_field($old_name);
        $parent_form->add_field($name => $self);
      }

      if(my $parent_field = $self->parent_field)
      {
        $parent_field->delete_field($old_name);
        $parent_field->add_field($name => $self);      
      }
    }

    return $name;
  }

  my $name = $self->{'local_name'};
  return $name  if(defined $name);
  return $self->{'local_name'} = $self->{'local_moniker'};
}

sub name
{
  my($self) = shift;

  if(@_)
  {
    $self->local_name(shift);
    return $self->html_attr('name', $self->fq_name);
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

sub moniker
{
  my($self) = shift;

  if(@_)
  {
    return $self->fq_moniker($self->{'moniker'} = shift);
  }
  else
  {
    return $self->{'moniker'}  if(defined $self->{'moniker'});
    return $self->{'moniker'} = $self->fq_moniker;
  }
}

sub default_value
{
  my($self) = shift;

  if(@_)
  {
    $self->{'internal_value'} = undef;
    $self->{'output_value'} = undef;
    return $self->{'default_value'} = shift;
  }

  return $self->{'default_value'};
}

sub default { shift->default_value(@_) }

sub inflate_value { $_[1] }
sub deflate_value { $_[1] }

sub input_value
{
  my($self) = shift;

  if(@_)
  {
    $self->{'is_cleared'} = 0;
    $self->{'internal_value'} = undef;
    $self->{'output_value'} = undef;
    $self->{'errors'} = undef;
    $self->{'input_value'} = shift;

    if(my $parent = $self->parent_field)
    {
      $parent->is_cleared(0)  if(!$parent->{'in_init'} && $parent->_is_full);

      if($self->auto_invalidate_parent)
      {
        $parent->invalidate_value;
      }
    }

    return $self->{'input_value'};
  }

  return undef  if($self->is_cleared || $self->has_partial_value);

  my $value = 
    (defined $self->{'input_value'}) ? $self->{'input_value'} :  
    $self->default_value;

  if(wantarray && ref $value eq 'ARRAY')
  {
    return @$value;
  }

  return $value;
}

sub _set_input_value
{
  # XXX: Evil, but I can't bear to add 3 method calls to
  # XXX: save and then restore this value.
  local $_[0]->{'auto_invalidate_parent'} = 0;
  shift->input_value(@_);
}

sub _is_full
{
  my($self) = shift;

  if($self->is_full(@_))
  {
    $self->has_partial_value(0);
    return 1;
  }

  return 0;
}

sub input_value_filtered
{
  my($self) = shift;

  my $value = $self->input_value;

  $value = $self->input_prefilter($value);

  if(my $input_filter = $self->input_filter)
  {
    local $_ = $value;
    $value = $input_filter->($self, $value);
  }

  return $value;
}

sub internal_value
{
  my($self) = shift;

  Carp::croak "Cannot set the internal value.  Use input_value() instead."  if(@_);

  return undef  if($self->is_cleared || $self->has_partial_value);

  if(defined $self->{'internal_value'})
  {
    if(wantarray && ref $self->{'internal_value'} eq 'ARRAY')
    {
      return @{$self->{'internal_value'}};
    }

    return $self->{'internal_value'};
  }

  my $value = $self->input_value;

  my($using_default, $final_value);

  unless(defined $value)
  {
    $value = $self->default_value;
    $using_default++;
  }

  $value = $self->input_prefilter($value);

  if(my $input_filter = $self->input_filter)
  {
    local $_ = $value;
    $final_value = $input_filter->($self, $value);
  }
  else { $final_value = $value }

  $final_value = $self->inflate_value($final_value);

  $self->{'internal_value'} = $final_value  unless($using_default);

  if(wantarray && ref $final_value eq 'ARRAY')
  {
    return @$final_value;
  }

  return $final_value;
}

sub internal_value_singular { shift->internal_value(@_) }

sub output_value
{
  my($self) = shift;

  Carp::croak "Cannot set the output value.  Use input_value() instead."  if(@_);

  return undef  if($self->is_cleared);

  return $self->{'output_value'}  if(defined $self->{'output_value'});

  my $value = $self->deflate_value(scalar $self->internal_value);

  if(my $output_filter = $self->output_filter)
  {
    local $_ = $value;
    $self->{'output_value'} = $output_filter->($self, $value);
  }
  else { $self->{'output_value'} = $value }

  if(wantarray && ref $self->{'output_value'} eq 'ARRAY')
  {
    return @{$self->{'output_value'}};
  }

  return $self->{'output_value'};
}

sub is_empty
{
  my($self) = shift;

  my $value = $self->internal_value;

  no warnings;  
  return ($value =~ /\S/ || (!$self->trim_spaces && length $value)) ? 0 : 1;
}

sub is_full { !shift->is_empty }

sub input_prefilter
{
  my($self, $value) = @_;

  return undef  unless(defined $value);

  unless(ref $value)
  {
    for($value)
    {
      no warnings;

      if($self->trim_spaces)
      {
        s/^\s+//;
        s/\s+$//;
      }
    }
  }

  return $value;
}

sub input_filter
{
  my($self) = shift;

  if(@_)
  {
    $self->{'internal_value'} = undef;
    $self->{'output_value'} = undef;
    return $self->{'input_filter'} = shift;
  }

  return $self->{'input_filter'};
}

sub output_filter
{
  my($self) = shift;

  if(@_)
  {
    $self->{'output_value'} = undef;
    return $self->{'output_filter'} = shift;
  }

  return $self->{'output_filter'};
}

sub filter
{
  my($self) = shift;

  if(@_)
  {
    my $filter = shift;
    $self->{'input_filter'}  = $filter;
    $self->{'output_filter'} = $filter;
  }

  my $input_filter = $self->{'input_filter'};

  if(ref $input_filter && $input_filter eq $self->output_filter)
  {
    return $input_filter;
  }

  return;
}

sub clear
{
  my($self) = shift;

  $self->_set_input_value(undef);
  $self->error(undef);
  $self->has_partial_value(0);
  $self->is_cleared(1);
}

sub reset
{
  my($self) = shift;

  $self->_set_input_value(undef);
  $self->error(undef);
  $self->has_partial_value(0);
  $self->is_cleared(0);
  return 1;
}

sub hidden_fields
{
  my($self) = shift;

  my $hidden_field_class = ref($self)->object_type_class_loaded('hidden');

  no strict 'refs';
  unless(@{$hidden_field_class . '::ISA'})
  {
    my $error;

    TRY:
    {
      local $@;
      eval "use $hidden_field_class";
      $error = $@;
    }

    Carp::croak "Could not load hidden field class '$hidden_field_class' - $error"
      if($error);
  }

  return 
    $hidden_field_class->new(
      name  => $self->html_attr('name'),
      id    => $self->html_attr('id'),
      class => $self->html_attr('class'),
      value => $self->output_value);
}

sub hidden_field { shift->hidden_fields(@_) }

sub html_hidden_fields
{
  my($self) = shift;

  my @html;

  foreach my $field ($self->hidden_fields)
  {
    push(@html, $field->html_field);
  }

  return (wantarray) ? @html : join("\n", @html);
}

sub html_hidden_field { shift->html_hidden_fields(@_) }

sub xhtml_hidden_fields
{
  my($self) = shift;

  my @xhtml;

  foreach my $field ($self->hidden_fields)
  {
    push(@xhtml, $field->xhtml_field);
  }

  return (wantarray) ? @xhtml : join("\n", @xhtml);
}

sub xhtml_hidden_field { shift->xhtml_hidden_fields(@_) }

sub element
{
  my($self) = shift;
  Carp::croak "Cannot set element for ", ref($self)  if(@_);
  return $self->html_element;
}

sub html_tag
{
  my($self) = shift;

  if($self->html_element && $self->apply_error_class && defined $self->error)
  {
    $self->add_class('error');

    my $html = $self->Rose::HTML::Object::html_tag(@_);

    $self->delete_class('error');

    return $html;
  }
  else
  {
    $self->SUPER::html_tag(@_);
  }
}

sub xhtml_tag
{
  my($self) = shift;

  if($self->html_element && $self->apply_error_class && defined $self->error)
  {
    $self->add_class('error');

    my $html = $self->Rose::HTML::Object::xhtml_tag(@_);

    $self->delete_class('error');

    return $html;
  }
  else
  {
    $self->SUPER::xhtml_tag(@_);
  }
}

*html_field  = \&html_tag;
*xhtml_field = \&xhtml_tag;

sub html
{
  my($self) = shift;

  my($field, $error);

  $field = $self->html_field;
  $error = $self->html_error;

  if($error)
  {
    return $field . $self->html_error_separator . $error;
  }

  return $field;
}

sub xhtml
{
  my($self) = shift;

  my($field, $error);

  $field = $self->xhtml_field;
  $error = $self->xhtml_error;

  if($error)
  {
    return $field . $self->xhtml_error_separator . $error;
  }

  return $field;
}

# sub label
# {
# 
# }

sub label_object
{
  my($self) = shift;
  my $label = $self->{'label_object'} ||= ref($self)->object_type_class_loaded('label')->new();

  $label->contents($self->escape_html ? __escape_html($self->label) : 
                                        $self->label);

  if($self->html_attr_exists('id'))
  {
    $label->for($self->html_attr('id'));
  }

  $self->required ?
    $label->add_class('required') :
    $label->delete_class('required');

  defined $self->error ?
    $label->add_class('error') :
    $label->delete_class('error');

  if(@_)
  {
    my %args = @_;

    while(my($k, $v) = each(%args))
    {
      $label->html_attr($k => $v);
    }
  }

  return $label;
}

sub html_label
{
  my($self) = shift;
  no warnings 'uninitialized';
  return ''  unless(length $self->label);
  return $self->label_object(@_)->html_tag;
}

sub xhtml_label
{
  my($self) = shift;
  no warnings 'uninitialized';
  return ''  unless(length $self->label);
  return $self->label_object(@_)->xhtml_tag;
}

sub validate
{
  my($self) = shift;

  $self->error(undef);

  my $value = $self->internal_value;

  if($self->required && 
     ((!ref $value && (!defined $value || ($self->trim_spaces && $value !~ /\S/))) ||
      (ref $value eq 'ARRAY' && !@$value)))
  {
    unless($self->is_empty && $self->empty_is_ok)
    {
      my $label = $self->error_label;

      if(defined $label)
      {
        #$self->add_error_id(FIELD_REQUIRED, $label);
        #$self->add_error_id(FIELD_REQUIRED, [ $label ]);
        $self->add_error_id(FIELD_REQUIRED, { label => $label });
      }
      else
      {
        $self->add_error_id(FIELD_REQUIRED);
      }

      return 0;
    }
  }

  return $self->validate_with_validator($value)  if($self->validator);

  return 1;
}

sub validate_with_validator
{
  my($self, $value) = @_;

  my $code = $self->validator or return 1;

  local $_ = $value;
  #$Debug && warn "running $code->($self)\n";
  my $ok = $code->($self);

  if(!$ok && !$self->has_errors)
  {
    my $label = $self->label;

    if(defined $label)
    {
      $self->add_error_id(FIELD_INVALID, { label => $label })
    }
    else
    {
      $self->add_error_id(FIELD_INVALID);
    }
  }

  return $ok;
}

sub validator
{
  my($self) = shift;

  if(@_)
  {
    my $code = shift;

    if(ref $code eq 'CODE')
    {
      return $self->{'validator'} = $code;
    }
    else
    {
      Carp::croak ref($self), "::validator() - argument must be a code reference";
    }
  }

  return $self->{'validator'};
}

*__escape_html = \&Rose::HTML::Util::escape_html;

sub message_for_error_id
{
  my($self, %args) = @_;

  my $error_id  = $args{'error_id'};
  my $msg_class = $args{'msg_class'} || $self->localizer->message_class;
  my $args      = $args{'args'} || [];

  no warnings 'uninitialized';
  if($error_id == FIELD_REQUIRED)
  {
    my $msg = $msg_class->new(args => $args);

    if((ref $args eq 'HASH' && keys %$args) || (ref $args eq 'ARRAY' && @$args))
    {
      $msg->id(FIELD_REQUIRED_LABELLED);
    }
    else
    {
      $msg->id(FIELD_REQUIRED_GENERIC);
    }

    return $msg;
  }
  elsif($error_id == FIELD_INVALID)
  {
    my $msg = $msg_class->new(args => $args);

    if((ref $args eq 'HASH' && keys %$args) || (ref $args eq 'ARRAY' && @$args))
    {
      $msg->id(FIELD_INVALID_LABELLED);
    }
    else
    {
      $msg->id(FIELD_INVALID_GENERIC);
    }

    return $msg;
  }

  return undef;
}

sub localize_label       { shift->label_message_id(FIELD_LABEL) }
sub localize_description { shift->description_message_id(FIELD_DESCRIPTION) }

# XXX: Ths sub contains a lame hack to work around an incompatibility with
# XXX: Scalar::Defer 0.11 - it manually detects and evaluates code refs.
sub localizer
{
  my($invocant) = shift;

  # Called as object method
  if(my $class = ref $invocant)
  {
    if(@_)
    {
      $invocant->{'localizer'} = shift;

      if(ref $invocant->{'localizer'} eq 'CODE')
      {
        return $invocant->{'localizer'}->();
      }
      else
      {
        return $invocant->{'localizer'};
      }
    }

    my $localizer = $invocant->{'localizer'};

    unless($localizer)
    {
      if(my $parent_field = $invocant->parent_field)
      {
        if(my $localizer = $parent_field->localizer)
        {
          return (ref $localizer eq 'CODE') ? $localizer->() : $localizer;
        }
      }
      elsif(my $parent_form = $invocant->parent_form)
      {
        if(my $localizer = $parent_form->localizer)
        {
          return (ref $localizer eq 'CODE') ? $localizer->() : $localizer;
        }      
      }
      else { return $class->default_localizer }
    }

    if(ref $localizer eq 'CODE')
    {
      return $localizer->();
    }

    return $localizer || $class->default_localizer;
  }
  else # Called as class method
  {
    if(@_)
    {
      return $invocant->default_localizer(shift);
    }

    return $invocant->default_localizer;
  }
}

# XXX: Ths sub contains a lame hack to work around an incompatibility with
# XXX: Scalar::Defer 0.11 - it manually detects and evaluates code refs.
sub locale
{
  my($invocant) = shift;

  # Called as object method
  if(my $class = ref $invocant)
  {
    if(@_)
    {
      $invocant->{'locale'} = shift;

      if(ref $invocant->{'locale'} eq 'CODE')
      {
        return $invocant->{'locale'}->();
      }
      else
      {
        return $invocant->{'locale'};
      }
    }

    my $locale = $invocant->{'locale'};

    if($locale)
    {
      return (ref $locale eq 'CODE') ? $locale->() : $locale;
    }

    if(my $parent_field = $invocant->parent_field)
    {
      if(my $locale = $parent_field->locale)
      {
        return (ref $locale eq 'CODE') ? $locale->() : $locale;
      }
    }
    elsif(my $parent_form = $invocant->parent_form)
    {
      if(my $locale = $parent_form->locale)
      {
        return (ref $locale eq 'CODE') ? $locale->() : $locale;
      }      
    }
    elsif($invocant->can('parent_group') && (my $parent_group = $invocant->parent_group))
    {
      if(my $locale = $parent_group->locale)
      {
        return (ref $locale eq 'CODE') ? $locale->() : $locale;
      }
    }
    else 
    {
      my $locale = $invocant->localizer->locale;

      if(ref $locale eq 'CODE')
      {
        return $locale->();
      }

      return $locale || $class->default_locale;
    }
  }
  else # Called as class method
  {
    if(@_)
    {
      return $invocant->default_locale(shift);
    }

    return $invocant->default_locale;
  }
}

sub prepare { }

if(__PACKAGE__->localizer->auto_load_messages)
{
  __PACKAGE__->localizer->load_all_messages;
}

use utf8; # The __DATA__ section contains UTF-8 text

1;

__DATA__

[% LOCALE en %]

FIELD_LABEL = ""
FIELD_DESCRIPTION = ""
FIELD_REQUIRED_GENERIC  = "This is a required field."
FIELD_REQUIRED_LABELLED = "[1] is a required field."

FIELD_PARTIAL_VALUE     = "Incomplete value."
FIELD_INVALID_GENERIC   = "Value is invalid."
FIELD_INVALID_LABELLED  = "[label] is invalid."

[% LOCALE de %]

FIELD_REQUIRED_GENERIC  = "Dies ist ein Pflichtfeld."
FIELD_REQUIRED_LABELLED = "[1] ist ein Pflichtfeld."

# ganze Sätze oder nur "Wert unvollständig/ungültig"?
FIELD_PARTIAL_VALUE    = "Der Wert ist unvollständig."
FIELD_INVALID_GENERIC  = "Der Wert ist ungültig."
FIELD_INVALID_LABELLED = "[label] ist ungültig."

[% LOCALE fr %]

FIELD_REQUIRED_GENERIC  = "Ce champ est obligatoire."
FIELD_REQUIRED_LABELLED = "[1] est un champ obligatoire."

FIELD_PARTIAL_VALUE     = "Valeur incomplète."
FIELD_INVALID_GENERIC   = "Valeur invalide."
FIELD_INVALID_LABELLED  = "[label] est invalide."

[% LOCALE bg %]

FIELD_REQUIRED_GENERIC  = "Това поле е задължително."
FIELD_REQUIRED_LABELLED = "Полето '[1]' е задължително."

FIELD_PARTIAL_VALUE     = "Непълна стойност."
FIELD_INVALID_GENERIC   = "Стойността е невалидна."
FIELD_INVALID_LABELLED  = "Полето '[label]' е невалидно."

__END__

=head1 NAME

Rose::HTML::Form::Field - HTML form field base class.

=head1 SYNOPSIS

    package MyField;

    use base 'Rose::HTML::Form::Field';
    ...

    my $f = MyField->new(name => 'test', label => 'Test');

    print $f->html_field;
    print $f->xhtml_field;

    $f->input_value('hello world');

    $i = $f->internal_value;

    print $f->output_value;
    ...

=head1 DESCRIPTION

L<Rose::HTML::Form::Field> is the base class for field objects used in an HTML form.  It defines a generic interface for field input, output, validation, and filtering.

This class inherits from, and follows the conventions of, L<Rose::HTML::Object>. Inherited methods that are not overridden will not be documented a second time here.  See the L<Rose::HTML::Object> documentation for more information.

=head1 OVERVIEW

A field object provides an interface for a logical field in an HTML form. Although it may serialize to multiple HTML tags, the field object itself is a single, logical entity.

L<Rose::HTML::Form::Field> is the base class for field objects.   Since the field object will eventually be asked to serialize itself as HTML, L<Rose::HTML::Form::Field> inherits from L<Rose::HTML::Object>.  That defines a lot of a field object's interface, leaving only the field-specific functions to L<Rose::HTML::Form::Field> itself.

The most important function of a field object is to accept and return user input.  L<Rose::HTML::Form::Field> defines a data flow for field values with several different hooks and callbacks along the way:

                        +------------+
                       / user input /
                      +------------+
                             |
                             V
                    +------------------+
             set -->.                  .
                    .   input_value    .   input_value()
             get <--.                  .
                    +------------------+
                             |
                             V
                    +------------------+
          toggle -->| input_prefilter  |   trim_spaces()
                    +------------------+
                             |
                             V
                    +------------------+
         define <-->|   input_filter   |   input_filter()
                    +------------------+
                             |
                             V
                  +----------------------+
                  .                      .
           get <--. input_value_filtered . input_value_filtered()
                  .                      .
                  +----------------------+
                             |
                             V
                    +------------------+
                    |   inflate_value  |   (override in subclass)
                    +------------------+
                             |
                             V
                    +------------------+
                    .                  .
             get <--.  internal_value  .   internal_value()
                    .                  .
                    +------------------+                      
                             |
                             V
                    +------------------+
                    |   deflate_value  |   (override in subclass)
                    +------------------+
                             |
                             V
                    +------------------+
         define <-->|   output_filter  |   output_filter()
                    +------------------+
                             |
                             V
                    +------------------+
                    .                  .
             get <--.   output_value   .   output_value()
                    .                  .
                    +------------------+


Input must be done "at the top", by calling L<input_value()|/input_value>. The value as it exists at various stages of the flow can be retrieved, but it can only be set at the top.  Input and output filters can be defined, but none exist by default.

The purposes of the various stages of the data flow are as follows:

=over 4

=item B<input value>

The value as it was passed to the field.

=item B<input value filtered>

The input value after being passed through all input filters, but before being inflated.

=item B<internal value>

The most useful representation of the value as far as the user of the L<Rose::HTML::Form::Field>-derived class is concerned.  It has been filtered and optionally "inflated" into a richer representation (i.e., an object). The internal value must also be a valid input value.

=item B<output value>

The value as it will be used in the serialized HTML representation of the field, as well as in the equivalent URI query string.  This is the internal value after being optionally "deflated" and then passed through an output filter. This value should be a string or a reference to an arry of strings. If passed back into the field as the input value, it should result in the same output value.

=back

Only subclasses can define class-wide "inflate" and "deflate" methods (by overriding the no-op implementations in this class), but users can define input and output filters on a per-object basis by passing code references to the appropriate object methods.

The prefilter exists to handle common filtering tasks without hogging the lone input filter spot (or requiring users to constantly set input filters for every field).  The L<Rose::HTML::Form::Field> prefilter optionally trims leading and trailing whitespace based on the value of the L<trim_spaces()|/trim_spaces> boolean attribute.  This is part of the public API for field objects, so subclasses that override L<input_prefilter()|/input_prefilter> must preserve this functionality.

In addition to the various kinds of field values, each field also has a name, which may or may not be the same as the value of the "name" HTML attribute.

Fields also have associated labels, error strings, default values, and various methods for testing, clearing, and reseting the field value.  See the list of object methods below for the details.

=head1 HIERARCHY

Though L<Rose::HTML::Form::Field> objects inherit from L<Rose::HTML::Object>, there are some semantic differences when it comes to the L<hierarchy|Rose::HTML::Object/HIERARCHY> of parent/child objects.  

A field is an abstraction for a collection of one or more HTML tags, including the field itself, the field's L<label|/html_label>, and any L<error messages|/html_error>.  Each of these things may be made up of multiple HTML elements, and they usually exist alongside each other rather than nested within each other.  As such, the field itself cannot rightly be considered the "parent" of these elements.  This is why the child-related methods inherited from L<Rose::HTML::Object> (L<children|Rose::HTML::Object/children>, L<descendants|Rose::HTML::Object/descendants>, etc.) will usually return empty lists.  Furthermore, any children L<added|Rose::HTML::Object/add_children> to the list will generally be ignored by the field's HTML output methods.

Effectively, once we move away from the L<Rose::HTML::Object>-derived classes that represent a single HTML element (with zero or more children nested within it) to a class that presents a higher-level abstraction, such as a L<form|Rose::HTML::Form> or field, the exact population of and relationship between the constituent HTML elements may be opaque.

If a field is a group of sibling HTML elements with no real parent HTML element (e.g., a L<radio button group|Rose::HTML::Form::Field::RadioButtonGroup>), then the individual sibling items will be available through a dedicated method (e.g., L<radio_buttons|Rose::HTML::Form::Field::RadioButtonGroup/radio_buttons>).

In cases where there really is a clear parent/child relationship among the HTML elements that make up a field, such as a L<select box|Rose::HTML::Form::Field::SelectBox> which contains zero or more L<options|Rose::HTML::Form::Field::Option> or L<option groups|Rose::HTML::Form::Field::OptionGroup>, the L<children|Rose::HTML::Object/children> method will return the expected list of objects.  In such cases, the list of child objects is usually restricted to be of the expected type (e.g., L<radio buttons|Rose::HTML::Form::Field::RadioButton> for a L<radio button group|Rose::HTML::Form::Field::RadioButtonGroup>), with all child-related methods acting as aliases for the existing item methods.  For example, the L<add_options|Rose::HTML::Form::Field::SelectBox/add_options> method in L<Rose::HTML::Form::Field::SelectBox> does the same thing as L<add_children|Rose::HTML::Object/add_children>.  See the documentation for each specific L<Rose::HTML::Form::Field>-derived class for more details.

=head1 CUSTOM FIELDS

This module distribution contains classes for most simple HTML fields, as well as examples of several more complex field types.  These "custom" fields do things like accept only valid email addresses or dates, coerce input and output into fixed formats, and provide rich internal representations (e.g., L<DateTime> objects).  Compound fields are made up of more than one field, and this construction can be nested: compound fields can contain other compound fields.  So long as each custom field class complies with the API outlined here, it doesn't matter how complex it is internally (or externally, in its HTML serialization).

(There are, however, certain rules that compound fields must follow in order to work correctly inside L<Rose::HTML::Form> objects.  See the L<Rose::HTML::Form::Field::Compound> documentation for more information.)

All of these classes are meant to be a starting point for your own custom fields.  The custom fields included in this module distribution are mostly meant as examples of what can be done.  I will accept any useful, interesting custom field classes into the C<Rose::HTML::Form::Field::*> namespace, but I'd also like to encourage suites of custom field classes in other namespaces entirely.  Remember, subclassing doesn't necessarily dictate namespace.

Building up a library of custom fields is almost always a big win in the long run.  Reuse, reuse, reuse!

=head1 HTML ATTRIBUTES

L<Rose::HTML::Form::Field> has the following set of valid HTML attributes.

    accesskey
    class
    dir
    id
    lang
    name
    onblur
    onclick
    ondblclick
    onfocus
    onkeydown
    onkeypress
    onkeyup
    onmousedown
    onmousemove
    onmouseout
    onmouseover
    onmouseup
    style
    tabindex
    title
    value
    xml:lang

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Constructs a new L<Rose::HTML::Form::Field> object based on PARAMS, where 
PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<auto_invalidate_parent [BOOL]>

Get or set a boolean value that indicates whether or not the value of any parent field is automatically invalidated when the input value of this field is set.  The default is true.

See L</"parent_field"> and L</"invalidate_value"> for more information.

=item B<clear>

Clears the field by setting both the "value" HTML attribute and the input value to undef.  Also sets the L<is_cleared()|/is_cleared> flag.

=item B<default VALUE>

Convenience wrapper for L<default_value()|/default_value>

=item B<default_value VALUE>

Set the default value for the field.  In the absence of a defined input value, the default value is used as the input value.

=item B<deflate_value VALUE>

This method is meant to be overridden by a subclass.  It should take VALUE and "deflate" it to a form that is a suitable for the output value: a string or reference to an array of strings.  The implementation in L<Rose::HTML::Form::Field> simply returns VALUE unmodified.

=item B<description [TEXT]>

Get or set a text description of the field.  This text is not currently used anywhere, but may be in the future.  It may be useful as help text, but keep in mind that any such text should stay true to its intended purpose: a description of the field.

Going too far off into the realm of generic help text is not a good idea since this text may be used elsewhere by this class or subclasses, and there it will be expected to be a description of the field rather than a description of how to fill out the field (e.g. "Command-click to make multiple selections") or any other sort of help text.

It may also be useful for debugging.

=item B<description_id [ID [, ARGS]]>

Get or set an integer L<message|Rose::HTML::Object::Messages> id for the description.

Get or set an integer L<message|Rose::HTML::Object::Messages> id for the description.  When setting the message id, an optional ARGS hash reference should be passed if the L<localized text|Rose::HTML::Object::Message::Localizer/"LOCALIZED TEXT"> for the L<corresponding|/message_for_error_id> message contains any L<placeholders|Rose::HTML::Object::Message::Localizer/"LOCALIZED TEXT">.

=item B<error_label [STRING]>

Get or set the field label used when constructing error messages.  For example, an error message might say "Value for [label] is too large."  The error label will go in the place of the C<[label]> placeholder.

If no error label is set, this method simply returns the L<label|/label>.

=item B<error_label_id [ID [, ARGS]]>

Get or set an integer L<message|Rose::HTML::Object::Messages> id for the error label.  When setting the message id, an optional ARGS hash reference should be passed if the L<localized text|Rose::HTML::Object::Message::Localizer/"LOCALIZED TEXT"> for the L<corresponding|/message_for_error_id> message contains any L<placeholders|Rose::HTML::Object::Message::Localizer/"LOCALIZED TEXT">.

=item B<filter [CODE]>

Sets both the input filter and output filter to CODE.

=item B<hidden_field>

Convenience wrapper for L<hidden_fields()|/hidden_fields>

=item B<hidden_fields>

Returns one or more L<Rose::HTML::Form::Field::Hidden> objects that represent the hidden fields needed to encode this field's value.

=item B<html>

Returns the HTML serialization of the field, along with the HTML error message, if any. The field and error HTML are joined by L<html_error_separator()|/html_error_separator>, which is "E<lt>brE<gt>\n" by default.

=item B<html_error>

Returns the error text, if any, as a snippet of HTML that looks like this:

    <span class="error">Error text goes here</span>

If the L<escape_html|Rose::HTML::Object/escape_html> flag is set to true (the default), then the error text has any HTML in it escaped.

=item B<html_error_separator [STRING]>

Get or set the string used to join the HTML field and HTML error message in the output of the L<html()|/html> method.  The default value is "E<lt>brE<gt>\n"

=item B<html_field>

Returns the HTML serialization of the field.

=item B<html_hidden_field>

Convenience wrapper for L<html_hidden_fields()|/html_hidden_fields>

=item B<html_hidden_fields>

In scalar context, returns the HTML serialization of the fields returned by L<hidden_fields()|/hidden_fields>, joined by newlines.  In list context, returns a list containing the HTML serialization of the fields returned by L<hidden_fields()|/hidden_fields>.

=item B<html_label [ARGS]>

Returns the HTML serialization of the label object, or the empty string if the field's C<label> is undefined or zero in length. Any ARGS are passed to the call to L<label_object()|/label_object>.

If L<required()|/required>is true for this field, then the name/value pair "class => 'required'" is passed to the call to L<label_object()|/label_object> I<before> any arguments that you pass.  This allows you to override the "class" value with one of your own.

=item B<html_prefix [STRING]>

Get or set an HTML prefix that may be displayed before the HTML field. L<Rose::HTML::Form::Field> does not use this prefix, but subclasses might. The default value is an empty string.

=item B<html_suffix [STRING]>

Get or set an HTML suffix that may be appended to the HTML field. L<Rose::HTML::Form::Field> does not use this suffix, but subclasses might. The default value is an empty string.

=item B<html_tag>

This method is part of the L<Rose::HTML::Object> API.  In this case, it simply calls L<html_field()|/html_field>.

=item B<inflate_value VALUE>

This method is meant to be overridden by subclasses.  It should take VALUE and "inflate" it to a form that is a suitable internal value.  (See the L<OVERVIEW> for more on internal values.)  The default implementation simply returns its first argument unmodified.

=item B<input_filter [CODE]>

Get or set the input filter.

=item B<input_prefilter VALUE>

Runs VALUE through the input prefilter.  This method is called automatically when needed and is not meant to be called by users of this module.  Subclasses may want to override it, however.

The default implementation optionally trims leading and trailing spaces based on the value of the L<trim_spaces()|/trim_spaces> boolean attribute.  This is part of the public API for field objects, so subclasses that override L<input_prefilter()|/input_prefilter> must preserve this functionality.

=item B<input_value [VALUE]>

Get or set the input value.

=item B<input_value_filtered>

Returns the input value after passing it through the input prefilter and input filter (if any).

=item B<internal_value>

Returns the internal value.

=item B<invalidate_output_value>

Invalidates the field's output value, causing it to be regenerated the next time it is retrieved.  This method is useful if the output value is created based on some configurable attribute of the field (e.g., a delimiter string).  If such an attribute is changed, then any existing output value must be invalidated.

=item B<invalidate_value>

Invalidates the field's value, causing the internal and output values to be recreated the next time they are retrieved.

This method is most useful in conjunction with the L</"parent_field"> attribute.  For example, when the input value of a subfield of a L<compound field|Rose::HTML::Form::Field::Compound> is set directly, it will invalidate the  value of its parent field(s).

=item B<is_cleared>

Returns true if the field is cleared (i.e., if L<clear()|/clear> has been called on it and it has not subsequently been L<reset()|/reset> or given a new input value), false otherwise.

=item B<is_empty>

Returns false if the internal value contains any non-whitespace characters or if L<trim_spaces|/trim_spaces> is false and the internal value has a non-zero length, true otherwise.  Subclasses should be sure to override this if they use internal values other than strings.

=item B<is_full>

Returns true if the internal value contains any non-whitespace characters, false otherwise.  Subclasses should be sure to override this if they use internal values other than strings.

=item B<label [STRING]>

Get or set the field label.  This label is used by the various label printing methods as well as in some error messages (assuming there is no explicitly defined L<error_label|/error_label>.  Even if you don't plan to use any of the former, it might be a good idea to set it to a sensible value for use in the latter.

=item B<label_id [ID]>

Get or set an integer L<message|Rose::HTML::Object::Messages> id for the field label.

=item B<label_object [ARGS]>

Returns a L<Rose::HTML::Label> object with its C<for> HTML attribute set to the calling field's C<id> attribute and any other HTML attributes specified by the name/value pairs in ARGS.  The HTML contents of the label object are set to the field's L<label()|/label>, which has its HTML escaped if L<escape_html|Rose::HTML::Object/escape_html> is true (which is the default).

=item B<local_name [NAME]>

Get or set the name of this field from the perspective of the L<parent_form|/parent_form> or L<parent_field|/parent_field>, depending on which type of thing is the direct parent of this field.  The local name should not change, regardless of how deeply this field is nested within other forms or fields.

=item B<message_for_error_id PARAMS>

Return the appropriate L<message|Rose::HTML::Object::Message> object associated with the L<error|Rose::HTML::Object::Errors> id.  The error id, message class, and message placeholder values are specified by PARAMS name/value pairs.  Valid PARAMS are:

=over 4

=item B<msg_class CLASS>

The name of the L<Rose::HTML::Object::Message>-derived class used to store each message.  If omitted, it defaults to the L<localizer|Rose::HTML::Object/localizer>'s L<message_class|Rose::HTML::Object::Message::Localizer/message_class>.

=back

=item B<name [NAME]>

If passed a NAME argument, then the L<local_name|/local_name> is set to NAME and the "name" HTML attribute is set to the fully-qualified field name, which may include dot (".") separated prefixes for the L<parent forms|/parent_form> and/or L<parent fields|/parent_field>.

If called without any arguments, and if the "name" HTML attribute is empty, then the "name" HTML attribute is set to the fully-qualified field name.

Returns the value of the "name" HTML attribute.

=item B<output_filter [CODE]>

Get or set the output filter.

=item B<output_value>

Returns the output value.

=item B<parent_field [FIELD]>

Get or set the parent field.  The parent field should only be set if the direct parent of this field is another field.  The reference to the parent field is "weakened" using L<Scalar::Util::weaken()|Scalar::Util/weaken> in order to avoid memory leaks caused by circular references.

=item B<parent_form [FORM]>

Get or set the parent L<form|Rose::HTML::Form>.  The parent form should only be set if the direct parent of this field is a form.  The reference to the parent form is "weakened" using L<Scalar::Util::weaken()|Scalar::Util/weaken> in order to avoid memory leaks caused by circular references.

=item B<parent_group [GROUP]>

Get or set the parent group.  Group objects are things like L<Rose::HTML::Form::Field::RadioButtonGroup> and L<Rose::HTML::Form::Field::CheckboxGroup>: conceptual groupings that have no concrete incarnation in HTML.  (That is, there is no parent HTML tag wrapping checkbox or radio button groups.)

The parent group should only be set if the direct parent of this field is a group object.  The reference to the parent group is "weakened" using L<Scalar::Util::weaken()|Scalar::Util/weaken> in order to avoid memory leaks caused by circular references.

=item B<prepare>

Prepares the field for use in a form.  Override this method in your custom field subclass to do any work required for each field before each use of that field.  Be sure to call the superclass implementation as well.  Example:

    package MyField;
    use base 'Rose::HTML::Form::Field';
    ...
    sub prepare
    {
      my($self) = shift;

      # Do anything that needs to be done before each use of this field
      ...

      # Call superclass implementation
      $self->SUPER::prepare(@_);
    }

=item B<rank [INT]>

Get or set the field's rank.  This value can be used for any purpose that suits you, but it is most often used to number and sort fields within a L<form|Rose::HTML::Form> using a custom L<compare_fields()|Rose::HTML::Form/compare_fields> method.

=item B<required [BOOL]>

Get to set a boolean flag that indicates whether or not a field is "required." See L<validate()|/validate> for more on what "required" means.

=item B<reset>

Reset the field to its default state: the input value and L<error()|Rose::HTML::Object/error> are set to undef and the L<is_cleared()|/is_cleared> flag is set to false.

=item B<trim_spaces [BOOL]>

Get or set the boolean flag that indicates whether or not leading and trailing spaces should be removed from the field value in the input prefilter. The default is true.

=item B<validate>

Validate the field and return a true value if it is valid, false otherwise. If the field is C<required>, then its internal value is tested according to the following rules.

* If the internal value is undefined, then return false.

* If the internal value is a reference to an array, and the array is empty, then return false.

* If L<trim_spaces()|/trim_spaces> is true (the default) and if the internal value does not contain any non-whitespace characters, return false.

If false is returned due to one of the conditions above, then L<error()|Rose::HTML::Object/error> is set to the string:

    $label is a required field.

where C<$label> is either the field's L<label()|/label> or, if L<label()|/label> is not defined, the string "This".

If a custom L<validator()|/validator> is set, then C<$_> is localized and set to the internal value and the validator subroutine is called with the field object as the first and only argument.

If the validator subroutine returns false and did not set L<error()|Rose::HTML::Object/error> to a defined value, then L<error()|Rose::HTML::Object/error> is set to the string:

    $label is invalid.

where C<$label> is is either the field's L<label()|/label> or, if L<label()|/label> is not defined, the string "Value".

The return value of the validator subroutine is then returned.

If none of the above tests caused a value to be returned, then true is returned.

=item B<validator [CODE]>

Get or set a validator subroutine.  If defined, this subroutine is called by L<validate()|/validate>.

=item B<value [VALUE]>

If a VALUE argument is passed, it sets both the input value and the "value" HTML attribute to VALUE.  Returns the value of the "value" HTML attribute.

=item B<xhtml>

Returns the XHTML serialization of the field, along with the HTML error message, if any. The field and error HTML are joined by L<xhtml_error_separator()|/xhtml_error_separator>, which is "E<lt>br /E<gt>\n" by default.

=item B<xhtml_error>

Returns the error text, if any, as a snippet of XHTML that looks like this:

    <span class="error">Error text goes here</span>

If the L<escape_html|Rose::HTML::Object/escape_html> flag is set to true (the default), then the error text has any HTML in it escaped.

=item B<xhtml_error_separator [STRING]>

Get or set the string used to join the XHTML field and HTML error message in the output of the L<xhtml()|/xhtml> method.  The default value is "E<lt>br /E<gt>\n"

=item B<xhtml_field>

Returns the XHTML serialization of the field.

=item B<xhtml_hidden_field>

Convenience wrapper for L<xhtml_hidden_fields()|/xhtml_hidden_fields>

=item B<xhtml_hidden_fields>

In scalar context, returns the XHTML serialization of the fields returned by L<hidden_fields()|/hidden_fields>, joined by newlines.  In list context, returns a list containing the XHTML serialization of the fields returned by L<hidden_fields()|/hidden_fields>.

=item B<xhtml_label [ARGS]>

Returns the XHTML serialization of the label object, or the empty string if the field's C<label> is undefined or zero in length. Any ARGS are passed to the call to L<label_object()|/label_object>.

If L<required()|/required>is true for this field, then the name/value pair "class => 'required'" is passed to the call to L<label_object()|/label_object> I<before> any arguments that you pass.  This allows you to override the "class" value with one of your own.

=item B<xhtml_tag>

This method is part of the L<Rose::HTML::Object> API.  In this case, it simply calls L<xhtml_field()|/xhtml_field>.

=back

=head1 SUPPORT

Any L<Rose::HTML::Objects> questions or problems can be posted to the L<Rose::HTML::Objects> mailing list.  To subscribe to the list or search the archives, go here:

L<http://groups.google.com/group/rose-html-objects>

Although the mailing list is the preferred support mechanism, you can also email the author (see below) or file bugs using the CPAN bug tracking system:

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-HTML-Objects>

There's also a wiki and other resources linked from the Rose project home page:

L<http://rosecode.org>

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
