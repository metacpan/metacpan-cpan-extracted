package Rose::HTML::Object::Message::Localizer;

use strict;

use Carp;
use Clone::PP();
use Scalar::Util();

use Rose::HTML::Object::Errors();
use Rose::HTML::Object::Messages();

use base 'Rose::Object';

our $VERSION = '0.606';

our $Debug = 0;

use constant DEFAULT_VARIANT => 'default';

#
# Object data
#

use Rose::Object::MakeMethods::Generic
(
  'hash --get_set_init' => 
  [
    'localized_messages_hash',
  ],

  'scalar --get_set_init' => 
  [
    'locale',
    'message_class',
    'messages_class',
    'errors_class',
    'error_class',
  ],
);

#
# Class data
#

use Rose::Class::MakeMethods::Generic
(
  inheritable_hash => 'default_locale_cascade',
);

use Rose::Class::MakeMethods::Generic
(
  inheritable_scalar => 
  [
    'default_locale',
    '_auto_load_messages',
    '_auto_load_locales',
  ],
);

__PACKAGE__->default_locale('en');
__PACKAGE__->default_locale_cascade('default' => [ 'en' ]);

#
# Class methods
#

sub default_variant { DEFAULT_VARIANT }

#
# Object methods
#

sub init_localized_messages_hash { {} }

sub init_locale_cascade 
{
  my($self) = shift;
  my $class = ref($self) || $self;
  return $class->default_locale_cascade;
}

sub locale_cascade
{
  my($self) = shift;

  my $hash = $self->{'locale_cascade'} ||= ref($self)->init_locale_cascade;

  if(@_)
  {
    if(@_ == 1)
    {
      return $hash->{$_[0]};
    }
    elsif(@_ % 2 == 0)
    {
      for(my $i = 0; $i < @_; $i += 2)
      {
        $hash->{$_[$i]} = $_[$i + 1];
      }
    }
    else { croak "Odd number of arguments passed to locale_cascade()" }
  }

  return wantarray ? %$hash : $hash;
}

sub init_locale
{
  my($self) = shift;
  my $class = ref($self) || $self;
  return $class->default_locale;
}

sub init_messages_class { 'Rose::HTML::Object::Messages' }
sub init_message_class  { 'Rose::HTML::Object::Message::Localized' }
sub init_errors_class   { 'Rose::HTML::Object::Errors' }
sub init_error_class    { 'Rose::HTML::Object::Error' }

sub clone { Clone::PP::clone(shift) }

sub parent
{
  my($self) = shift; 
  return Scalar::Util::weaken($self->{'parent'} = shift)  if(@_);
  return $self->{'parent'};
}

sub localize_message
{
  my($self, %args) = @_;

  my $message = $args{'message'};

  return $message  unless($message->can('text') && $message->can('id'));  
  return $message->text  if($message->is_custom);

  my $parent = $message;

  if($parent->can('parent'))
  {
    $parent = $parent->parent;
  }

  if($parent && $parent->isa('Rose::HTML::Object::Error'))
  {
    $parent = $parent->parent;
  }

  my $calling_class = $parent ? ref($parent) : $args{'caller'} || (caller)[0];

  my $first_parent = $parent;

  my $args   = $args{'args'}   || $message->args;
  my $locale = $args{'locale'} || $message->locale || $self->locale;

  my $id = $message->id;

  my $variant = $args{'variant'} ||=
    $self->select_variant_for_message(id     => $id,
                                      args   => $args,
                                      locale => $locale);

  my $locale_cascade = $self->locale_cascade($locale) ||
                       $self->locale_cascade('default') || [];

  foreach my $try_locale ($locale, @$locale_cascade)
  {
    my $variant_cascade = 
      $self->variant_cascade(locale  => $try_locale,
                             variant => $variant,
                             message => $message,
                             args    => $args) || [];

    foreach my $try_variant ($variant, @$variant_cascade)
    {
      my $text =
        $self->get_localized_message_text(
          id         => $id, 
          locale     => $try_locale,
          variant    => $try_variant,
          from_class => $calling_class);

      $parent = $first_parent;

      # Look for messages in parents
      while(!defined $text && $parent)
      {
        $parent = $parent->can('parent_field') ? $parent->parent_field :
                  $parent->can('parent_form')  ? $parent->parent_form  :
                  $parent->can('parent')       ? $parent->parent       : 
                  undef;

        if($parent)
        {
          $text = 
            $self->get_localized_message_text(
              id         => $id,
              locale     => $try_locale,
              variant    => $try_variant,
              from_class => ref($parent));
        }
      }

      return $self->process_placeholders($text, $args)  if(defined $text);
    }
  }

  return undef;
}

# All this to avoid making Scalar::Defer a prerequisite....sigh.
sub _evaluate
{  
  no warnings 'uninitialized';
  return $_[0]  unless(ref $_[0] eq 'CODE');
  return $_[0]->();
}

sub process_placeholders
{
  my($self, $text, $args) = @_;

  my %args = $args ? %$args : ();

   # Values will be modified in-place
  foreach my $value (values %args)
  {
    if(my $ref = ref($value))
    {
      if($ref eq 'ARRAY')
      {
        $value = [ map { _evaluate($_) } @$value ];
      }
      else
      {
        $value = _evaluate($value);
      }
    }
  }

  no warnings 'uninitialized';

  for($text)
  {
    # Process [@123(...)] and [@foo(...)] placeholders
    s{ ( (?:\\.|[^\[]*)* ) \[ \@ (\d+ | [a-zA-Z]\w* ) (?: \( (.*) \) )? \] }
     { $1 . join(defined $3 ? $3 : ', ', ref $args{$2} ? @{$args{$2}} : $args{$2}) }gex;

    # Process [123] and [foo] placeholders
    s{ ( (?:\\.|[^\[]*)* ) \[ (\d+ | [a-zA-Z]\w* ) \] }{$1$args{$2}}gx;

    # Unescape escaped opening square brackets
    s/\\\[/[/g;
  }

  return $text;
}

sub get_message_name { shift->messages_class->get_message_name(@_) }
sub get_message_id   { shift->messages_class->get_message_id(@_) }

sub get_error_name { shift->errors_class->get_error_name(@_) }
sub get_error_id   { shift->errors_class->get_error_id(@_) }

sub message_for_error_id
{
  my($self, %args) = @_;

  my $error_id  = $args{'error_id'};
  my $msg_class = $args{'msg_class'} || $self->message_class;
  my $args      = $args{'args'} || [];

  my $messages_class = $self->messages_class;

  if(defined $messages_class->get_message_name($error_id))
  {
    return $msg_class->new(id => $error_id, args => $args);
  }
  elsif($error_id !~ /^\d+$/)
  {
    croak "Unknown error id: $error_id";
  }

  return $msg_class->new(args => $args);
}

sub select_variant_for_message
{
  my($self, %args) = @_;

  my $args = $args{'args'};

  return $args->{'variant'}  if($args->{'variant'});  

  if(defined(my $count = $args->{'count'}))
  {
    return $self->select_variant_for_count(%args, count => $count);
  }

  return DEFAULT_VARIANT;
}

sub select_variant_for_count
{
  my($self, %args) = @_;

  my $locale = $args{'locale'} || $self->locale;
  my $count  = abs($args{'count'});

  # Possibilities:
  #
  # zero
  # one (singular)
  # two (dual)
  # few (paucal)
  # many
  # plural

  # No default judgements on "few" and "many"
  return $count == 0 ? 'zero' : 
         $count == 1 ? 'one'  :
         $count == 2 ? 'two'  :
         'plural';
}

my %Variant_Cascade =
(
  'zero'   => [ 'plural', DEFAULT_VARIANT ],
  'one'    => [ DEFAULT_VARIANT ],
  'two'    => [ 'plural', DEFAULT_VARIANT ],
  'few'    => [ 'plural', DEFAULT_VARIANT ],
  'many'   => [ 'plural', DEFAULT_VARIANT ],
  'plural' => [ DEFAULT_VARIANT ],
);

# Trying to avoid repeated anonymous array generation that
# might(?) result from using literal [] below
my @None;

sub variant_cascade
{
  my($self, %args) = @_;
  return $Variant_Cascade{$args{'variant'}} ||
         \@None;
}

sub localized_message_exists
{
  my($self, $name, $locale, $variant) = @_;

  my $msgs = $self->localized_messages_hash;

  $variant ||= DEFAULT_VARIANT;

  no warnings 'uninitialized';
  if(exists $msgs->{$name} && exists $msgs->{$name}{$locale})
  {
    if(ref $msgs->{$name}{$locale})
    {
      return $msgs->{$name}{$locale}{$variant} ? 1 : 0;
    }
    elsif($variant eq DEFAULT_VARIANT)
    {
      return 1;
    }
  }

  return 0;
}

sub locales_for_message_name
{
  my($self, $name) = @_;

  my $msgs = $self->localized_messages_hash;

  return wantarray ? () : []  unless(ref $msgs->{$name});

  return wantarray ? (sort keys %{$msgs->{$name}}) :
                     [ sort keys %{$msgs->{$name}} ];
}

sub add_localized_message_text { shift->set_localized_message_text(@_) }

sub set_localized_message_text
{
  my($self, %args) = @_;

  my $id      = $args{'id'};
  my $name    = $args{'name'};
  my $locale  = $args{'locale'} || $self->locale;
  my $text    = $args{'text'};
  my $variant = $args{'variant'};

  croak "Missing new localized message text"  unless(defined $text);

  if($name =~ /[^A-Z0-9_]/)
  {
    croak "Message names must be uppercase and may contain only ",
          "letters, numbers, and underscores";
  }

  if($id && $name)
  {
    unless($name eq $self->messages_class->get_message_name($id))
    {
      croak "The message id '$id' does not match the name '$name'";
    }
  }
  elsif(!defined $name)
  {
    croak "Missing message id"  unless(defined $id);
    $name = $self->messages_class->get_message_name($id) 
      or croak "No such message id - '$id'";
  }
  elsif(!defined $id)
  {
    croak "Missing message name"  unless(defined $name);
    $id = $self->messages_class->get_message_id($name) 
      or croak "No such message name - '$name'";
  }

  unless(ref $text eq 'HASH')
  {
    $text = { $locale => $text };
  }

  my $msgs = $self->localized_messages_hash;

  while(my($l, $t) = each(%$text))
  {
    $Debug && warn qq($self - Adding text $name), 
                   ($variant ? "($variant)" : ''), 
                   qq( [$l] - "$t"\n);

    if($variant)
    {
      if(ref $msgs->{$name}{$l})
      {
        $msgs->{$name}{$l}{$variant} = "$t"; # force stringification
      }
      else
      {
        my $existing = $msgs->{$name}{$l};

        if(defined $existing)
        {
          $msgs->{$name}{$l} = {};
          $msgs->{$name}{$l}{DEFAULT_VARIANT()} = $existing;
        }

        $msgs->{$name}{$l}{$variant} = "$t"; # force stringification
      }
    }
    else
    {
      if(ref ref $msgs->{$name}{$l})
      {
        $msgs->{$name}{$l}{DEFAULT_VARIANT()} = "$t"; # force stringification
      }
      else
      {
        $msgs->{$name}{$l} = "$t"; # force stringification
      }
    }
  }

  return $id;
}

sub import_message_ids
{
  my($self) = shift;

  if($Rose::HTML::Object::Exporter::Target_Class)
  {
    $self->messages_class->import(@_);
  }
  else
  {
    local $Rose::HTML::Object::Exporter::Target_Class = (caller)[0];
    $self->messages_class->import(@_);
  }
}

sub import_error_ids
{
  my($self) = shift;

  @_ = (':all')  unless(@_);

  if($Rose::HTML::Object::Exporter::Target_Class)
  {
    $self->errors_class->import(@_);
  }
  else
  {
    local $Rose::HTML::Object::Exporter::Target_Class = (caller)[0];
    $self->errors_class->import(@_);
  }
}

sub add_localized_message
{
  my($self, %args) = @_;

  my $id     = $args{'id'} || $self->generate_message_id;
  my $name   = $args{'name'} || croak "Missing name for new localized message";
  my $locale = $args{'locale'} || $self->locale;
  my $text   = $args{'text'};

  croak "Missing new localized message text"  unless(defined $text);

  if($name =~ /[^A-Z0-9_]/)
  {
    croak "Message names must be uppercase and may contain only ",
          "letters, numbers, and underscores";
  }

  unless(ref $text eq 'HASH')
  {
    $text = { $locale => $text };
  }

  my $msgs = $self->localized_messages_hash;
  my $msgs_class = $self->messages_class;

  my $const = "${msgs_class}::$name";

  if(defined &$const)
  {
    croak "A constant or subroutine named $name already exists in the class $msgs_class";
  }

  $msgs_class->add_message($name, $id);

  while(my($l, $t) = each(%$text))
  {
    $Debug && warn qq($self - Adding message $name ($l) = "$t"\n);
    $msgs->{$name}{$l} = "$t"; # force stringification
  }

  return $id;
}

use constant NEW_ID_OFFSET => 100_000;

our $Last_Generated_Message_Id = NEW_ID_OFFSET;
our $Last_Generated_Error_Id   = NEW_ID_OFFSET;

sub generate_message_id
{
  my($self) = shift;

  my $messages_class = $self->messages_class;
  my $errors_class = $self->errors_class;

  my $new_id = $Last_Generated_Error_Id;
  $new_id++  while($messages_class->message_id_exists($new_id) ||
                   $errors_class->error_id_exists($new_id));

  return $Last_Generated_Message_Id = $new_id;
}

sub generate_error_id
{
  my($self) = shift;

  my $errors_class = $self->errors_class;
  my $messages_class = $self->messages_class;

  my $new_id = $Last_Generated_Error_Id;
  $new_id++  while($errors_class->error_id_exists($new_id) || 
                   $messages_class->message_id_exists($new_id));

  return $Last_Generated_Error_Id = $new_id;
}

sub add_localized_error
{
  my($self, %args) = @_;

  my $id   = $args{'id'} || $self->generate_error_id;
  my $name = $args{'name'} or croak "Missing localized error name";

  my $errors_class = $self->errors_class;

  my $const = "${errors_class}::$name";

  if(defined &$const)
  {
    croak "A constant or subroutine named $name already exists in the class $errors_class";
  }

  $errors_class->add_error($name, $id);

  return $id;
}

sub dump_messages
{
  my($self, $code) = @_;
  my $msgs = $self->localized_messages_hash;
  return $code->($msgs)  if($code);
  require Data::Dumper;
  return Data::Dumper::Dumper($msgs);
}

sub get_localized_message_text
{
  my($self, %args) = @_;

  my $id         = $args{'id'};
  my $name       = $args{'name'};
  my $locale     = $args{'locale'} || $self->locale;
  my $variant    = $args{'variant'} || DEFAULT_VARIANT;
  my $from_class = $args{'from_class'}; 

  $from_class ||= (caller)[0];

  $name ||= $self->get_message_name($id);

  my $msgs = $self->localized_messages_hash;

  # Try this twice: before and after loading messages
  foreach my $try (1, 2)
  {
    no warnings 'uninitialized';
    if(exists $msgs->{$name} && exists $msgs->{$name}{$locale})
    {
      if(ref $msgs->{$name}{$locale} && exists $msgs->{$name}{$locale}{$variant})
      {
        return $msgs->{$name}{$locale}{$variant};
      }

      return $msgs->{$name}{$locale}  if($variant eq DEFAULT_VARIANT);
    }

    last  if($try == 2);

    $self->load_localized_message($name, $locale, $variant, $from_class);
  }

  return undef;
}

# ([A-Z0-9_]+) -> ([A-Z0-9_]+) (?: \( \s* (\w[-\w]*) \s* \) )?
# ([A-Z0-9_]+) -> ([A-Z0-9_]+)(?:\(\s*([-\w]+)\s*\))?
my $Locale_Declaration = qr{^\s* \[% \s* LOCALE \s* (\S+) \s* %\] \s* (?: \#.*)?$}x;
my $Start_Message = qr{^\s* \[% \s* START \s+ ([A-Z0-9_]+)(?:\(\s*([-\w]+)\s*\))? \s* %\] \s* (?: \#.*)?$}x;
my $End_Message = qr{^\s* \[% \s* END \s+ ([A-Z0-9_]+)(?:\(\s*([-\w]+)\s*\))?? \s* %\] \s* (?: \#.*)?$}x;
my $Message_Spec = qr{^ \s* ([A-Z0-9_]+)(?:\(\s*([-\w]+)\s*\))? \s* = \s* "((?:[^"\\]+|\\.)*)" \s* (?: \#.*)? $}x;
my $Comment_Or_Blank = qr{^ \s* \# | ^ \s* $}x;
my $End_Messages = qr{^=\w|^\s*__END__};

my %Data_Pos;

sub load_localized_message
{
  my($self, $name, $locale, $variant, $from_class) = @_;

  $from_class ||= $self->messages_class;

  if($self->localized_message_exists($name, $locale, $variant))
  {
    return $self->get_localized_message_text(name   => $name, 
                                            locale  => $locale, 
                                            variant => $variant);
  }

  no strict 'refs';
  my $fh = \*{"${from_class}::DATA"};

  if(fileno($fh))
  {
    local $/ = "\n";

    if($Data_Pos{$from_class})
    {
      # Rewind to the start of the __DATA__ section
      seek($fh, $Data_Pos{$from_class}, 0);
    }
    else
    {
      $Data_Pos{$from_class} = tell($fh);
    }

    my $text = $self->load_messages_from_fh(fh         => $fh, 
                                            locales    => $locale,
                                            variants   => $variant,
                                            names      => $name,
                                            force_utf8 => 1);
    return $text  if(defined $text);
  }

  no strict 'refs';

  my @classes = @{"${from_class}::ISA"};
  my %seen;

  while(@classes)
  {
    my $class = pop(@classes);
    next  if($seen{$class}++);
    #$Debug && warn "$self SEARCHING $class FOR $name ($locale)\n";
    my $msg = $self->load_localized_message($name, $locale, $variant, $class);
    return $msg  if(defined $msg);
    push(@classes, grep { !$seen{$_} } @{"${class}::ISA"});
  }

  return undef;
}

sub auto_load_locales
{
  my($self_or_class) = shift;

  my $class = ref($self_or_class) || $self_or_class;

  if(@_)
  {
    my $locales = (@_ == 1 && ref $_[0] eq 'ARRAY') ? [ @{$_[0]} ] : [ @_ ];
    return $class->_auto_load_locales($locales);
  }

  my $locales = $class->_auto_load_locales;
  return wantarray ? @$locales : $locales  if(defined $locales);

  if(my $locales = $ENV{'RHTMLO_LOCALES'})
  {
    $locales = [ split(/\s*,\s*/, $locales) ]  unless(ref $locales);
    $class->_auto_load_locales($locales);
    return wantarray ? @$locales : $locales;
  }

  return wantarray ? () : [];
}

sub auto_load_messages
{
  my($self_or_class) = shift;

  my $class = ref($self_or_class) || $self_or_class;

  if(@_)
  {
    return $class->_auto_load_messages(@_);
  }

  my $ret = $class->_auto_load_messages;
  return $ret  if(defined $ret);

  if(($ENV{'MOD_PERL'} && (!defined($ENV{'RHTMLO_PRIME_CACHES'}) || $ENV{'RHTMLO_PRIME_CACHES'})) ||
     $ENV{'RHTMLO_PRIME_CACHES'})
  {
    return $class->_auto_load_messages(1);
  }

  return undef;
}

sub load_all_messages
{
  my($class) = shift;

  my %args;

  if(@_ > 1)
  {
    %args = @_;
  }
  else
  {
    $args{'from_class'} = $_[0];
  }

  my $from_class = $args{'from_class'} || (caller)[0];

  no strict 'refs';
  my $fh = \*{"${from_class}::DATA"};

  if(fileno($fh))
  {
    local $/ = "\n";

    if($Data_Pos{$from_class})
    {
      # Rewind to the start of the __DATA__ section
      seek($fh, $Data_Pos{$from_class}, 0);
    }
    else
    {
      $Data_Pos{$from_class} = tell($fh);
    }

    my $locales = $class->auto_load_locales;

    $Debug && warn "$class - Loading messages from DATA section of $from_class\n";
    $class->load_messages_from_fh(fh => $fh, locales => $locales, force_utf8 => 1);
  }
}

sub load_messages_from_file
{
  my($self) = shift;

  my %args;
  if(@_ == 1)
  {
    $args{'file'} = shift;
  }
  elsif(@_ > 1)
  {
    croak "Odd number of arguments passed to load_messages_from_file()"
      if(@_ % 2 != 0);
    %args = @_;
  }

  my $file = delete $args{'file'} or croak "Missing file argument";

  open($args{'fh'}, $file) or croak "Could no open messages file '$file' - $!";
  $self->load_messages_from_fh(%args);
  close($args{'fh'});
}

sub load_messages_from_fh
{
  my($self, %args) = @_;

  my($fh, $locales, $variants, $msg_names) = @args{qw(fh locales variants names)};

  binmode($fh, ':utf8')  if($args{'force_utf8'});

  if(ref $locales eq 'ARRAY')
  {
    $locales = @$locales ? { map { $_ => 1} @$locales } : undef;
  }
  elsif($locales && !ref $locales)
  {
    $locales = { $locales => 1 };
  }

  if(ref $variants eq 'ARRAY')
  {
    $variants = @$variants ? { map { $_ => 1} @$variants } : undef;
  }
  elsif($variants && !ref $variants)
  {
    $variants = { $variants => 1 };
  }

  my $msg_re;

  if($msg_names)
  {
    if(!ref $msg_names)
    {
      $msg_names = { $msg_names => 1 };
    }
    elsif(ref $msg_names eq 'ARRAY')
    {
      $msg_names = { map { $_ => 1 } @$msg_names };
    }
    elsif(ref $msg_names eq 'Regexp')
    {
      $msg_re = $msg_names;
      $msg_names = undef;
    }
  }

  my @text;
  my $in_locale = '';
  my $in_msg    = '';
  my $variant   = '';
  my $text      = '';

  my $pos = tell($fh);;

  no strict 'refs';

  local $_;

  while(<$fh>)
  {
    last  if(/$End_Messages/o);

    #$Debug && warn "PROC: $_";

    if(/$End_Message/o && (!$2 || $2 eq $in_msg))
    {
      if(!$msg_names || $msg_names->{$in_msg} || ($msg_re && $in_msg =~ /$msg_re/))
      {
        for($text)
        {
          s/\A(\s*\n)+//;
          s/(\s*\n)+\z//;
        }

        #if($args{'force_utf8'} && !utf8::is_utf8($text))
        #{
        #  require Encode;
        #  $text = Encode::decode('UTF-8', $text);
        #}

        $self->set_localized_message_text(name    => $in_msg,
                                          locale  => $in_locale,
                                          variant => $variant,
                                          text    => $text);
      }

      $text    = '';
      $in_msg  = '';
      $variant = '';
    }
    elsif($in_msg)
    {
      $text .= $_;
    }
    elsif(/$Locale_Declaration/o)
    {
      $in_locale = $1;
    }
    elsif(/$Message_Spec/o)
    {
      if((!$locales || $locales->{$in_locale}) && 
         (!$variants || $variants->{$2 || DEFAULT_VARIANT}) && 
         (!$msg_names || $msg_names->{$1}))
      {
        my $name = $1;
        $variant = $2;
        my $text = $3;

        for($text)
        {
          s/\\n/\n/g;
          s/\\([^\[])/$1/g;
        }

        #if($args{'force_utf8'} && !utf8::is_utf8($text))
        #{
        #  require Encode;
        #  $text = Encode::decode('UTF-8', $text);
        #}

        $self->set_localized_message_text(name    => $name,
                                          locale  => $in_locale,
                                          text    => $text,
                                          variant => $variant);
        push(@text, $text)  if($msg_names);
      }
    }
    elsif(/$Start_Message/o)
    {
      $in_msg  = $1;
      $variant = $2;
    }
    elsif(!/$Comment_Or_Blank/o)
    {
      chomp;
      carp "WARNING: Localized message line not understood: $_";
    }
  }

  # Rewind to the starting position
  seek($fh, $pos, 0);

  return wantarray ? @text : $text[0];
  return;
}

sub load_messages_from_string
{
  my($self) = shift;

  my %args = @_ == 1 ? (string => shift) : @_;

  require IO::String;

  $args{'fh'} = IO::String->new(delete $args{'string'});

  return $self->load_messages_from_fh(%args);
}

use utf8; # The __END__ section contains UTF-8 text

1;

__END__

=encoding utf-8

=head1 NAME

Rose::HTML::Object::Message::Localizer - Message localizer class.

=head1 SYNOPSIS

    # The localizer for a given class or object is usually accessibly
    # via the "localizer" class or object method.

    $localizer = Rose::HTML::Object->localizer;    
    $localizer = $object->localizer;

    ...

    # The localizer is rarely used directly.  More often, it is
    # subclassed so you can provide your own alternate source for
    # localized messages. See the LOCALIZATION section of the
    # Rose::HTML::Objects documentation for more information.

    package My::HTML::Object::Message::Localizer;

    use base qw(Rose::HTML::Object::Message::Localizer);
    ...
    sub get_localized_message_text
    {
      my($self) = shift;

      # Get localized message text from the built-in sources
      my $text = $self->SUPER::get_localized_message_text(@_);

      unless(defined $text)
      {
        my %args = @_;

        # Get message text from some other source
        ...
      }

      return $text;
    }

=head1 DESCRIPTION

L<Rose::HTML::Object::Message::Localizer> objects are responsible for managing localized L<messages|Rose::HTML::Object::Messages> and L<errors|Rose::HTML::Object::Errors> which are identified by integer ids and symbolic constant names.  See the L<Rose::HTML::Object::Messages> and L<Rose::HTML::Object::Errors> documentation for more infomation on messages and errors.

In addition to collecting and providing access to messages and errors, L<Rose::HTML::Object::Message::Localizer> objects also provide appropriately localized text for each message and error.

This class inherits from, and follows the conventions of, L<Rose::Object>. See the L<Rose::Object> documentation for more information.

=head2 MESSAGES AND ERRORS

L<Messages|Rose::HTML::Object::Messages> and L<errors|Rose::HTML::Object::Errors> are stored and tracked separately, but are intimately related.  Both entities have integer ids which may be imported as symbolic constants, but only messages have associated localized text.

The integer message and error ids are convenient, compact, and easily comparable.  Using these constants in your code allows you to refer to messages and errors in a way that is divorced from any actual message text.  For example, if you wanted to subclass L<Rose::HTML::Form::Field::Integer> and do something special in response to "invalid integer" errors, you could do this:

    package My::HTML::Form::Field::Integer;

    use base 'Rose::HTML::Form::Field::Integer';

    # Import the symbol for the "invalid integer" error
    use Rose::HTML::Object::Errors qw(NUM_INVALID_INTEGER);

    sub validate
    {
      my($self) = shift;

      my $ret = $self->SUPER::validate(@_);

      unless($ret)
      {
        if($self->error_id == NUM_INVALID_INTEGER)
        {
          ... # do something here
        }
      }

      return $ret;
    }

Note how detecting the exact error did not require regex-matching against error message text or anything similarly unmaintainable.

When it comes time to display appropriate localized message text for the C<NUM_INVALID_INTEGER> error, the aptly named L<message_for_error_id|/message_for_error_id> method is called.  This method exists in the localizer, and also in L<Rose::HTML::Object|Rose::HTML::Object/message_for_error_id> and L<Rose::HTML::Form::Field|Rose::HTML::Form::Field/message_for_error_id>.  The localizer's incarnation of the method is usually only called if the other two are not available (e.g., in the absence of any HTML object or field).  The mapping between error ids and message ids is direct by default (i.e., error id 123 maps to message id 123) but can be entirely aribtrary. 

=head2 LOCALIZED TEXT

Broadly speaking, localized text can come from anywhere.  See the L<localization|Rose::HTML::Objects/LOCALIZATION> section of the L<Rose::HTML::Objects> documentaton for a description of how to create your own localizer subclass that loads localized message text from the source of your choosing.

The base L<Rose::HTML::Object::Message::Localizer> class reads localized text from the C<__DATA__> sections of Perl source code files and stores it in memory within the localizer object itself.  Such text is read in en masse when the L<load_all_messages|/load_all_messages> method is called, or on demand in response to requests for localized text.  The L<auto_load_messages|/auto_load_messages> flag may be used to distinguish between the two policies.  Here's an example C<__DATA__> section and L<load_all_messages|/load_all_messages> call (from the L<Rose::HTML::Form::Field::Integer> source code):

    if(__PACKAGE__->localizer->auto_load_messages)
    {
      __PACKAGE__->localizer->load_all_messages;
    }

    1;

    __DATA__

    [% LOCALE en %]

    NUM_INVALID_INTEGER          = "[label] must be an integer."
    NUM_INVALID_INTEGER_POSITIVE = "[label] must be a positive integer."
    NUM_NOT_POSITIVE_INTEGER     = "[label] must be a positive integer."

    [% LOCALE de %]

    NUM_INVALID_INTEGER          = "[label] muß eine Ganzzahl sein."
    NUM_INVALID_INTEGER_POSITIVE = "[label] muß eine positive Ganzzahl sein."
    NUM_NOT_POSITIVE_INTEGER     = "[label] muß eine positive Ganzzahl sein."

    [% LOCALE fr %]

    NUM_INVALID_INTEGER          = "[label] doit être un entier."
    NUM_INVALID_INTEGER_POSITIVE = "[label] doit être un entier positif."
    NUM_NOT_POSITIVE_INTEGER     = "[label] doit être un entier positif."

The messages for each locale are set off by C<LOCALE> directives surrounded by C<[%> and C<%]>.  All messages until the next such declaration are stored under the specified locale.

Localized text is provided in double-quoted strings to the right of symbolic L<messages|Rose::HTML::Object::Messages> constant names.  

Placeholders are replaced with text provided at runtime.  Placeholder names are surrounded by square brackets.  They must start with C<[a-zA-Z]> and may contain only characters that match C<\w>.  For an example, see the C<[label]> placeholders in the mssage text above.  A C<@> prefix is allowed to specify that the placeholder value is expected to be a reference to an array of values.

    SOME_MESSAGE = "A list of values: [@values]"

In such a case, the values are joined with ", " to form the text that replaces the placeholder.

Embedded double quotes in message text must be escaped with a backslash.  Embedded newlines may be included using a C<\n> sequence.  Literal opening square brackets must be backslash-escaped: C<\[>.  Literal backslashes must be doubled: C<\\>.  Example:

    SOME_MESSAGE = "Here\[]:\nA backslash \\ and some \"embedded\" double quotes"

The resulting text:

    Here[]:
    A backslash \ and some "embedded" double quotes

There's also a multi-line format for longer messages:

    [% START SOME_MESSAGE %]
    This message has multiple lines.
    Here's another one.
    [% END SOME_MESSAGE %]

Leading and trailing spaces and newlines are removed from text provided in the multi-line format.

Blank lines and any lines beginning with a C<#> character are skipped.

=head3 VARIANTS

Any L<message|Rose::HTML::Object::Messages> constant name may be followed immediately by a variant name within parentheses.  Variant names may contain only the characters C<[A-Za-z0-9_-]>.  If no variant is provided, the variant is assumed to be C<default>.  In other words, this:

    SOME_MESSAGE(default) = "..."

is equivalent to this:

    SOME_MESSAGE = "..."

Before going any further, the key thing to remember about variants is that you can ignore them entirely, if you wish.  Don't use any variants in your message text and don't specify any variants when asking for localized message text and you can pretend that they do not exist.

With that out of the way, there are some good reasons why you might want to use variants.  But first, let's examine how they work.  We've already seen the syntax for specifying variants using the built-in localized message text format.  The next piece of the puzzle is the ability to specify a particular variant for a message.  That can be done either explicitly or indirectly.  First, the explicit approach.

Requesting a variant explicitly is done using the special C<variant> L<message argument|Rose::HTML::Object::Message::Localized/args>.  Example:

    $field->error_id($id, { variant => 'foo' });

Aside from indicating the message variant, the C<variant> argument is treated just like any other.  That is, if you happen to have a placeholder named C<variant>, then the value will be subtituted for it.  (This being the case, it's usually a good idea to avoid using C<variant> as a placeholder name.)

If no explicit C<variant> is specified, the L<select_variant_for_message|/select_variant_for_message> method is called to select an appropriate variant.  The default implementation of this method returns the L<default variant|/default_variant> most of the time.  But if there is a L<message argument|Rose::HTML::Object::Message::Localized/args> named C<count>, then the L<select_variant_for_count|/select_variant_for_count> method is called in order to select the variant.

This leads to the primary intended use of variants: pluralization.  English has relatively simple pluralization rules, but other languages have special grammar for not just singular and plural, but also "dual," and sometimes even "many" and "few."  The pluralization variant names expected by the default implementation of L<select_variant_for_count|/select_variant_for_count> roughly follow the CLDR guidelines:

L<http://www.unicode.org/cldr/data/charts/supplemental/language_plural_rules.html>

with the exception that C<plural> is used in place of C<other>.  (Variants are a general purpose mechanism, whereas the context of pluralization is implied in the case of the CLDR terms.  A variant named C<other> has no apparent connection to pluralization.) 

The default implementation of L<select_variant_for_count|/select_variant_for_count> (sanely) makes no judgements about "few" or "many," but does return C<zero> for a C<count> of 0, C<one> for 1, C<two> for 2, and C<plural> for all other values of C<count>.

But since English has no special pluralization grammar for two items, how is this expected to work in the general case?  The answer is the so-called "L<variant cascade|/variant_cascade>."  If the desired variant is not available for the specified message in the requested locale, then the L<variant_cascade|/variant_cascade> method is called.  It is passed the locale, the desired variant, the message itself, and the message arguments.  It returns a list of other variants to try based on the arguments it was passed.

The default implementation of L<variant_cascade|/variant_cascade> follows simple English-centric rules, cascading directly to C<plural> except in the case of the C<one> variant, and appending the L<default variant|/default_variant> to the end of all cascades.

(Incidentally, there is also a L<locale cascade|/locale_cascade>.  The L<localize_message|/localize_message> method uses a nested loop: for each locale, for each variant, look for message text.  See the L<localize_message|/localize_message> documentation for more information.)

Here's an example using variants.  (Please forgive the poor translations.  I don't speak French.  Corrections welcome!)  First, the message text:

  [% LOCALE en %]

  FIELD_ERROR_TOO_MANY_DAYS = "Too many days."
  FIELD_ERROR_TOO_MANY_DAYS(one) = "One day is too many."
  FIELD_ERROR_TOO_MANY_DAYS(two) = "Two days is too many."
  FIELD_ERROR_TOO_MANY_DAYS(few) = "[count] days is too many (few)."
  FIELD_ERROR_TOO_MANY_DAYS(many) = "[count] days is too many (many)."
  FIELD_ERROR_TOO_MANY_DAYS(plural) = "[count] days is too many."

  [% LOCALE fr %]

  FIELD_ERROR_TOO_MANY_DAYS = "Trop de jours."
  FIELD_ERROR_TOO_MANY_DAYS(one) = "Un jour est un trop grand nombre."
  FIELD_ERROR_TOO_MANY_DAYS(plural) = "[count] jours est un trop grand nombre."

Now some examples of variant selection:

  use My::HTML::Object::Errors qw(FIELD_ERROR_TOO_MANY_DAYS)l
  ...

  $id = FIELD_ERROR_TOO_MANY_DAYS; # to make for shorter lines below

  $field->locale('en');

  $field->error_id($id, { count => 0 });

  # No explicit variant given.  The select_variant_for_count() called
  # and returns variant "zero".  No "zero" variant found for this
  # message in locale "en", so the variant_cascade() containing
  # ('plural', 'default') is considered, in that order.  A "plural"
  # variant is found.
  print $field->error; # "0 days is too many."

  $field->error_id($id, { count => 2 });

  # No explicit variant given.  The select_variant_for_count() called and 
  # returns variant "two".  That message variant is found in locale "en"
  print $field->error; # "Two days is too many."

  $field->error_id($id, { count => 3, variant => 'few'  });

  # Explicit variant given.  That message variant is found in locale "en"
  print $field->error; # "3 days is too many (few)."

  $field->locale('fr');

  $field->error_id($id, { count => 0 });

  # No explicit variant given.  The select_variant_for_count() called
  # and returns variant "zero".  No "zero" variant found for this
  # message in locale "fr", so the variant_cascade() containing
  # ('plural', 'default') is considered, in that order.  A "plural"
  # variant is found.
  print $field->error; # "0 jours est un trop grand nombre."

  $field->error_id($id, { count => 3, variant => 'few' });

  # Explicit variant given.  No "few" variant found for this message
  # in locale "fr", so the variant_cascade() containing ('plural',
  # 'default') is considered, in that order.  A "plural" variant is
  # found.
  print $field->error; # "3 jours est un trop grand nombre."

I hope you get the idea.  Remember that what's described above is merely the default implementation.  You are fully expected to override any and all public methods in the localizer in you L<private library|Rose::HTML::Objects/"PRIVATE LIBRARIES"> to alter their behavior.  An obvious choice is the L<variant_cascade|/variant_cascade> method, which you might want to override to provide more sensible per-locale cascades, replacing the default English-centric rules.

And even if you don't plan to use the variant system at all, you might want to override L<select_variant_for_message|/select_variant_for_message> to unconditionally return the L<default variant|/default_variant>, which will eliminate the special treatment of message arguments named C<count> and C<variant>.

=head3 CUSTOMIZATION

The implementation of localized message storage described above exists primarily because it's the most convenient way to store and distribute the localized messages that ship with the L<Rose::HTML::Objects> module distribution.  For a real application, it may be preferable to store localized text elsewhere.

The easiest way to do this is to create your own L<Rose::HTML::Object::Message::Localizer> subclass and override the L<get_localized_message_text|/get_localized_message_text> method, or any other method(s) you desire, and provide your own implementation of localized message storage and retrieval.

You must then ensure that your new localizer subclass is actually used by all of your HTML objects.  You can, of course, set the L<localizer|Rose::HTML::Object/localizer> attribute directly, but a much more comprehensive way to customize your HTML objects is by creating your own, private family tree of L<Rose::HTML::Object>-derived classes.  Please see the L<private libraries|Rose::HTML::Objects/"PRIVATE LIBRARIES"> section of the L<Rose::HTML::Objects> documentation for more information.

=head2 LOCALES

Localization is done based on a "locale", which is an arbitrary string containing one or more non-space characters.  The locale string must evaluate to a true value (i.e., the string "0" is not allowed as a locale).  The default set of locales used by the L<Rose::HTML::Objects> modules are lowercase two-letter language codes:

    LOCALE      LANGUAGE
    ------      --------
    en          English
    de          German
    fr          French
    bg          Bulgarian

Localized versions of all built-in messages and errors are provided for all of these locales.

=head1 CLASS METHODS

=over 4

=item B<auto_load_messages [BOOL]>

Get or set a boolean value indicating whether or not localized message text should be automatically loaded from classes that call their localizer's L<load_all_messages|/load_all_messages> method.  The default value is true if either of the C<MOD_PERL> or C<RHTMLO_PRIME_CACHES> environment variables are set to a true value, false otherwise.

=item B<default_locale [LOCALE]>

Get or set the default L<locale|/locale> used by objects of this class.  Defaults to "en".

=item B<default_locale_cascade [PARAMS]>

Get or set the default locale cascade.  PARAMS are L<locale|/"LOCALES">/arrayref pairs.  Each referenced array contains a list of locales to check, in the order specified, when message text is not available in the desired locale.  There is one special locale name, C<default>, that's used if no locale cascade exists for a particular locale.  The default locale cascade is:

    default => [ 'en' ]

That is, if message text is not available in the desired locale, C<en> text will be returned instead (assuming it exists).

This method returns the default locale cascade as a reference to a hash of locale/arrayref pairs (in scalar context) or a list of locale/arrayref pairs (in list context).

=item B<load_all_messages [PARAMS]>

Load all localized message text from the C<__DATA__> section of the class specified by PARAMS name/value pairs.  Valid PARAMS are:

=over 4

=item B<from_class CLASS>

The name of the class from which to load localized message text.  Defaults to the name of the class from which this method was called.

=back

=back

=head1 CONSTRUCTOR

=over 4

=item B<new [PARAMS]>

Constructs a new L<Rose::HTML::Object::Message::Localizer> object based on PARAMS, where PARAMS are
name/value pairs.  Any object method is a valid parameter name.

=back

=head1 OBJECT METHODS

=over 4

=item B<add_localized_error PARAMS>

Add a new localized error message.  PARAMS are name/value pairs.  Valid PARAMS are:

=over 4

=item B<id ID>

An integer L<error|Rose::HTML::Object::Errors> id.  Error ids from 0 to 29,999 are reserved for built-in errors.  Negative error ids are reserved for internal use.  Please use error ids 30,000 or higher for your errors.  If omitted, the L<generate_error_id|/generate_error_id> method will be called to generate a value.

=item B<name NAME>

An L<error|Rose::HTML::Object::Errors> name.  This parameter is required.  Error names may contain only the characters C<[A-Z0-9_]> and must be unique among all error names.

=back

=item B<add_localized_message PARAMS>

Add a new localized message.  PARAMS are name/value pairs.  Valid PARAMS are:

=over 4

=item B<id ID>

An integer L<message|Rose::HTML::Object::Messages> id.  Message ids from 0 to 29,999 are reserved for built-in messages.  Negative message ids are reserved for internal use.  Please use message ids 30,000 or higher for your messages.  If omitted, the L<generate_message_id|/generate_message_id> method will be called to generate a value.

=item B<name NAME>

A L<message|Rose::HTML::Object::Messages> name.  This parameter is required.  Message names may contain only the characters C<[A-Z0-9_]> and must be unique among all message names.

=back

=item B<default_variant>

Returns the name of the default variant: C<default>.  See the L<variants|/VARIANTS> subsection of the L<localized text|/"LOCALIZED TEXT"> section above for more information on variants.

=item B<error_class [CLASS]>

Get or set the name of the L<Rose::HTML::Object::Error>-derived class used to store each error.  The default value is L<Rose::HTML::Object::Error>.  To change the default, override the C<init_error_class> method in your subclass and return a different class name.

=item B<errors_class [CLASS]>

Get or set the name of the L<Rose::HTML::Object::Errors>-derived class used to store and track error ids and symbolic constant names.  The default value is L<Rose::HTML::Object::Errors>.  To change the default, override the C<init_errors_class> method in your subclass and return a different class name.

=item B<locale [LOCALE]>

Get or set the locale assumed by the localizer in the absence of an explicit locale argument.  Defaults to the value returned by the L<default_locale|/default_locale> class method.

=item B<message_class [CLASS]>

Get or set the name of the L<Rose::HTML::Object::Message>-derived class used to store each message.  The default value is L<Rose::HTML::Object::Message::Localized>.  To change the default, override the C<init_message_class> method in your subclass and return a different class name.

=item B<messages_class [CLASS]>

Get or set the name of the L<Rose::HTML::Object::Messages>-derived class used to store and track message ids and symbolic constant names.  The default value is L<Rose::HTML::Object::Messages>.  To change the default, override the C<init_messages_class> method in your subclass and return a different class name.

=item B<generate_error_id>

Returns a new integer L<error|Rose::HTML::Object::Errors> id.  This method will not return the same value more than once.

=item B<generate_message_id>

Returns a new integer L<message|Rose::HTML::Object::Messages> id.  This method will not return the same value more than once.

=item B<get_error_id NAME>

This method is a proxy for the L<errors_class|/errors_class>'s L<get_error_id|Rose::HTML::Object::Errors/get_error_id> method.

=item B<get_error_name ID>

This method is a proxy for the L<errors_class|/errors_class>'s L<get_error_name|Rose::HTML::Object::Errors/get_error_name> method.

=item B<get_localized_message_text PARAMS>

Returns localized message text based on PARAMS name/value pairs.  Valid PARAMS are:

=over 4

=item B<id ID>

An integer L<message|Rose::HTML::Object::Messages> id.  If a C<name> is not passed, then the name corresponding to this message id will be looked up using the L<get_message_name|/get_message_name> method.

=item B<name NAME>

The L<message|Rose::HTML::Object::Messages> name.  If this parameter is not passed, then the C<id> parameter must be passed.

=item B<locale LOCALE>

The L<locale|/LOCALES> of the localized message text.  Defaults to the localizer's L<locale()|/locale> if omitted.

=item B<from_class CLASS>

The name of the class from which to attempt to L<load the localized message text|/"LOCALIZED TEXT">.  If omitted, it defaults to the name of the package from which this method was called.

=back

=item B<get_message_id NAME>

This method is a proxy for the L<messages_class|/messages_class>'s L<get_message_id|Rose::HTML::Object::Messages/get_message_id> method.

=item B<get_message_name ID>

This method is a proxy for the L<messages_class|/messages_class>'s L<get_message_name|Rose::HTML::Object::Messages/get_message_name> method.

=item B<load_messages_from_file [ FILE | PARAMS ]>

Load localized message text, in the format described in the L<LOCALIZED TEXT|/"LOCALIZED TEXT"> section above, from a file on disk.  Note that this method only loads message I<text>.  The message ids must already exist in the L<messages_class|/messages_class>.

If a single FILE argument is passed, it is taken as the value for the C<file> parameter.  Otherwise, PARAMS name/value pairs are expected.  Valid PARAMS are:

=over 4

=item B<file PATH>

The path to the file.  This parameter is required.

=item B<locales [ LOCALE | ARRAYREF ]>

A L<locale|/"LOCALES"> or a reference to an array of locales.  If provided, only message text for the specified locales will be loaded.  If omitted, all locales will be loaded.

=item B<names [ NAME | ARRAYREF | REGEX ]>

Only load text for the specified messages.  Pass either a single message NAME, a reference to an array of names, or a regular expression that matches the names of the messages you want to load.

=back

=item B<locale [LOCALE]>

Get or set the L<locale|/"LOCALES"> of this localizer.  This locale is used by several methods when a locale is not explicitly provided.  The default value is determined by the L<default_locale|/default_locale> class method.

=item B<locale_cascade [PARAMS]>

Get or set the locale cascade.  PARAMS are L<locale|/"LOCALES">/arrayref pairs.  Each referenced array contains a list of locales to check, in the order specified, when message text is not available in the desired locale.  There is one special locale name, C<default>, that's used if no locale cascade exists for a particular locale.  The default locale cascade is determined by the L<default_locale_cascade|/default_locale_cascade> class method.

This method returns the locale cascade as a reference to a hash of locale/arrayref pairs (in scalar context) or a list of locale/arrayref pairs (in list context).

=item B<localize_message PARAMS>

Localize a message, returning the appropriately localized and processed message text.  Valid PARAMS name/value pairs are:

=over 4

=item B<args HASHREF>

A reference to a hash of L<message arguments|Rose::HTML::Object::Message::Localized/args>.  If omitted, the C<message>'s L<args|Rose::HTML::Object::Message::Localized/args> are used.

=item B<locale LOCALE>

The locale.  If omitted, the C<message>'s L<locale|Rose::HTML::Object::Message::Localized/locale> is used.

=item B<message MESSAGE>

The L<Rose::HTML::Object::Message>-derived message object.  This parameter is required.

=item B<variant VARIANT>

The message L<variant|/"VARIANTS">.  If omitted, the L<select_variant_for_message|/select_variant_for_message> method is called, passing the C<message> L<id|Rose::HTML::Object::Message/id>, C<args>, and C<locale>.

=back

This method performs a nested loop to search for localized message text: for each locale (including any L<locale_cascade|/locale_cascade>), for each variant (including any L<variant_cascade|/variant_cascade>), for each parent L<field|Rose::HTML::Form::Field/parent_field>, L<form|Rose::HTML::Form::Field/parent_form>, or generic parent L<object|Rose::HTML::Object/parent> (considered in that order), look for message text by calling the L<get_localized_message_text|/get_localized_message_text> method.

=item B<message_for_error_id PARAMS>

Given an L<error|Rose::HTML::Object::Errors> id, return the corresponding L<message_class|/message_class> object.  The default implementation simply looks for a message with the same integer id as the error.  Valid PARAMS name/value pairs are:

=over 4

=item B<error_id ID>

The integer error id.  This parameter is required.

=item B<args HASHREF>

A reference to a hash of name/value pairs to be used as the L<message arguments|Rose::HTML::Object::Message/args>.

=back

=item B<parent [OBJECT]>

Get or set a weakened reference to the localizer's parent object.

=item B<select_variant_for_count PARAMS>

Select and return a L<variant|/"VARIANTS"> name based on PARAMS name/value pairs.  Valid PARAMS are:

=over 4

=item B<args HASHREF>

A reference to a hash of L<message arguments|Rose::HTML::Object::Message::Localized/args>.

=item B<count INTEGER>

The count for which to select a variant.  This parameter is required.

=item B<locale LOCALE>

The L<locale|/LOCALES> of the localized message text.  Defaults to the localizer's L<locale()|/locale> if omitted.

=back

The default implementation looks only at the C<count> parameter and returns the following values based on it (the C<*> below means "any other value"):

    count   variant
    -----   -------
    0       zero
    1       one
    2       two
    *       plural

See the L<variants|/VARIANTS> section for more information on this and other variant-related methods

=item B<select_variant_for_message PARAMS>

Select and return a L<variant|/"VARIANTS"> name based on PARAMS name/value pairs.  Valid PARAMS are:

=over 4

=item B<args HASHREF>

A reference to a hash of L<message arguments|Rose::HTML::Object::Message::Localized/args>.

=item B<id MESSAGEID>

The L<message id|Rose::HTML::Object::Messages>.

=item B<locale LOCALE>

The L<locale|/LOCALES> of the localized message text.  Defaults to the localizer's L<locale()|/locale> if omitted.

=back

If C<args> contains a C<count> parameter, then the L<select_variant_for_count|/select_variant_for_count> method is called, passing all arguments plus the C<count> value as its own parameter, and the variant it returns is returned from this method.

If C<args> contains a C<variant> parameter, then the value of that parameter is returned.

Otherwise, the L<default_variant|/default_variant> is returned.

=item B<set_localized_message_text PARAMS>

Set the localized text for a message.  Valid PARAMS name/value pairs are:

=over 4

=item B<id ID>

An integer L<message|Rose::HTML::Object::Messages> id.  If a C<name> is not passed, then the name corresponding to this message id will be looked up using the L<get_message_name|/get_message_name> method.

=item B<name NAME>

The L<message|Rose::HTML::Object::Messages> name.  If this parameter is not passed, then the C<id> parameter must be passed.

=item B<locale LOCALE>

The L<locale|/LOCALES> of the localized message text.  Defaults to the localizer's L<locale|/locale>.

=item B<text TEXT>

The localized message text.

=item B<variant VARIANT>

The message variant, if any.  See the L<LOCALIZED TEXT|/"LOCALIZED TEXT"> section above for more information about variants.

=back

=item B<variant_cascade [PARAMS]>

Return a reference to an array of L<variant|/VARIANTS> names under which to look for localized text, assuming the requested variant is not available in the context specified in PARAMS name/value pairs.  Valid params are:

=over 4

=item B<args HASHREF>

A reference to a hash of L<message arguments|Rose::HTML::Object::Message::Localized/args>.

=item B<locale LOCALE>

The L<locale|/LOCALES> of the desired localized message text.

=item B<message MESSAGE>

The L<Rose::HTML::Object::Message>-derived message object.

=item B<variant VARIANT>

The originally requested message L<variant|/"VARIANTS">.

=back

The default implementation looks only at the C<variant> parameter and returns references to arrays containing the following variant lists based on it:

    variant   variant cascade
    -------   ---------------
    zero      plural, default
    one       default
    two       plural, default
    few       plural, default
    many      plural, default
    plural    default

The array references returned should be treated as read-only.

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
