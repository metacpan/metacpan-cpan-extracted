package Rose::HTML::Object::Exporter;

use strict;

use Carp;

our $VERSION = '0.605';

our $Debug = 0;

use Rose::Class::MakeMethods::Generic
(
  inheritable_hash => 
  [
    export_tags        => { interface => 'get_set_all', hash_key => 'export_tags' },
    _export_tag        => { interface => 'get_set', hash_key => 'export_tags' },
    clear_export_tags  => { interface => 'clear', hash_key => 'export_tags' },
    delete_export_tags => { interface => 'delete', hash_key => 'export_tags' },

    _pre_import_hooks       => { interface => 'get_set_all', hash_key => 'pre_import_hooks' },
    _pre_import_hook        => { interface => 'get_set', hash_key => 'pre_import_hooks' },
    clear_pre_import_hooks  => { interface => 'clear', hash_key => 'pre_import_hooks' },
    delete_pre_import_hooks => { interface => 'delete', hash_key => 'pre_import_hooks' },
  ],
);

our %Imported;

sub imported
{
  my($class, $symbol) = (shift, shift);

  if(@_)
  {
    return $Imported{$class}{$symbol}{'from'} = shift;
  }

  return $Imported{$class}{$symbol};
}

our $Target_Class;

sub import
{
  my($class) = shift;

  my $target_class = $Target_Class || (caller)[0];

  my($force, @symbols, %import_as, $imported);

  foreach my $arg (@_)
  {
    if($arg =~ /^-?-force$/)
    {
      $force = 1;
    }
    elsif($arg =~ /^:(.+)/)
    {
      my $symbols = $class->export_tag($1) or
        croak "Unknown export tag - '$arg'";

      push(@symbols, @$symbols);
    }
    elsif(ref $arg eq 'HASH')
    {
      while(my($symbol, $name) = each(%$arg))
      {
        push(@symbols, $symbol);
        $import_as{$symbol} = $name;
      }
    }
    else
    {
      push(@symbols, $arg);
    }
  }

  foreach my $symbol (@symbols)
  {
    my $code = $class->can($symbol) or 
      croak "Could not import symbol '$symbol' from $class into $target_class - no such symbol";

    my $is_constant = (defined prototype($code) && !length(prototype($code))) ? 1 : 0;

    my $import_as = $import_as{$symbol} || $symbol;

    my $existing_code = $target_class->can($import_as);

    no strict 'refs';
    no warnings 'uninitialized';

    if($existing_code && !$force && (
         ($is_constant && $existing_code eq \&{"${target_class}::$import_as"}) ||
         (!$is_constant && $existing_code)))
    {
      next  if($Imported{$target_class}{$import_as});

      croak "Could not import symbol '$import_as' from $class into ",
            "$target_class - a symbol by that name already exists. ",
            "Pass a '--force' argument to import() to override ",
            "existing symbols."
    }

    if(my $hooks = $class->pre_import_hooks($symbol))
    {
      foreach my $code (@$hooks)
      {
        my $error;

        TRY:
        {
          local $@;
          eval { $code->($class, $symbol, $target_class, $import_as) };
          $error = $@;
        }

        if($error)
        {
          croak "Could not import symbol '$import_as' from $class into ",
                "$target_class - $error";
        }
      }
    }

    if($is_constant)
    {
      no strict 'refs';
      $Debug && warn "${target_class}::$import_as = ${class}::$symbol\n";
      *{$target_class . '::' . $import_as} = *{"${class}::$symbol"};
    }
    else
    {
      no strict 'refs';
      $Debug && warn "${target_class}::$import_as = ${class}->$symbol\n";
      *{$target_class . '::' . $import_as} = $code;
    }

    $Imported{$target_class}{$import_as}{'from'} = $class;
  }
}

sub export_tag
{
  my($class, $tag) = (shift, shift);

  if(index($tag, ':') == 0)
  {
    croak 'Tag name arguments to export_tag() should not begin with ":"';
  }

  if(@_ && (@_ > 1 || (ref $_[0] || '') ne 'ARRAY'))
  {
    croak 'export_tag() expects either a single tag name argument, ',
          'or a tag name and a reference to an array of symbol names';
  }

  my $ret = $class->_export_tag($tag, @_);

  croak "No such tag: $tag"  unless($ret);

  return wantarray ? @$ret : $ret;
}

sub add_export_tags
{
  my($class) = shift;

  while(@_)
  {
    my($tag, $arg) = (shift, shift);
    $class->export_tag($tag, $arg);
  }
}

sub add_to_export_tag
{
  my($class, $tag) = (shift, shift);
  my $list = $class->export_tag($tag);
  push(@$list, @_);
}

*delete_export_tag = \&delete_export_tags;

sub pre_import_hook
{
  my($class, $symbol) = (shift, shift);

  if(@_ && (@_ > 1 || (ref $_[0] && (ref $_[0] || '') !~ /\A(?:ARRAY|CODE)\z/)))
  {
    croak 'pre_import_hook() expects either a single symbol name argument, ',
          'or a symbol name and a code reference or a reference to an array ',
          'of code references';
  }

  if(@_)
  {
    unless(ref $_[0] eq 'ARRAY')
    {
      $_[0] = [ $_[0] ];
    }
  }

  my $ret = $class->_pre_import_hook($symbol, @_) || [];

  return wantarray ? @$ret : $ret;
}

sub pre_import_hooks { shift->pre_import_hook(shift) }

*delete_pre_import_hook = \&delete_pre_import_hooks;

1;
