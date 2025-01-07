package Rose::HTML::Object;

use strict;

use base 'Rose::HTML::Object::Localized';

use Carp;
use Scalar::Util();
use List::Util qw(uniq);

use Rose::HTML::Util();
use Rose::HTML::Object::Message::Localizer;

our $VERSION = '0.626';

our $Debug = undef;

#
# Class data
#

use Rose::Class::MakeMethods::Generic
(
  inherited_hash =>
  [
    'object_type_class' => { plural_name => 'object_type_classes' },
  ],
);

__PACKAGE__->default_localizer(Rose::HTML::Object::Message::Localizer->new);
__PACKAGE__->default_locale('en');

__PACKAGE__->autoload_html_attr_methods(1);

__PACKAGE__->add_valid_html_attrs
(
  'id',
  'class',
  'style',
  'title',
  'lang',
  'xml:lang',
  'dir',
  'onclick',
  'ondblclick',
  'onmousedown',
  'onmouseup',
  'onmouseover',
  'onmousemove',
  'onmouseout',
  'onkeypress',
  'onkeydown',
  'onkeyup'
);

__PACKAGE__->object_type_classes
(
  'anchor'             => 'Rose::HTML::Anchor',
  'image'              => 'Rose::HTML::Image',
  'label'              => 'Rose::HTML::Label',
  'link'               => 'Rose::HTML::Link',
  'script'             => 'Rose::HTML::Script',
  'literal text'       => 'Rose::HTML::Text',

  'form'               => 'Rose::HTML::Form',
  'repeatable form'    => 'Rose::HTML::Form::Repeatable',

  'text'               => 'Rose::HTML::Form::Field::Text',
  'scalar'             => 'Rose::HTML::Form::Field::Text',
  'char'               => 'Rose::HTML::Form::Field::Text',
  'character'          => 'Rose::HTML::Form::Field::Text',
  'varchar'            => 'Rose::HTML::Form::Field::Text',
  'string'             => 'Rose::HTML::Form::Field::Text',

  'text area'          => 'Rose::HTML::Form::Field::TextArea',
  'textarea'           => 'Rose::HTML::Form::Field::TextArea',
  'blob'               => 'Rose::HTML::Form::Field::TextArea',

  'option'             => 'Rose::HTML::Form::Field::Option',
  'option group'       => 'Rose::HTML::Form::Field::OptionGroup',

  'checkbox'           => 'Rose::HTML::Form::Field::Checkbox',
  'check'              => 'Rose::HTML::Form::Field::Checkbox',

  'radio button'       => 'Rose::HTML::Form::Field::RadioButton',
  'radio'              => 'Rose::HTML::Form::Field::RadioButton',

  'checkboxes'         => 'Rose::HTML::Form::Field::CheckboxGroup',
  'checks'             => 'Rose::HTML::Form::Field::CheckboxGroup',
  'checkbox group'     => 'Rose::HTML::Form::Field::CheckboxGroup',
  'check group'        => 'Rose::HTML::Form::Field::CheckboxGroup',

  'radio buttons'      => 'Rose::HTML::Form::Field::RadioButtonGroup',
  'radios'             => 'Rose::HTML::Form::Field::RadioButtonGroup',
  'radio button group' => 'Rose::HTML::Form::Field::RadioButtonGroup',
  'radio group'        => 'Rose::HTML::Form::Field::RadioButtonGroup',

  'pop-up menu'        => 'Rose::HTML::Form::Field::PopUpMenu',
  'popup menu'         => 'Rose::HTML::Form::Field::PopUpMenu',
  'menu'               => 'Rose::HTML::Form::Field::PopUpMenu',

  'select box'         => 'Rose::HTML::Form::Field::SelectBox',
  'selectbox'          => 'Rose::HTML::Form::Field::SelectBox',
  'select'             => 'Rose::HTML::Form::Field::SelectBox',

  'submit'             => 'Rose::HTML::Form::Field::Submit',
  'submit button'      => 'Rose::HTML::Form::Field::Submit',

  'reset'              => 'Rose::HTML::Form::Field::Reset',
  'reset button'       => 'Rose::HTML::Form::Field::Reset',

  'file'               => 'Rose::HTML::Form::Field::File',
  'upload'             => 'Rose::HTML::Form::Field::File',

  'password'           => 'Rose::HTML::Form::Field::Password',

  'hidden'             => 'Rose::HTML::Form::Field::Hidden',

  'num'                => 'Rose::HTML::Form::Field::Numeric',
  'number'             => 'Rose::HTML::Form::Field::Numeric',
  'numeric'            => 'Rose::HTML::Form::Field::Numeric',

  'int'                => 'Rose::HTML::Form::Field::Integer',
  'integer'            => 'Rose::HTML::Form::Field::Integer',

  'email'              => 'Rose::HTML::Form::Field::Email',

  'phone'              => 'Rose::HTML::Form::Field::PhoneNumber::US',
  'phone us'           => 'Rose::HTML::Form::Field::PhoneNumber::US',

  'phone us split'     => 'Rose::HTML::Form::Field::PhoneNumber::US::Split',

  'set'                => 'Rose::HTML::Form::Field::Set',

  'time'               => 'Rose::HTML::Form::Field::Time',
  'time split hms'     => 'Rose::HTML::Form::Field::Time::Split::HourMinuteSecond',

  'time hours'         => 'Rose::HTML::Form::Field::Time::Hours',
  'time minutes'       => 'Rose::HTML::Form::Field::Time::Minutes',
  'time seconds'       => 'Rose::HTML::Form::Field::Time::Seconds',

  'date'               => 'Rose::HTML::Form::Field::Date',
  'datetime'           => 'Rose::HTML::Form::Field::DateTime',

  'datetime range'     => 'Rose::HTML::Form::Field::DateTime::Range',

  'datetime start'     => 'Rose::HTML::Form::Field::DateTime::StartDate',
  'datetime end'       => 'Rose::HTML::Form::Field::DateTime::EndDate',

  'datetime split mdy'    => 'Rose::HTML::Form::Field::DateTime::Split::MonthDayYear',
  'datetime split mdyhms' => 'Rose::HTML::Form::Field::DateTime::Split::MDYHMS',
);

#
# Object data
#

use Rose::Object::MakeMethods::Generic
(
  scalar =>
  [
    'html_element',  # may be read-only in subclasses
    'xhtml_element', # may be read-only in subclasses
  ],

  boolean =>
  [
    'escape_html'         => { default => 1 },
    'validate_html_attrs' => { default => 1 },
    'is_self_closing'     => { default => 0 },
  ],

  'scalar --get_set_init' =>
  [
    'html_error_formatter',
    'xhtml_error_formatter',
  ],
);

use Rose::Class::MakeMethods::Generic
(
  inheritable_scalar =>
  [
    'autoload_html_attr_methods',
    'force_utf8',
  ],
);

use Rose::Class::MakeMethods::Set
(
  inheritable_set =>
  [
    required_html_attr =>
    {
      add_implies => 'add_valid_html_attr',
      test_method => 'html_attr_is_required',
    },
  ],

  inherited_set =>
  [
    valid_html_attr =>
    {
      test_method     => '_html_attr_is_valid', 
      delete_implies  => [ 'delete_boolean_html_attr', 'delete_required_html_attr' ],
      inherit_implies => 'inherit_boolean_html_attr',
    },

    boolean_html_attr =>
    {
      add_implies => 'add_valid_html_attr',
      test_method => 'html_attr_is_boolean', 
    },
  ]
);

use Rose::HTML::Object::MakeMethods::Generic
(
  array =>
  [
    'children'         => { interface => 'get_set_inited' },
    'child'            => { interface => 'get_item', hash_key => 'children' },
    'push_children'    => { interface => 'push', hash_key => 'children' },
    'pop_children'     => { interface => 'pop', hash_key => 'children' },
    'shift_children'   => { interface => 'shift', hash_key => 'children' },
    'unshift_children' => { interface => 'unshift', hash_key => 'children' },
    'delete_children'  => { interface => 'clear', hash_key => 'children' },
    'delete_child_at_index'  => { interface => 'delete_item', hash_key => 'children' },
  ],
);

#
# Class methods
#

sub generic_object_class { __PACKAGE__ }

*object_type_names = \&object_type_class_keys;

#
# Constructor
#

sub new
{
  my($class) = shift;

  my $self =
  {
    html_attrs  => {},
    escape_html => 1,
    error       => undef,
    validate_html_attrs => $class eq $class->generic_object_class ? 0 : 1,
  };

  bless $self, $class;

  $self->init(@_);

  return $self;
}

#
# Object methods
#

sub init
{
  my($self) = shift;

  @_ = (element => @_)  if(@_ % 2);

  my $class = ref $self;

  no strict 'refs';
  while(my($k, $v) = each %{$class->required_html_attrs_hash})
  {
    $self->{'html_attrs'}{$k} = $v;
  }

  $self->SUPER::init(@_);
}

sub add_children  { shift->push_children(@_) }
sub add_child     { shift->push_children(@_) }
sub push_child    { shift->push_children(@_) }
sub pop_child     { shift->pop_children(@_) }
sub shift_child   { shift->shift_children(@_) }
sub unshift_child { shift->unshift_children(@_) }

sub has_children
{
  my $children = shift->children; 
  return $children && @$children ? 1 : 0;
}

sub has_parent { shift->parent ? 1 : 0 }

sub parent
{
  my($self) = shift; 

  if(@_)
  {
    my $old_parent = $self->parent;

    Scalar::Util::weaken($self->{'parent'} = shift);

    my $new_parent = $self->{'parent'};

    if($old_parent && Scalar::Util::refaddr($old_parent) != Scalar::Util::refaddr($new_parent))
    {
      $old_parent->delete_child($self);
      $new_parent->push_child($self)  unless($new_parent->has_child($self));
    }
  }

  return $self->{'parent'};
}

sub descendants { map { $_, $_->descendants } shift->children }

sub delete_child
{
  my($self) = shift;

  if($_[0] =~ /^[+-]?\d+$/)
  {
    return $self->delete_child_at_index(@_);
  }

  my $refaddr = Scalar::Util::refaddr($_[0]);

  my $i = 0;

  foreach my $child ($self->children)
  {
    if(Scalar::Util::refaddr($child) == $refaddr)
    {
      return $self->delete_child_at_index($i);
    }

    $i++;
  }

  return undef;
}

sub has_child
{
  my($self) = shift;

  my $refaddr = Scalar::Util::refaddr($_[0]);

  foreach my $child ($self->children)
  {
    if(Scalar::Util::refaddr($child) == $refaddr)
    {
      return 1;
    }
  }

  return 0;
}

my %Loaded; # Lame, but trying to be fast here

sub object_type_class_loaded
{
  my($class) = shift;

  my $type_class = $class->object_type_class(@_);

  unless($Loaded{$type_class})
  {
    no strict 'refs';
    unless(@{$type_class . '::ISA'})
    {
      my $error;

      TRY:
      {
        local $@;
        eval "use $type_class";
        $error = $@;
      }

      Carp::croak "Could not load class '$type_class' - $error"  if($error);
    }

    $Loaded{$type_class}++;
  }

  return $type_class;
}

sub message_for_error_id
{
  my($self, %args) = @_;

  my $error_id  = $args{'error_id'};
  my $msg_class = $args{'msg_class'} || $self->localizer->message_class;
  my $args      = $args{'args'} || [];

  return $msg_class->new(id => $error_id, args => $args);
}


sub init_html_error_formatter  { }
sub init_xhtml_error_formatter { }

sub element
{
  my($self) = shift;

  return $self->html_element  unless(@_);

  $self->xhtml_element(@_);
  return $self->html_element(@_);
}

sub html_attr_exists
{
  my($self, $attr) = @_;

  if(@_ == 2)
  {
    return (exists $self->{'html_attrs'}{$attr}) ? 1 : 0;
  }

  croak 'Missing attribute name';
}

sub delete_html_attrs
{
  my($self) = shift;

  if(@_)
  {
    local $_;
    delete $self->{'html_attrs'}{$_}  for(@_);
    return scalar @_;
  }

  croak 'Missing attribute name';
}

sub delete_html_attr { shift->delete_html_attrs(@_) }

sub delete_all_html_attrs { $_[0]->delete_html_attrs($_[0]->html_attr_names) }

sub clear_html_attrs
{
  my($self) = shift;

  if(@_)
  {
    local $_;
    $self->{'html_attrs'}{$_} = undef  for(@_);
    return scalar @_;
  }

  croak 'Missing attribute name';
}

sub clear_html_attr { shift->clear_html_attrs(@_) }

sub clear_all_html_attrs { $_[0]->clear_html_attrs($_[0]->html_attr_names) }

sub html_attr
{
  my($self, $attr, $value) = @_;

  croak "Invalid attribute: '$attr'"  
    unless(!$self->validate_html_attrs ||
           $self->html_attr_is_valid($attr));

  my $hook = $self->html_attr_hook($attr);

  if(@_ == 3)
  {
    if($hook)
    {
      local $_ = $value;
      $value = $self->$hook($value);
    }

    return $self->{'html_attrs'}{$attr} = $value;
  }
  elsif(@_ == 2)
  {
    if(exists $self->{'html_attrs'}{$attr})
    {
      $value = $self->{'html_attrs'}{$attr};

      if($hook)
      {
        local $_ = $value;
        $value = $self->$hook();
      }

      return $value;
    }

    return undef;
  }

  croak 'Missing attribute name';
}

sub html_attr_is_valid
{
  my ($self, $attr) = @_;
  return 1  if($attr =~ /^data-\w/);
  return $self->_html_attr_is_valid($attr);
}

sub html_attr_names 
{
  wantarray ? sort keys %{$_[0]->{'html_attrs'}} : 
              [ sort keys %{$_[0]->{'html_attrs'}} ];
}

sub html_attrs
{
  my($self) = shift;

  if(@_)
  {
    my $attrs;

    if(@_ == 1 && ref $_[0] eq 'HASH')
    {
      $attrs = shift;
    }
    else
    {
      croak 'Odd number of arguments'  if(@_ % 2);
      $attrs = { @_ };
    }

    while(my($attr, $value) = each(%$attrs))
    {
      $self->html_attr($attr => $value);
    }
  }

  return (wantarray) ? %{$self->{'html_attrs'}} : $self->{'html_attrs'};
}

sub html_attr_hook
{
  my($self, $attr) = (shift, shift);

  croak "Invalid attribute: '$attr'"
    unless(!$self->validate_html_attrs ||
           $self->html_attr_is_valid($attr));

  if(@_)
  {
    # XXX: possibly check that it's a code reference
    return $self->{'html_attr_hook'}{$attr} = shift;
  }

  if(exists $self->{'html_attr_hook'}{$attr})
  {
    return $self->{'html_attr_hook'}{$attr};
  }

  return undef;
}

sub delete_html_attr_hook { shift->html_attr_hook($_[0] => undef) }

sub set_error   { shift->error('')    }
sub unset_error { shift->error(undef) }

sub html_error
{
  my($self) = shift;

  if(my $code = $self->html_error_formatter)
  {
    return $code->($self);
  }

  my $error = $self->error;

  if($error && length "$error")
  {
    return qq(<span class="error">) . 
           ($self->escape_html ? Rose::HTML::Util::escape_html($error) : $error) .
           '</span>';
  }

  return '';
}

sub xhtml_error
{
  my($self) = shift;

  if(my $code = $self->html_error_formatter)
  {
    return $code->($self);
  }

  return $self->html_error;
}

sub html_errors
{
  my($self) = shift;

  if(my $code = $self->html_error_formatter)
  {
    return $code->($self);
  }

  my $error = join(', ', grep { /\S/ } $self->errors);

  if($error)
  {
    return qq(<span class="error">) . 
           ($self->escape_html ? Rose::HTML::Util::escape_html($error) : $error) .
           '</span>';
  }

  return '';
}

sub xhtml_errors
{
  my($self) = shift;

  if(my $code = $self->html_error_formatter)
  {
    return $code->($self);
  }

  return $self->html_errors;
}

sub html_attrs_string
{
  my($self) = shift;

  my @html;

  local $_;

  my $required_attrs = $self->required_html_attrs_hash;
  my %boolean_attrs  = map { $_ => 1 } $self->boolean_html_attrs;

  local $self->{'html_attrs'}{'required'} = $self->required
    if ($boolean_attrs{'required'});
  
  foreach my $attr (sort(uniq(keys(%{$self->{'html_attrs'}}), keys(%$required_attrs))))
  {
    my $value;

    if(exists $self->{'html_attrs'}{$attr})
    {
      $value = $self->{'html_attrs'}{$attr};
    }

    if(defined($value) || exists $boolean_attrs{$attr})
    {
      if($boolean_attrs{$attr})
      {
        push(@html, $attr)  if($value);
        next;
      }

      $value = ''  unless(defined $value);
      push(@html, $attr . q(=") .
      	($value =~ /\W/ ? Rose::HTML::Util::escape_html($value) : $value) . q("));
    }
    elsif(exists $required_attrs->{$attr})
    {
      $value = $required_attrs->{$attr};
      $value = ''  unless(defined $value);
      push(@html, $attr . q(=") .
        ($value =~ /\W/ ? Rose::HTML::Util::escape_html($value) : $value) . q("));
    }
  }

  return ''  unless(@html);

  return ' ' . join(' ', @html);
}

our (%Boolean_Attrs, %Required_Attrs);

sub xhtml_attrs_string
{
  my($self) = shift;

  my $class = ref($self);

  my @html;

  local $_;
  my $required_attrs = $self->required_html_attrs_hash;
  my %boolean_attrs  = map { $_ => 1 } $self->boolean_html_attrs;

  local $self->{'html_attrs'}{'required'} = $self->required
    if ($boolean_attrs{'required'});

  foreach my $attr (sort(uniq(keys(%{$self->{'html_attrs'}}), keys(%$required_attrs))))
  {
    my $value;

    if(exists $self->{'html_attrs'}{$attr})
    {
      $value = $self->{'html_attrs'}{$attr};
    }

    if(defined($value) || exists $boolean_attrs{$attr})
    {
      if($boolean_attrs{$attr})
      {
        push(@html, $attr . q(=") . ($attr =~ /\W/ ? Rose::HTML::Util::escape_html($attr) : $attr) . q("))  if($value);
        next;
      }

      $value = ''  unless(defined $value);
      push(@html, $attr . q(=") .
      	($value =~ /\W/ ? Rose::HTML::Util::escape_html($value) : $value) . q("));
    }
    elsif(exists $required_attrs->{$attr})
    {
      $value = $required_attrs->{$attr};
      $value = ''  unless(defined $value);
      push(@html, $attr . q(=") .
        ($value =~ /\W/ ? Rose::HTML::Util::escape_html($value) : $value) . q("));
    }
  }

  return ''  unless(@html);

  return ' ' . join(' ', @html);
}

sub html  { shift->html_tag(@_) }
sub xhtml { shift->xhtml_tag(@_) }

sub html_tag
{
  my($self) = shift;

  no warnings 'uninitialized';

  if($self->has_children || !$self->is_self_closing)
  {
    return '<' . $self->html_element . $self->html_attrs_string . '>' . 
           join('', map { $_->html_tag } $self->children) . 
           '</' . $self->html_element . '>';
  }

  return '<' . $self->html_element . $self->html_attrs_string . '>';
}

sub xhtml_tag
{
  my($self) = shift;

  no warnings 'uninitialized';

  if($self->has_children || !$self->is_self_closing)
  {
    return '<' . $self->xhtml_element . $self->xhtml_attrs_string . '>' . 
           join('', map { $_->xhtml_tag } $self->children) . 
           '</' . $self->xhtml_element . '>';
  }

  return '<' . $self->xhtml_element . $self->xhtml_attrs_string . ' />';
}

sub add_class
{
  my ($self, $new_class) = @_;

  my $class = $self->html_attr('class');

  no warnings 'uninitialized';
  unless($class =~ /(?:^| )$new_class(?: |$)/)
  {
    $self->html_attr(class => $class ? "$class $new_class" : $new_class);
  }
}

sub add_classes
{
  my ($self) = shift;

  no warnings 'uninitialized';
  foreach my $class ((ref $_[0] eq ref []) ? @{$_[0]} : @_)
  {
    $self->add_class($class);
  }
}

sub delete_class
{
  my ($self, $delete_class) = @_;

  my $class = $self->html_attr('class');

  no warnings 'uninitialized';
  if($class =~ s/(^| |\G)\Q$delete_class\E( |$)/$1$2/g)
  {
    for($class)
    {
      s/^ +//;
      s/ +$//;
      s/  +/ /g;
    }

    $self->html_attr(class => $class);
  }
}

sub delete_classes
{
  my ($self) = shift;

  no warnings 'uninitialized';
  foreach my $class ((ref $_[0] eq ref []) ? @{$_[0]} : @_)
  {
    $self->delete_class($class);
  }
}

#
# Lame start/end HTML fall-backs for lazy derived classes
#

sub start_html
{
  my($self) = shift;

  return '<' . $self->html_element . $self->html_attrs_string . '>';

  #my $html = $self->html;
  #$html =~ s{</\w+>\z}{};
  #return $html;
}

sub end_html
{
  my($self) = shift;

  return '</' . $self->html_element . '>';

  #my $html = $self->html;
  #$html =~ m{</\w+>\z};
  #return $1 || '';
}

sub start_xhtml
{
  my($self) = shift;

  return '<' . $self->xhtml_element . $self->xhtml_attrs_string . '>';

  #my $xhtml = $self->xhtml;
  #$xhtml =~ s{</\w+>\z}{};
  #return $xhtml;
}

sub end_xhtml
{
  my($self) = shift;

  return '</' . $self->xhtml_element . '>';

  #my $xhtml = $self->xhtml;
  #$xhtml =~ m{</\w+>\z};
  #return $1 || '';
}

sub default_html_attr_value 
{
  my($class) = shift;
  my($attr)  = shift;

  if(@_)
  {
    $class->add_required_html_attr({ $attr => $_[0] });
    return $_[0];
  }

  return $class->required_html_attr_value($attr);
}

sub load_all_messages
{
  my($self_or_class) = shift;

  my $class = ref($self_or_class) || $self_or_class;

  $class->localizer->load_all_messages(from_class => $class);
}

our $AUTOLOAD;

# We "can" do what will eventually be AUTOLOADed HTML attribute methods
sub can
{
  my($self, $name) = @_;

  my $class = ref($self) || $self;

  my $code = $self->SUPER::can($name);
  return $code  if($code);

  return  unless($self->html_attr_is_valid($name) && $class->autoload_html_attr_methods);

  # can() expects a code ref that will actually work...
  return sub
  {
    my $self = $_[0];

    my $code = $self->SUPER::can($name); # exists already?
    goto &$code  if($code);

    $AUTOLOAD = $class;
    goto &AUTOLOAD
  };
}

sub __method_was_autoloaded
{
  my($class) = ref($_[0]) || $_[0];
  no strict 'refs';
  exists ${$class . '::__AUTOLOADED'}{$_[1]};
}

sub create_html_attr_methods
{
  my($class) = shift;

  my $count = 0;

  foreach my $attr (@_ ? @_ : $class->valid_html_attrs)
  {
    no strict 'refs';
    my $method = $class . '::' . $attr;
    next  if(defined &$method);
    *$method = sub { shift->html_attr($attr, @_) };
    $count++;
  }

  return $count;
}

sub import
{
  my($class) = shift;

  foreach my $arg (@_)
  {
    if($arg eq ':customize')
    {
      $class->import_methods(
        { target_class => (caller)[0] },
        qw(object_type_class_exists object_type_class_keys 
           delete_object_type_class object_type_classes 
           clear_object_type_classes object_type_class 
           inherit_object_type_classes object_type_classes_cache 
           inherit_object_type_class add_object_type_classes 
           delete_object_type_classes add_object_type_class
           localizer locale default_localizer default_locale));
    }
    else
    {
      carp "$class: Unknown import argument '$arg'";
    }
  }
}

# XXX: This is undocumented for now...
#
# =item B<import_methods NAME1 [, NAME2, ...]>
# 
# Import methods from the named class (the invocant) into the current class.
# This works by searching the class hierarchy, starting from the invocant class,
# and using a breadth-first search.  When an existing method with the requested
# NAME is found, it is aliased into the current (calling) package.  If a method
# of the desired name is not found, a fatal error is thrown.
# 
# This is a somewhat evil hack that i used internally to get around some
# inconvenient consequences of multiple inheritence and its interaction with
# Perl's default left-most depth-first method dispatch.
# 
# This method is an implementation detail and is not part of the public "user"
# API. It is described here for the benefit of those who are subclassing
# L<Rose::HTML::Object> and who also may find themselves in a bit of a multiple
# inheritence bind.
# 
# Example:
# 
#     package MyTag;
# 
#     use base 'SomeTag';
# 
#     use MyOtherTag;
# 
#     # Do a bredth-first search, starting in the class MyOtherTag,
#     # for methods named 'foo' and 'bar', and alias them into
#     # this package (MyTag)
#     MyOtherTag->import_methods('foo', 'bar');

# If method dispatch was breadth-first, I probably wouldn't need this...
sub import_methods
{
  my($this_class) = shift;

  my $options = ref $_[0] && ref $_[0] eq 'HASH' ? shift : {};

  my $target_class = $options->{'target_class'} || (caller)[0];

  my(@search_classes, @parents);

  @parents = ($this_class);

  while(my $class = shift(@parents))
  {
    push(@search_classes, $class);

    no strict 'refs';
    foreach my $subclass (@{$class . '::ISA'})
    {
      push(@parents, $subclass);
    }
  }

  my %methods;

  foreach my $arg (@_)
  {
    if(ref $arg eq 'HASH')
    {
      $methods{$_} = $arg->{$_}  for(keys %$arg);
    }
    else
    {
      $methods{$arg} = $arg;
    }
  }

  METHOD: while(my($method, $import_as) = each(%methods))
  {
    no strict 'refs';
    foreach my $class (@search_classes)
    {
      if(defined &{$class . '::' . $method})
      {
        #print STDERR "${target_class}::$import_as = ${class}::$method\n";
        *{$target_class . '::' . $import_as} = \&{$class . '::' . $method};
        next METHOD;
      }
    }

    Carp::croak "Could not find method '$method' in any subclass of $this_class";
  }
}

sub DESTROY { }

sub AUTOLOAD
{
  my($self) = $_[0];

  if(my $class = ref($self))
  {
    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    if($class->html_attr_is_valid($name) && $class->autoload_html_attr_methods)
    {
      no strict 'refs';
      *$AUTOLOAD = sub { shift->html_attr($name, @_) };
      ${$class . '::__AUTOLOADED'}{$name} = 1;
      goto &$AUTOLOAD;
    }

    confess
      qq(Can't locate object method "$name" via package "$class" - ) .
      ($class->html_attr_is_valid($name) ? 
      "did not auto-create method because $class->autoload_html_attr_methods is not set" :
      "no such method, and none auto-created because it is not a valid HTML attribute for this class");
  }
  else
  {
    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    confess qq(Can't locate class method "$name" via package "$self");
  }
}

1;

__END__

=head1 NAME

Rose::HTML::Object - HTML object base class.

=head1 SYNOPSIS

  #
  # Generic HTML construction
  #

  $o = Rose::HTML::Object->new('p');
  $o->push_child('Hi');

  print $o->html; # <p>hi</p>

  $br = Rose::HTML::Object->new(element => 'br', is_self_closing => 1);

  print $br->html;  # <br>
  print $br->xhtml; # <br />

  $o->unshift_children($br, ' '); # add two children

  print $o->html; # <p><br> Hi</p>

  $b = Rose::HTML::Object->new('body', children => $o);

  print $b->html; # <body><p><br> Hi</p></body>

  foreach my $object ($b->descendants)
  {
    ...
  }

  $d = Rose::HTML::Object->new('div', class => 'x');

  $b->child(0)->parent($d); # re-parent: $o now belongs to $d

  print $b->html; # <body></body>
  print $d->html; # <div class="x"><p><br> Hi</p></div>

  #
  # Subclass to add strictures
  #

  package MyTag;

  use base 'Rose::HTML::Object';

  __PACKAGE__->add_valid_html_attrs
  (
    'foo',
    'bar',
    'baz',
    ...
  );

  __PACKAGE__->add_required_html_attrs(
  {
    foo => 5,  # with default value
    goo => '', # required implies valid
  });

  __PACKAGE__->add_boolean_html_attrs
  (
    'selected', # boolean implies valid
  );

  sub html_element  { 'mytag' }
  sub xhtml_element { 'mytag' }

  ...

  my $o = MyTag->new(bar => 'hello', selected => 1);

  # prints: bar="hello" foo="5" goo="" selected
  print $o->html_attrs_string;  

  # prints: bar="hello" foo="5" goo="" selected="selected"
  print $o->xhtml_attrs_string;

  $o->html_attr(selected => 0);

  print "Has bar\n"  if($o->html_attr_exists('bar'));
  $o->delete_html_attr('bar');

  $o->is_self_closing(1);

  print $o->html_tag;  # <mytag foo="5" goo="">
  print $o->xhtml_tag; # <mytag foo="5" goo="" />
  ...

=head1 DESCRIPTION

L<Rose::HTML::Object> is the base class for HTML objects.  It defines the HTML element name, provides methods for specifying, manipulating, and validating HTML attributes, and can serialize itself as either HTML or XHTML.

This class inherits from, and follows the conventions of, L<Rose::Object>. See the L<Rose::Object> documentation for more information.

=head1 HIERARCHY

Each L<Rose::HTML::Object> may have zero or more L<children|/children>, each of which is another L<Rose::HTML::Object> (or L<Rose::HTML::Object>-derived) object.  The L<html|/html> produced for an object will include the HTML for all of its L<descendants|/descendants>.

=head1 VALIDATION

Although several methods, data structures, and policies exist to aid the creation of valid HTML, they are in no way a replacement for real markup validation.

This class and those that inherit from it try to support a superset of the elements and attributes specified in the HTML 4.01 and XHTML 1.x specifications.  As a result, these classes will tend to be more permissive than actual validation.  The support of these standards is not exhaustive, and will inevitably expand.  Also remember that there are several variant DTDs that make up XHTML 1.x.  By trying to support a superset of these standards, this class can't correctly enforce the rules of any individual standard.

So I say again: these classes are not a replacement for real markup validation. Use an external validator.

Going forward, the compatibility policy of these classes is that attribute specifications may be added in the future, but existing attribute specifications will never be removed (unless they originally existed in error, i.e., were never part of any HTML 4.01 or XHTML 1.x standard).

This support policy is pragmatic rather than ideological.  There is enough default validation to catch most typos or other unintentional errors, but not so much that the entire class hierarchy is weighed down by language lawyering and bookkeeping.

If the runtime overhead of validating every HTML attribute is deemed too onerous, it can be turned off on a per-object basis with the L<validate_html_attrs|/validate_html_attrs> method.   Subclasses can set this attribute during object construction to make the effect class-wide.  (You will also want to look at the L<autoload_html_attr_methods|/autoload_html_attr_methods> class attribute.)

There are also methods for adding and removing valid, required, and boolean HTML attributes for a class.

Finally, all element and attribute names are case-sensitive and lowercase in order to comply with XHTML (and to be easy to type).

=head1 CLASS METHODS

These class methods can be called with a class name or an object as the invocant.  Either way, remember that the data structures and attributes affected are part of the class as a whole, not any individual object.  For example, adding a valid HTML attribute makes it valid for all objects of the class, including any objects that already exist.

Many of the class methods manipulate "inheritable sets," "inherited sets," or "inherited hashes."  See the L<Rose::Class::MakeMethods::Set> and L<Rose::Class::MakeMethods::Generic|Rose::Class::MakeMethods::Generic/inherited_hash> documentation for an explanation of these method types.

The sets of valid and boolean HTML attributes are "inherited sets."  The set of required HTML attributes is an "inheritable set."  The L<object_type_classes|/object_type_classes> map is an "inherited hash."

The inheritance behavior of these sets is noted here in order to facilitate subclassing.  But it is an implementation detail, not a part of the public API.  The requirements of the APIs themselves do not include any particular inheritance behavior.

=over 4

=item B<add_boolean_html_attr NAME>

Adds a value to the list of boolean HTML attributes for this class. Boolean HTML attributes appear without values in HTML tags, (e.g., <dl compact>) or with fixed values in XHTML tags (e.g., <dl compact="compact">)

=item B<add_boolean_html_attrs NAME1, NAME2, ...>

Adds one or more values to the list of boolean HTML attributes for this class. Boolean HTML attributes appear without values in HTML tags, (e.g., <dl compact>) or with fixed values in XHTML tags (e.g., <dl compact="compact">)

=item B<add_object_type_classes [MAP]>

Add entries to the L<object_type_classes|/object_type_classes> hash that maps object type strings to the names of the L<Rose::HTML::Object>-derived classes.  Example:

    My::HTML::Form->add_object_type_classes
    (
      blockquote => 'My::HTML::Blockquote',
      abbr       => 'My::HTML::Abbr',
      ...
    );

=item B<add_required_html_attr NAME [, DEFAULT]>

Adds a value to the list of required HTML attributes for this class. Required HTML attributes will always appear in the HTML tag, with or without a non-empty value. You can set the default value for a required HTML attribute using the L<required_html_attr_value|/required_html_attr_value> method or by passing the DEFAULT parameter to this method.

=item B<add_required_html_attrs NAME1, NAME2, ... | HASHREF>

Adds one or more values to the list of required HTML attributes for this class. Required HTML attributes will always appear in the HTML tag, with or without a non-empty value.  You can set the default value for a required HTML attribute using the L<required_html_attr_value|/required_html_attr_value> method or by passing a reference to a hash containing name/default pairs.

=item B<add_valid_html_attr NAME>

Adds a value to the list of valid HTML attributes for this class.  If the object property C<validate_html_attrs> is true, then only valid attributes can be added to an object of this class.

=item B<add_valid_html_attrs NAME1, NAME2, ...>

Adds one or more values to the list of valid HTML attributes for this class. If the object property C<validate_html_attrs> is true, then only valid attributes can be added to an object of this class.

=item B<autoload_html_attr_methods [BOOL]>

Get or set the boolean flag that determines whether or not any valid HTML attribute can be used as a method call of the same name.  The default is true, and the value is inherited by subclasses unless overridden.

In the case of a name conflict, the existing method is called and a new method is not auto-created for the HTML attribute of the same name.

Examples:

    MyTag->add_valid_html_attrs('foo', 'bar', 'error');

    $o = MyTag->new;

    # Auto-created method, equivalent to $o->html_attr(foo => 5)
    $o->foo(5);

    # Fatal error: invalid HTML attribute and not an existing method
    print $o->blah; 

    MyTag->autoload_html_attr_methods(0); # stop autoloading

    # Fatal error: method does not exist and was never auto-created
    print $o->bar;

    # This still works: once the method is auto-created, it stays
    print $o->foo; # prints "5"

    # Calls the existing error() object method; does not affect
    # the HTML attribute named "error"
    $o->error(99);

Yes, the existence of this capability means that adding a method to a future version of a L<Rose::HTML::Object>-derived class that has the same name as a valid HTML attribute may cause older code that calls the auto-created method of the same name to break.

To avoid this, you can choose not to use any auto-created methods, opting instead to use the L<html_attr|/html_attr> method everywhere (and you can set C<autoload_html_attr_methods> to false to make sure that you don't accidentally use such a method).

=item B<boolean_html_attrs>

Returns a reference to a sorted list of boolean HTML attributes in scalar context, or a sorted list of boolean HTML attributes in list context. The default set of boolean HTML attributes is empty.

See the introduction to the L<"CLASS METHODS"> section for more information about the "inherited set" implementation used by the set of boolean HTML attributes.

=item B<default_html_attr_value NAME [, VALUE]>

Returns the default value for the HTML attribute NAME.

If passed both an attribute NAME and a VALUE, it adds NAME to the set of required HTML attributes and sets its default value to VALUE.

=item B<default_locale [LOCALE]>

Get or set the default L<locale|Rose::HTML::Object::Message::Localizer/LOCALES> for this class.  The default value C<en>.

=item B<default_localizer [LOCALIZER]>

Get or set the default L<Rose::HTML::Object::Message::Localizer>-derived localizer object.  Defaults to a new L<Rose::HTML::Object::Message::Localizer>-derived object.

=item B<delete_boolean_html_attr NAME>

Removes the HTML attribute NAME from the set of boolean HTML attributes.

=item B<delete_object_type_class TYPE>

Delete the type/class L<mapping|/object_type_classes> entry for the object type TYPE.

=item B<delete_required_html_attr NAME>

Removes the HTML attribute NAME from the set of required HTML attributes.

=item B<delete_valid_html_attr NAME>

Removes the HTML attribute NAME from the set of valid HTML attributes. The attribute is also removed from the set of required and boolean HTML attributes, if it existed in either set.

=item B<html_attr_is_boolean NAME>

Returns a boolean value indicating whether or not the attribute NAME is a boolean HTML attribute.  A boolean attribute must also be a valid attribute.

=item B<html_attr_is_required NAME>

Returns a boolean value indicating whether or not the attribute NAME is a required HTML attribute.  A required attribute must also be a valid attribute.

=item B<html_attr_is_valid NAME>

Returns a boolean value indicating whether or not the attribute NAME is a valid HTML attribute.

=item B<load_all_messages>

Ask the L<localizer|/localizer> to L<load_all_messages|Rose::HTML::Object::Message::Localizer/load_all_messages> from this class.

=item B<locale [LOCALE]>

This method may be called as a class method or an object method.

When called as a class method and a L<LOCALE|Rose::HTML::Object::Message::Localizer/LOCALES> is passed, then the L<default_locale|/default_locale> is set.  When called as an object method and a L<LOCALE|Rose::HTML::Object::Message::Localizer/LOCALES> is passed, then the L<locale|Rose::HTML::Object::Message::Localizer/LOCALES> of this object is set.

If no locale is set for this class (when called as a class method) then the L<localizer|/localizer>'s L<locale|Rose::HTML::Object::Message::Localizer/locale> is returned, if it is set.  Otherwise, the L<default_locale|/default_locale> is returned.

If no locale is set for this object (when called as an object method), then the the first defined locale from the object's L<parent_group|Rose::HTML::Form::Field/parent_group>, L<parent_field|Rose::HTML::Form::Field/parent_field>, L<parent_form|Rose::HTML::Form::Field/parent_form>, or generic L<parent|/parent> is returned.  If none of those locales are defined, then the L<localizer|/localizer>'s L<locale|Rose::HTML::Object::Message::Localizer/locale> is returned, if it is set.  Otherwise, the L<default_locale|/default_locale> is returned.

=item B<object_type_class TYPE [, CLASS]>

Given the object type string TYPE, return the name of the L<Rose::HTML::Object>-derived class mapped to that name.  If a CLASS is passed, the object type TYPE is mapped to CLASS.

This map of type names to classes is an L<inherited hash|Rose::Class::MakeMethods::Generic/inherited_hash> representing the union of the hashes of all superclasses, minus any keys that are explicitly L<deleted|/delete_object_type_class> in the current class.

=item B<object_type_classes [MAP]>

Get or set the hash that maps object type strings to the names of the L<Rose::HTML::Object>-derived classes.

If passed MAP (a list of type/class pairs or a reference to a hash of the same) then MAP replaces the current object type mapping.  Returns a list of type/class pairs (in list context) or a reference to a hash of type/class mappings (in scalar context).

This map of type names to classes is an L<inherited hash|Rose::Class::MakeMethods::Generic/inherited_hash> representing the union of the hashes of all superclasses, minus any keys that are explicitly L<deleted|/delete_object_type_class> in the current class.

The default mapping of type names to class names is:

  'image'              => Rose::HTML::Image
  'label'              => Rose::HTML::Label
  'link'               => Rose::HTML::Link
  'script'             => Rose::HTML::Script
  'literal text'       => Rose::HTML::Text

  'form'               => Rose::HTML::Form
  'repeatable form'    => Rose::HTML::Form::Repeatable

  'text'               => Rose::HTML::Form::Field::Text
  'scalar'             => Rose::HTML::Form::Field::Text
  'char'               => Rose::HTML::Form::Field::Text
  'character'          => Rose::HTML::Form::Field::Text
  'varchar'            => Rose::HTML::Form::Field::Text
  'string'             => Rose::HTML::Form::Field::Text

  'text area'          => Rose::HTML::Form::Field::TextArea
  'textarea'           => Rose::HTML::Form::Field::TextArea
  'blob'               => Rose::HTML::Form::Field::TextArea

  'option'             => Rose::HTML::Form::Field::Option
  'option group'       => Rose::HTML::Form::Field::OptionGroup

  'checkbox'           => Rose::HTML::Form::Field::Checkbox
  'check'              => Rose::HTML::Form::Field::Checkbox

  'radio button'       => Rose::HTML::Form::Field::RadioButton
  'radio'              => Rose::HTML::Form::Field::RadioButton

  'checkboxes'         => Rose::HTML::Form::Field::CheckboxGroup
  'checks'             => Rose::HTML::Form::Field::CheckboxGroup
  'checkbox group'     => Rose::HTML::Form::Field::CheckboxGroup
  'check group'        => Rose::HTML::Form::Field::CheckboxGroup

  'radio buttons'      => Rose::HTML::Form::Field::RadioButtonGroup
  'radios'             => Rose::HTML::Form::Field::RadioButtonGroup
  'radio button group' => Rose::HTML::Form::Field::RadioButtonGroup
  'radio group'        => Rose::HTML::Form::Field::RadioButtonGroup

  'pop-up menu'        => Rose::HTML::Form::Field::PopUpMenu
  'popup menu'         => Rose::HTML::Form::Field::PopUpMenu
  'menu'               => Rose::HTML::Form::Field::PopUpMenu

  'select box'         => Rose::HTML::Form::Field::SelectBox
  'selectbox'          => Rose::HTML::Form::Field::SelectBox
  'select'             => Rose::HTML::Form::Field::SelectBox

  'submit'             => Rose::HTML::Form::Field::Submit
  'submit button'      => Rose::HTML::Form::Field::Submit

  'reset'              => Rose::HTML::Form::Field::Reset
  'reset button'       => Rose::HTML::Form::Field::Reset

  'file'               => Rose::HTML::Form::Field::File
  'upload'             => Rose::HTML::Form::Field::File

  'password'           => Rose::HTML::Form::Field::Password

  'hidden'             => Rose::HTML::Form::Field::Hidden

  'num'                => Rose::HTML::Form::Field::Numeric
  'number'             => Rose::HTML::Form::Field::Numeric
  'numeric'            => Rose::HTML::Form::Field::Numeric

  'int'                => Rose::HTML::Form::Field::Integer
  'integer'            => Rose::HTML::Form::Field::Integer

  'email'              => Rose::HTML::Form::Field::Email

  'phone'              => Rose::HTML::Form::Field::PhoneNumber::US
  'phone us'           => Rose::HTML::Form::Field::PhoneNumber::US

  'phone us split' =>
    Rose::HTML::Form::Field::PhoneNumber::US::Split

  'set'  => Rose::HTML::Form::Field::Set

  'time' => Rose::HTML::Form::Field::Time

  'time split hms' => 
    Rose::HTML::Form::Field::Time::Split::HourMinuteSecond

  'time hours'       => Rose::HTML::Form::Field::Time::Hours
  'time minutes'     => Rose::HTML::Form::Field::Time::Minutes
  'time seconds'     => Rose::HTML::Form::Field::Time::Seconds

  'date'             => Rose::HTML::Form::Field::Date
  'datetime'         => Rose::HTML::Form::Field::DateTime

  'datetime range'   => Rose::HTML::Form::Field::DateTime::Range

  'datetime start'   => Rose::HTML::Form::Field::DateTime::StartDate
  'datetime end'     => Rose::HTML::Form::Field::DateTime::EndDate

  'datetime split mdy' => 
    Rose::HTML::Form::Field::DateTime::Split::MonthDayYear

  'datetime split mdyhms' => 
    Rose::HTML::Form::Field::DateTime::Split::MDYHMS

=item B<required_html_attrs>

Returns a reference to a sorted list of required HTML attributes in scalar context, or a sorted list of required HTML attributes in list context. The default set of required HTML attributes is empty.

Required HTML attributes are included in the strings generated by the L<html_attrs_string|/html_attrs_string> and L<xhtml_attrs_string|/xhtml_attrs_string> methods, even if they have been deleted using the L<delete_html_attr|/delete_html_attr> method or one of its variants.  If a required HTML attribute does not have a default value, its value defaults to an empty string or, if the attribute is also boolean, the name of the attribute.

See the introduction to the L<"CLASS METHODS"> section for more information about the "inheritable set" implementation used by the set of boolean HTML attributes.

=item B<required_html_attr_value ATTR [, VALUE]>

Get or set the default value of the required HTML attrbute ATTR.  If both ATTR and VALUE are passed, the value is set.  The current value is returned.

=item B<valid_html_attrs>

Returns a reference to a sorted list of valid HTML attributes in scalar context, or a sorted list of valid HTML attributes in list context.  The default set is:

    id
    class
    style
    title
    lang
    xml:lang
    dir
    onclick
    ondblclick
    onmousedown
    onmouseup
    onmouseover
    onmousemove
    onmouseout
    onkeypress
    onkeydown
    onkeyup

See the L<"VALIDATION"> section for more on the philosophy and policy of validation.  See the introduction to the L<"CLASS METHODS"> section for more information about the "inherited set" implementation used by the set of valid HTML attributes.

=item B<xhtml_element [NAME]>

Get or set the name of the XHTML element.  The XHTML element is the name of the tag, e.g. "img", "p", "a", "select", "textarea", etc.

This attribute may be read-only in subclasses, but is read/write here for increased flexibility.  The value is inherited by subclasses.

=back

=head1 CONSTRUCTOR

=over 4

=item B<new [ PARAMS | ELEMENT, PARAMS ]>

Constructs a new L<Rose::HTML::Object> object.  If an odd number of arguments is passed, the first argument is taken as the value for the L<element|/element> parameter.  Otherwise an even number of PARAMS name/value pairs are expected.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<add_child OBJECT>

This is an alias for the L<push_child|/push_child> method.

=item B<add_children OBJECTS>

This is an alias for the L<push_children|/push_children> method.

=item B<child INT>

Returns the L<child|/children> at the index specified by INT.  The first child is at index zero (0).

=item B<children [LIST]>

Get or set the list of L<Rose::HTML::Object>-derived objects that are contained within, or otherwise "children of" this object.  Any plain scalar in LIST is converted to a L<Rose::HTML::Text> object, with the scalar used as the value of the L<text|Rose::HTML::Text/text> attribute.

Returns a list (in list context) or a reference to an array (in scalar context) of L<Rose::HTML::Object>-derived objects.  The array reference return value should be treated as read-only.  The individual items may be treated as read/write provided that you understand that you're modifying the actual children, not copies.

=item B<clear_all_html_attrs>

Clears all the HTML attributes by settings their values to undef.

=item B<clear_html_attr NAME>

Clears the HTML attribute NAME by settings its value to undef.

=item B<clear_html_attrs NAME1, NAME2, ...>

Clears the HTML attributes specified by NAME1, NAME2, etc. by settings their values to undef.

=item B<delete_all_html_attrs>

Deletes all the HTML attributes.

=item B<delete_child [ INDEX | OBJECT ]>

Delete the L<child|/child> at INDEX (starting from zero) or the exact child OBJECT.

=item B<delete_children>

Deletes all L<children|/children>.

=item B<delete_html_attr NAME>

Deletes the HTML attribute NAME.

=item B<delete_html_attrs NAME1, NAME2, ...>

Deletes the HTML attributes specified by NAME1, NAME2, etc.

=item B<descendants>

Returns a list of the L<children|/children> of this object, plus all their children, and so on.

=item B<element [NAME]>

If passed a NAME, sets both L<html_element|/html_element> and L<xhtml_element|/xhtml_element> to NAME.  Returns L<html_element|/html_element>.

=item B<error [TEXT]>

Get or set an error string.

=item B<error_id [ID [, ARGS]]>

Get or set an integer L<error|Rose::HTML::Object::Errors> id.  When setting the error id, an optional ARGS hash reference should be passed if the L<localized text|Rose::HTML::Object::Message::Localizer/"LOCALIZED TEXT"> for the L<corresponding|/message_for_error_id> message contains any L<placeholders|Rose::HTML::Object::Message::Localizer/"LOCALIZED TEXT">.  Example:

  # Set error id, passing args for the label and value placeholders
  $obj->error_id(NUM_ABOVE_MAX, { label => $l, => value => $v });

=item B<escape_html [BOOL]>

This flag may be used by other methods to decide whether or not to escape HTML.  It is set to true by default.  The only method in L<Rose::HTML::Object> that references it is L<html_error|/html_error>.  All other HTML is escaped as appropriate regardless of the L<escape_html|/escape_html> setting (e.g. the text returned by C<html_attrs_string> always has its attribute values escaped).  Subclasses may consult this flag for similar purposes (which they must document, of course).

=item B<has_child OBJECT>

Returns true if OBJECT is a L<child|/child> of this object, false otherwise.

=item B<has_children>

Returns true if there are any L<children|/child>, false otherwise.

=item B<has_parent>

Returns true if this object is the L<child|/child> of another object, false otherwise.

=item B<has_error>

Returns true if an L<error|/error> is set, false otherwise.

=item B<html>

A synonym for the L<html_tag|/html_tag> method.

=item B<html_attr NAME [, VALUE]>

Get or set the HTML attribute NAME.  If just NAME is passed, it returns the value of the HTML attribute specified by NAME, or undef if there is no such attribute.

If both NAME and VALUE are passed, it sets the HTML attribute NAME to VALUE.

If NAME is not a valid attribute, a fatal error is thrown.

Examples:

    $o->html_attr(color => 'red');   # set color to red
    $color = $o->html_attr('color'); # get color

=item B<html_attrs [ATTRS]>

If called with an argument, this method sets and/or adds the HTML attributes specified by ATTRS, where ATTRS is a series of name/value pairs or a reference to a hash of name/value pairs.

Returns all of the existing HTML attributes as a hash (in list context) or a reference to a hash (in scalar context).

Note that the reference returned in scalar context is a reference to the object's actual hash of attributes; modifying it will change the state of the object!  I recommend that you treat the contents of the referenced hash as read-only, and I cannot promise that I will not find a way to force it to be read-only in the future.

The order of the attributes in the return value is indeterminate.

Examples:

    # Set/add attributes
    $o->html_attrs(color => 'red', age => 5); # name/value pairs
    $o->html_attrs({ style => fancy });       # hashref

    %h = $o->html_attrs; # get all three attributes as a hash
    $h = $o->html_attrs; # get all three attributes as a hash ref

=item B<html_attrs_string>

If there are any HTML attributes, it returns a sorted list of HTML attributes and their values in a string suitable for use in an HTML tag.  The string includes a leading space.

If there are no HTML attributes, an empty string is returned.

Examples:

    MyTag->add_valid_html_attrs('color', 'age');
    MyTag->add_boolean_html_attr('happy');

    $o = MyTag->new;

    $o->html_attrs(color => 'red<', age => 5, happy => 12345);

    $s = $o->html_attrs_string; # ' age="5" color="red&lt;" happy'

=item B<html_attr_hook NAME [, CODE]>

If called with two arguments, it sets the hook method for the attribute NAME to the code reference CODE.

If called with one or two arguments, it returns the hook method for the HTML attribute NAME as a code reference, or undef if there is no hook method.

Hook methods are called whenever their corresponding HTML attribute is set or retrieved.  When the attribute is set, the hook method gets the proposed value of the attribute as an argument.  The return value of the hook method is then used as the actual value of the attribute.

When an attribute is retrieved, the hook method is called with no arguments, and its return value is what is actually returned to the caller.

In both cases, the default variable C<$_> is localized and then set to the new or existing value of the attribute before the hook method is called.

Examples:

    # Set hook for 'color' attribute
    $o->html_attr_hook(color => sub 
    {
      my($self) = shift;

      if(@_) # attribute is being set
      {
        return uc shift; # make it uppercase
      }

      # attribute being retrieved: 
      return $_; # return the existing attribute value as-is
    });

    $o->html_attr(color => 'red');   # color set to 'RED'
    $color = $o->html_attr('color'); # $color = 'RED'

=item B<html_element [NAME]>

Get or set the name of the HTML element.  The HTML element is the name of the tag, e.g. "img", "p", "a", "select", "textarea", etc.

This attribute may be read-only in subclasses.

=item B<html_error>

Returns the error text, if any, as a snippet of HTML that looks like this:

    <span class="error">Error text goes here</span>

If the L<escape_html|/escape_html> flag is set to true (the default), then the error text has any HTML in it escaped.

=item B<html_tag>

Serializes the object as an HTML tag.  In other words, it is the concatenation of the strings returned by the L<html_element|/html_element> and L<html_attrs_string|/html_attrs_string> methods, wrapped with the appropriate angled brackets.

=item B<is_self_closing [BOOL]>

Get or set a boolean attribute that determines whether or not the HTML for this object requires a separate closing tag.  If set to true, then an empty "foo" tag would look like this:

     HTML: <foo>
    XHTML: <foo />

If false, then the tags above would look like this instead:

     HTML: <foo></foo>
    XHTML: <foo></foo>

The default value is false.  This attribute may be read-only in subclasses.

=item B<locale [LOCALE]>

This method may be called as a class method or an object method.

When called as an object method and a L<LOCALE|Rose::HTML::Object::Message::Localizer/LOCALES> is passed, then the L<locale|Rose::HTML::Object::Message::Localizer/LOCALES> of this object is set.  When called as a class method and a L<LOCALE|Rose::HTML::Object::Message::Localizer/LOCALES> is passed, then the L<default_locale|/default_locale> is set.

If no locale is set for this object (when called as an object method), then the the first defined locale from the object's L<parent_group|Rose::HTML::Form::Field/parent_group>, L<parent_field|Rose::HTML::Form::Field/parent_field>, L<parent_form|Rose::HTML::Form::Field/parent_form>, or generic L<parent|/parent> is returned.  If none of those locales are defined, then the L<localizer|/localizer>'s L<locale|Rose::HTML::Object::Message::Localizer/locale> is returned, if it is set.  Otherwise, the L<default_locale|/default_locale> is returned.

If no locale is set for this class (when called as a class method) then the L<localizer|/localizer>'s L<locale|Rose::HTML::Object::Message::Localizer/locale> is returned, if it is set.  Otherwise, the L<default_locale|/default_locale> is returned.

=item B<localizer [LOCALIZER]>

Get or set the L<Rose::HTML::Object::Message::Localizer>-derived object used to localize message text on behalf of this object.  If no localizer is set then the L<default_localizer|/default_localizer> is returned.

=item B<message_for_error_id [PARAMS]>

Given an L<error|Rose::HTML::Object::Errors> id, return the corresponding L<message|Rose::HTML::Object::Message::Localizer/message_class> object.  The default implementation simply looks for a message with the same integer id as the error.  Valid PARAMS name/value pairs are:

=over 4

=item B<error_id ID>

The integer error id.  This parameter is required.

=item B<args HASHREF>

A reference to a hash of name/value pairs to be used as the L<message arguments|Rose::HTML::Object::Message/args>.

=back

=item B<parent [OBJECT]>

Get or set the parent object.

=item B<pop_child [INT]>

Remove an object from the end of the list of L<children|/children> and return it.

=item B<pop_children [INT]>

Remove INT objects from the end of the list of L<children|/children> and return them.  If INT is ommitted, it defaults to 1.

=item B<push_child OBJECT>

Add OBJECT to the end of the list of L<children|/children>.  The object must be of or derived from the L<Rose::HTML::Object> class, or a plain scalar.  If it's a plain scalar, it will be converted to a L<Rose::HTML::Text> object, with the scalar used as the value of the L<text|Rose::HTML::Text/text> attribute.

=item B<push_children OBJECT1 [, OBJECT2, ...]>

Add objects on to the end of the list of L<children|/children>.  Each object must be of or derived from the L<Rose::HTML::Object> class, or a plain scalar.  All plain scalars will be converted to L<Rose::HTML::Text> objects, with the scalar used as the value of the L<text|Rose::HTML::Text/text> attribute.

=item B<set_error>

Set the L<error|/error> to a defined but "invisible" (zero-length) value.  This value will not be displayed by the L<html_error|/html_error> or L<xhtml_error|/xhtml_error> methods.  Use this method when you want to flag a field as having an error, but don't want a visible error message.

=item B<shift_child [INT]>

Remove an object from the start of the list of L<children|/children> and return it.

=item B<shift_children [INT]>

Remove INT objects from the start of the list of L<children|/children> and return them.  If INT is ommitted, it defaults to 1.

=item B<unshift_child OBJECT>

Add OBJECT to the start of the list of L<children|/children>.  The object must be of or derived from the L<Rose::HTML::Object> class, or a plain scalar.  If it's a plain scalar, it will be converted to a L<Rose::HTML::Text> object, with the scalar used as the value of the L<text|Rose::HTML::Text/text> attribute.

=item B<unshift_children OBJECT1 [, OBJECT2, ...]>

Add objects to the start of the list of L<children|/children>.  Each object must be of or derived from the L<Rose::HTML::Object> class, or a plain scalar.  All plain scalars will be converted to L<Rose::HTML::Text> objects, with the scalar used as the value of the L<text|Rose::HTML::Text/text> attribute.

=item B<unset_error>

Set the L<error|/error> to a undef.

=item B<validate_html_attrs BOOL>

If set to true, HTML attribute arguments to C<html_attr> and C<html_attr_hook> will be validated by calling C<html_attr_is_valid(ATTR)>, where ATTR is the name of the attribute being set or read.  The default value is true for any class derived from L<Rose::HTML::Object>, but false for objects whose class is L<Rose::HTML::Object>.

=item B<xhtml>

A synonym for the L<xhtml_tag|/xhtml_tag> method.

=item B<xhtml_element [NAME]>

Get or set the name of the XHTML element.  The XHTML element is the name of the tag, e.g. "img", "p", "a", "select", "textarea", etc.

This attribute may be read-only in subclasses.

=item B<xhtml_error>

Returns the error text, if any, as a snippet of XHTML that looks like this:

    <span class="error">Error text goes here</span>

If the L<escape_html|/escape_html> flag is set to true (the default), then the error text has any HTML in it escaped.

=item B<xhtml_tag>

Serializes the object as an XHTML tag.  In other words, it is the concatenation of the strings returned by the L<xhtml_element|/xhtml_element> and L<xhtml_attrs_string|/xhtml_attrs_string> methods, wrapped with the appropriate angled brackets and forward slash character.

=item B<xhtml_attrs_string>

If there are any HTML attributes, it returns a sorted list of HTML attributes and their values in a string suitable for use in an XHTML tag.  The string includes a leading space.

If there are no HTML attributes, an empty string is returned.

Examples:

    MyTag->add_valid_html_attrs('color', 'age');
    MyTag->add_boolean_html_attr('happy');

    $o = MyTag->new;

    $o->html_attrs(color => 'red<', age => 5, happy => 12345);

    # ' age="5" color="red&lt;" happy="happy"'
    $s = $o->xhtml_attrs_string;

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
