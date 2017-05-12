package Rose::DB::Object::MakeMethods::Generic;

use strict;

use Bit::Vector::Overload;

use Carp();
use Scalar::Util qw(weaken refaddr);

use Rose::Object::MakeMethods;
our @ISA = qw(Rose::Object::MakeMethods);

use Rose::DB::Object::Manager;
use Rose::DB::Constants qw(IN_TRANSACTION);
use Rose::DB::Object::Constants 
  qw(PRIVATE_PREFIX FLAG_DB_IS_PRIVATE STATE_IN_DB STATE_LOADING
     STATE_SAVING ON_SAVE_ATTR_NAME MODIFIED_COLUMNS MODIFIED_NP_COLUMNS
     SET_COLUMNS EXCEPTION_CODE_NO_KEY);

use Rose::DB::Object::Helpers();
use Rose::DB::Object::Util qw(column_value_formatted_key);

our $VERSION = '0.812';

our $Debug = 0;

sub scalar
{
  my($class, $name, $args) = @_;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';
  my $length    = $args->{'length'} || 0;
  my $overflow  = $args->{'overflow'};
  my $default   = $args->{'default'};
  my $check_in  = $args->{'check_in'};
  my $smart     = $args->{'smart_modification'};
  my $type      = $args->{'_method_type'} || 'scalar';

  my $column_name = $args->{'column'} ? $args->{'column'}->name : $name;

  $length = undef  if($type eq 'integer'); # don't limit integers by length

  my $init_method;

  if(exists $args->{'with_init'} || exists $args->{'init_method'})
  {
    $init_method = $args->{'init_method'} || "init_$name";
  }

  my $undef_overrides_default = $args->{'undef_overrides_default'};

  ##
  ## Build code snippets
  ##

  my $qkey = $key;
  $qkey =~ s/'/\\'/g;
  my $qname = $name;
  $qname =~ s/"/\\"/g;

  my $col_name_escaped = $column_name;
  $col_name_escaped =~ s/'/\\'/g;

  my $mod_columns_key = ($args->{'column'} ? $args->{'column'}->nonpersistent : 0) ? 
    MODIFIED_NP_COLUMNS : MODIFIED_COLUMNS;

  my $dont_use_default_code = !$undef_overrides_default ? qq(defined \$self->{'$qkey'}) :
    qq(defined \$self->{'$qkey'} || ) .
    qq((\$self->{STATE_IN_DB()} && !(\$self->{SET_COLUMNS()}{'$col_name_escaped'} || \$self->{'$mod_columns_key'}{'$col_name_escaped'})) || ) .
    qq(\$self->{SET_COLUMNS()}{'$col_name_escaped'} || ) .
    qq(\$self->{'$mod_columns_key'}{'$col_name_escaped'});

  #
  # check_in code
  #

  my $check_in_code = '';
  my %check;

  if($check_in)
  {
    $check_in = [ $check_in ] unless(ref $check_in);
    %check = map { $_ => 1 } @$check_in;

    $check_in_code=<<"EOF";
if(defined \$value)
    {
      Carp::croak "Invalid $name: '\$value'"  unless(exists \$check{\$value});
    }

EOF
  }

  #
  # length check code
  #

  my $length_check_code = '';

  if($length)
  {
    unless($length =~ /^\d+$/)
    {
      Carp::croak "Invalid length for $type column $qname: '$length'";
    }

    no warnings 'uninitialized';
    if($overflow eq 'fatal')
    {
      $length_check_code =<<"EOF";
no warnings 'uninitialized';
if(length(\$value) > $length)
    {
      Carp::croak ref(\$self), ": Value for $qname() is too long.  Maximum ",
                  "length is $length character@{[ $length == 1 ? '' : 's' ]}.  ",
                  "Value is ", length(\$value), " characters: \$value";
    }

EOF
    }
    elsif($overflow eq 'warn')
    {
      $length_check_code =<<"EOF";
no warnings 'uninitialized';
if(length(\$value) > $length)
    {
      Carp::carp ref(\$self), ": WARNING: Value for $qname() is too long.  ",
                  "Maximum length is $length character@{[ $length == 1 ? '' : 's' ]}.  ",
                  "Value is ", length(\$value), " characters: \$value";
    }
EOF
    }
    elsif($overflow eq 'truncate')
    {
      $length_check_code =<<"EOF";
no warnings 'uninitialized';
if(length(\$value) > $length)
    {
      \$value = substr(\$value, 0, $length);
    }

EOF
    }
    elsif(defined $overflow)
    {
      Carp::croak "Invalid overflow value: $overflow";
    }
  }

  #
  # set code
  #

  my $set_code;

  if($type eq 'character')
  {
    $set_code = qq(\$self->{'$qkey'} = defined \$value ? sprintf("%-${length}s", \$value) : undef;);
  }
  else
  {
    $set_code = qq(\$self->{'$qkey'} = \$value;);
  }

  #
  # column modified code
  #

  my $column_modified_code = 
    qq(\$self->{'$mod_columns_key'}{'$col_name_escaped'} = 1);

  #
  # return code
  #

  my $return_code = '';
  my $return_code_get = '';
  my $return_code_shift = '';

  if(defined $default)
  {
    if($type eq 'character')
    {
      $return_code_get=<<"EOF";
return ($dont_use_default_code) ? \$self->{'$qkey'} : 
  (\$self->{'$qkey'} = sprintf("%-${length}s", \$default));
EOF

      $return_code=<<"EOF";
return ($dont_use_default_code) ? \$self->{'$qkey'} : 
  (scalar($column_modified_code, 
          \$self->{'$qkey'} = sprintf("%-${length}s", \$default)));
EOF
    }
    else
    {
      $return_code_get=<<"EOF";
return ($dont_use_default_code) ? \$self->{'$qkey'} : 
  (\$self->{'$qkey'} = \$default);
EOF

      $return_code=<<"EOF";
return ($dont_use_default_code) ? \$self->{'$qkey'} : 
  (scalar($column_modified_code, 
          \$self->{'$qkey'} = \$default));
EOF
    }
  }
  elsif(defined $init_method)
  {
    if($type eq 'character')
    {
      $return_code_get=<<"EOF";
return (defined \$self->{'$qkey'}) ? \$self->{'$qkey'} : 
  (\$self->{'$qkey'} = sprintf("%-${length}s", \$self->$init_method()));
EOF

      $return_code=<<"EOF";
return (defined \$self->{'$qkey'}) ? \$self->{'$qkey'} : 
  (scalar($column_modified_code, 
          \$self->{'$qkey'} = sprintf("%-${length}s", \$self->$init_method())));
EOF
    }
    else
    {
      $return_code_get=<<"EOF";
return (defined \$self->{'$qkey'}) ? \$self->{'$qkey'} : 
  (\$self->{'$qkey'} = \$self->$init_method());
EOF

      $return_code=<<"EOF";
return (defined \$self->{'$qkey'}) ? \$self->{'$qkey'} : 
  (scalar($column_modified_code, 
          \$self->{'$qkey'} = \$self->$init_method()));
EOF
    }
  }
  else
  {
    $return_code       = qq(return \$self->{'$qkey'};);
    $return_code_shift = qq(return shift->{'$qkey'};);
  }

  $return_code_get   ||= $return_code;
  $return_code_shift ||= $return_code;

  my $save_old_val_code = $smart ? 
    qq(no warnings 'uninitialized';\nmy \$old_val = \$self->{'$qkey'};) : '';

  my $was_set_code = $smart ?
    qq(\$self->{SET_COLUMNS()}{'$col_name_escaped'} = 1;) : '';

  my $mod_cond_code;

  if($smart)
  {
    $mod_cond_code = ($type eq 'integer') ?
      qq(unless(\$self->{STATE_LOADING()} || (!defined \$old_val && !defined \$self->{'$qkey'}) || (\$old_val == \$self->{'$qkey'} && length \$old_val && length \$self->{'$qkey'}));) :
      qq(unless(\$self->{STATE_LOADING()} || (!defined \$old_val && !defined \$self->{'$qkey'}) || \$old_val eq \$self->{'$qkey'}););
  }
  else
  {
    $mod_cond_code = qq(unless(\$self->{STATE_LOADING()}););
  }

  my $mod_cond_pre_set_code;

  if($smart)
  {
    $mod_cond_pre_set_code = ($type eq 'integer') ?
      qq(unless(\$self->{STATE_LOADING()} || (!defined \$value && !defined \$self->{'$qkey'}) || (\$value == \$self->{'$qkey'} && length \$value && length \$self->{'$qkey'}));) :
      qq(unless(\$self->{STATE_LOADING()} || (!defined \$value && !defined \$self->{'$qkey'}) || \$value eq \$self->{'$qkey'}););
  }
  else
  {
    $mod_cond_pre_set_code = qq(unless(\$self->{STATE_LOADING()}););
  }

  my %methods;

  if($interface eq 'get_set')
  {
    my $code;

    # I can't help myself...
    if(defined $default || defined $init_method)
    {
      $code=<<"EOF";
sub
{
  my \$self = shift;

  if(\@_)
  {
    my \$value = shift;

    no warnings;
    $check_in_code
    $length_check_code
    $save_old_val_code
    $set_code
    $column_modified_code  $mod_cond_code
    $was_set_code
    $return_code
  }

  $return_code_get
};
EOF
    }
    else
    {
      $code=<<"EOF";
sub
{
  if(\@_ > 1)
  {
    my \$self  = shift;
    my \$value = shift;

    no warnings;
    $check_in_code
    $length_check_code
    $column_modified_code  $mod_cond_pre_set_code
    $was_set_code
    return $set_code
  }

  $return_code_shift
};
EOF
    }

    my $error;

    TRY:
    {
      local $@;
      $Debug && warn "sub $name = ", $code;
      $methods{$name} = eval $code;
      $error = $@;
    }

    if($error)
    {
      Carp::croak "Error in generated code for method $name - $error\n",
                  "Code was: $code";
    }
  }
  elsif($interface eq 'get')
  {
    my $code;

    # I can't help myself...
    if(defined $default || defined $init_method)
    {
      $code = qq(sub { my \$self = shift; $return_code };);
    }
    else
    {
      $code = qq(sub { shift->{'$qkey'} });
    }

    my $error;

    TRY:
    {
      local $@;
      $Debug && warn "sub $name = ", $code;
      $methods{$name} = eval $code;
      $error = $@;
    }

    if($error)
    {
      Carp::croak "Error in generated code for method $name - $error\n",
                  "Code was: $code";
    }
  }
  elsif($interface eq 'set')
  {
    my $arg_check_code = 
      qq(Carp::croak ref(\$_[0]), ": Missing argument in call to $qname"  unless(\@_ > 1););

    my $code=<<"EOF";
sub
{
  $arg_check_code
  my \$self = shift;
  my \$value = shift;

  no warnings;
  $check_in_code
  $length_check_code
  $save_old_val_code
  $set_code
  $column_modified_code  $mod_cond_code
  $was_set_code
  $return_code
};
EOF

    my $error;

    TRY:
    {
      local $@;
      $Debug && warn "sub $name = ", $code;
      $methods{$name} = eval $code;
      $error = $@;
    }

    if($error)
    {
      Carp::croak "Error in generated code for method $name - $error\n",
                  "Code was: $code";
    }
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

sub enum
{
  my($class, $name, $args) = @_;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';

  my $column_name = $args->{'column'} ? $args->{'column'}->name : $name;

  my $undef_overrides_default = $args->{'undef_overrides_default'} || 0;

  my $values = $args->{'values'} || $args->{'check_in'};

  unless(ref $values && @$values)
  {
    Carp::croak "Missing list of valid values for enum column '$name'";
  }

  my %values = map { $_ => 1 } @$values;

  my $default = $args->{'default'};

  # Good-old MySQL and its empty-string defaults for NOT NULL columns...
  no warnings 'uninitialized';
  delete $args->{'default'}  if($default eq '' && !$values{$default});

  if(exists $args->{'default'})
  {
    unless(exists $values{$default})
    {
      Carp::croak "Illegal default value for enum column '$name' - '$default'";
    }
  }

  my $mod_columns_key = ($args->{'column'} ? $args->{'column'}->nonpersistent : 0) ? 
    MODIFIED_NP_COLUMNS : MODIFIED_COLUMNS;

  my %methods;

  if($interface eq 'get_set')
  {
    if(exists $args->{'default'})
    {
      $methods{$name} = sub
      {
        my($self) = shift;

        if(@_)
        {
          Carp::croak "Invalid $name: '$_[0]'"  unless(!defined $_[0] || exists $values{$_[0]});
          $self->{MODIFIED_COLUMNS()}{$column_name} = 1  unless($self->{STATE_LOADING()});
          return $self->{$key} = $_[0];
        }

        if(defined $self->{$key} || ($undef_overrides_default && ($self->{MODIFIED_COLUMNS()}{$column_name} || 
           ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
        {
          return $self->{$key};
        }      
        else
        {
          $self->{$mod_columns_key}{$column_name} = 1;
          return $self->{$key} = $default;
        }
      };
    }
    elsif(exists $args->{'with_init'} || exists $args->{'init_method'})
    {
      my $init_method = $args->{'init_method'} || "init_$name";

      $methods{$name} = sub
      {
        my($self) = shift;

        if(@_)
        {
          Carp::croak "Invalid $name: '$_[0]'"  unless(!defined $_[0] || exists $values{$_[0]});
          $self->{$mod_columns_key}{$column_name} = 1;
          return $self->{$key} = $_[0];
        }

        if(defined $self->{$key} || ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
           ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
        {
          return $self->{$key};
        }      
        else
        {
          $self->{$mod_columns_key}{$column_name} = 1;
          return $self->{$key} = $self->$init_method();
        }
      };
    }
    else
    {
      $methods{$name} = sub
      {
        my($self) = shift;

        if(@_)
        {
          Carp::croak "Invalid $name: '$_[0]'"  unless(!defined $_[0] || exists $values{$_[0]});
          $self->{$mod_columns_key}{$column_name} = 1  unless($self->{STATE_LOADING()});
          return $self->{$key} = $_[0];
        }

        return $self->{$key};
      };
    }
  }
  elsif($interface eq 'set')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      Carp::croak "Missing argument in call to $name"  unless(@_);
      Carp::croak "Invalid $name: '$_[0]'"  unless(!defined $_[0] || exists $values{$_[0]});
      $self->{$mod_columns_key}{$column_name} = 1   unless($self->{STATE_LOADING()});
      return $self->{$key} = $_[0];
    };
  }
  elsif($interface eq 'get')
  {
    if(exists $args->{'default'})
    {
      $methods{$name} = sub
      {
        my($self) = shift;

        if(defined $self->{$key} || ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
           ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
        {
          return $self->{$key};
        }      
        else
        {
          $self->{$mod_columns_key}{$column_name} = 1;
          return $self->{$key} = $default;
        }
      };
    }
    elsif(exists $args->{'with_init'} || exists $args->{'init_method'})
    {
      my $init_method = $args->{'init_method'} || "init_$name";

      $methods{$name} = sub
      {
        my($self) = shift;
        return (defined $self->{$key}) ? $self->{$key} : 
                 (scalar($self->{$mod_columns_key}{$column_name} = 1,
                         $self->{$key} = $self->$init_method()));
      };
    }
    else
    {
      $methods{$name} = sub { shift->{$key} };
    }
  }
  else { Carp::croak "Unknown interface: $interface" }

  if($Debug > 1)
  {
    require Data::Dumper;
    warn Data::Dumper::Dumper(\%methods);
  }

  return \%methods;
}

sub character 
{
  my($class, $name, $args) = @_;
  $args->{'_method_type'} = 'character';
  $class->scalar($name, $args);
}

sub varchar 
{
  my($class, $name, $args) = @_;
  $args->{'_method_type'} = 'varchar';
  $class->scalar($name, $args);
}

sub integer 
{
  my($class, $name, $args) = @_;
  $args->{'_method_type'} = 'integer';
  $class->scalar($name, $args);
}

sub boolean
{
  my($class, $name, $args) = @_;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';

  my $column_name = $args->{'column'} ? $args->{'column'}->name : $name;

  my $formatted_key = column_value_formatted_key($key);

  my $undef_overrides_default = $args->{'undef_overrides_default'} || 0;

  my $mod_columns_key = ($args->{'column'} ? $args->{'column'}->nonpersistent : 0) ? 
    MODIFIED_NP_COLUMNS : MODIFIED_COLUMNS;

  my %methods;

  if($interface eq 'get_set')
  {
    my $default = $args->{'default'};

    if(defined $default)
    {
      $default = ($default =~ /^(?:0(?:\.0*)?|f(?:alse)?|no?)$/) ? 0 : $default ? 1 : 0;

      $methods{$name} = sub
      {
        my $self = shift;

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        if(@_)
        {
          no warnings 'uninitialized';
          my $value = $_[0];

          if($self->{STATE_LOADING()})
          {
            $self->{$key} = undef;
            return $self->{$formatted_key,$driver} = $value;
          }
          else
          {
            if($value =~ /^(?:1(?:\.0*)?|t(?:rue)?|y(?:es)?)$/i)
            {
              $self->{$formatted_key,$driver} = undef;
              $self->{$mod_columns_key}{$column_name} = 1;
              return $self->{$key} = 1;
            }
            elsif($value =~ /^(?:0(?:\.0*)?|f(?:alse)?|no?)$/i)
            {
              $self->{$formatted_key,$driver} = undef;
              $self->{$mod_columns_key}{$column_name} = 1;
              return $self->{$key} = 0;
            }
            elsif($value)
            {
              my $value = $db->parse_boolean($value);
              Carp::croak($db->error)  unless(defined $value);
              $self->{$formatted_key,$driver} = undef;
              $self->{$mod_columns_key}{$column_name} = 1;
              return $self->{$key} = $value;
            }
            else
            {
              $self->{$formatted_key,$driver} = undef;
              $self->{$mod_columns_key}{$column_name} = 1;
              return $self->{$key} = defined($value) ? 0 : undef;
            }
          }
        }

        # Pull default through if necessary
        unless(defined $self->{$key} || defined $self->{$formatted_key,$driver} ||
               ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
                ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
        {
          $self->{$mod_columns_key}{$column_name} = 1;
          $self->{$key} = $default;
        }

        if($self->{STATE_SAVING()})
        {
          $self->{$formatted_key,$driver} = $db->format_boolean($self->{$key})
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        if(!defined $self->{$key} && defined $self->{$formatted_key,$driver})
        {
          return $self->{$key} = $db->parse_boolean($self->{$formatted_key,$driver});
        }

        if(defined $self->{$key} || ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
           ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
        {
          return $self->{$key};
        }      
        else
        {
          return $self->{$key} = $default;
        }
      }
    }
    else
    {
      $methods{$name} = sub
      {
        my $self = shift;

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        if(@_)
        {
          no warnings 'uninitialized';
          my $value = $_[0];

          if($self->{STATE_LOADING()})
          {
            $self->{$key} = undef;
            return $self->{$formatted_key,$driver} = $value;
          }
          else
          {
            if($value =~ /^(?:1(?:\.0*)?|t(?:rue)?|y(?:es)?)$/i)
            {
              $self->{$formatted_key,$driver} = undef;
              $self->{$mod_columns_key}{$column_name} = 1;
              return $self->{$key} = 1;
            }
            elsif($value =~ /^(?:0(?:\.0*)?|f(?:alse)?|no?)$/i)
            {
              $self->{$formatted_key,$driver} = undef;
              $self->{$mod_columns_key}{$column_name} = 1;
              return $self->{$key} = 0;
            }
            elsif($value)
            {
              my $value = $db->parse_boolean($value);
              Carp::croak($db->error)  unless(defined $value);
              $self->{$formatted_key,$driver} = undef;
              $self->{$mod_columns_key}{$column_name} = 1;
              return $self->{$key} = $value;
            }
            else
            {
              $self->{$formatted_key,$driver} = undef;
              $self->{$mod_columns_key}{$column_name} = 1;
              return $self->{$key} = defined($value) ? 0 : undef;
            }
          }

          $self->{$formatted_key,$driver} = undef;
          $self->{$mod_columns_key}{$column_name} = 1;
          return $self->{$key} = defined $_[0] ? 0 : undef;
        }

        if($self->{STATE_SAVING()})
        {
          $self->{$formatted_key,$driver} = $db->format_boolean($self->{$key})
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        if(!defined $self->{$key} && defined $self->{$formatted_key,$driver})
        {
          return $self->{$key} = $db->parse_boolean($self->{$formatted_key,$driver});
        }

        return $self->{$key};
      }
    }
  }
  elsif($interface eq 'get')
  {
    my $default = $args->{'default'};

    if(defined $default)
    {
      $default = ($default =~ /^(?:0(?:\.0*)?|f(?:alse)?|no?)$/) ? 0 : $default ? 1 : 0;

      $methods{$name} = sub
      {
        my $self = shift;

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        # Pull default through if necessary
        unless(defined $self->{$key} || defined $self->{$formatted_key,$driver} ||
               ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
                ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
        {
          $self->{$mod_columns_key}{$column_name} = 1;
          $self->{$key} = $default;
        }

        if($self->{STATE_SAVING()})
        {
          $self->{$formatted_key,$driver} = $db->format_boolean($self->{$key})
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        if(!defined $self->{$key} && defined $self->{$formatted_key,$driver})
        {
          return $self->{$key} = $db->parse_boolean($self->{$formatted_key,$driver});
        }

        if(defined $self->{$key} || ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
           ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
        {
          return $self->{$key};
        }      
        else
        {
          return $self->{$key} = $default;
        }
      }
    }
    else
    {
      $methods{$name} = sub
      {
        my $self = shift;

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        if($self->{STATE_SAVING()})
        {
          $self->{$formatted_key,$driver} = $db->format_boolean($self->{$key})
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        if(!defined $self->{$key} && defined $self->{$formatted_key,$driver})
        {
          return $self->{$key} = $db->parse_boolean($self->{$formatted_key,$driver});
        }

        return $self->{$key};
      }
    }
  }
  elsif($interface eq 'set')
  {
    $methods{$name} = sub
    {
      my $self = shift;

      Carp::croak "Missing argument in call to $name"  unless(@_);
      my $db = $self->db or die "Missing Rose::DB object attribute";
      my $driver = $db->driver || 'unknown';

      my $value = shift;

      if($self->{STATE_LOADING()})
      {
        $self->{$key} = undef;
        return $self->{$formatted_key,$driver} = $value;
      }
      else
      {
        if($value =~ /^(?:1(?:\.0*)?|t(?:rue)?|y(?:es)?)$/i)
        {
          $self->{$formatted_key,$driver} = undef;
          $self->{$mod_columns_key}{$column_name} = 1;
          return $self->{$key} = 1;
        }
        elsif($value =~ /^(?:0(?:\.0*)?|f(?:alse)?|no?)$/i)
        {
          $self->{$formatted_key,$driver} = undef;
          $self->{$mod_columns_key}{$column_name} = 1;
          return $self->{$key} = 0;
        }
        elsif($value)
        {
          my $value = $db->parse_boolean($value);
          Carp::croak($db->error)  unless(defined $value);
          $self->{$formatted_key,$driver} = undef;
          $self->{$mod_columns_key}{$column_name} = 1;
          return $self->{$key} = $value;
        }
        else
        {
          $self->{$formatted_key,$driver} = undef;
          $self->{$mod_columns_key}{$column_name} = 1;
          return $self->{$key} = defined($value) ? 0 : undef;
        }
      }
    }
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

sub bitfield
{
  my($class, $name, $args) = @_;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';

  my $column_name = $args->{'column'} ? $args->{'column'}->name : $name;

  my $undef_overrides_default = $args->{'undef_overrides_default'} || 0;

  my $mod_columns_key = ($args->{'column'} ? $args->{'column'}->nonpersistent : 0) ? 
    MODIFIED_NP_COLUMNS : MODIFIED_COLUMNS;

  my %methods;

  if($interface eq 'get_set')
  {
    my $size = $args->{'bits'} ||= 32;

    my $default = $args->{'default'};
    my $formatted_key = column_value_formatted_key($key);

    if(defined $default)
    {
      $methods{$name} = sub
      {
        my $self = shift;

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        if(@_)
        {
          if($self->{STATE_LOADING()})
          {
            $self->{$key} = undef;
            $self->{$formatted_key,$driver} = $_[0];
          }
          else
          {
            $self->{$key} = $db->parse_bitfield($_[0], $size);

            if(!defined $_[0] || defined $self->{$key})
            {
              $self->{$formatted_key,$driver} = undef;
              $self->{$mod_columns_key}{$column_name} = 1;
            }
            else
            {
              Carp::croak $self->error($db->error);
            }
          }
        }

        return unless(defined wantarray);

        # Pull default through if necessary
        unless(defined $self->{$key} || defined $self->{$formatted_key,$driver} ||
               ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
                ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
        {
          $self->{$key} = $db->parse_bitfield($default, $size);

          if(!defined $default || defined $self->{$key})
          {
            $self->{$mod_columns_key}{$column_name} = 1;
          }
          else
          {
            Carp::croak $self->error($db->error);
          }
        }

        if($self->{STATE_SAVING()})
        {
          $self->{$formatted_key,$driver} = $db->format_bitfield($self->{$key}, $size)
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        if(defined $self->{$key})
        {
          $self->{$formatted_key,$driver} = undef;
          return $self->{$key};
        }

        if(defined $self->{$formatted_key,$driver})
        {
          $self->{$key} = $db->parse_bitfield($self->{$formatted_key,$driver}, $size, 1);
          $self->{$formatted_key,$driver} = undef;
          return $self->{$key};
        }

        return undef;
      };
    }
    else
    {
      $methods{$name} = sub
      {
        my $self = shift;

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        if(@_)
        {
          if($self->{STATE_LOADING()})
          {
            $self->{$key} = undef;
            $self->{$formatted_key,$driver} = $_[0];
          }
          else
          {
            $self->{$key} = $db->parse_bitfield($_[0], $size);

            if(!defined $_[0] || defined $self->{$key})
            {
              $self->{$formatted_key,$driver} = undef;
              $self->{$mod_columns_key}{$column_name} = 1;
            }
            else
            {
              Carp::croak $self->error($db->error);
            }
          }
        }

        if($self->{STATE_SAVING()})
        {
          return undef  unless(defined($self->{$formatted_key,$driver}) || defined($self->{$key}));

          $self->{$formatted_key,$driver} = $db->format_bitfield($self->{$key}, $size)
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        return unless(defined wantarray);

        if(defined $self->{$key})
        {
          $self->{$formatted_key,$driver} = undef;
          return $self->{$key};
        }

        if(defined $self->{$formatted_key,$driver})
        {
          $self->{$key} = $db->parse_bitfield($self->{$formatted_key,$driver}, $size, 1);
          $self->{$formatted_key,$driver} = undef;
          return $self->{$key};
        }

        return undef;
      };

      if($args->{'with_intersects'})
      {
        my $method = $args->{'intersects'} || $name . '_intersects';

        $methods{$method} = sub 
        {
          my($self, $vec) = @_;

          my $val = $self->{$key} or return undef;

          unless(ref $vec)
          {
            my $db = $self->db or die "Missing Rose::DB object attribute";
            $vec = $db->parse_bitfield($vec, $size);
            Carp::croak $self->error($db->error)  unless(defined $vec);
          }

          $vec = Bit::Vector->new_Bin($size, $vec->to_Bin)  if($vec->Size != $size);

          my $test = Bit::Vector->new($size);
          $test->Intersection($val, $vec);
          return ($test->to_Bin > 0) ? 1 : 0;
        };
      }
    }
  }
  elsif($interface eq 'get')
  {
    my $size = $args->{'bits'} ||= 32;

    my $default = $args->{'default'};
    my $formatted_key = column_value_formatted_key($key);

    if(defined $default)
    {
      $methods{$name} = sub
      {
        my $self = shift;

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        unless(defined $self->{$key} || defined $self->{$formatted_key,$driver} || 
               ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
                ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
        {
          $self->{$key} = $db->parse_bitfield($default, $size);

          if(!defined $default || defined $self->{$key})
          {
            $self->{$mod_columns_key}{$column_name} = 1;
          }
          else
          {
            Carp::croak $self->error($db->error);
          }
        }

        if($self->{STATE_SAVING()})
        {
          $self->{$formatted_key,$driver} = $db->format_bitfield($self->{$key}, $size)
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        return unless(defined wantarray);

        if(defined $self->{$key})
        {
          $self->{$formatted_key,$driver} = undef;
          return $self->{$key};
        }

        if(defined $self->{$formatted_key,$driver})
        {
          $self->{$key} = $db->parse_bitfield($self->{$formatted_key,$driver}, $size, 1);
          $self->{$formatted_key,$driver} = undef;
          return $self->{$key};
        }

        return undef;
      };
    }
    else
    {
      $methods{$name} = sub
      {
        my $self = shift;

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        if($self->{STATE_SAVING()})
        {
          return undef  unless(defined($self->{$formatted_key,$driver}) || defined($self->{$key}));

          $self->{$formatted_key,$driver} = $db->format_bitfield($self->{$key}, $size)
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        return unless(defined wantarray);

        if(defined $self->{$key})
        {
          $self->{$formatted_key,$driver} = undef;
          return $self->{$key};
        }

        if(defined $self->{$formatted_key,$driver})
        {
          $self->{$key} = $db->parse_bitfield($self->{$formatted_key,$driver}, $size, 1);
          $self->{$formatted_key,$driver} = undef;
          return $self->{$key};
        }

        return undef;
      };
    }
  }
  elsif($interface eq 'set')
  {
    my $size = $args->{'bits'} ||= 32;

    my $formatted_key = column_value_formatted_key($key);

    $methods{$name} = sub
    {
      my $self = shift;

      my $db = $self->db or die "Missing Rose::DB object attribute";
      my $driver = $db->driver || 'unknown';

      Carp::croak "Missing argument in call to $name"  unless(@_);

      if($self->{STATE_LOADING()})
      {
        $self->{$key} = undef;
        $self->{$formatted_key,$driver} = $_[0];
      }
      else
      {
        $self->{$key} = $db->parse_bitfield($_[0], $size);

        if(!defined $_[0] || defined $self->{$key})
        {
          $self->{$formatted_key,$driver} = undef;
          $self->{$mod_columns_key}{$column_name} = 1;
        }
        else
        {
          Carp::croak $self->error($db->error);
        }
      }

      if($self->{STATE_SAVING()})
      {
        return undef  unless(defined($self->{$formatted_key,$driver}) || defined($self->{$key}));

        $self->{$formatted_key,$driver} = $db->format_bitfield($self->{$key}, $size)
          unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

        return $self->{$formatted_key,$driver};
      }

      if(defined $self->{$key})
      {
        $self->{$formatted_key,$driver} = undef;
        return $self->{$key};
      }

      if(defined $self->{$formatted_key,$driver})
      {
        $self->{$key} = $db->parse_bitfield($self->{$formatted_key,$driver}, $size, 1);
        $self->{$formatted_key,$driver} = undef;
        return $self->{$key};
      }

      return undef;
    };
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

sub array
{
  my($class, $name, $args) = @_;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';

  my $column_name = $args->{'column'} ? $args->{'column'}->name : $name;

  my $formatted_key = column_value_formatted_key($key);

  my $undef_overrides_default = $args->{'undef_overrides_default'} || 0;

  my $mod_columns_key = ($args->{'column'} ? $args->{'column'}->nonpersistent : 0) ? 
    MODIFIED_NP_COLUMNS : MODIFIED_COLUMNS;

  my %methods;

  if($interface eq 'get_set')
  {
    my $default = $args->{'default'};

    if(defined $default)
    {
      $methods{$name} = sub
      {
        my $self = shift;

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        if(@_)
        {
          if($self->{STATE_LOADING()})
          {
            if(ref $_[0] eq 'ARRAY')
            {
              $self->{$key} = $_[0];
              $self->{$formatted_key,$driver} = undef;
            }
            else
            {
              $self->{$key} = undef;
              $self->{$formatted_key,$driver} = $_[0];
            }
          }
          else
          {
            $self->{$key} = $db->parse_array(@_);

            if(!defined $_[0] || defined $self->{$key})
            {
              $self->{$formatted_key,$driver} = undef;
              $self->{$mod_columns_key}{$column_name} = 1;
            }
            else
            {
              Carp::croak $self->error($db->error);
            }
          }
        }
        elsif(!defined $self->{$key})
        {
          unless(!defined $self->{$formatted_key,$driver} && 
                 $undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
                 ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name}))))
          {
            $self->{$key} = $db->parse_array(defined $self->{$formatted_key,$driver} ? 
                                             $self->{$formatted_key,$driver} : $default);

            if(!defined $default || defined $self->{$key})
            {
              $self->{$formatted_key,$driver} = undef;
              $self->{$mod_columns_key}{$column_name} = 1;
            }
            else
            {
              Carp::croak $self->error($db->error);
            }
          }
        }

        return unless(defined wantarray);

        # Pull default through if necessary
        unless(defined $self->{$key} || defined $self->{$formatted_key,$driver} || 
               ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
                ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
        {
          $self->{$key} = $db->parse_array($default);

          if(!defined $default || defined $self->{$key})
          {
            $self->{$formatted_key,$driver} = undef;
            $self->{$mod_columns_key}{$column_name} = 1;
          }
          else
          {
            Carp::croak $self->error($db->error);
          }
        }

        if($self->{STATE_SAVING()})
        {
          $self->{$formatted_key,$driver} = $db->format_array($self->{$key})
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        return defined $self->{$key} ? wantarray ? @{$self->{$key}} : $self->{$key} : undef;        
      }
    }
    else
    {
      $methods{$name} = sub
      {
        my $self = shift;

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        if(@_)
        {
          if($self->{STATE_LOADING()})
          {
            if(ref $_[0] eq 'ARRAY')
            {
              $self->{$key} = $_[0];
              $self->{$formatted_key,$driver} = undef;
            }
            else
            {
              $self->{$key} = undef;
              $self->{$formatted_key,$driver} = $_[0];
            }
          }
          else
          {
            $self->{$key} = $db->parse_array(@_);

            if(!defined $_[0] || defined $self->{$key})
            {
              $self->{$formatted_key,$driver} = undef;
              $self->{$mod_columns_key}{$column_name} = 1;
            }
            else
            {
              Carp::croak $self->error($db->error);
            }
          }
        }

        if($self->{STATE_SAVING()})
        {
          return undef  unless(defined($self->{$formatted_key,$driver}) || defined($self->{$key}));

          $self->{$formatted_key,$driver} = $db->format_array($self->{$key})
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        return unless(defined wantarray);

        if(defined $self->{$key})
        {
          $self->{$formatted_key,$driver} = undef;
          return wantarray ? @{$self->{$key}} : $self->{$key};
        }

        if(defined $self->{$formatted_key,$driver})
        {
          $self->{$key} = $db->parse_array($self->{$formatted_key,$driver});
          $self->{$formatted_key,$driver} = undef;

          return defined $self->{$key} ? wantarray ? @{$self->{$key}} : $self->{$key} : undef;
        }

        return undef;
      }
    }
  }
  elsif($interface eq 'get')
  {
    my $default = $args->{'default'};

    if(defined $default)
    {
      $methods{$name} = sub
      {
        my $self = shift;

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        if(!defined $self->{$key} && (!$self->{STATE_SAVING()} || !defined $self->{$formatted_key,$driver}))
        {
          unless(!defined $default || ($undef_overrides_default && 
                 ($self->{$mod_columns_key}{$column_name} || ($self->{STATE_IN_DB()} && 
                 !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
          {
            $self->{$key} = $db->parse_array($default);

            if(!defined $default || defined $self->{$key})
            {
              $self->{$formatted_key,$driver} = undef;
              $self->{$mod_columns_key}{$column_name} = 1;
            }
            else
            {
              Carp::croak $self->error($db->error);
            }
          }
        }

        if($self->{STATE_SAVING()})
        {
          $self->{$formatted_key,$driver} = $db->format_array($self->{$key})
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        return unless(defined wantarray);

        if(defined $self->{$key})
        {
          $self->{$formatted_key,$driver} = undef;
          return wantarray ? @{$self->{$key}} : $self->{$key};
        }

        if(defined $self->{$formatted_key,$driver})
        {
          $self->{$key} = $db->parse_array($self->{$formatted_key,$driver});
          $self->{$formatted_key,$driver} = undef;

          return defined $self->{$key} ? wantarray ? @{$self->{$key}} : $self->{$key} : undef;
        }

        return undef;
      }
    }
    else
    {
      $methods{$name} = sub
      {
        my $self = shift;

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        if($self->{STATE_SAVING()})
        {
          return undef  unless(defined($self->{$formatted_key,$driver}) || defined($self->{$key}));

          $self->{$formatted_key,$driver} = $db->format_array($self->{$key})
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        return unless(defined wantarray);

        if(defined $self->{$key})
        {
          $self->{$formatted_key,$driver} = undef;
          return wantarray ? @{$self->{$key}} : $self->{$key};
        }

        if(defined $self->{$formatted_key,$driver})
        {
          $self->{$key} = $db->parse_array($self->{$formatted_key,$driver});
          $self->{$formatted_key,$driver} = undef;

          return defined $self->{$key} ? wantarray ? @{$self->{$key}} : $self->{$key} : undef;
        }

        return undef;
      }
    }
  }
  elsif($interface eq 'set')
  {
    $methods{$name} = sub
    {
      my $self = shift;

      my $db = $self->db or die "Missing Rose::DB object attribute";
      my $driver = $db->driver || 'unknown';

      Carp::croak "Missing argument in call to $name"  unless(@_);

      if($self->{STATE_LOADING()})
      {
        if(ref $_[0] eq 'ARRAY')
        {
          $self->{$key} = $_[0];
          $self->{$formatted_key,$driver} = undef;
        }
        else
        {
          $self->{$key} = undef;
          $self->{$formatted_key,$driver} = $_[0];
        }
      }
      else
      {
        $self->{$key} = $db->parse_array($_[0]);

        if(!defined $_[0] || defined $self->{$key})
        {
          $self->{$formatted_key,$driver} = undef;
          $self->{$mod_columns_key}{$column_name} = 1;
        }
        else
        {
          Carp::croak $self->error($db->error);
        }
      }

      if($self->{STATE_SAVING()})
      {
        return undef  unless(defined($self->{$formatted_key,$driver}) || defined($self->{$key}));

        $self->{$formatted_key,$driver} = $db->format_array($self->{$key})
          unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

        return $self->{$formatted_key,$driver};
      }

      if(defined $self->{$key})
      {
        $self->{$formatted_key,$driver} = undef;
        return wantarray ? @{$self->{$key}} : $self->{$key};
      }

      if(defined $self->{$formatted_key,$driver})
      {
        $self->{$key} = $db->parse_array($self->{$formatted_key,$driver});
        $self->{$formatted_key,$driver} = undef;

        return defined $self->{$key} ? wantarray ? @{$self->{$key}} : $self->{$key} : undef;
      }

      return undef;
    }
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

sub set
{
  my($class, $name, $args) = @_;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';

  my $column_name = $args->{'column'} ? $args->{'column'}->name : $name;
  my $choices = $args->{'choices'} || $args->{'check_in'};
  my %choices = $choices ? (map { $_ => 1 } @$choices) : ();

  my $formatted_key = column_value_formatted_key($key);

  my $value_type = $args->{'value_type'} || 'scalar';

  my $undef_overrides_default = $args->{'undef_overrides_default'} || 0;

  my $mod_columns_key = ($args->{'column'} ? $args->{'column'}->nonpersistent : 0) ? 
    MODIFIED_NP_COLUMNS : MODIFIED_COLUMNS;

  my %methods;

  if($interface eq 'get_set')
  {
    my $default = $args->{'default'};

    if(defined $default)
    {
      $methods{$name} = sub
      {
        my $self = shift;

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        if(@_)
        {
          if($self->{STATE_LOADING()})
          {
            $self->{$key} = undef;
            $self->{$formatted_key,$driver} = $_[0];
          }
          else
          {
            my $set = $db->parse_set(@_, { value_type => $value_type });

            if($choices)
            {
              foreach my $val (@$set)
              {
                Carp::croak "Invalid value for set $key - '$val'"
                  unless(exists $choices{$val});
              }
            }

            $self->{$key} = $set;

            if(!defined $_[0] || defined $self->{$key})
            {
              $self->{$formatted_key,$driver} = undef;
              $self->{$mod_columns_key}{$column_name} = 1;
            }
            else
            {
              Carp::croak $self->error($db->error);
            }            
          }
        }
        elsif(!defined $self->{$key})
        {
          unless(!defined $self->{$formatted_key,$driver} && 
                 $undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
                 ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name}))))
          {
            my $set = $db->parse_set((defined $self->{$formatted_key,$driver} ? 
                                      $self->{$formatted_key,$driver} : $default),
                                     { value_type => $value_type });

            if($choices)
            {
              foreach my $val (@$set)
              {
                Carp::croak "Invalid default value for set $key - '$val'"
                  unless(exists $choices{$val});
              }
            }

            $self->{$key} = $set;

            if(!defined $default || defined $self->{$key})
            {
              $self->{$formatted_key,$driver} = undef;
            }
            else
            {
              Carp::croak $self->error($db->error);
            }
          }
        }

        return unless(defined wantarray);

        # Pull default through if necessary
        unless(defined $self->{$key} || defined $self->{$formatted_key,$driver} || 
               ($undef_overrides_default && ($self->{$mod_columns_key}{$column_name} || 
                ($self->{STATE_IN_DB()} && !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
        {
          $self->{$key} = $db->parse_set($default, { value_type => $value_type });

          if(!defined $default || defined $self->{$key})
          {
            $self->{$formatted_key,$driver} = undef;
            $self->{$mod_columns_key}{$column_name} = 1;
          }
          else
          {
            Carp::croak $self->error($db->error);
          }
        }

        if($self->{STATE_SAVING()})
        {
          $self->{$formatted_key,$driver} = $db->format_set($self->{$key})
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        return defined $self->{$key} ? wantarray ? @{$self->{$key}} : $self->{$key} : undef;        
      }
    }
    else
    {
      $methods{$name} = sub
      {
        my $self = shift;

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        if(@_)
        {
          if($self->{STATE_LOADING()})
          {
            $self->{$key} = undef;
            $self->{$formatted_key,$driver} = $_[0];
          }
          else
          {
            my $set = $db->parse_set(@_, { value_type => $value_type });

            if($choices)
            {
              foreach my $val (@$set)
              {
                Carp::croak "Invalid value for set $key - '$val'"
                  unless(exists $choices{$val});
              }
            }

            $self->{$key} = $set;

            if(!defined $_[0] || defined $self->{$key})
            {
              $self->{$formatted_key,$driver} = undef;
              $self->{$mod_columns_key}{$column_name} = 1;
            }
            else
            {
              Carp::croak $self->error($db->error);
            }
          }
        }

        if($self->{STATE_SAVING()})
        {
          return undef  unless(defined($self->{$formatted_key,$driver}) || defined($self->{$key}));

          $self->{$formatted_key,$driver} = $db->format_set($self->{$key})
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        return unless(defined wantarray);

        if(defined $self->{$key})
        {
          $self->{$formatted_key,$driver} = undef;
          return wantarray ? @{$self->{$key}} : $self->{$key};
        }

        if(defined $self->{$formatted_key,$driver})
        {
          $self->{$key} = $db->parse_set($self->{$formatted_key,$driver}, { value_type => $value_type });
          $self->{$formatted_key,$driver} = undef;

          return defined $self->{$key} ? wantarray ? @{$self->{$key}} : $self->{$key} : undef;
        }

        return undef;
      }
    }
  }
  elsif($interface eq 'get')
  {
    my $default = $args->{'default'};

    if(defined $default)
    {
      $methods{$name} = sub
      {
        my $self = shift;

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        if(!defined $self->{$key} && (!$self->{STATE_SAVING()} || !defined $self->{$formatted_key,$driver}))
        {
          unless(!defined $default || ($undef_overrides_default && 
                 ($self->{$mod_columns_key}{$column_name} || ($self->{STATE_IN_DB()} && 
                 !($self->{SET_COLUMNS()}{$column_name} || $self->{$mod_columns_key}{$column_name})))))
          {
            my $set = $db->parse_set($default, { value_type => $value_type });

            if($choices)
            {
              foreach my $val (@$set)
              {
                Carp::croak "Invalid default value for set $key - '$val'"
                  unless(exists $choices{$val});
              }
            }

            $self->{$key} = $set;

            if(!defined $default || defined $self->{$key})
            {
              $self->{$formatted_key,$driver} = undef;
              $self->{$mod_columns_key}{$column_name} = 1;
            }
            else
            {
              Carp::croak $self->error($db->error);
            }
          }
        }

        if($self->{STATE_SAVING()})
        {
          $self->{$formatted_key,$driver} = $db->format_set($self->{$key})
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        return unless(defined wantarray);

        if(defined $self->{$key})
        {
          $self->{$formatted_key,$driver} = undef;
          return wantarray ? @{$self->{$key}} : $self->{$key};
        }

        if(defined $self->{$formatted_key,$driver})
        {
          $self->{$key} = $db->parse_set($self->{$formatted_key,$driver}, { value_type => $value_type });
          $self->{$formatted_key,$driver} = undef;

          return defined $self->{$key} ? wantarray ? @{$self->{$key}} : $self->{$key} : undef;
        }

        return undef;
      }
    }
    else
    {
      $methods{$name} = sub
      {
        my $self = shift;

        my $db = $self->db or die "Missing Rose::DB object attribute";
        my $driver = $db->driver || 'unknown';

        if($self->{STATE_SAVING()})
        {
          return undef  unless(defined($self->{$formatted_key,$driver}) || defined($self->{$key}));

          $self->{$formatted_key,$driver} = $db->format_set($self->{$key})
            unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

          return $self->{$formatted_key,$driver};
        }

        return unless(defined wantarray);

        if(defined $self->{$key})
        {
          $self->{$formatted_key,$driver} = undef;
          return wantarray ? @{$self->{$key}} : $self->{$key};
        }

        if(defined $self->{$formatted_key,$driver})
        {
          $self->{$key} = $db->parse_set($self->{$formatted_key,$driver}, { value_type => $value_type });
          $self->{$formatted_key,$driver} = undef;

          return defined $self->{$key} ? wantarray ? @{$self->{$key}} : $self->{$key} : undef;
        }

        return undef;
      }
    }
  }
  elsif($interface eq 'set')
  {
    $methods{$name} = sub
    {
      my $self = shift;

      my $db = $self->db or die "Missing Rose::DB object attribute";
      my $driver = $db->driver || 'unknown';

      Carp::croak "Missing argument in call to $name"  unless(@_);

      if($self->{STATE_LOADING()})
      {
        $self->{$key} = undef;
        $self->{$formatted_key,$driver} = $_[0];
      }
      else
      {
        my $set = $db->parse_set(@_, { value_type => $value_type });

        if($choices)
        {
          foreach my $val (@$set)
          {
            Carp::croak "Invalid value for set $key - '$val'"
              unless(exists $choices{$val});
          }
        }

        $self->{$key} = $set;

        if(!defined $_[0] || defined $self->{$key})
        {
          $self->{$formatted_key,$driver} = undef;
          $self->{$mod_columns_key}{$column_name} = 1;
        }
        else
        {
          Carp::croak $self->error($db->error);
        }
      }

      if($self->{STATE_SAVING()})
      {
        return undef  unless(defined($self->{$formatted_key,$driver}) || defined($self->{$key}));

        $self->{$formatted_key,$driver} = $db->format_set($self->{$key})
          unless(defined $self->{$formatted_key,$driver} || !defined $self->{$key});

        return $self->{$formatted_key,$driver};
      }

      if(defined $self->{$key})
      {
        $self->{$formatted_key,$driver} = undef;
        return wantarray ? @{$self->{$key}} : $self->{$key};
      }

      if(defined $self->{$formatted_key,$driver})
      {
        $self->{$key} = $db->parse_set($self->{$formatted_key,$driver}, { value_type => $value_type });
        $self->{$formatted_key,$driver} = undef;

        return defined $self->{$key} ? wantarray ? @{$self->{$key}} : $self->{$key} : undef;
      }

      return undef;
    }
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

sub object_by_key
{
  my($class, $name, $args, $options) = @_;

  # Delegate to plural with coercion to single as indicated by args
  if($args->{'manager_class'} || $args->{'manager_method'} ||
     $args->{'manager_args'} || $args->{'query_args'} ||
     $args->{'join_args'})
  {
    $args->{'single'} = 1;
    return $class->objects_by_key($name, $args, $options);
  }

  my %methods;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';
  my $target_class = $options->{'target_class'} or die "Missing target class";
  #my $query_args = $args->{'query_args'} || [];

  weaken(my $fk       = $args->{'foreign_key'} || $args->{'relationship'});
  my $fk_class = $args->{'class'} or die "Missing foreign object class";
  weaken(my $fk_meta  = $fk_class->meta);
  weaken(my $meta     = $target_class->meta);
  my $fk_pk;

  my $required = 
    exists $args->{'required'} ? $args->{'required'} :
    exists $args->{'referential_integrity'} ? $args->{'referential_integrity'} : 1;

  my $ref_integrity = 
    ($fk && $fk->isa('Rose::DB::Object::Metadata::ForeignKey')) ? $fk->referential_integrity : 0;

  if(exists $args->{'required'} && exists $args->{'referential_integrity'} &&
    (!$args->{'required'} != !$$args->{'referential_integrity'}))
  {
    Carp::croak "The required and referential_integrity parameters conflict. ",
                "Please pass one or the other, not both.";
  }

  my $fk_columns = $args->{'key_columns'} or die "Missing key columns hash";
  my $share_db   = $args->{'share_db'};

  # Delegate to plural with coercion to single as indicated by column map
  my(%unique, $key_ok);

  foreach my $uk_cols (scalar($fk_meta->primary_key_column_names),
                       $fk_meta->unique_keys_column_names)
  {
    $unique{join($;, sort @$uk_cols)} = 1;
  }

  my @f_columns = sort values %$fk_columns;

  for my $i (0 .. $#f_columns)
  {
    if($unique{join($;, @f_columns[0 .. $i])})
    {
      $key_ok = 1;
      last;
    }
  }

  unless($key_ok)
  {
    $args->{'single'} = 1;
    $args->{'relationship'} ||= $fk;
    return $class->objects_by_key($name, $args, $options);
  }

  if($interface eq 'get_set')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      if(@_)
      {
        # If loading, just assign
        if($self->{STATE_LOADING()})
        {
          return $self->{$key} = $_[0];
        }

        unless(defined $_[0]) # undef argument
        {
          if($ref_integrity || $required)
          {
            local $fk->{'disable_column_triggers'} = 1;

            # Set the foreign key columns
            while(my($local_column, $foreign_column) = each(%$fk_columns))
            {
              next  if($meta->column($local_column)->is_primary_key_member);
              my $local_method = $meta->column_mutator_method_name($local_column);
              $self->$local_method(undef);
            }
          }

          return $self->{$key} = undef;
        }

        my $object = __args_to_object($self, $key, $fk_class, \$fk_pk, \@_);

        local $fk->{'disable_column_triggers'} = 1;

        while(my($local_column, $foreign_column) = each(%$fk_columns))
        {
          my $local_method   = $meta->column_mutator_method_name($local_column);
          my $foreign_method = $fk_meta->column_accessor_method_name($foreign_column);

          $self->$local_method($object->$foreign_method);
        }

        return $self->{$key} = $object;
      }

      return $self->{$key}  if(defined $self->{$key});

      my %key;

      while(my($local_column, $foreign_column) = each(%$fk_columns))
      {
        my $local_method   = $meta->column_accessor_method_name($local_column);
        my $foreign_method = $fk_meta->column_mutator_method_name($foreign_column);

        $key{$foreign_method} = $self->$local_method();

        # XXX: Comment this out to allow null keys
        unless(defined $key{$foreign_method})
        {
          keys(%$fk_columns); # reset iterator
          $self->error("Could not load $name object - the " .
                       "$local_method attribute is undefined");
          return undef;
        }
      }

      my $obj;

      if($share_db)
      {
        $obj = $fk_class->new(%key, db => $self->db);
      }
      else
      {
        $obj = $fk_class->new(%key);
      }

      my $ret;

      if($required)
      {
        my $error;

        TRY:
        {
          local $@;
          eval { $ret = $obj->load };
          $error = $@;
        }

        if($error || !$ret)
        {
          my $msg = $obj->error || $error;

          $self->error(ref $msg ? $msg : 
                       ("Could not load $fk_class object with key " .
                        join(', ', map { "$_ = '$key{$_}'" } sort keys %key) .
                        " - $msg"));
          $self->meta->handle_error($self);
          return $ret;
        }
      }
      else
      {
        return undef  unless($obj->load(speculative => 1));
      }

      return $self->{$key} = $obj;
    };
  }
  elsif($interface eq 'get_set_now')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      if(@_)
      {
        # If loading, just assign
        if($self->{STATE_LOADING()})
        {
          return $self->{$key} = $_[0];
        }

        # Can't add until the object is saved
        unless($self->{STATE_IN_DB()})
        {
          Carp::croak "Can't $name() until this object is loaded or saved";
        }

        unless(defined $_[0]) # undef argument
        {
          if($ref_integrity || $required)
          {
            local $fk->{'disable_column_triggers'} = 1;

            # Set the foreign key columns
            while(my($local_column, $foreign_column) = each(%$fk_columns))
            {
              next  if($meta->column($local_column)->is_primary_key_member);
              my $local_method = $meta->column_mutator_method_name($local_column);
              $self->$local_method(undef);
            }
          }

          return $self->{$key} = undef;
        }

        my $object = __args_to_object($self, $key, $fk_class, \$fk_pk, \@_);

        my($db, $started_new_tx, $error);

        TRY:
        {
          local $@;

          eval
          {
            $db = $self->db;
            $object->db($db);

            my $ret = $db->begin_work;

            unless(defined $ret)
            {
              die 'Could not begin transaction during call to $name() - ',
                  $db->error;
            }

            $started_new_tx = ($ret == IN_TRANSACTION) ? 0 : 1;

            # If the object is not marked as already existing in the database,
            # see if it represents an existing row.  If it does, merge the
            # existing row's column values into the object, allowing any
            # modified columns in the object to take precedence. Returns true
            # if the object represents an existing row.
            if(__check_and_merge($object))
            {
              $object->save(changes_only => 1) or die $object->error;
            }
            else
            {
              $object->save or die $object->error;
            }

            local $fk->{'disable_column_triggers'} = 1;

            while(my($local_column, $foreign_column) = each(%$fk_columns))
            {
              my $local_method   = $meta->column_mutator_method_name($local_column);
              my $foreign_method = $fk_meta->column_accessor_method_name($foreign_column);

              $self->$local_method($object->$foreign_method);
            }

            $self->save(changes_only => 1) or die $self->error;

            $self->{$key} = $object;

            # Not sharing?  Aw.
            $object->db(undef)  unless($share_db);

            if($started_new_tx)
            {
              $db->commit or die $db->error;
            }
          };

          $error = $@;
        }

        if($error)
        {
          $self->error(ref $error ? $error : "Could not add $name object - $error");
          $db->rollback  if($db && $started_new_tx);
          $meta->handle_error($self);
          return undef;
        }

        return $self->{$key};
      }

      return $self->{$key}  if(defined $self->{$key});

      my %key;

      while(my($local_column, $foreign_column) = each(%$fk_columns))
      {
        my $local_method   = $meta->column_accessor_method_name($local_column);
        my $foreign_method = $fk_meta->column_mutator_method_name($foreign_column);

        $key{$foreign_method} = $self->$local_method();

        # XXX: Comment this out to allow null keys
        unless(defined $key{$foreign_method})
        {
          keys(%$fk_columns); # reset iterator
          $self->error("Could not load $name object - the " .
                       "$local_method attribute is undefined");
          return undef;
        }
      }

      my $obj;

      if($share_db)
      {
        $obj = $fk_class->new(%key, db => $self->db);
      }
      else
      {
        $obj = $fk_class->new(%key);
      }

      my $ret;

      if($required)
      {
        my $error;

        TRY:
        {
          local $@;
          eval { $ret = $obj->load };
          $error = $@;
        }

        if($error || !$ret)
        {
          my $msg = $obj->error || $error;

          $self->error(ref $msg ? $msg : 
                       ("Could not load $fk_class with key " .
                        join(', ', map { "$_ = '$key{$_}'" } sort keys %key) .
                        " - $msg"));
          $self->meta->handle_error($self);
          return $ret;
        }
      }
      else
      {
        return undef  unless($obj->load(speculative => 1));
      }

      return $self->{$key} = $obj;
    };
  }
  elsif($interface eq 'get_set_on_save')
  {
    unless($fk)
    {
      Carp::confess "Cannot make 'get_set_on_save' method $name without foreign key argument";
    }

    my $fk_name = $fk->name;
    my $is_fk = $fk->type eq 'foreign key' ? 1 : 0;

    $methods{$name} = sub
    {
      my($self) = shift;

      if(@_)
      {
        # If loading, just assign
        if($self->{STATE_LOADING()})
        {
          return $self->{$key} = $_[0];
        }

        unless(defined $_[0]) # undef argument
        {
          if($ref_integrity || $required)
          {
            local $fk->{'disable_column_triggers'} = 1;

            # Set the foreign key columns
            while(my($local_column, $foreign_column) = each(%$fk_columns))
            {
              next  if($meta->column($local_column)->is_primary_key_member);
              my $local_method = $meta->column_mutator_method_name($local_column);
              $self->$local_method(undef);
            }
          }

          delete $self->{ON_SAVE_ATTR_NAME()}{'pre'}{'fk'}{$fk_name}{'set'};
          delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$fk_name}{'set'};
          return $self->{$key} = undef;
        }

        my $object = __args_to_object($self, $key, $fk_class, \$fk_pk, \@_);

        my $linked_up = 0;

        if($is_fk && (!$fk->requires_preexisting_parent_object || $self->{STATE_IN_DB()}))
        {
          local $fk->{'disable_column_triggers'} = 1;

          # Set the foreign key columns
          while(my($local_column, $foreign_column) = each(%$fk_columns))
          {
            my $local_method   = $meta->column_mutator_method_name($local_column);
            my $foreign_method = $fk_meta->column_accessor_method_name($foreign_column);

            $self->$local_method($object->$foreign_method);
          }

          $linked_up = 1;
        }

        # Set the attribute
        $self->{$key} = $object;

        # Make the code that will run on save()
        my $save_code = sub
        {
          my($self, $args) = @_;

          # Bail if there's nothing to do
          my $object = $self->{$key} or return;

          my $db;

          unless($linked_up)
          {
            while(my($local_column, $foreign_column) = each(%$fk_columns))
            {
              my $local_method   = $meta->column_mutator_method_name($local_column);
              my $foreign_method = $fk_meta->column_accessor_method_name($foreign_column);

              $object->$foreign_method($self->$local_method)
                unless(defined $object->$foreign_method);
            }
          }

          my $error;

          TRY:
          {
            local $@;

            eval
            {
              $db = $self->db;
              $object->db($db);

              # If the object is not marked as already existing in the database,
              # see if it represents an existing row.  If it does, merge the
              # existing row's column values into the object, allowing any
              # modified columns in the object to take precedence. Returns true
              # if the object represents an existing row.
              if(__check_and_merge($object))
              {
                $object->save(%$args, changes_only => 1) or die $object->error;
              }
              else
              {
                $object->save(%$args) or die $object->error;
              }

              local $fk->{'disable_column_triggers'} = 1;

              # Set the foreign key columns
              while(my($local_column, $foreign_column) = each(%$fk_columns))
              {
                my $local_method   = $meta->column_mutator_method_name($local_column);
                my $foreign_method = $fk_meta->column_accessor_method_name($foreign_column);

                $self->$local_method($object->$foreign_method);
              }

              # Not sharing?  Aw.
              $object->db(undef)  unless($share_db);

              return $self->{$key} = $object;
            };

            $error = $@;
          }

          if($error)
          {
            $self->error(ref $error ? $error : "Could not add $name object - $error");
            $meta->handle_error($self);
            return undef;
          }

          return $self->{$key};
        };

        if($linked_up)
        {
          $self->{ON_SAVE_ATTR_NAME()}{'pre'}{'fk'}{$fk_name}{'set'} = $save_code;
        }
        else
        {
          $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$fk_name}{'set'} = $save_code;
        }

        return $self->{$key};
      }

      return $self->{$key}  if(defined $self->{$key});

      my %key;

      while(my($local_column, $foreign_column) = each(%$fk_columns))
      {
        my $local_method   = $meta->column_accessor_method_name($local_column);
        my $foreign_method = $fk_meta->column_mutator_method_name($foreign_column);

        $key{$foreign_method} = $self->$local_method();

        # XXX: Comment this out to allow null keys
        unless(defined $key{$foreign_method})
        {
          keys(%$fk_columns); # reset iterator
          $self->error("Could not load $name object - the " .
                       "$local_method attribute is undefined");
          return undef;
        }
      }

      my $obj;

      if($share_db)
      {
        $obj = $fk_class->new(%key, db => $self->db);
      }
      else
      {
        $obj = $fk_class->new(%key);
      }

      my $ret;

      if($required)
      {
        my $error;

        TRY:
        {
          local $@;
          eval { $ret = $obj->load };
          $error = $@;
        }

        if($error || !$ret)
        {
          my $msg = $obj->error || $error;
          $self->error(ref $msg ? $msg : ("Could not load $fk_class with key " .
                       join(', ', map { "$_ = '$key{$_}'" } sort keys %key) .
                       " - $msg"));
          $self->meta->handle_error($self);
          return $ret;
        }
      }
      else
      {
        return undef  unless($obj->load(speculative => 1));
      }

      return $self->{$key} = $obj;
    };
  }
  elsif($interface eq 'delete_now')
  {
    unless($fk)
    {
      Carp::croak "Cannot make 'delete' method $name without foreign key argument";
    }

    my $fk_name = $fk->name;
    my $is_fk = $fk->type eq 'foreign key' ? 1 : 0;

    $methods{$name} = sub
    {
      my($self) = shift;

      my $object = $self->{$key} || $fk_class->new;

      my %key;

      while(my($local_column, $foreign_column) = each(%$fk_columns))
      {
        my $local_method   = $meta->column_accessor_method_name($local_column);
        my $foreign_method = $fk_meta->column_mutator_method_name($foreign_column);

        $key{$foreign_method} = $self->$local_method();

        # XXX: Comment this out to allow null keys
        unless(defined $key{$foreign_method})
        {
          keys(%$fk_columns); # reset iterator

          # If this failed because we haven't saved it yet
          if(delete $self->{ON_SAVE_ATTR_NAME()}{'pre'}{'fk'}{$fk_name}{'set'} ||
             delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$fk_name}{'set'})
          {
            if($ref_integrity || $required)
            {
              local $fk->{'disable_column_triggers'} = 1;

              # Clear foreign key columns
              foreach my $local_column (keys %$fk_columns)
              {
                next  if($meta->column($local_column)->is_primary_key_member);
                my $local_method = $meta->column_accessor_method_name($local_column);
                $self->$local_method(undef);
              }
            }

            $self->{$key} = undef;
            return 1;
          }

          $self->error("Could not delete $name object - the " .
                       "$local_method attribute is undefined");
          return undef;
        }
      }

      $object->init(%key);

      my($db, $started_new_tx, $deleted, %save_fk, $to_save_pre, $to_save_post, $error);

      TRY:
      {
        local $@;

        eval
        {
          $db = $self->db;
          $object->db($db);

          my $ret = $db->begin_work;

          unless(defined $ret)
          {
            die 'Could not begin transaction during call to $name() - ',
                $db->error;
          }

          $started_new_tx = ($ret == IN_TRANSACTION) ? 0 : 1;

          if($ref_integrity || $required)
          {
            local $fk->{'disable_column_triggers'} = 1;

            # Clear columns that reference the foreign key
            foreach my $local_column (keys %$fk_columns)
            {
              next  if($meta->column($local_column)->is_primary_key_member);
              my $local_method = $meta->column_accessor_method_name($local_column);
              $save_fk{$local_method} = $self->$local_method();
              $self->$local_method(undef);
            }
          }

          # Forget about any value we were going to set on save
          $to_save_pre  = delete $self->{ON_SAVE_ATTR_NAME()}{'pre'}{'fk'}{$fk_name}{'set'};
          $to_save_post = delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$fk_name}{'set'};

          $self->save or die $self->error;

          # Propogate cascade arg, if any
          $deleted = $object->delete(@_) or die $object->error;

          if($started_new_tx)
          {
            $db->commit or die $db->error;
          }

          $self->{$key} = undef;

          # Not sharing?  Aw.
          $object->db(undef)  unless($share_db);
        };

        $error = $@;
      }

      if($error)
      {
        $self->error(ref $error ? $error : "Could not delete $name object - $error");
        $db->rollback  if($db && $started_new_tx);

        # Restore foreign key column values
        while(my($method, $value) = each(%save_fk))
        {
          $self->$method($value);
        }

        # Restore any value we were going to set on save
        $self->{ON_SAVE_ATTR_NAME()}{'pre'}{'fk'}{$fk_name}{'set'} = $to_save_pre
          if($to_save_pre);

        $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$fk_name}{'set'} = $to_save_post
          if($to_save_post);

        $meta->handle_error($self);
        return undef;
      }

      return $deleted;
    };
  }
  elsif($interface eq 'delete_on_save')
  {
    unless($fk)
    {
      Carp::croak "Cannot make 'delete_on_save' method $name without foreign key argument";
    }

    my $fk_name = $fk->name;
    my $is_fk = $fk->type eq 'foreign key' ? 1 : 0;

    $methods{$name} = sub
    {
      my($self) = shift;

      my $object = $self->{$key} || $fk_class->new;

      my %key;

      while(my($local_column, $foreign_column) = each(%$fk_columns))
      {
        my $local_method   = $meta->column_accessor_method_name($local_column);
        my $foreign_method = $fk_meta->column_mutator_method_name($foreign_column);

        $key{$foreign_method} = $self->$local_method();

        # XXX: Comment this out to allow null keys
        unless(defined $key{$foreign_method})
        {
          keys(%$fk_columns); # reset iterator

          # If this failed because we haven't saved it yet
          if(delete $self->{ON_SAVE_ATTR_NAME()}{'pre'}{'fk'}{$fk_name}{'set'} ||
             delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$fk_name}{'set'})
          {
            if($ref_integrity || $required)
            {
              local $fk->{'disable_column_triggers'} = 1;

              # Clear foreign key columns
              foreach my $local_column (keys %$fk_columns)
              {
                next  if($meta->column($local_column)->is_primary_key_member);
                my $local_method = $meta->column_accessor_method_name($local_column);
                $self->$local_method(undef);
              }
            }

            $self->{$key} = undef;
            return 0;
          }

          $self->error("Could not delete $name object - the " .
                       "$local_method attribute is undefined");
          return undef;
        }
      }

      $object->init(%key);

      my %save_fk;

      if($ref_integrity || $required)
      {
        local $fk->{'disable_column_triggers'} = 1;

        # Clear columns that reference the foreign key, saving old values
        foreach my $local_column (keys %$fk_columns)
        {
          next  if($meta->column($local_column)->is_primary_key_member);
          my $local_method = $meta->column_accessor_method_name($local_column);
          $save_fk{$local_method} = $self->$local_method();
          $self->$local_method(undef);
        }
      }

      # Forget about any value we were going to set on save
      delete $self->{ON_SAVE_ATTR_NAME()}{'pre'}{'fk'}{$fk_name}{'set'};
      delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$fk_name}{'set'};

      # Clear the foreign object attribute
      $self->{$key} = undef;

      # Make the code to run on save
      my $delete_code = sub
      {  
        my($self, $args) = @_;

        my @delete_args = 
          map { ($_ => $args->{$_}) } grep { exists $args->{$_} } qw(prepare_cached);

        my($db, $error);

        TRY:
        {
          local $@;

          eval
          {
            $db = $self->db;
            $object->db($db);
            $object->delete(@delete_args) or die $object->error;
          };

          $error = $@;
        }

        if($error)
        {
          $self->error(ref $error ? $error : "Could not delete $name object - $error");

          # Restore old foreign key column values if prudent
          while(my($method, $value) = each(%save_fk))
          {
            $self->$method($value)  unless(defined $self->$method);
          }

          $meta->handle_error($self);
          return undef;
        }

        # Not sharing?  Aw.
        $object->db(undef)  unless($share_db);

        return 1;
      };

      # Add the on save code to the list
      push(@{$self->{ON_SAVE_ATTR_NAME()}{'post'}{'fk'}{$fk_name}{'delete'}}, 
           { code => $delete_code, object => $object, is_fk => $is_fk });

      return 1;
    };
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

sub objects_by_key
{
  my($class, $name, $args, $options) = @_;

  my %methods;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';
  my $target_class = $options->{'target_class'} or die "Missing target class";

  my $relationship = $args->{'relationship'};

  my $ft_class    = $args->{'class'} or die "Missing foreign object class";
  weaken(my $meta = $target_class->meta);
  my $ft_pk;

  unless(exists $args->{'key_columns'} || exists $args->{'query_args'} || 
         exists $args->{'join_args'})
  {
    # The key_columns attr is aliased to column_map when used 
    # through the OneToMany relationship.
    die "Missing both column_map hash and query_args";
  }

  my $ft_columns = $args->{'key_columns'} || {};
  my $ft_manager = $args->{'manager_class'};
  my $ft_method  = $args->{'manager_method'} || 'get_objects';
  my $share_db   = $args->{'share_db'} || 1;
  my $mgr_args   = $args->{'manager_args'} || {};
  my $query_args = $args->{'query_args'} || [];
  my $single     = $args->{'single'} || 0;

  push(@$query_args, @{$args->{'join_args'} || []});

  my $ft_count_method = $args->{'manager_count_method'} || 'get_objects_count';

  if($mgr_args->{'query'})
  {
    Carp::croak "Cannot use the key 'query' in the manager_args parameter ",
                "hash.  Use the separate query_args parameter instead";
  }

  #if(@$query_args % 2 != 0)
  #{
  #  Carp::croak "Odd number of arguments passed in query_args parameter";
  #}

  unless($ft_manager)
  {
    $ft_manager = 'Rose::DB::Object::Manager';
    $mgr_args->{'object_class'} = $ft_class;
  }

  my $required = 
    exists $args->{'required'} ? $args->{'required'} :
    exists $args->{'referential_integrity'} ? $args->{'referential_integrity'} : 1;

  if(exists $args->{'required'} && exists $args->{'referential_integrity'} &&
    (!$args->{'required'} != !$$args->{'referential_integrity'}))
  {
    Carp::croak "The required and referential_integrity parameters conflict. ",
                "Please pass one or the other, not both.";
  }

  my $mod_columns_key = ($args->{'column'} ? $args->{'column'}->nonpersistent : 0) ? 
    MODIFIED_NP_COLUMNS : MODIFIED_COLUMNS;

  if($interface eq 'count')
  {
    my $cache_key = PRIVATE_PREFIX . '_' . $name;

    $methods{$name} = sub
    {
      my($self) = shift;

      my %args;

      if(my $ref = ref $_[0])
      {
        if($ref eq 'HASH')
        {
          %args = (query => [ %{shift(@_)} ], @_);
        }
        elsif(ref $_[0] eq 'ARRAY')
        {
          %args = (query => shift, @_);
        }
      }
      else { %args = @_ }

      if(delete $args{'from_cache'})
      {
        if(keys %args)
        {
          Carp::croak "Additional parameters not allowed in call to ",
                      "$name() with from_cache parameter";
        }

        if(defined $self->{$cache_key})
        {
          return wantarray ? @{$self->{$cache_key}} : $self->{$cache_key};
        }
      }

      my $count;

      # Get query key
      my %key;

      while(my($local_column, $foreign_column) = each(%$ft_columns))
      {
        my $local_method = $meta->column_accessor_method_name($local_column);

        $key{$foreign_column} = $self->$local_method();

        # Comment this out to allow null keys
        unless(defined $key{$foreign_column})
        {
          keys(%$ft_columns); # reset iterator
          $self->error("Could not fetch objects via $name() - the " .
                       "$local_method attribute is undefined");
          return;
        }
      }

      my $cache = delete $args{'cache'};

      # Merge query args
      my @query = (%key, @$query_args, @{delete $args{'query'} || []});      

      # Merge the rest of the arguments
      foreach my $param (keys %args)
      {
        if(exists $mgr_args->{$param})
        {
          my $ref = ref $args{$param};

          if($ref eq 'ARRAY')
          {
            unshift(@{$args{$param}}, ref $mgr_args->{$param} ? 
                    @{$mgr_args->{$param}} :  $mgr_args->{$param});
          }
          elsif($ref eq 'HASH')
          {
            while(my($k, $v) = each(%{$mgr_args->{$param}}))
            {
              $args{$param}{$k} = $v  unless(exists $args{$param}{$k});
            }
          }
        }
      }

      while(my($k, $v) = each(%$mgr_args))
      {
        $args{$k} = $v  unless(exists $args{$k});
      }

      $args{'multi_many_ok'} = 1;

      my $error;

      TRY:
      {
        local $@;

        # Make query for object count
        eval
        {
          #local $Rose::DB::Object::Manager::Debug = 1;
          if($share_db)
          {
            $count = 
              $ft_manager->$ft_count_method(query => \@query, db => $self->db, %args);
          }
          else
          {
            $count = 
              $ft_manager->$ft_count_method(query    => \@query, 
                                            db       => $self->db,
                                            share_db => 0, %args);
          }
        };

        $error = $@;
      }

      if($error || !defined $count)
      {
        my $msg = $error || $ft_manager->error;
        $self->error(ref $msg ? $msg : ("Could not count $ft_class objects - $msg"));
        $self->meta->handle_error($self);
        return wantarray ? () : $count;
      }

      $self->{$cache_key} = $count  if($cache);

      return $count;
    };
  }
  elsif($interface eq 'find' || $interface eq 'iterator')
  {
    my $cache_key = PRIVATE_PREFIX . ":$interface:$name";

    my $is_iterator = $interface eq 'iterator' ? 1 : 0;

    if($is_iterator)
    {
      $ft_method = $args->{'manager_iterator_method'} || 'get_objects_iterator';
    }
    else
    {
      $ft_method = $args->{'manager_find_method'} || 'get_objects';
    }

    $methods{$name} = sub
    {
      my($self) = shift;

      my %args;

      if(my $ref = ref $_[0])
      {
        if($ref eq 'HASH')
        {
          %args = (query => [ %{shift(@_)} ], @_);
        }
        elsif(ref $_[0] eq 'ARRAY')
        {
          %args = (query => shift, @_);
        }
      }
      else { %args = @_ }

      if(delete $args{'from_cache'})
      {
        if(keys %args)
        {
          Carp::croak "Additional parameters not allowed in call to ",
                      "$name() with from_cache parameter";
        }

        if(defined $self->{$cache_key})
        {
          return wantarray ? @{$self->{$cache_key}} : $self->{$cache_key};
        }
      }

      my $objs;

      # Get query key
      my %key;

      while(my($local_column, $foreign_column) = each(%$ft_columns))
      {
        my $local_method = $meta->column_accessor_method_name($local_column);

        $key{$foreign_column} = $self->$local_method();

        # Comment this out to allow null keys
        unless(defined $key{$foreign_column})
        {
          keys(%$ft_columns); # reset iterator
          $self->error("Could not fetch objects via $name() - the " .
                       "$local_method attribute is undefined");
          return;
        }
      }

      my $cache = delete $args{'cache'};

      # Merge query args
      my @query = (%key, @$query_args, @{delete $args{'query'} || []});      

      # Merge the rest of the arguments
      foreach my $param (keys %args)
      {
        if(exists $mgr_args->{$param})
        {
          my $ref = ref $args{$param};

          if($ref eq 'ARRAY')
          {
            unshift(@{$args{$param}}, ref $mgr_args->{$param} ? 
                    @{$mgr_args->{$param}} :  $mgr_args->{$param});
          }
          elsif($ref eq 'HASH')
          {
            while(my($k, $v) = each(%{$mgr_args->{$param}}))
            {
              $args{$param}{$k} = $v  unless(exists $args{$param}{$k});
            }
          }
        }
      }

      while(my($k, $v) = each(%$mgr_args))
      {
        $args{$k} = $v  unless(exists $args{$k});
      }

      my $error;

      TRY:
      {
        local $@;

        # Make query for object list
        eval
        {
          #local $Rose::DB::Object::Manager::Debug = 1;
          if($share_db)
          {
            $objs = 
              $ft_manager->$ft_method(query => \@query, db => $self->db, %args)
                or die $ft_manager->error;
          }
          else
          {
            $objs = 
              $ft_manager->$ft_method(query    => \@query, 
                                      db       => $self->db,
                                      share_db => 0, %args)
                or die $ft_manager->error;
          }
        };

        $error = $@;
      }

      if($error || !$objs)
      {
        my $msg = $error || $ft_manager->error;
        $self->error(ref $msg ? $msg : ("Could not " . ($is_iterator ? 'get iterator for' : 'find') .
                     " $ft_class objects - $msg"));
        $self->meta->handle_error($self);
        return wantarray ? () : $objs;
      }

      return $objs  if($is_iterator);

      $self->{$cache_key} = $objs  if($cache);

      return wantarray ? @$objs: $objs;
    };
  }
  elsif($interface eq 'get_set' || $interface eq 'get_set_load')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      if(@_)
      {      
        return $self->{$key} = undef  if(@_ == 1 && !defined $_[0]);
        $self->{$key} = __args_to_objects($self, $key, $ft_class, \$ft_pk, \@_);

        if(!$single)
        {
          return wantarray ? @{$self->{$key}} : $self->{$key};
        }
        else
        {
          return $self->{$key}[0];
        }
      }

      if(defined $self->{$key})
      {
        if(!$single)
        {
          return wantarray ? @{$self->{$key}} : $self->{$key};
        }
        else
        {
          return $self->{$key}[0];
        }
      }

      my %key;

      while(my($local_column, $foreign_column) = each(%$ft_columns))
      {
        my $local_method = $meta->column_accessor_method_name($local_column);

        $key{$foreign_column} = $self->$local_method();

        # Comment this out to allow null keys
        unless(defined $key{$foreign_column})
        {
          keys(%$ft_columns); # reset iterator
          $self->error("Could not fetch objects via $name() - the " .
                       "$local_method attribute is undefined");
          return;
        }
      }

      my($objs, $error);

      TRY:
      {
        local $@;

        eval
        {
          if($share_db)
          {
            $objs = 
              $ft_manager->$ft_method(query => [ %key, @$query_args ], 
                                     %$mgr_args, 
                                     db => $self->db)
                or die $ft_manager->error;
          }
          else
          {
            $objs = 
              $ft_manager->$ft_method(query    => [ %key, @$query_args ],
                                      db       => $self->db, 
                                      share_db => 0, %$mgr_args)
                or die $ft_manager->error;
          }
        };

        $error = $@;
      }

      if($error || !$objs)
      {
        my $msg = $error || $ft_manager->error;
        $self->error(ref $msg ? $msg : ("Could not load $ft_class objects with key " .
                     join(', ', map { "$_ = '$key{$_}'" } sort keys %key) .
                     " - $msg"));
        $self->meta->handle_error($self);
        return wantarray ? () : $objs;
      }

      $self->{$key} = $objs;

      if(!$single)
      {
        return wantarray ? @{$self->{$key}} : $self->{$key};
      }
      else
      {
        if($required && !@$objs)
        {
          my %query = (%key, @$query_args);
          $self->error("No related $ft_class object found with query " .
                       join(', ', map { "$_ = '$query{$_}'" } sort keys %query));
          $self->meta->handle_error($self);
          return 0;
        }

        return $self->{$key}[0];
      }
    };

    if($interface eq 'get_set_load')
    {
      my $method_name = $args->{'load_method'} || 'load_' . $name;

      $methods{$method_name} = sub
      {
        return (defined shift->$name(@_)) ? 1 : 0;
      };
    }
  }
  elsif($interface eq 'get_set_now')
  {
    my $ft_delete_method  = $args->{'manager_delete_method'} || 'delete_objects';

    unless($relationship)
    {
      Carp::confess "Cannot make 'get_set_now' method $name without relationship argument";
    }

    my $rel_name = $relationship->name;

    $methods{$name} = sub
    {
      my($self) = shift;

      if(@_)
      {
        # If loading, just assign
        if($self->{STATE_LOADING()})
        {
          return $self->{$key} = undef  if(@_ == 1 && !defined $_[0]);
          $self->{$key} = (@_ == 1 && ref $_[0] eq 'ARRAY') ? $_[0] : [ @_ ];

          if(!$single)
          {
            return wantarray ? @{$self->{$key}} : $self->{$key};
          }
          else
          {
            return $self->{$key}[0];
          }
        }

        # Can't set until the object is saved
        unless($self->{STATE_IN_DB()})
        {
          Carp::croak "Can't set $name() until this object is loaded or saved";
        }

        # Set to undef resets the attr  
        if(@_ == 1 && !defined $_[0])
        {
          # Delete any pending set or add actions
          delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'set'};
          delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'};

          $self->{$key} = undef;
          $single ? return undef : return;
        }

        # Set up join conditions and column map
        my(%key, %map);

        my $ft_meta = $ft_class->meta 
          or Carp::croak "Missing metadata for foreign object class $ft_class";

        while(my($local_column, $foreign_column) = each(%$ft_columns))
        {
          my $local_method     = $meta->column_accessor_method_name($local_column);
          my $foreign_accessor = $ft_meta->column_accessor_method_name($foreign_column);
          my $foreign_mutator  = $ft_meta->column_mutator_method_name($foreign_column);

          $key{$foreign_column} = $map{$foreign_mutator} = $self->$local_method();

          # Comment this out to allow null keys
          unless(defined $key{$foreign_column})
          {
            keys(%$ft_columns); # reset iterator
            $self->error("Could not set objects via $name() - the " .
                         "$local_method attribute is undefined");
            $single ? return undef : return;
          }
        }

        my($db, $started_new_tx, $error);

        TRY:
        {
          local $@;

          eval
          {
            $db = $self->db;

            my $ret = $db->begin_work;

            unless(defined $ret)
            {
              die 'Could not begin transaction during call to $name() - ',
                  $db->error;
            }

            $started_new_tx = ($ret == IN_TRANSACTION) ? 0 : 1;

            # Get the list of new objects
            my $objects = __args_to_objects($self, $key, $ft_class, \$ft_pk, \@_);

            # Prep objects for saving.
            foreach my $object (@$objects)
            {
              # Map object to parent
              $object->init(%map, db => $db);

              # If the object is not marked as already existing in the database,
              # see if it represents an existing row.  If it does, merge the
              # existing row's column values into the object, allowing any
              # modified columns in the object to take precedence.
              __check_and_merge($object);
            }

            # Delete any existing objects
            my $deleted = 
              $ft_manager->$ft_delete_method(object_class => $ft_class,
                                             where => [ %key, @$query_args ], 
                                             db => $db);
            die $ft_manager->error  unless(defined $deleted);

            # Save all the new objects
            foreach my $object (@$objects)
            {
              $object->{STATE_IN_DB()} = 0  if($deleted);

              # If the object is not marked as already existing in the database,
              # see if it represents an existing row.  If it does, merge the
              # existing row's column values into the object, allowing any
              # modified columns in the object to take precedence. Returns true
              # if the object represents an existing row.
              if(__check_and_merge($object))
              {
                $object->save(changes_only => 1) or die $object->error;
              }
              else
              {
                $object->save or die $object->error;
              }

              # Not sharing?  Aw.
              $object->db(undef)  unless($share_db);
            }

            # Assign to attribute or blank the attribute, causing the objects
            # to be fetched from the db next time, depending on whether or not
            # there's a custom sort order
            $self->{$key} = defined $mgr_args->{'sort_by'} ? undef : $objects;

            if($started_new_tx)
            {
              $db->commit or die $db->error;
            }

            # Delete any pending set or add actions
            delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'set'};
            delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'};
          };

          $error = $@;
        }

        if($error)
        {
          $self->error(ref $error ? $error : "Could not set $name objects - $error");
          $db->rollback  if($db && $started_new_tx);
          $meta->handle_error($self);
          return undef;
        }

        return 1  unless(defined $self->{$key});

        if(!$single)
        {
          return wantarray ? @{$self->{$key}} : $self->{$key};
        }
        else
        {
          return $self->{$key}[0];
        }
      }

      # Return existing list of objects, if it exists
      if(defined $self->{$key})
      {
        if(!$single)
        {
          return wantarray ? @{$self->{$key}} : $self->{$key};
        }
        else
        {
          return $self->{$key}[0];
        }
      }

      my $objs;

      # Get query key
      my %key;

      while(my($local_column, $foreign_column) = each(%$ft_columns))
      {
        my $local_method = $meta->column_accessor_method_name($local_column);

        $key{$foreign_column} = $self->$local_method();

        # Comment this out to allow null keys
        unless(defined $key{$foreign_column})
        {
          keys(%$ft_columns); # reset iterator
          $self->error("Could not fetch objects via $name() - the " .
                       "$local_method attribute is undefined");
          $single ? return undef : return;
        }
      }

      my $error;

      TRY:
      {
        local $@;

        # Make query for object list
        eval
        {
          if($share_db)
          {
            $objs = 
              $ft_manager->$ft_method(query => [ %key, @$query_args ], 
                                     %$mgr_args, db => $self->db)
                or die $ft_manager->error;
          }
          else
          {
            $objs = 
              $ft_manager->$ft_method(query    => [ %key, @$query_args ],
                                      db       => $self->db,
                                      share_db => 0, %$mgr_args)
                or die $ft_manager->error;
          }
        };

        $error = $@;
      }

      if($error || !$objs)
      {
        my $msg = $error || $ft_manager->error;
        $self->error(ref $msg ? $msg : ("Could not load $ft_class objects with key " .
                     join(', ', map { "$_ = '$key{$_}'" } sort keys %key) .
                     " - $msg"));
        $self->meta->handle_error($self);
        return wantarray ? () : $objs;
      }

      $self->{$key} = $objs;

      if(!$single)
      {
        return wantarray ? @{$self->{$key}} : $self->{$key};
      }
      else
      {
        if($required && !@$objs)
        {
          my %query = (%key, @$query_args);
          $self->error("Not related $ft_class object found with query " .
                       join(', ', map { "$_ = '$query{$_}'" } sort keys %query));
          $self->meta->handle_error($self);
          return 0;
        }

        return $self->{$key}[0];
      }
    };
  }
  elsif($interface eq 'get_set_on_save')
  {
    my $ft_delete_method  = $args->{'manager_delete_method'} || 'delete_objects';

    unless($relationship)
    {
      Carp::confess "Cannot make 'get_set_on_save' method $name without relationship argument";
    }

    my $rel_name = $relationship->name;

    $methods{$name} = sub
    {
      my($self) = shift;

      if(@_)
      {
        # If loading, just assign
        if($self->{STATE_LOADING()})
        {
          return $self->{$key} = undef  if(@_ == 1 && !defined $_[0]);
          $self->{$key} = (@_ == 1 && ref $_[0] eq 'ARRAY') ? $_[0] : [ @_ ];

          if(!$single)
          {
            return wantarray ? @{$self->{$key}} : $self->{$key};
          }
          else
          {
            return $self->{$key}[0];
          }
        }

        # Set to undef resets the attr  
        if(@_ == 1 && !defined $_[0])
        {
          # Delete any pending set or add actions
          delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'set'};
          delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'};

          $self->{$key} = undef;
          $single ? return undef : return;
        }

        my $objects = __args_to_objects($self, $key, $ft_class, \$ft_pk, \@_);

        my $db = $self->db;

        # Set up column map
        my %map;

        my $ft_meta = $ft_class->meta 
          or Carp::croak "Missing metadata for foreign object class $ft_class";

        while(my($local_column, $foreign_column) = each(%$ft_columns))
        {
          my $local_method   = $meta->column_accessor_method_name($local_column);
          my $foreign_method = $ft_meta->column_mutator_method_name($foreign_column);

          $map{$foreign_method} = $self->$local_method();
        }

        # Map all the objects to the parent
        foreach my $object (@$objects)
        {
          $object->init(%map, ($share_db ? (db => $db) : ()));
        }

        # Set the attribute
        $self->{$key} = $objects;

        my $save_code = sub
        {
          my($self, $args) = @_;

          # Set up join conditions and column map
          my(%key, %map);

          my $ft_meta = $ft_class->meta 
            or Carp::croak "Missing metadata for foreign object class $ft_class";

          while(my($local_column, $foreign_column) = each(%$ft_columns))
          {
            my $local_method     = $meta->column_accessor_method_name($local_column);
            my $foreign_accessor = $ft_meta->column_accessor_method_name($foreign_column);
            my $foreign_mutator  = $ft_meta->column_mutator_method_name($foreign_column);

            $key{$foreign_column} = $map{$foreign_mutator} = $self->$local_method();

            # Comment this out to allow null keys
            unless(defined $key{$foreign_column})
            {
              keys(%$ft_columns); # reset iterator
              $self->error("Could not set objects via $name() - the " .
                           "$local_method attribute is undefined");
              return;
            }
          }

          my $db = $self->db;

          # Prep objects for saving.  Use the current list, even if it's
          # different than it was when the "set on save" was called.
          foreach my $object (@{$self->{$key} || []})
          {
            # Map object to parent
            $object->init(%map, db => $db);

            # If the object is not marked as already existing in the database,
            # see if it represents an existing row.  If it does, merge the
            # existing row's column values into the object, allowing any
            # modified columns in the object to take precedence.
            __check_and_merge($object);
          }

          # Delete any existing objects
          my $deleted = 
            $ft_manager->$ft_delete_method(object_class => $ft_class,
                                           where => [ %key, @$query_args ], 
                                           db => $db);
          die $ft_manager->error  unless(defined $deleted);

          # Save all the objects.  Use the current list, even if it's
          # different than it was when the "set on save" was called.
          foreach my $object (@{$self->{$key} || []})
          {
            $object->{STATE_IN_DB()} = 0  if($deleted);

            # If the object is not marked as already existing in the database,
            # see if it represents an existing row.  If it does, merge the
            # existing row's column values into the object, allowing any
            # modified columns in the object to take precedence. Returns true
            # if the object represents an existing row.
            if(__check_and_merge($object))
            {
              $object->save(changes_only => 1) or die $object->error;
            }
            else
            {
              $object->save or die $object->error;
            }

            # Not sharing?  Aw.
            $object->db(undef)  unless($share_db);
          }

          # Forget about any adds if we just set the list
          if(defined $self->{$key})
          {
            # Set to undef instead of deleting because this code ref
            # will be called while iterating over this very hash.
            $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'} = undef;
          }

          # Blank the attribute, causing the objects to be fetched from
          # the db next time, if there's a custom sort order or if
          # the list is defined but empty
          $self->{$key} = undef  if(defined $mgr_args->{'sort_by'} ||
                                    (defined $self->{$key} && !@{$self->{$key}}));

          return 1;
        };

        $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'set'} = $save_code;

        # Forget about any adds
        delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'};

        return 1  unless(defined $self->{$key});

        if(!$single)
        {
          return wantarray ? @{$self->{$key}} : $self->{$key};
        }
        else
        {
          return $self->{$key}[0];
        }
      }

      # Return existing list of objects, if it exists
      if(defined $self->{$key})
      {
        if(!$single)
        {
          return wantarray ? @{$self->{$key}} : $self->{$key};
        }
        else
        {
          return $self->{$key}[0];
        }
      }

      my $objs;

      # Get query key
      my %key;

      while(my($local_column, $foreign_column) = each(%$ft_columns))
      {
        my $local_method = $meta->column_accessor_method_name($local_column);

        $key{$foreign_column} = $self->$local_method();

        # Comment this out to allow null keys
        unless(defined $key{$foreign_column})
        {
          keys(%$ft_columns); # reset iterator
          $self->error("Could not fetch objects via $name() - the " .
                       "$local_method attribute is undefined");
          $single ? return undef : return;
        }
      }

      my $error;

      TRY:
      {
        local $@;

        # Make query for object list
        eval
        {
          if($share_db)
          {
            $objs = 
              $ft_manager->$ft_method(query => [ %key, @$query_args ], 
                                     %$mgr_args, db => $self->db)
                or die $ft_manager->error;
          }
          else
          {
            $objs = 
              $ft_manager->$ft_method(query    => [ %key, @$query_args ],
                                      db       => $self->db, 
                                      share_db => 0,
                                      %$mgr_args)
                or die $ft_manager->error;
          }
        };

        $error = $@;
      }

      if($error || !$objs)
      {
        my $msg = $error || $ft_manager->error;
        $self->error(ref $msg ? $msg : ("Could not load $ft_class objects with key " .
                     join(', ', map { "$_ = '$key{$_}'" } sort keys %key) .
                     " - $msg"));
        $self->meta->handle_error($self);
        return wantarray ? () : $objs;
      }

      $self->{$key} = $objs;

      if(!$single)
      {
        return wantarray ? @{$self->{$key}} : $self->{$key};
      }
      else
      {
        if($required && !@$objs)
        {
          my %query = (%key, @$query_args);
          $self->error("Not related $ft_class object found with query " .
                       join(', ', map { "$_ = '$query{$_}'" } sort keys %query));
          $self->meta->handle_error($self);
          return 0;
        }

        return $self->{$key}[0];
      }
    };
  }
  elsif($interface eq 'delete_now')
  {
    my $ft_delete_method  = $args->{'manager_delete_method'} || 'delete_objects';

    unless($relationship)
    {
      Carp::confess "Cannot make 'delete_now' method $name without relationship argument";
    }

    my $rel_name = $relationship->name;

    $methods{$name} = sub
    {
      my($self) = shift;

      # Set up join conditions and column map
      my(%key, %map);

      my $ft_meta = $ft_class->meta 
        or Carp::croak "Missing metadata for foreign object class $ft_class";

      while(my($local_column, $foreign_column) = each(%$ft_columns))
      {
        my $local_method     = $meta->column_accessor_method_name($local_column);
        my $foreign_accessor = $ft_meta->column_accessor_method_name($foreign_column);
        my $foreign_mutator  = $ft_meta->column_mutator_method_name($foreign_column);

        $key{$foreign_column} = $map{$foreign_mutator} = $self->$local_method();

        # Comment this out to allow null keys
        unless(defined $key{$foreign_column})
        {
          keys(%$ft_columns); # reset iterator
          $self->error("Could not delete objects via $name() - the " .
                       "$local_method attribute is undefined");
          $single ? return undef : return;
        }
      }

      my($db, $started_new_tx, $error);

      TRY:
      {
        local $@;

        eval
        {
          $db = $self->db;

          my $ret = $db->begin_work;

          unless(defined $ret)
          {
            die 'Could not begin transaction during call to $name() - ',
                $db->error;
          }

          $started_new_tx = ($ret == IN_TRANSACTION) ? 0 : 1;

          # Delete existing objects
          my $deleted = 
            $ft_manager->$ft_delete_method(object_class => $ft_class,
                                           where => [ %key, @$query_args ], 
                                           db => $db);
          die $ft_manager->error  unless(defined $deleted);

          # Delete any pending set or add actions
          delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'set'};
          delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'};

          if($started_new_tx)
          {
            $db->commit or die $db->error;
          }
        };

        $error = $@;
      }

      if($error)
      {
        $self->error(ref $error ? $error : "Could not delete $name objects - $error");
        $db->rollback  if($db && $started_new_tx);
        $meta->handle_error($self);
        return undef;
      }

      return 1;
    };
  }
  elsif($interface eq 'delete_on_save')
  {
    my $ft_delete_method  = $args->{'manager_delete_method'} || 'delete_objects';

    unless($relationship)
    {
      Carp::confess "Cannot make 'delete_on_save' method $name without relationship argument";
    }

    my $rel_name = $relationship->name;

    $methods{$name} = sub
    {
      my($self) = shift;

      # Delete any pending set or add actions
      delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'set'};
      delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'};

      $self->{$key} = undef;

      #weaken(my $self = $self);

      my $delete_code = sub
      {
        my($self, $args) = @_;

        my @delete_args = 
          map { ($_ => $args->{$_}) } grep { exists $args->{$_} } qw(prepare_cached);

        # Set up join conditions and column map
        my(%key, %map);

        my $ft_meta = $ft_class->meta 
          or Carp::croak "Missing metadata for foreign object class $ft_class";

        while(my($local_column, $foreign_column) = each(%$ft_columns))
        {
          my $local_method     = $meta->column_accessor_method_name($local_column);
          my $foreign_accessor = $ft_meta->column_accessor_method_name($foreign_column);
          my $foreign_mutator  = $ft_meta->column_mutator_method_name($foreign_column);

          $key{$foreign_column} = $map{$foreign_mutator} = $self->$local_method();

          # Comment this out to allow null keys
          unless(defined $key{$foreign_column})
          {
            keys(%$ft_columns); # reset iterator
            $self->error("Could not set objects via $name() - the " .
                         "$local_method attribute is undefined");
            return;
          }
        }

        my $db = $self->db;

        # Delete existing objects
        my $deleted = 
          $ft_manager->$ft_delete_method(object_class => $ft_class,
                                         where => [ %key, @$query_args ], 
                                         db => $db, @delete_args);
        die $ft_manager->error  unless(defined $deleted);

        $self->{$key} = undef;

        return 1;
      };

      $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'delete'} = $delete_code;

      # Forget about any adds
      delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'};

      return 1;
    };
  }
  elsif($interface eq 'add_now')
  {
    unless($relationship)
    {
      Carp::confess "Cannot make 'add_now' method $name without relationship argument";
    }

    my $rel_name = $relationship->name;

    $methods{$name} = sub
    {
      my($self) = shift;

      unless(@_)
      {
        $self->error("No $name to add");
        return wantarray ? () : 0;
      }

      # Can't add until the object is saved
      unless($self->{STATE_IN_DB()})
      {
        Carp::croak "Can't add $name until this object is loaded or saved";
      }

      if($self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'set'})
      {
        Carp::croak "Cannot add objects via the 'add_now' method $name() ",
                    "because the list of objects is already going to be ".
                    "set to something else on save.  Use the 'add_on_save' ",
                    "method type instead.";
      }

      # Set up column map
      my %map;

      my $ft_meta = $ft_class->meta 
        or Carp::croak "Missing metadata for foreign object class $ft_class";

      while(my($local_column, $foreign_column) = each(%$ft_columns))
      {
        my $local_method   = $meta->column_accessor_method_name($local_column);
        my $foreign_method = $ft_meta->column_mutator_method_name($foreign_column);

        $map{$foreign_method} = $self->$local_method();

        # Comment this out to allow null keys
        unless(defined $map{$foreign_method})
        {
          keys(%$ft_columns); # reset iterator
          $self->error("Could add set objects via $name() - the " .
                       "$local_method attribute is undefined");
          return;
        }
      }

      my $objects = __args_to_objects($self, $key, $ft_class, \$ft_pk, \@_);

      my($db, $started_new_tx, $error);

      TRY:
      {
        local $@;

        eval
        {
          $db = $self->db;

          my $ret = $db->begin_work;

          unless(defined $ret)
          {
            die 'Could not begin transaction during call to $name() - ',
                $db->error;
          }

          $started_new_tx = ($ret == IN_TRANSACTION) ? 0 : 1;

          # Add all the new objects
          foreach my $object (@$objects)
          {
            # Map object to parent
            $object->init(%map, db => $db);

            # If the object is not marked as already existing in the database,
            # see if it represents an existing row.  If it does, merge the
            # existing row's column values into the object, allowing any
            # modified columns in the object to take precedence. Returns true
            # if the object represents an existing row.
            if(__check_and_merge($object))
            {
              $object->save(changes_only => 1) or die $object->error;
            }
            else
            {
              $object->save or die $object->error;
            }
          }

          # Clear the existing list, forcing it to be reloaded next time
          # it's asked for
          $self->{$key} = undef;

          if($started_new_tx)
          {
            $db->commit or die $db->error;
          }
        };

        $error = $@;
      }

      if($error)
      {
        $self->error(ref $error ? $error : "Could not add $name - $error");
        $db->rollback  if($db && $started_new_tx);
        $meta->handle_error($self);
        return;
      }

      return @$objects;
    };
  }
  elsif($interface eq 'add_on_save')
  {
    unless($relationship)
    {
      Carp::confess "Cannot make 'add_on_save' method $name without relationship argument";
    }

    my $rel_name = $relationship->name;

    $methods{$name} = sub
    {
      my($self) = shift;

      unless(@_)
      {
        $self->error("No $name to add");
        return wantarray ? () : 0;
      }

      # Add all the new objects
      my $objects = __args_to_objects($self, $key, $ft_class, \$ft_pk, \@_);

      # Add the objects to the list, if it's defined
      if(defined $self->{$key})
      {
        my $db = $self->db;

        # Set up column map
        my %map;

        my $ft_meta = $ft_class->meta 
          or Carp::croak "Missing metadata for foreign object class $ft_class";

        while(my($local_column, $foreign_column) = each(%$ft_columns))
        {
          my $local_method   = $meta->column_accessor_method_name($local_column);
          my $foreign_method = $ft_meta->column_mutator_method_name($foreign_column);

          $map{$foreign_method} = $self->$local_method();
        }

        # Map all the objects to the parent
        foreach my $object (@$objects)
        {
          $object->init(%map, ($share_db ? (db => $db) : ()));
        }

        # Add the objects
        push(@{$self->{$key}}, @$objects);
      }

      my $add_code = sub
      {
        my($self, $args) = @_;

        # Set up column map
        my %map;

        my $ft_meta = $ft_class->meta 
          or Carp::croak "Missing metadata for foreign object class $ft_class";

        while(my($local_column, $foreign_column) = each(%$ft_columns))
        {
          my $local_method   = $meta->column_accessor_method_name($local_column);
          my $foreign_method = $ft_meta->column_mutator_method_name($foreign_column);

          $map{$foreign_method} = $self->$local_method();

          # Comment this out to allow null keys
          unless(defined $map{$foreign_method})
          {
            keys(%$ft_columns); # reset iterator
            die $self->error("Could not add objects via $name() - the " .
                             "$local_method attribute is undefined");
          }
        }

        my $db = $self->db;

        # Add all the objects.
        foreach my $object (@{$self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'}{'objects'}})
        {
          # Map object to parent
          $object->init(%map, db => $db);

          # If the object is not marked as already existing in the database,
          # see if it represents an existing row.  If it does, merge the
          # existing row's column values into the object, allowing any
          # modified columns in the object to take precedence. Returns true
          # if the object represents an existing row.
          if(__check_and_merge($object))
          {
            $object->save(%$args, changes_only => 1) or die $object->error;
          }
          else
          {
            $object->save(%$args) or die $object->error;
          }
        }

        # Blank the attribute, causing the objects to be fetched from
        # the db next time, if there's a custom sort order or if
        # the list is defined but empty
        $self->{$key} = undef  if(defined $mgr_args->{'sort_by'} ||
                                  (defined $self->{$key} && !@{$self->{$key}}));

        return 1;
      };

      my $stash = $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'} ||= {};

      push(@{$stash->{'objects'}}, @$objects);
      $stash->{'code'} = $add_code;

      return @$objects;
    };
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

# XXX: These are duplicated from ManyToMany.pm because I don't want to use()
# XXX: that module from here if I don't have to.  Lazy or foolish?  Hm.
# XXX: Anyway, make sure they stay in sync!
use constant MAP_RECORD_METHOD => 'map_record';
use constant DEFAULT_REL_KEY   => PRIVATE_PREFIX . '_default_rel_key';

our %Made_Map_Record_Method;

sub objects_by_map
{
  my($class, $name, $args, $options) = @_;

  my %methods;

  my $key = $args->{'hash_key'} || $name;
  my $interface = $args->{'interface'} || 'get_set';
  my $target_class = $options->{'target_class'} or die "Missing target class";

  my $relationship = $args->{'relationship'} or die "Missing relationship";
  my $rel_name     = $relationship->name;
  my $map_class    = $args->{'map_class'} or die "Missing map class";
  weaken(my $map_meta = $map_class->meta or die "Missing meta for $map_class");
  my $map_from     = $args->{'map_from'};
  my $map_to       = $args->{'map_to'};
  my $map_manager  = $args->{'manager_class'};
  my $map_method   = $args->{'manager_method'} || 'get_objects';
  my $mgr_args     = $args->{'manager_args'} || {};
  my $query_args   = $args->{'query_args'} || [];

  push(@$query_args, @{$args->{'join_args'} || []});

  my $count_method = $args->{'manager_count_method'} || 'get_objects_count';

  if($mgr_args->{'query'})
  {
    Carp::croak "Cannot use the key 'query' in the manager_args parameter ",
                "hash.  Use the separate query_args parameter instead";
  }

  my($map_to_class, $map_to_meta, $map_to_method);

  my $map_delete_method = $args->{'map_delete_method'} || 'delete_objects';

  #if(@$query_args % 2 != 0)
  #{
  #  Carp::croak "Odd number of arguments passed in query_args parameter";
  #}

  unless($map_manager)
  {
    $map_manager = 'Rose::DB::Object::Manager';
    $mgr_args->{'object_class'} = $map_class;
  }

  my $meta     = $target_class->meta;
  my $share_db = $args->{'share_db'} || 1;

  # "map" is the map table, "self" is the $target_class, and "remote"
  # is the foreign object class
  my(%map_column_to_self_method,
     %map_column_to_self_column,
     %map_method_to_remote_method);

  # Also grab the foreign object class that the mapper points to,
  # the relationship name that points back to us, and the class 
  # name of the objects we really want to fetch.
  my($require_objects, $local_rel, $foreign_class, %seen_fk);

  foreach my $item ($map_meta->foreign_keys, $map_meta->relationships)
  {
    # Track which foreign keys we've seen
    if($item->isa('Rose::DB::Object::Metadata::ForeignKey'))
    {
      $seen_fk{$item->id}++;
    }
    elsif($item->isa('Rose::DB::Object::Metadata::Relationship'))
    {
      # Skip a relationship if we've already seen the equivalent foreign key
      next  if($seen_fk{$item->id});
    }

    if($item->can('class') && $item->class eq $target_class)
    {
      # Skip if there was an explicit local relationship name and
      # this is not that name.
      unless($map_from && $item->name ne $map_from)
      {
        if(%map_column_to_self_method)
        {
          Carp::croak "Map class $map_class has more than one foreign key ",
                      "and/or 'many to one' relationship that points to the ",
                      "class $target_class.  Please specify one by name ",
                      "with a 'local' parameter in the 'map' hash";
        }

        $map_from = $local_rel = $item->name;

        my $map_columns = 
          $item->can('column_map') ? $item->column_map : $item->key_columns;

        # "local" and "foreign" here are relative to the *mapper* class
        while(my($local_column, $foreign_column) = each(%$map_columns))
        {
          my $foreign_method = $meta->column_accessor_method_name($foreign_column)
            or Carp::croak "Missing accessor method for column '$foreign_column'", 
                           " in class ", $meta->class;
          $map_column_to_self_method{$local_column} = $foreign_method;
          $map_column_to_self_column{$local_column} = $foreign_column;
        }

        next;
      }
    }

    if($item->isa('Rose::DB::Object::Metadata::ForeignKey') ||
          $item->type eq 'many to one')
    {
      # Skip if there was an explicit foreign relationship name and
      # this is not that name.
      next  if($map_to && $item->name ne $map_to);

      $map_to = $item->name;

      if($require_objects)
      {
        Carp::croak "Map class $map_class has more than one foreign key ",
                    "and/or 'many to one' relationship that points to a ",
                    "class other than $target_class.  Please specify one ",
                    "by name with a 'foreign' parameter in the 'map' hash";
      }

      $map_to_class = $item->class;
      $map_to_meta  = $map_to_class->meta;

      my $map_columns = 
        $item->can('column_map') ? $item->column_map : $item->key_columns;

      # "local" and "foreign" here are relative to the *mapper* class
      while(my($local_column, $foreign_column) = each(%$map_columns))
      {
        my $local_method = $map_meta->column_accessor_method_name($local_column)
          or Carp::croak "Missing accessor method for column '$local_column'", 
                         " in class ", $map_meta->class;

        my $foreign_method = $map_to_meta->column_accessor_method_name($foreign_column)
          or Carp::croak "Missing accessor method for column '$foreign_column'", 
                         " in class ", $map_to_meta->class;

        # local           foreign
        # Map:color_id => Color:id
        $map_method_to_remote_method{$local_method} = $foreign_method;
      }

      $require_objects = [ $item->name ];
      $foreign_class = $item->class;
      $map_to_method = $item->method_name('get_set') || 
                       $item->method_name('get_set_now') ||
                       $item->method_name('get_set_on_save') ||
                       Carp::confess "No 'get_*' method found for ",
                                     $item->name;
    }
  }

  unless(%map_column_to_self_method)
  {
    Carp::croak "Could not find a foreign key or 'many to one' relationship ",
                "in $map_class that points to $target_class";
  }

  unless(%map_column_to_self_column)
  {
    Carp::croak "Could not find a foreign key or 'many to one' relationship ",
                "in $map_class that points to ", ($map_to_class || $map_to);
  }

  unless($require_objects)
  {
    # Make a second attempt to find a suitable foreign relationship in the
    # map class, this time looking for links back to $target_class so long as
    # it's a different relationship than the one used in the local link.
    foreach my $item ($map_meta->foreign_keys, $map_meta->relationships)
    {
      # Skip a relationship if we've already seen the equivalent foreign key
      if($item->isa('Rose::DB::Object::Metadata::Relationship'))
      {
        next  if($seen_fk{$item->id});
      }

      if(($item->isa('Rose::DB::Object::Metadata::ForeignKey') ||
         $item->type eq 'many to one') &&
         $item->class eq $target_class && $item->name ne $local_rel)
      {  
        if($require_objects)
        {
          Carp::croak "Map class $map_class has more than two foreign keys ",
                      "and/or 'many to one' relationships that points to a ",
                      "$target_class.  Please specify which ones to use ",
                      "by including 'local' and 'foreign' parameters in the ",
                      "'map' hash";
        }

        $require_objects = [ $item->name ];
        $foreign_class = $item->class;
        $map_to_method = $item->method_name('get_set') ||
                         $item->method_name('get_set_now') ||
                         $item->method_name('get_set_on_save') ||
                         Carp::confess "No 'get_*' method found for ",
                                       $item->name;
      }
    }
  }

  unless($require_objects)
  {
    Carp::croak "Could not find a foreign key or 'many to one' relationship ",
                "in $map_class that points to a class other than $target_class"
  }

  # Populate relationship with the info we've extracted
  $relationship->column_map(\%map_column_to_self_column);
  $relationship->map_from($map_from);
  $relationship->map_to($map_to);
  $relationship->foreign_class($foreign_class);

  # Relationship names
  $map_to   ||= $require_objects->[0];
  $map_from ||= $local_rel;

  # This var will old the name of the primary key column in the foreign 
  # class, provided that there is only one column in that key.
  my $ft_pk;

  # Pre-process sort_by args to map unqualified column names to the
  # leaf-node table rather than the map table.
  if(my $sort_by = $mgr_args->{'sort_by'})
  {
    my $table = $foreign_class->meta->table;

    foreach my $sort (ref $sort_by ? @$sort_by : $sort_by)
    {
      $sort =~ s/^(['"`]?)\w+\1(?:\s+(?:ASC|DESC))?$/$table.$sort/;
    }

    $mgr_args->{'sort_by'} = $sort_by;
  }

  my $map_record_method = $relationship->map_record_method;

  unless($map_record_method)
  {
    if($map_record_method = $mgr_args->{'with_map_records'})
    {
      if($map_record_method && $map_record_method eq '1')
      {
        $map_record_method = MAP_RECORD_METHOD;
      }
    }
  }

  if($map_record_method)
  {
    if($map_to_class->can($map_record_method) && 
      (my $info = $Made_Map_Record_Method{"${map_to_class}::$map_record_method"}))
    {
      unless($info->{'rel_class'} eq $target_class &&
             $info->{'rel_name'} eq $relationship->name)
      {
        Carp::croak "Already made a map record method named $map_record_method in ",
                    "class $map_to_class on behalf of the relationship ",
                    "'$info->{'rel_name'}' in class $info->{'rel_class'}.  ",
                    "Please choose another name for the map record method for ",
                    "the relationship named '", $relationship->name, "' in $target_class.";
      }
    }

    require Rose::DB::Object::Metadata::Relationship::ManyToMany;

    unless($map_to_class->can($map_record_method))
    {
      Rose::DB::Object::Metadata::Relationship::ManyToMany::make_map_record_method(
        $map_to_class, $map_record_method, $map_class);

      $Made_Map_Record_Method{"${map_to_class}::$map_record_method"} =
      {
        rel_class => $target_class,
        rel_name  => $relationship->name,
      };
    }
  }

  my $mod_columns_key = ($args->{'column'} ? $args->{'column'}->nonpersistent : 0) ? 
    MODIFIED_NP_COLUMNS : MODIFIED_COLUMNS;

  if($interface eq 'find' || $interface eq 'iterator')
  {
    my $cache_key = PRIVATE_PREFIX . ":$interface:$name";

    my $is_iterator = $interface eq 'iterator' ? 1 : 0;

    if($is_iterator && $map_method eq 'get_objects')
    {
      $map_method = 'get_objects_iterator';
    }

    $methods{$name} = sub
    {
      my($self) = shift;

      my %args;

      if(my $ref = ref $_[0])
      {
        if($ref eq 'HASH')
        {
          %args = (query => [ %{shift(@_)} ], @_);
        }
        elsif(ref $_[0] eq 'ARRAY')
        {
          %args = (query => shift, @_);
        }
      }
      else { %args = @_ }

      if(delete $args{'from_cache'})
      {
        if(keys %args)
        {
          Carp::croak "Additional parameters not allowed in call to ",
                      "$name() with from_cache parameter";
        }

        if(defined $self->{$cache_key})
        {
          return wantarray ? @{$self->{$cache_key}} : $self->{$cache_key};
        }
      }

      my %join_map_to_self;

      while(my($map_column, $self_method) = each(%map_column_to_self_method))
      {
        $join_map_to_self{$map_column} = $self->$self_method();

        # Comment this out to allow null keys
        unless(defined $join_map_to_self{$map_column})
        {
          keys(%map_column_to_self_method); # reset iterator
          $self->error("Could not fetch indirect objects via $name() - the " .
                       "$self_method attribute is undefined");
          return;
        }
      }

      my $objs;

      my $cache = delete $args{'cache'};

      # Merge query args
      my @query = (%join_map_to_self, @$query_args, @{delete $args{'query'} || []});

      # Merge the rest of the arguments
      foreach my $param (keys %args)
      {
        if(exists $mgr_args->{$param})
        {
          my $ref = ref $args{$param};

          if($ref eq 'ARRAY')
          {
            unshift(@{$args{$param}}, ref $mgr_args->{$param} ? 
                    @{$mgr_args->{$param}} :  $mgr_args->{$param});
          }
          elsif($ref eq 'HASH')
          {
            while(my($k, $v) = each(%{$mgr_args->{$param}}))
            {
              $args{$param}{$k} = $v  unless(exists $args{$param}{$k});
            }
          }
        }
      }

      while(my($k, $v) = each(%$mgr_args))
      {
        $args{$k} = $v  unless(exists $args{$k});
      }

      my $error;

      TRY:
      {
        local $@;

        eval
        {
          if($share_db)
          {
            $objs =
              $map_manager->$map_method(query => \@query,
                                        require_objects => $require_objects,
                                        %args, db => $self->db);
          }
          else
          {
            $objs = 
              $map_manager->$map_method(query => \@query,
                                        require_objects => $require_objects,
                                        db => $self->db, share_db => 0,
                                        %args);
          }
        };

        $error = $@;
      }

      if($error || !$objs)
      {
        my $msg = $error || $map_manager->error;
        $self->error(ref $msg ? $msg : "Could not find $foreign_class objects - $msg");
        $self->meta->handle_error($self);
        return wantarray ? () : $objs;
      }

      if($map_record_method)
      {
        $objs =
        [
          map 
          {
            my $map_rec = $_;
            my $o = $map_rec->$map_to_method();

            # This should work too, if we want to keep the ref
            #if(refaddr($map_rec->{$map_to}) == refaddr($o))
            #{
            #  weaken($map_rec->{$map_to} = $o);
            #}

            # Ditch the map record's reference to the foreign object
            delete $map_rec->{$map_to};
            $o->$map_record_method($map_rec); 
            $o;
          }
          @$objs
        ];
      }
      elsif($is_iterator)
      {
        my $next_code = $objs->_next_code;

        my $post_proc = sub
        {
          my($self, $map_object) = @_;
          return $map_object->$map_to();
        };

        $objs->_next_code
        (
          sub
          {
            my $self = shift;
            my $object = $next_code->($self, @_);
            return $object  unless($object);
            return $post_proc->($self, $object);
          }
        );

        return $objs;      
      }
      else
      {
        $objs =
        [
          map 
          {
            # This should work too, if we want to keep the ref
            #my $map_rec = $_;
            #my $o = $map_rec->$map_to_method();
            #
            #if(refaddr($map_rec->{$map_to}) == refaddr($o))
            #{
            #  weaken($map_rec->{$map_to} = $o);
            #}
            #
            #$o;

            # Ditch the map record's reference to the foreign object
            my $o = $_->$map_to_method();
            $_->$map_to_method(undef);
            $o;
          }
          @$objs 
        ];
      }

      $self->{$cache_key} = $objs  if($cache);

      return wantarray ? @$objs: $objs;
    };
  }
  elsif($interface eq 'count')
  {
    my $cache_key = PRIVATE_PREFIX . '_' . $name;

    $methods{$name} = sub
    {
      my($self) = shift;

      my %args;

      if(my $ref = ref $_[0])
      {
        if($ref eq 'HASH')
        {
          %args = (query => [ %{shift(@_)} ], @_);
        }
        elsif(ref $_[0] eq 'ARRAY')
        {
          %args = (query => shift, @_);
        }
      }
      else { %args = @_ }

      if(delete $args{'from_cache'})
      {
        if(keys %args)
        {
          Carp::croak "Additional parameters not allowed in call to ",
                      "$name() with from_cache parameter";
        }

        if(defined $self->{$cache_key})
        {
          return wantarray ? @{$self->{$cache_key}} : $self->{$cache_key};
        }
      }

      my %join_map_to_self;

      while(my($map_column, $self_method) = each(%map_column_to_self_method))
      {
        $join_map_to_self{$map_column} = $self->$self_method();

        # Comment this out to allow null keys
        unless(defined $join_map_to_self{$map_column})
        {
          keys(%map_column_to_self_method); # reset iterator
          $self->error("Could not count indirect objects via $name() - the " .
                       "$self_method attribute is undefined");
          return;
        }
      }

      my $cache = delete $args{'cache'};

      # Merge query args
      my @query = (%join_map_to_self, @$query_args, @{delete $args{'query'} || []});

      # Merge the rest of the arguments
      foreach my $param (keys %args)
      {
        if(exists $mgr_args->{$param})
        {
          my $ref = ref $args{$param};

          if($ref eq 'ARRAY')
          {
            unshift(@{$args{$param}}, ref $mgr_args->{$param} ? 
                    @{$mgr_args->{$param}} :  $mgr_args->{$param});
          }
          elsif($ref eq 'HASH')
          {
            while(my($k, $v) = each(%{$mgr_args->{$param}}))
            {
              $args{$param}{$k} = $v  unless(exists $args{$param}{$k});
            }
          }
        }
      }

      while(my($k, $v) = each(%$mgr_args))
      {
        $args{$k} = $v  unless(exists $args{$k});
      }

      $args{'multi_many_ok'} = 1;

      my($count, $error);

      TRY:
      {
        local $@;

        eval
        {
          if($share_db)
          {
            $count =
              $map_manager->$count_method(query => \@query,
                                          require_objects => $require_objects,
                                          %$mgr_args, db => $self->db);
          }
          else
          {
            $count = 
              $map_manager->$count_method(query => \@query,
                                          require_objects => $require_objects,
                                          db => $self->db, share_db => 0,
                                          %$mgr_args);
          }
        };

        $error = $@;
      }

      if($error || !defined $count)
      {
        my $msg = $error || $map_manager->error;
        $self->error(ref $msg ? $msg : "Could not count $foreign_class objects - $msg");
        $self->meta->handle_error($self);
        return $count;
      }

      $self->{$cache_key} = $count  if($cache);

      return $count;
    };
  }
  elsif($interface eq 'get_set' || $interface eq 'get_set_load')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      if(@_)
      {      
        return $self->{$key} = undef  if(@_ == 1 && !defined $_[0]);
        $self->{$key} = __args_to_objects($self, $key, $foreign_class, \$ft_pk, \@_);
        return wantarray ? @{$self->{$key}} : $self->{$key};
      }

      if(defined $self->{$key})
      {
        return wantarray ? @{$self->{$key}} : $self->{$key};  
      }

      my %join_map_to_self;

      while(my($map_column, $self_method) = each(%map_column_to_self_method))
      {
        $join_map_to_self{$map_column} = $self->$self_method();

        # Comment this out to allow null keys
        unless(defined $join_map_to_self{$map_column})
        {
          keys(%map_column_to_self_method); # reset iterator
          $self->error("Could not fetch indirect objects via $name() - the " .
                       "$self_method attribute is undefined");
          return;
        }
      }

      my $objs;

      if($share_db)
      {
        $objs =
          $map_manager->$map_method(query => [ %join_map_to_self, @$query_args ],
                                    require_objects => $require_objects,
                                    %$mgr_args, db => $self->db);
      }
      else
      {
        $objs = 
          $map_manager->$map_method(query => [ %join_map_to_self, @$query_args ],
                                    require_objects => $require_objects,
                                    db => $self->db, share_db => 0,
                                    %$mgr_args);
      }

      unless($objs)
      {
        my $error = $map_manager->error;
        $self->error(ref $error ? $error : ("Could not load $foreign_class " .
                     "objects via map class $map_class - $error"));
        return wantarray ? () : $objs;
      }

      if($map_record_method)
      {
        $self->{$key} = 
        [
          map 
          {
            my $map_rec = $_;
            my $o = $map_rec->$map_to_method();

            # This should work too, if we want to keep the ref
            #if(refaddr($map_rec->{$map_to}) == refaddr($o))
            #{
            #  weaken($map_rec->{$map_to} = $o);
            #}

            # Ditch the map record's reference to the foreign object
            delete $map_rec->{$map_to};
            $o->$map_record_method($map_rec); 
            $o;
          }
          @$objs
        ];
      }
      else
      {
        $self->{$key} = 
        [
          map 
          {
            # This should work too, if we want to keep the ref
            #my $map_rec = $_;
            #my $o = $map_rec->$map_to_method();
            #
            #if(refaddr($map_rec->{$map_to}) == refaddr($o))
            #{
            #  weaken($map_rec->{$map_to} = $o);
            #}
            #
            #$o;

            # Ditch the map record's reference to the foreign object
            my $o = $_->$map_to_method();
            $_->$map_to_method(undef);
            $o;
          }
          @$objs 
        ];
      }

      return wantarray ? @{$self->{$key}} : $self->{$key};
    };

    if($interface eq 'get_set_load')
    {
      my $method_name = $args->{'load_method'} || 'load_' . $name;

      $methods{$method_name} = sub
      {
        return (defined shift->$name(@_)) ? 1 : 0;
      };
    }
  }
  elsif($interface eq 'get_set_now')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      if(@_)
      {
        # If loading, just assign
        if($self->{STATE_LOADING()})
        {
          return $self->{$key} = undef  if(@_ == 1 && !defined $_[0]);
          return $self->{$key} = (@_ == 1 && ref $_[0] eq 'ARRAY') ? $_[0] : [@_];
        }

        # Can't set until the object is saved
        unless($self->{STATE_IN_DB()})
        {
          Carp::croak "Can't set $name() until this object is loaded or saved";
        }

        # Set to undef resets the attr  
        if(@_ == 1 && !defined $_[0])
        {
          # Delete any pending set or add actions
          delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'set'};
          delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'};

          $self->{$key} = undef;
          return;
        }

        # Set up join conditions and map record connections
        my(%join_map_to_self,    # map column => self value
           %method_map_to_self); # map method => self value

        while(my($map_column, $self_method) = each(%map_column_to_self_method))
        {
          my $map_method = $map_meta->column_accessor_method_name($map_column);

          $method_map_to_self{$map_method} = $join_map_to_self{$map_column} = 
            $self->$self_method();

          # Comment this out to allow null keys
          unless(defined $join_map_to_self{$map_column})
          {
            keys(%map_column_to_self_method); # reset iterator
            $self->error("Could not fetch indirect objects via $name() - the " .
                         "$self_method attribute is undefined");
            return;
          }
        }

        my($db, $started_new_tx, $error);

        TRY:
        {
          local $@;

          eval
          {
            $db = $self->db;

            my $ret = $db->begin_work;

            unless(defined $ret)
            {
              die 'Could not begin transaction during call to $name() - ',
                  $db->error;
            }

            $started_new_tx = ($ret == IN_TRANSACTION) ? 0 : 1;

            # Delete any existing objects
            my $deleted = 
              $map_manager->$map_delete_method(object_class => $map_class,
                                               where => [ %join_map_to_self ],
                                               db    => $db);
            die $map_manager->error  unless(defined $deleted);

            # Save all the new objects
            my $objects = __args_to_objects($self, $key, $foreign_class, \$ft_pk, \@_);

            foreach my $object (@$objects)
            {
              # It's essential to share the db so that the code
              # below can see the delete (above) which happened in
              # the current transaction
              $object->db($db); 

              $object->{STATE_IN_DB()} = 0  if($deleted);

              # If the object is not marked as already existing in the database,
              # see if it represents an existing row.  If it does, merge the
              # existing row's column values into the object, allowing any
              # modified columns in the object to take precedence. Returns true
              # if the object represents an existing row.
              if(__check_and_merge($object))
              {
                $object->save or die $object->error;
              }
              else
              {
                $object->save or die $object->error;
              }

              # Not sharing?  Aw.
              $object->db(undef)  unless($share_db);

              my $map_record;

              # Create or retrieve map record, connected to self
              if($map_record_method)
              {
                $map_record = $object->$map_record_method();

                if($map_record)
                {
                  if($map_record->{STATE_IN_DB()})
                  {
                    foreach my $method ($map_record->meta->primary_key_column_mutator_names)
                    {
                      $map_record->$method(undef);
                    }

                    $map_record->{STATE_IN_DB()} = 0;
                  }
                }
                else
                {
                  $map_record = $map_class->new;
                }

                $map_record->init(%method_map_to_self, db => $db);
              }
              else
              {
                $map_record = $map_class->new(%method_map_to_self, db => $db);
              }

              # Connect map record to remote object
              while(my($map_method, $remote_method) = each(%map_method_to_remote_method))
              {
                $map_record->$map_method($object->$remote_method);
              }

              my $in_db = $map_record->{STATE_IN_DB()};

              # Try to load the map record if doesn't appear to exist already
              unless($in_db)
              {
                my $dbh = $map_record->dbh;

                # It's okay if this fails because the key(s) is/are undefined
                local $dbh->{'PrintError'} = 0;
                eval { $in_db = $map_record->load(speculative => 1) };

                if(my $error = $@)
                {
                  # ...but re-throw all other errors
                  unless(UNIVERSAL::isa($error, 'Rose::DB::Object::Exception') &&
                         $error->code == EXCEPTION_CODE_NO_KEY)
                  {
                    die $error;
                  }
                }
              }

              # Save the map record, if necessary
              unless($in_db)
              {
                $map_record->save or die $map_record->error;
              }
            }

            # Assign to attribute or blank the attribute, causing the objects
            # to be fetched from the db next time, depending on whether or not
            # there's a custom sort order
            $self->{$key} = defined $mgr_args->{'sort_by'} ? undef : $objects;

            if($started_new_tx)
            {
              $db->commit or die $db->error;
            }

            # Delete any pending set or add actions
            delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'set'};
            delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'};
          };

          $error = $@;
        }

        if($error)
        {
          $self->error(ref $error ? $error : "Could not set $name objects - $error");
          $db->rollback  if($db && $started_new_tx);
          $meta->handle_error($self);
          return undef;
        }

        return 1  unless(defined $self->{$key});
        return wantarray ? @{$self->{$key}} : $self->{$key};
      }

      # Return existing list of objects, if it exists
      if(defined $self->{$key})
      {
        return wantarray ? @{$self->{$key}} : $self->{$key};  
      }

      my %join_map_to_self;

      while(my($local_column, $foreign_method) = each(%map_column_to_self_method))
      {
        $join_map_to_self{$local_column} = $self->$foreign_method();

        # Comment this out to allow null keys
        unless(defined $join_map_to_self{$local_column})
        {
          keys(%map_column_to_self_method); # reset iterator
          $self->error("Could not fetch indirect objects via $name() - the " .
                       "$foreign_method attribute is undefined");
          return;
        }
      }

      my $objs;

      if($share_db)
      {
        $objs =
          $map_manager->$map_method(query        => [ %join_map_to_self, @$query_args ],
                                    require_objects => $require_objects,
                                    %$mgr_args, db => $self->db);
      }
      else
      {
        $objs = 
          $map_manager->$map_method(query        => [ %join_map_to_self, @$query_args ],
                                    require_objects => $require_objects,
                                    db => $self->db, share_db => 0,
                                    %$mgr_args);
      }

      unless($objs)
      {
        my $error = $map_manager->error;
        $self->error(ref $error ? $error : ("Could not load $foreign_class " .
                     "objects via map class $map_class - $error"));
        return wantarray ? () : $objs;
      }

      if($map_record_method)
      {
        $self->{$key} = 
        [
          map 
          {
            my $map_rec = $_;
            my $o = $map_rec->$map_to_method();

            # This should work too, if we want to keep the ref
            #if(refaddr($map_rec->{$map_to}) == refaddr($o))
            #{
            #  weaken($map_rec->{$map_to} = $o);
            #}

            # Ditch the map record's reference to the foreign object
            delete $map_rec->{$map_to};
            $o->$map_record_method($map_rec); 
            $o;
          }
          @$objs
        ];
      }
      else
      {
        $self->{$key} = 
        [
          map
          {
            # This works too, if we want to keep the ref
            #my $map_rec = $_;
            #my $o = $map_rec->$map_to_method();
            #
            #if(refaddr($map_rec->{$map_to}) == refaddr($o))
            #{
            #  weaken($map_rec->{$map_to} = $o);
            #}
            #
            #$o;

            # Ditch the map record's reference to the foreign object
            my $o = $_->$map_to_method();
            $_->$map_to_method(undef);
            $o;
          }
          @$objs
        ];
      }

      return wantarray ? @{$self->{$key}} : $self->{$key};
    };
  }
  elsif($interface eq 'get_set_on_save')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      if(@_)
      {
        # If loading, just assign
        if($self->{STATE_LOADING()})
        {
          return $self->{$key} = undef  if(@_ == 1 && !defined $_[0]);
          return $self->{$key} = (@_ == 1 && ref $_[0] eq 'ARRAY') ? $_[0] : [@_];
        }

        # Set to undef resets the attr  
        if(@_ == 1 && !defined $_[0])
        {
          # Delete any pending set or add actions
          delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'set'};
          delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'};

          $self->{$key} = undef;
          return;
        }

        # Get all the new objects
        my $objects = __args_to_objects($self, $key, $foreign_class, \$ft_pk, \@_);

        # Set the attribute
        $self->{$key} = $objects;

        my $save_code = sub
        {
          my($self, $args) = @_;

          # Set up join conditions and map record connections
          my(%join_map_to_self,    # map column => self value
             %method_map_to_self); # map method => self value

          while(my($map_column, $self_method) = each(%map_column_to_self_method))
          {
            my $map_method = $map_meta->column_accessor_method_name($map_column);

            $method_map_to_self{$map_method} = $join_map_to_self{$map_column} = 
              $self->$self_method();

            # Comment this out to allow null keys
            unless(defined $join_map_to_self{$map_column})
            {
              keys(%map_column_to_self_method); # reset iterator
              $self->error("Could not fetch indirect objects via $name() - the " .
                           "$self_method attribute is undefined");
              return;
            }
          }

          my $db = $self->db;

          # Delete any existing objects
          my $deleted = 
            $map_manager->$map_delete_method(object_class => $map_class,
                                             where => [ %join_map_to_self ],
                                             db    => $db);
          die $map_manager->error  unless(defined $deleted);

          # Save all the objects.  Use the current list, even if it's
          # different than it was when the "set on save" was called.
          foreach my $object (@{$self->{$key} || []})
          {
            # It's essential to share the db so that the code
            # below can see the delete (above) which happened in
            # the current transaction
            $object->db($db); 

            #$object->{STATE_IN_DB()} = 0  if($deleted);

            # If the object is not marked as already existing in the database,
            # see if it represents an existing row.  If it does, merge the
            # existing row's column values into the object, allowing any
            # modified columns in the object to take precedence. Returns true
            # if the object represents an existing row.
            if(__check_and_merge($object))
            {
              $object->save(%$args, changes_only => 1) or die $object->error;
            }
            else
            {
              $object->save(%$args) or die $object->error;
            }

            # Not sharing?  Aw.
            $object->db(undef)  unless($share_db);

            my $map_record;

            # Create or retrieve map record, connected to self
            if($map_record_method)
            {
              $map_record = $object->$map_record_method();

              if($map_record)
              {
                if($map_record->{STATE_IN_DB()})
                {
                  foreach my $method ($map_record->meta->primary_key_column_mutator_names)
                  {
                    $map_record->$method(undef);
                  }

                  $map_record->{STATE_IN_DB()} = 0;
                }
              }
              else
              {
                $map_record = $map_class->new;
              }

              $map_record->init(%method_map_to_self, db => $db);
            }
            else
            {
              $map_record = $map_class->new(%method_map_to_self, db => $db);
            }

            # Connect map record to remote object
            while(my($map_method, $remote_method) = each(%map_method_to_remote_method))
            {
              $map_record->$map_method($object->$remote_method);
            }

            my $in_db = $map_record->{STATE_IN_DB()};

            # Try to load the map record if doesn't appear to exist already
            unless($in_db)
            {
              my $dbh = $map_record->dbh;

              my $error;

              TRY:
              {
                local $@;
                # It's okay if this fails because the key(s) is/are undefined
                local $dbh->{'PrintError'} = 0;
                eval { $in_db = $map_record->load(speculative => 1) };
                $error = $@;
              }

              if($error)
              {
                # ...but re-throw all other errors
                unless(UNIVERSAL::isa($error, 'Rose::DB::Object::Exception') &&
                       $error->code == EXCEPTION_CODE_NO_KEY)
                {
                  die $error;
                }
              }
            }

            # Save the map record, if necessary
            unless($in_db)
            {
              $map_record->save(%$args) or die $map_record->error;
            }
          }

          # Forget about any adds if we just set the list
          if(defined $self->{$key})
          {
            # Set to undef instead of deleting because this code ref
            # will be called while iterating over this very hash.
            $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'} = undef;
          }

          # Blank the attribute, causing the objects to be fetched from
          # the db next time, if there's a custom sort order or if
          # the list is defined but empty
          $self->{$key} = undef  if(defined $mgr_args->{'sort_by'} ||
                                    (defined $self->{$key} && !@{$self->{$key}}));

          return 1;
        };

        $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'set'} = $save_code;

        return 1  unless(defined $self->{$key});
        return wantarray ? @{$self->{$key}} : $self->{$key};
      }

      # Return existing list of objects, if it exists
      if(defined $self->{$key})
      {
        return wantarray ? @{$self->{$key}} : $self->{$key};  
      }

      my %join_map_to_self;

      while(my($local_column, $foreign_method) = each(%map_column_to_self_method))
      {
        $join_map_to_self{$local_column} = $self->$foreign_method();

        # Comment this out to allow null keys
        unless(defined $join_map_to_self{$local_column})
        {
          keys(%map_column_to_self_method); # reset iterator
          $self->error("Could not fetch indirect objects via $name() - the " .
                       "$foreign_method attribute is undefined");
          return;
        }
      }

      my $objs;

      if($share_db)
      {
        $objs =
          $map_manager->$map_method(query        => [ %join_map_to_self, @$query_args ],
                                    require_objects => $require_objects,
                                    %$mgr_args, db => $self->db);
      }
      else
      {
        $objs = 
          $map_manager->$map_method(query        => [ %join_map_to_self, @$query_args ],
                                    require_objects => $require_objects,
                                    db => $self->db, share_db => 0,
                                    %$mgr_args);
      }

      unless($objs)
      {
        my $error = $map_manager->error;
        $self->error(ref $error ? $error : ("Could not load $foreign_class " .
                     "objects via map class $map_class - $error"));
        return wantarray ? () : $objs;
      }

      if($map_record_method)
      {
        $self->{$key} = 
        [
          map 
          {
            my $map_rec = $_;
            my $o = $map_rec->$map_to_method();

            # This should work too, if we want to keep the ref
            #if(refaddr($map_rec->{$map_to}) == refaddr($o))
            #{
            #  weaken($map_rec->{$map_to} = $o);
            #}

            # Ditch the map record's reference to the foreign object
            delete $map_rec->{$map_to};
            $o->$map_record_method($map_rec); 
            $o;
          }
          @$objs
        ];
      }
      else
      {
        $self->{$key} = 
        [
          map
          {
            # This works too, if we want to keep the ref
            #my $map_rec = $_;
            #my $o = $map_rec->$map_to_method();
            #
            #if(refaddr($map_rec->{$map_to}) == refaddr($o))
            #{
            #  weaken($map_rec->{$map_to} = $o);
            #}
            #
            #$o;

            # Ditch the map record's reference to the foreign object
            my $o = $_->$map_to_method();
            $_->$map_to_method(undef);
            $o;
          }
          @$objs
        ];
      }

      return wantarray ? @{$self->{$key}} : $self->{$key};
    };
  }
  elsif($interface eq 'add_now')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      unless(@_)
      {
        $self->error("No $name to add");
        return wantarray ? () : 0;
      }

      # Can't set until the object is saved
      unless($self->{STATE_IN_DB()})
      {
        Carp::croak "Can't add $name until this object is loaded or saved";
      }

      if($self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'set'})
      {
        Carp::croak "Cannot add objects via the 'add_now' method $name() ",
                    "because the list of objects is already going to be ".
                    "set to something else on save.  Use the 'add_on_save' ",
                    "method type instead.";
      }

      # Set up join conditions and map record connections
      my(%join_map_to_self,    # map column => self value
         %method_map_to_self); # map method => self value

      while(my($map_column, $self_method) = each(%map_column_to_self_method))
      {
        my $map_method = $map_meta->column_accessor_method_name($map_column);

        $method_map_to_self{$map_method} = $join_map_to_self{$map_column} = 
          $self->$self_method();

        # Comment this out to allow null keys
        unless(defined $join_map_to_self{$map_column})
        {
          keys(%map_column_to_self_method); # reset iterator
          $self->error("Could not fetch indirect objects via $name() - the " .
                       "$self_method attribute is undefined");
          return;
        }
      }

      my $objects = __args_to_objects($self, $key, $foreign_class, \$ft_pk, \@_);

      my($db, $started_new_tx, $error);

      TRY:
      {
        local $@;

        eval
        {
          $db = $self->db;

          my $ret = $db->begin_work;

          unless(defined $ret)
          {
            die 'Could not begin transaction during call to $name() - ',
                $db->error;
          }

          $started_new_tx = ($ret == IN_TRANSACTION) ? 0 : 1;

          # Add all the new objects
          foreach my $object (@$objects)
          {
            # It's essential to share the db so that the code
            # below can see the delete (above) which happened in
            # the current transaction
            $object->db($db); 

            # If the object is not marked as already existing in the database,
            # see if it represents an existing row.  If it does, merge the
            # existing row's column values into the object, allowing any
            # modified columns in the object to take precedence. Returns true
            # if the object represents an existing row.
            if(__check_and_merge($object))
            {
              $object->save(changes_only => 1) or die $object->error;
            }
            else
            {
              $object->save or die $object->error;
            }

            # Not sharing?  Aw.
            $object->db(undef)  unless($share_db);

            # Create map record, connected to self
            my $map_record = $map_class->new(%method_map_to_self, db => $db);

            # Connect map record to remote object
            while(my($map_method, $remote_method) = each(%map_method_to_remote_method))
            {
              $map_record->$map_method($object->$remote_method);
            }

            my $in_db = $map_record->{STATE_IN_DB()};

            # Try to load the map record if doesn't appear to exist already
            unless($in_db)
            {
              my $dbh = $map_record->dbh;

              # It's okay if this fails because the key(s) is/are undefined
              local $dbh->{'PrintError'} = 0;
              eval { $in_db = $map_record->load(speculative => 1) };

              if(my $error = $@)
              {
                # ...but re-throw all other errors
                unless(UNIVERSAL::isa($error, 'Rose::DB::Object::Exception') &&
                       $error->code == EXCEPTION_CODE_NO_KEY)
                {
                  die $error;
                }
              }
            }

            # Save the map record, if necessary
            unless($in_db)
            {
              $map_record->save or die $map_record->error;
            }
          }

          # Clear the existing list, forcing it to be reloaded next time
          # it's asked for
          $self->{$key} = undef;

          if($started_new_tx)
          {
            $db->commit or die $db->error;
          }

          # Delete any pending set or add actions
          delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'set'};
          delete $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'};
        };

        $error = $@;
      }

      if($error)
      {
        $self->error(ref $error ? $error : "Could not add $name objects - $error");
        $db->rollback  if($db && $started_new_tx);
        $meta->handle_error($self);
        return;
      }

      return @$objects;
    };
  }
  elsif($interface eq 'add_on_save')
  {
    $methods{$name} = sub
    {
      my($self) = shift;

      unless(@_)
      {
        $self->error("No $name to add");
        return wantarray ? () : 0;
      }

      # Get all the new objects
      my $objects = __args_to_objects($self, $key, $foreign_class, \$ft_pk, \@_);

      # Add the objects to the list, if it's defined
      if(defined $self->{$key})
      {
        push(@{$self->{$key}}, @$objects);
      }

      my $add_code = sub
      {
        my($self, $args) = @_;

        # Set up join conditions and map record connections
        my(%join_map_to_self,    # map column => self value
           %method_map_to_self); # map method => self value

        while(my($map_column, $self_method) = each(%map_column_to_self_method))
        {
          my $map_method = $map_meta->column_accessor_method_name($map_column);

          $method_map_to_self{$map_method} = $join_map_to_self{$map_column} = 
            $self->$self_method();

          # Comment this out to allow null keys
          unless(defined $join_map_to_self{$map_column})
          {
            keys(%map_column_to_self_method); # reset iterator
            $self->error("Could not fetch indirect objects via $name() - the " .
                         "$self_method attribute is undefined");
            return;
          }
        }

        my $db = $self->db;

        # Add all the objects.
        foreach my $object (@{$self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'}{'objects'}})
        {
          # It's essential to share the db so that the code
          # below can see the delete (above) which happened in
          # the current transaction
          $object->db($db); 

          # If the object is not marked as already existing in the database,
          # see if it represents an existing row.  If it does, merge the
          # existing row's column values into the object, allowing any
          # modified columns in the object to take precedence. Returns true
          # if the object represents an existing row.
          if(__check_and_merge($object))
          {
            $object->save(%$args, changes_only => 1) or die $object->error;
          }
          else
          {
            $object->save(%$args) or die $object->error;
          }

          # Not sharing?  Aw.
          $object->db(undef)  unless($share_db);

          # Create map record, connected to self
          my $map_record = $map_class->new(%method_map_to_self, db => $db);

          # Connect map record to remote object
          while(my($map_method, $remote_method) = each(%map_method_to_remote_method))
          {
            $map_record->$map_method($object->$remote_method);
          }

          my $in_db = $map_record->{STATE_IN_DB()};

          # Try to load the map record if doesn't appear to exist already
          unless($in_db)
          {
            my $dbh = $map_record->dbh;


            my $error;

            TRY:
            {
              local $@;

              # It's okay if this fails because the key(s) is/are undefined...
              local $dbh->{'PrintError'} = 0;

              eval
              {
                if($map_record->load(speculative => 1))
                {
                  # (Re)connect map record to self
                  $map_record->init(%method_map_to_self);

                  # (Re)connect map record to remote object
                  while(my($map_method, $remote_method) = each(%map_method_to_remote_method))
                  {
                    $map_record->$map_method($object->$remote_method);
                  }
                }
              };

              $error = $@;
            }

            if($error)
            {
              # ...but re-throw all other errors
              unless(UNIVERSAL::isa($error, 'Rose::DB::Object::Exception') &&
                     $error->code == EXCEPTION_CODE_NO_KEY)
              {
                die $error;
              }
            }
          }

          # Save changes to map record
          $map_record->save(changes_only => 1) or die $map_record->error;
        }

        # Blank the attribute, causing the objects to be fetched from
        # the db next time, if there's a custom sort order or if
        # the list is defined but empty
        $self->{$key} = undef  if(defined $mgr_args->{'sort_by'} ||
                                  (defined $self->{$key} && !@{$self->{$key}}));

        return 1;
      };

      my $stash = $self->{ON_SAVE_ATTR_NAME()}{'post'}{'rel'}{$rel_name}{'add'} ||= {};

      push(@{$stash->{'objects'}}, @$objects);
      $stash->{'code'} = $add_code;

      return @$objects;
    };
  }
  else { Carp::croak "Unknown interface: $interface" }

  return \%methods;
}

sub __args_to_objects
{
  my($self, $name, $object_class, $pk_name, $args) = @_;

  if(@$args == 1 && ref $args->[0] eq 'ARRAY')
  {
    $args = $args->[0];
  }

  unless(defined $$pk_name)
  {
    my @cols = $object_class->meta->primary_key_column_names;

    if(@cols == 1)
    {
      $$pk_name = $cols[0];
    }
    else
    {
      $$pk_name = 0;
    }
  }

  my @objects;

  foreach my $arg (@$args)
  {
    # Already an object
    if(UNIVERSAL::isa($arg, $object_class))
    {
      push(@objects, $arg);
    }
    else
    {  
      my $ref = ref $arg;

      if($ref eq 'HASH')
      {
        push(@objects, $object_class->new(%$arg));
      }
      elsif(!$ref && $pk_name)
      {
        push(@objects, $object_class->new($$pk_name => $arg));
      }
      else
      {
        Carp::croak "Invalid $name argument: $arg";
      }
    }
  }

  return \@objects;
}

sub __args_to_object
{
  my($self, $name, $object_class, $pk_name, $args) = @_;

  unless(defined $$pk_name)
  {
    my @cols = $object_class->meta->primary_key_column_names;

    if(@cols == 1)
    {
      $$pk_name = $cols[0];
    }
    else
    {
      $$pk_name = 0;
    }
  }

  if(@$args == 1)
  {
    my $arg = $args->[0];

    # Already an object
    if(UNIVERSAL::isa($arg, $object_class))
    {
      return $arg;
    }
    elsif(ref $arg eq 'HASH')
    {
      return $object_class->new(%$arg);
    }
    elsif($pk_name)
    {
      return $object_class->new($$pk_name => $arg);
    }
    else
    {
      Carp::croak "Invalid $name argument: $arg";
    }
  }
  elsif(@$args % 2 == 0)
  {
    return $object_class->new(@$args);
  }

  Carp::croak "Invalid $name argument: @$args";
}

# If an object is not marked as already existing in the database, see if it
# represents an existing row.  If it does, merge the existing row's column
# values into the object, allowing any modified columns in the object to
# take precedence.  Returns true if the object represents an existing row.
sub __check_and_merge
{
  my($object) = shift;

  # Attempt to load the object if necessary
  unless($object->{STATE_IN_DB()})
  {
    my $db = $object->db;

    # Make a key-column-only clone of object to test whether
    # it represents and existing row, and if it does, to pull
    # in any missing column values.

    my $clone = ref($object)->new(db => $db);

    Rose::DB::Object::Helpers::init_with_column_value_pairs($clone, 
      Rose::DB::Object::Helpers::key_column_value_pairs($object));

    my($ret, $error);

    # Ignore any errors due to missing primary keys
    TRY:
    {
      local $@;

      eval 
      {
        local $db->dbh->{'PrintError'} = 0;
        $ret = $clone->load(speculative => 1);
      };

      $error = $@;
    }

    if($error)
    {
      # ...but re-throw all other errors
      unless(UNIVERSAL::isa($error, 'Rose::DB::Object::Exception') &&
             $error->code == EXCEPTION_CODE_NO_KEY)
      {
        die $error;
      }
    }

    # $object represents and existing row
    if($ret)
    {
      my $meta = $object->meta;

      my $pk_present = 0;

      if(%{$object->{MODIFIED_COLUMNS()} || {}})
      {
        my $pk_columns = $meta->primary_key_column_names;

        # If any primary key columns are set, presume it was used to load()
        # and mark all pk columns as not modified
        foreach my $name (@$pk_columns)
        {
          if($object->{MODIFIED_COLUMNS()}{$name})
          {
            $pk_present = 1;
            delete @{$object->{MODIFIED_COLUMNS()}}{@$pk_columns};
            last;
          }
        }
      }

      # Otherwise, mark all key columns as not modified
      unless($pk_present)
      {
        delete @{$object->{MODIFIED_COLUMNS()}}{$meta->key_column_names};
      }

      # Merge the column values from the db into the new $object.
      my %modified = map { $_ => 1 } Rose::DB::Object::Helpers::dirty_columns($object);

      # Simulate loading
      local $object->{STATE_LOADING()}  = 1;    

      # XXX: Performance cheat
      foreach my $column (@{ $object->meta->columns_ordered })
      {
        # Values from the db only overwrite unmodified columns.
        next  if($modified{$column->{'name'}}); # XXX: Performance cheat

        my $mutator_method  = $column->mutator_method_name;
        my $accessor_method = $column->accessor_method_name;

        $object->$mutator_method($clone->$accessor_method());
      }

      $object->{STATE_IN_DB()} = 1;
    }

    return $ret;
  }

  return 1;
}

1;

__END__

=head1 NAME

Rose::DB::Object::MakeMethods::Generic - Create generic object methods for Rose::DB::Object-derived objects.

=head1 SYNOPSIS

  package MyDBObject;

  our @ISA = qw(Rose::DB::Object);

  use Rose::DB::Object::MakeMethods::Generic
  (
    scalar => 
    [
      'type' => 
      {
        with_init => 1,
        check_in  => [ qw(AA AAA C D) ],
      },

      'set_type' => { hash_key => 'type' },
    ],

    character =>
    [
      code => { length => 6 }
    ],

    varchar =>
    [
      name => { length => 10 }
    ],

    boolean => 
    [
      'is_red',
      'is_happy' => { default => 1 },
    ],
  );

  sub init_type { 'C' }
  ...

  $obj = MyDBObject->new(...);

  print $obj->type; # C

  $obj->name('Bob');   # set
  $obj->set_type('C'); # set
  $obj->type('AA');    # set

  $obj->set_type; # Fatal error: no argument passed to "set" method

  $obj->name('C' x 40); # truncate on set
  print $obj->name;     # 'CCCCCCCCCC'

  $obj->code('ABC'); # pad on set
  print $obj->code;  # 'ABC   '

  eval { $obj->type('foo') }; # fatal error: invalid value

  print $obj->name, ' is ', $obj->type; # get

  $obj->is_red;         # returns undef
  $obj->is_red('true'); # returns 1 (assuming "true" a
                        # valid boolean literal according to
                        # $obj->db->parse_boolean('true'))
  $obj->is_red('');     # returns 0
  $obj->is_red;         # returns 0

  $obj->is_happy;       # returns 1

  ...

  package Person;

  our @ISA = qw(Rose::DB::Object);
  ...
  use Rose::DB::Object::MakeMethods::Generic
  (
    scalar => 'name',

    set => 
    [
      'nicknames',
      'parts' => { default => [ qw(arms legs) ] },
    ],

    # See the Rose::DB::Object::Metadata::Relationship::ManyToMany
    # documentation for a more complete example
    objects_by_map =>
    [
      friends =>
      {
        map_class    => 'FriendMap',
        manager_args => { sort_by => Friend->meta->table . '.name' },
      },
    ],
  );
  ...

  @parts = $person->parts; # ('arms', 'legs')
  $parts = $person->parts; # [ 'arms', 'legs' ]

  $person->nicknames('Jack', 'Gimpy');   # set with list
  $person->nicknames([ 'Slim', 'Gip' ]); # set with array ref

  print join(', ', map { $_->name } $person->friends);
  ...

  package Program;

  our @ISA = qw(Rose::DB::Object);
  ...
  use Rose::DB::Object::MakeMethods::Generic
  (
    objects_by_key =>
    [
      bugs => 
      {
        class => 'Bug',
        key_columns =>
        {
          # Map Program column names to Bug column names
          id      => 'program_id',
          version => 'version',
        },
        manager_args => 
        {
          sort_by => Bug->meta->table . '.date_submitted DESC',
        },
        query_args   => [ state => { ne => 'closed' } ],
      },
    ]
  );
  ...

  $prog = Program->new(id => 5, version => '3.0', ...);

  $bugs = $prog->bugs;

  # Calls (essentially):
  #
  # Rose::DB::Object::Manager->get_objects(
  #   db           => $prog->db, # share_db defaults to true
  #   object_class => 'Bug',
  #   query =>
  #   {
  #     program_id => 5,     # value of $prog->id
  #     version    => '3.0', # value of $prog->version
  #     state      => { ne => 'closed' },
  #   },
  #   sort_by => 'date_submitted DESC');

  ...

  package Product;

  our @ISA = qw(Rose::DB::Object);
  ...
  use Rose::DB::Object::MakeMethods::Generic
  (
    object_by_key =>
    [
      category => 
      {
        class => 'Category',
        key_columns =>
        {
          # Map Product column names to Category column names
          category_id => 'id',
        },
      },
    ]
  );
  ...

  $product = Product->new(id => 5, category_id => 99);

  $category = $product->category;

  # $product->category call is roughly equivalent to:
  #
  # $cat = Category->new(id => $product->category_id,
  #                      db => $prog->db);
  #
  # $ret = $cat->load;
  # return $ret  unless($ret);
  # return $cat;

=head1 DESCRIPTION

L<Rose::DB::Object::MakeMethods::Generic> is a method maker that inherits from L<Rose::Object::MakeMethods>.  See the L<Rose::Object::MakeMethods> documentation to learn about the interface.  The method types provided by this module are described below.

All method types defined by this module are designed to work with objects that are subclasses of (or otherwise conform to the interface of) L<Rose::DB::Object>.  In particular, the object is expected to have a L<db|Rose::DB::Object/db> method that returns a L<Rose::DB>-derived object.  See the L<Rose::DB::Object> documentation for more details.

=head1 METHODS TYPES

=over 4

=item B<array>

Create get/set methods for "array" attributes.   A "array" column in a database table contains an ordered list of values.  Not all databases support an "array" column type.  Check the L<Rose::DB|Rose::DB/"DATABASE SUPPORT"> documentation for your database type.

=over 4

=item Options

=over 4

=item B<default VALUE>

Determines the default value of the attribute.  The value should be a reference to an array.

=item B<hash_key NAME>

The key inside the hash-based object to use for the storage of this
attribute.  Defaults to the name of the method.

=item B<interface NAME>

Choose the interface.  The default is C<get_set>.

=back

=item Interfaces

=over 4

=item B<get_set>

Creates a get/set method for a "array" object attribute.  A "array" column in a database table contains an ordered list of values.

When setting the attribute, the value is passed through the L<parse_array|Rose::DB::Pg/parse_array> method of the object's L<db|Rose::DB::Object/db> attribute.

When saving to the database, if the attribute value is defined, the method will pass the attribute value through the L<format_array|Rose::DB::Pg/format_array> method of the object's L<db|Rose::DB::Object/db> attribute before returning it.

When not saving to the database, the method returns the array as a list in list context, or as a reference to the array in scalar context.

=item B<get>

Creates an accessor method for a "array" object attribute.  A "array" column in a database table contains an ordered list of values.

When saving to the database, if the attribute value is defined, the method will pass the attribute value through the L<format_array|Rose::DB::Pg/format_array> method of the object's L<db|Rose::DB::Object/db> attribute before returning it.

When not saving to the database, the method returns the array as a list in list context, or as a reference to the array in scalar context.

=item B<set>

Creates a mutator method for a "array" object attribute.  A "array" column in a database table contains an ordered list of values.

When setting the attribute, the value is passed through the L<parse_array|Rose::DB::Pg/parse_array> method of the object's L<db|Rose::DB::Object/db> attribute.

When saving to the database, if the attribute value is defined, the method will pass the attribute value through the L<format_array|Rose::DB::Pg/format_array> method of the object's L<db|Rose::DB::Object/db> attribute before returning it.

When not saving to the database, the method returns the array as a list in list context, or as a reference to the array in scalar context.

If called with no arguments, a fatal error will occur.

=back

=back

Example:

    package Person;

    our @ISA = qw(Rose::DB::Object);
    ...
    use Rose::DB::Object::MakeMethods::Generic
    (
      array => 
      [
        'nicknames',
        set_nicks => { interface => 'set', hash_key => 'nicknames' },
        parts     => { default => [ qw(arms legs) ] },
      ],
    );
    ...

    @parts = $person->parts; # ('arms', 'legs')
    $parts = $person->parts; # [ 'arms', 'legs' ]

    $person->nicknames('Jack', 'Gimpy');   # set with list
    $person->nicknames([ 'Slim', 'Gip' ]); # set with array ref

    $person->set_nicks('Jack', 'Gimpy');   # set with list
    $person->set_nicks([ 'Slim', 'Gip' ]); # set with array ref

=item B<bitfield>

Create get/set methods for bitfield attributes.

=over 4

=item Options

=over 4

=item B<default VALUE>

Determines the default value of the attribute.

=item B<hash_key NAME>

The key inside the hash-based object to use for the storage of this
attribute.  Defaults to the name of the method.

=item B<interface NAME>

Choose the interface.  The default is C<get_set>.

=item B<intersects NAME>

Set the name of the "intersects" method.  (See C<with_intersects> below.)  Defaults to the bitfield attribute method name with "_intersects" appended.

=item B<bits INT>

The number of bits in the bitfield.  Defaults to 32.

=item B<with_intersects BOOL>

This option is only applicable with the C<get_set> interface.

If true, create an "intersects" helper method in addition to the C<get_set> method.  The intersection method name will be the attribute method name with "_intersects" appended, or the value of the C<intersects> option, if it is passed.

The "intersects" method will return true if there is any intersection between its arguments and the value of the bitfield attribute (i.e., if L<Bit::Vector>'s L<Intersection|Bit::Vector/Intersection> method returns a value greater than zero), false (but defined) otherwise.  Its argument is passed through the L<parse_bitfield|Rose::DB/parse_bitfield> method of the object's L<db|Rose::DB::Object/db> attribute before being tested for intersection.  Returns undef if the bitfield is not defined.

=back

=item Interfaces

=over 4

=item B<get_set>

Creates a get/set method for a bitfield attribute.  When setting the attribute, the value is passed through the L<parse_bitfield|Rose::DB/parse_bitfield> method of the object's L<db|Rose::DB::Object/db> attribute before being assigned.

When saving to the database, the method will pass the attribute value through the L<format_bitfield|Rose::DB/format_bitfield> method of the object's L<db|Rose::DB::Object/db> attribute before returning it.  Otherwise, the value is returned as-is.

=item B<get>

Creates an accessor method for a bitfield attribute.  When saving to the database, the method will pass the attribute value through the L<format_bitfield|Rose::DB/format_bitfield> method of the object's L<db|Rose::DB::Object/db> attribute before returning it.  Otherwise, the value is returned as-is.

=item B<set>

Creates a mutator method for a bitfield attribute.  When setting the attribute, the value is passed through the L<parse_bitfield|Rose::DB/parse_bitfield> method of the object's L<db|Rose::DB::Object/db> attribute before being assigned.

When saving to the database, the method will pass the attribute value through the L<format_bitfield|Rose::DB/format_bitfield> method of the object's L<db|Rose::DB::Object/db> attribute before returning it.  Otherwise, the value is returned as-is.

If called with no arguments, a fatal error will occur.

=back

=back

Example:

    package MyDBObject;

    our @ISA = qw(Rose::DB::Object);

    use Rose::DB::Object::MakeMethods::Generic
    (
      bitfield => 
      [
        'flags' => { size => 32, default => 2 },
        'bits'  => { size => 16, with_intersects => 1 },
      ],
    );

    ...

    print $o->flags->to_Bin; # 00000000000000000000000000000010

    $o->bits('101');

    $o->bits_intersects('100'); # true
    $o->bits_intersects('010'); # false

=item B<boolean>

Create get/set methods for boolean attributes.

=over 4

=item Options

=over 4

=item B<default VALUE>

Determines the default value of the attribute.

=item B<hash_key NAME>

The key inside the hash-based object to use for the storage of this
attribute.  Defaults to the name of the method.

=item B<interface NAME>

Choose the interface.  The default is C<get_set>.

=back

=item Interfaces

=over 4

=item B<get_set>

Creates a get/set method for a boolean attribute.  When setting the attribute, if the value is "true" according to Perl's rules, it is compared to a list of "common" true and false values: 1, 0, 1.0 (with any number of zeros), 0.0 (with any number of zeros), t, true, f, false, yes, no.  (All are case-insensitive.)  If the value matches, then it is set to true (1) or false (0) accordingly.

If the value does not match any of those, then it is passed through the L<parse_boolean|Rose::DB/parse_boolean> method of the object's L<db|Rose::DB::Object/db> attribute.  If L<parse_boolean|Rose::DB/parse_boolean> returns true (1) or false (0), then the attribute is set accordingly.  If L<parse_boolean|Rose::DB/parse_boolean> returns undef, a fatal error will occur.  If the value is "false" according to Perl's rules, the attribute is set to zero (0).

When saving to the database, the method will pass the attribute value through the L<format_boolean|Rose::DB/format_boolean> method of the object's L<db|Rose::DB::Object/db> attribute before returning it.  Otherwise, the value is returned as-is.

=item B<get>

Creates an accessor method for a boolean attribute.  When saving to the database, the method will pass the attribute value through the L<format_boolean|Rose::DB/format_boolean> method of the object's L<db|Rose::DB::Object/db> attribute before returning it.  Otherwise, the value is returned as-is.

=item B<set>

Creates a mutator method for a boolean attribute.  When setting the attribute, if the value is "true" according to Perl's rules, it is compared to a list of "common" true and false values: 1, 0, 1.0 (with any number of zeros), 0.0 (with any number of zeros), t, true, f, false, yes, no.  (All are case-insensitive.)  If the value matches, then it is set to true (1) or false (0) accordingly.

If the value does not match any of those, then it is passed through the L<parse_boolean|Rose::DB/parse_boolean> method of the object's L<db|Rose::DB::Object/db> attribute.  If L<parse_boolean|Rose::DB/parse_boolean> returns true (1) or false (0), then the attribute is set accordingly.  If L<parse_boolean|Rose::DB/parse_boolean> returns undef, a fatal error will occur.  If the value is "false" according to Perl's rules, the attribute is set to zero (0).

If called with no arguments, a fatal error will occur.

=back

=back

Example:

    package MyDBObject;

    our @ISA = qw(Rose::DB::Object);

    use Rose::DB::Object::MakeMethods::Generic
    (
      boolean => 
      [
        'is_red',
        'is_happy'  => { default => 1 },
        'set_happy' => { interface => 'set', hash_key => 'is_happy' },
      ],
    );

    $obj->is_red;         # returns undef
    $obj->is_red('true'); # returns 1 (assuming "true" a
                          # valid boolean literal according to
                          # $obj->db->parse_boolean('true'))
    $obj->is_red('');     # returns 0
    $obj->is_red;         # returns 0

    $obj->is_happy;       # returns 1
    $obj->set_happy(0);   # returns 0
    $obj->is_happy;       # returns 0

=item B<character>

Create get/set methods for fixed-length character string attributes.

=over 4

=item Options

=over 4

=item B<check_in ARRAYREF>

A reference to an array of valid values.  When setting the attribute, if the new value is not equal (string comparison) to one of the valid values, a fatal error will occur.

=item B<default VALUE>

Determines the default value of the attribute.

=item B<hash_key NAME>

The key inside the hash-based object to use for the storage of this attribute.  Defaults to the name of the method.

=item B<init_method NAME>

The name of the method to call when initializing the value of an undefined attribute.  Defaults to the method name with the prefix C<init_> added.  This option implies C<with_init>.

=item B<interface NAME>

Choose the interface.  The default is C<get_set>.

=item B<length INT>

The number of characters in the string.  Any strings shorter than this will be padded with spaces to meet the length requirement.  If length is omitted, the string will be left unmodified.

=item B<overflow BEHAVIOR>

Determines the behavior when the value is greater than the number of characters specified by the C<length> option.  Valid values for BEHAVIOR are:

=over 4

=item B<fatal>

Throw an exception.

=item B<truncate>

Truncate the value to the correct length.

=item B<warn>

Print a warning message.

=back

=item B<with_init BOOL>

Modifies the behavior of the C<get_set> and C<get> interfaces.  If the attribute is undefined, the method specified by the C<init_method> option is called and the attribute is set to the return value of that
method.

=back

=item Interfaces

=over 4

=item B<get_set>

Creates a get/set method for a fixed-length character string attribute.  When setting, any strings longer than C<length> will be truncated, and any strings shorter will be padded with spaces to meet the length requirement.  If C<length> is omitted, the string will be left unmodified.

=item B<get>

Creates an accessor method for a fixed-length character string attribute.

=item B<set>

Creates a mutator method for a fixed-length character string attribute.  Any strings longer than C<length> will be truncated, and any strings shorter will be padded with spaces to meet the length requirement.  If C<length> is omitted, the string will be left unmodified.

=back

=back

Example:

    package MyDBObject;

    our @ISA = qw(Rose::DB::Object);

    use Rose::DB::Object::MakeMethods::Generic
    (
      character => 
      [
        'name' => { length => 3 },
      ],
    );

    ...

    $o->name('John'); # truncates on set
    print $o->name;   # 'Joh'

    $o->name('A'); # pads on set
    print $o->name;   # 'A  '

=item B<enum>

Create get/set methods for enum attributes.

=over 4

=item Options

=over 4

=item B<default VALUE>

Determines the default value of the attribute.

=item B<values ARRAYREF>

A reference to an array of the enum values.  This attribute is required.  When setting the attribute, if the new value is not equal (string comparison) to one of the enum values, a fatal error will occur.

=item B<hash_key NAME>

The key inside the hash-based object to use for the storage of this attribute.  Defaults to the name of the method.

=item B<init_method NAME>

The name of the method to call when initializing the value of an undefined attribute.  Defaults to the method name with the prefix C<init_> added.  This option implies C<with_init>.

=item B<interface NAME>

Choose the interface.  The C<get_set> interface is the default.

=item B<with_init BOOL>

Modifies the behavior of the C<get_set> and C<get> interfaces.  If the attribute is undefined, the method specified by the C<init_method> option is called and the attribute is set to the return value of that
method.

=back

=item Interfaces

=over 4

=item B<get_set>

Creates a get/set method for an enum attribute.  When called with an argument, the value of the attribute is set.  If the value is invalid, a fatal error will occur.  The current value of the attribute is returned.

=item B<get>

Creates an accessor method for an object attribute that returns the current value of the attribute.

=item B<set>

Creates a mutator method for an object attribute.  When called with an argument, the value of the attribute is set.  If the value is invalid, a fatal error will occur.  If called with no arguments, a fatal error will occur.

=back

=back

Example:

    package MyDBObject;

    our @ISA = qw(Rose::DB::Object);

    use Rose::DB::Object::MakeMethods::Generic
    (
      enum => 
      [
        type  => { values => [ qw(main aux extra) ], default => 'aux' },
        stage => { values => [ qw(new std old) ], with_init => 1 },
      ],
    );

    sub init_stage { 'new' }
    ...

    $o = MyDBObject->new(...);

    print $o->type;   # aux
    print $o->stage;  # new

    $o->type('aux');  # set
    $o->stage('old'); # set

    eval { $o->type('foo') }; # fatal error: invalid value

    print $o->type, ' is at stage ', $o->stage; # get

=item B<integer>

Create get/set methods for integer attributes.

=over 4

=item Options

=over 4

=item B<default VALUE>

Determines the default value of the attribute.

=item B<hash_key NAME>

The key inside the hash-based object to use for the storage of this attribute.  Defaults to the name of the method.

=item B<init_method NAME>

The name of the method to call when initializing the value of an undefined attribute.  Defaults to the method name with the prefix C<init_> added.  This option implies C<with_init>.

=item B<interface NAME>

Choose the interface.  The C<get_set> interface is the default.

=item B<with_init BOOL>

Modifies the behavior of the C<get_set> and C<get> interfaces.  If the attribute is undefined, the method specified by the C<init_method> option is called and the attribute is set to the return value of that method.

=back

=item Interfaces

=over 4

=item B<get_set>

Creates a get/set method for an integer object attribute.  When called with an argument, the value of the attribute is set.  The current value of the attribute is returned.

=item B<get>

Creates an accessor method for an integer object attribute that returns the current value of the attribute.

=item B<set>

Creates a mutator method for an integer object attribute.  When called with an argument, the value of the attribute is set.  If called with no arguments, a fatal error will occur.

=back

=back

Example:

    package MyDBObject;

    our @ISA = qw(Rose::DB::Object);

    use Rose::DB::Object::MakeMethods::Generic
    (
      integer => 
      [
        code => { default => 99  },
        type => { with_init => 1 }
      ],
    );

    sub init_type { 123 }
    ...

    $o = MyDBObject->new(...);

    print $o->code; # 99
    print $o->type; # 123

    $o->code(8675309); # set
    $o->type(42);      # set


=item B<objects_by_key>

Create get/set methods for an array of L<Rose::DB::Object>-derived objects fetched based on a key formed from attributes of the current object.

=over 4

=item Options

=over 4

=item B<class CLASS>

The name of the L<Rose::DB::Object>-derived class of the objects to be fetched.  This option is required.

=item B<hash_key NAME>

The key inside the hash-based object to use for the storage of the fetched objects.  Defaults to the name of the method.

=item B<key_columns HASHREF>

A reference to a hash that maps column names in the current object to those in the objects to be fetched.  This option is required.

=item B<manager_args HASHREF>

A reference to a hash of arguments passed to the C<manager_class> when fetching objects.  If C<manager_class> defaults to L<Rose::DB::Object::Manager>, the following argument is added to the C<manager_args> hash: C<object_class =E<gt> CLASS>, where CLASS is the value of the C<class> option (see above).  If C<manager_args> includes a "sort_by" argument, be sure to prefix each column name with the appropriate table name.  (See the L<synopsis|/SYNOPSIS> for examples.)

=item B<manager_class CLASS>

The name of the L<Rose::DB::Object::Manager>-derived class used to fetch the objects.  The C<manager_method> class method is called on this class.  Defaults to L<Rose::DB::Object::Manager>.

=item B<manager_method NAME>

The name of the class method to call on C<manager_class> in order to fetch the objects.  Defaults to C<get_objects>.

=item B<manager_count_method NAME>

The name of the class method to call on C<manager_class> in order to count the objects.  Defaults to C<get_objects_count>.

=item B<interface NAME>

Choose the interface.  The C<get_set> interface is the default.

=item B<relationship OBJECT>

The L<Rose::DB::Object::Metadata::Relationship> object that describes the "key" through which the "objects_by_key" are fetched.  This is required when using the "add_now", "add_on_save", and "get_set_on_save" interfaces.

=item B<share_db BOOL>

If true, the L<db|Rose::DB::Object/db> attribute of the current object is shared with all of the objects fetched.  Defaults to true.

=item B<query_args ARRAYREF>

A reference to an array of arguments added to the value of the C<query> parameter passed to the call to C<manager_class>'s C<manager_method> class method.

=back

=item Interfaces

=over 4

=item B<count>

Creates a method that will attempt to count L<Rose::DB::Object>-derived objects based on a key formed from attributes of the current object, plus any additional parameters passed to the method call.  Note that this method counts the objects I<in the database at the time of the call>.  This may be different than the number of objects attached to the current object or otherwise in memory.

Since the objects counted are partially determined by the arguments passed to the method, the count is not retained.  It is simply returned.  Each call counts the specified objects again, even if the arguments are the same as the previous call.

If the first argument is a reference to a hash or array, it is converted to a reference to an array (if necessary) and taken as the value of the C<query> parameter.  All arguments are passed on to the C<manager_class>'s C<manager_count_method> method, augmented by the key formed from attributes of the current object.  Query parameters are added to the existing contents of the C<query> parameter.  Other parameters replace existing parameters if the existing values are simple scalars, or augment existing parameters if the existing values are references to hashes or arrays.

The count may fail for several reasons.  The count will not even be attempted if any of the key attributes in the current object are undefined.  Instead, undef (in scalar context) or an empty list (in list context) will be returned.  If the call to C<manager_class>'s C<manager_count_method> method returns undef, the behavior is determined by the L<metadata object|Rose::DB::Object/meta>'s L<error_mode|Rose::DB::Object::Metadata/error_mode>.  If the mode is C<return>, that false value (in scalar context) or an empty list (in list context) is returned.

If the count succeeds, the number is returned.  (If the count finds zero objects, the count will be 0.  This is still considered success.)

=item B<find>

Creates a method that will attempt to fetch L<Rose::DB::Object>-derived objects based on a key formed from attributes of the current object, plus any additional parameters passed to the method call.  Since the objects fetched are partially determined by the arguments passed to the method, the list of objects is not retained.  It is simply returned.  Each call fetches the requested objects again, even if the arguments are the same as the previous call.

If the first argument is a reference to a hash or array, it is converted to a reference to an array (if necessary) and taken as the value of the C<query> parameter.  All arguments are passed on to the C<manager_class>'s C<manager_method> method, augmented by the key formed from attributes of the current object.  Query parameters are added to the existing contents of the C<query> parameter.  Other parameters replace existing parameters if the existing values are simple scalars, or augment existing parameters if the existing values are references to hashes or arrays.

The fetch may fail for several reasons.  The fetch will not even be attempted if any of the key attributes in the current object are undefined.  Instead, undef (in scalar context) or an empty list (in list context) will be returned.  If the call to C<manager_class>'s C<manager_method> method returns false, the behavior is determined by the L<metadata object|Rose::DB::Object/meta>'s L<error_mode|Rose::DB::Object::Metadata/error_mode>.  If the mode is C<return>, that false value (in scalar context) or an empty list (in list context) is returned.

If the fetch succeeds, a list (in list context) or a reference to the array of objects (in scalar context) is returned.  (If the fetch finds zero objects, the list or array reference will simply be empty.  This is still considered success.)

=item B<iterator>

Behaves just like B<find> but returns an L<iterator|Rose::DB::Object::Iterator> rather than an array or arrayref.

=item B<get_set>

Creates a method that will attempt to fetch L<Rose::DB::Object>-derived objects based on a key formed from attributes of the current object.

If passed a single argument of undef, the C<hash_key> used to store the objects is set to undef.  Otherwise, the argument(s) must be a list or reference to an array containing items in one or more of the following formats:

=over 4

=item * An object of type C<class>.

=item * A reference to a hash containing method name/value pairs.

=item * A single scalar primary key value.

=back

The latter two formats will be used to construct an object of type C<class>.  A single primary key value is only a valid argument format if the C<class> in question has a single-column primary key.  A hash reference argument must contain sufficient information for the object to be uniquely identified.

The list of object is assigned to C<hash_key>.  Note that these objects are B<not> added to the database.  Use the C<get_set_now> or C<get_set_on_save> interface to do that.

If called with no arguments and the hash key used to store the list of objects is defined, the list (in list context) or a reference to that array (in scalar context) of objects is returned.  Otherwise, the objects are fetched.

The fetch may fail for several reasons.  The fetch will not even be attempted if any of the key attributes in the current object are undefined.  Instead, undef (in scalar context) or an empty list (in list context) will be returned.  If the call to C<manager_class>'s C<manager_method> method returns false, the behavior is determined by the L<metadata object|Rose::DB::Object/meta>'s L<error_mode|Rose::DB::Object::Metadata/error_mode>.  If the mode is C<return>, that false value (in scalar context) or an empty list (in list context) is returned.

If the fetch succeeds, a list (in list context) or a reference to the array of objects (in scalar context) is returned.  (If the fetch finds zero objects, the list or array reference will simply be empty.  This is still considered success.)

=item B<get_set_now>

Creates a method that will attempt to fetch L<Rose::DB::Object>-derived objects based on a key formed from attributes of the current object, and will also save the objects to the database when called with arguments.  The objects do not have to already exist in the database; they will be inserted if needed.

If passed a single argument of undef, the list of objects is set to undef, causing it to be reloaded the next time the method is called with no arguments.  (Pass a reference to an empty array to cause all of the existing objects to be deleted from the database.)  Any pending C<set_on_save> or C<add_on_save> actions are discarded.

Otherwise, the argument(s) must be a list or reference to an array containing items in one or more of the following formats:

=over 4

=item * An object of type C<class>.

=item * A reference to a hash containing method name/value pairs.

=item * A single scalar primary key value.

=back

The latter two formats will be used to construct an object of type C<class>.  A single primary key value is only a valid argument format if the C<class> in question has a single-column primary key.  A hash reference argument must contain sufficient information for the object to be uniquely identified.

The list of object is assigned to C<hash_key>, the old objects are deleted from the database, and the new ones are added to the database.  Any pending C<set_on_save> or C<add_on_save> actions are discarded.

When adding each object, if the object does not already exists in the database, it will be inserted.  If the object was previously L<load|Rose::DB::Object/load>ed from or L<save|Rose::DB::Object/save>d to the database, it will be updated.  Otherwise, it will be L<load|Rose::DB::Object/load>ed.

The parent object must have been L<load|Rose::DB::Object/load>ed or L<save|Rose::DB::Object/save>d prior to setting the list of objects.  If this method is called with arguments before the object has been  L<load|Rose::DB::Object/load>ed or L<save|Rose::DB::Object/save>d, a fatal error will occur.

If called with no arguments and the hash key used to store the list of objects is defined, the list (in list context) or a reference to that array (in scalar context) of objects is returned.  Otherwise, the objects are fetched.

The fetch may fail for several reasons.  The fetch will not even be attempted if any of the key attributes in the current object are undefined.  Instead, undef (in scalar context) or an empty list (in list context) will be returned.  If the call to C<manager_class>'s C<manager_method> method returns false, the behavior is determined by the L<metadata object|Rose::DB::Object/meta>'s L<error_mode|Rose::DB::Object::Metadata/error_mode>.  If the mode is C<return>, that false value (in scalar context) or an empty list (in list context) is returned.

If the fetch succeeds, a list (in list context) or a reference to the array of objects (in scalar context) is returned.  (If the fetch finds zero objects, the list or array reference will simply be empty.  This is still considered success.)

=item B<get_set_on_save>

Creates a method that will attempt to fetch L<Rose::DB::Object>-derived objects based on a key formed from attributes of the current object, and will also save the objects to the database when the "parent" object is L<save|Rose::DB::Object/save>d.  The objects do not have to already exist in the database; they will be inserted if needed.

If passed a single argument of undef, the list of objects is set to undef, causing it to be reloaded the next time the method is called with no arguments.  (Pass a reference to an empty array to cause all of the existing objects to be deleted from the database when the parent is L<save|Rose::DB::Object/save>d.)

Otherwise, the argument(s) must be a list or reference to an array containing items in one or more of the following formats:

=over 4

=item * An object of type C<class>.

=item * A reference to a hash containing method name/value pairs.

=item * A single scalar primary key value.

=back

The latter two formats will be used to construct an object of type C<class>.  A single primary key value is only a valid argument format if the C<class> in question has a single-column primary key.  A hash reference argument must contain sufficient information for the object to be uniquely identified.

The list of object is assigned to C<hash_key>.  The old objects are scheduled to be deleted from the database and the new ones are scheduled to be added to the database when the parent is L<save|Rose::DB::Object/save>d.  Any pending C<set_on_save> or C<add_on_save> actions are discarded.

When adding each object when the parent is L<save|Rose::DB::Object/save>d, if the object does not already exists in the database, it will be inserted.  If the object was previously L<load|Rose::DB::Object/load>ed from or L<save|Rose::DB::Object/save>d to the database, it will be updated.  Otherwise, it will be L<load|Rose::DB::Object/load>ed.

If called with no arguments and the hash key used to store the list of objects is defined, the list (in list context) or a reference to that array (in scalar context) of objects is returned.  Otherwise, the objects are fetched.

The fetch may fail for several reasons.  The fetch will not even be attempted if any of the key attributes in the current object are undefined.  Instead, undef (in scalar context) or an empty list (in list context) will be returned.  If the call to C<manager_class>'s C<manager_method> method returns false, the behavior is determined by the L<metadata object|Rose::DB::Object/meta>'s L<error_mode|Rose::DB::Object::Metadata/error_mode>.  If the mode is C<return>, that false value (in scalar context) or an empty list (in list context) is returned.

If the fetch succeeds, a list (in list context) or a reference to the array of objects (in scalar context) is returned.  (If the fetch finds zero objects, the list or array reference will simply be empty.  This is still considered success.)

=item B<add_now>

Creates a method that will add to a list of L<Rose::DB::Object>-derived objects that are related to the current object by a key formed from attributes of the current object.  The objects do not have to already exist in the database; they will be inserted if needed.

This method returns the list of objects added when called in list context, and the number of objects added when called in scalar context.  If one or more objects could not be added, undef (in scalar context) or an empty list (in list context) is returned and the parent object's L<error|Rose::DB::Object/error> attribute is set.

If passed an empty list, the method does nothing and the parent object's L<error|Rose::DB::Object/error> attribute is set.

If passed any arguments, the parent object must have been L<load|Rose::DB::Object/load>ed or L<save|Rose::DB::Object/save>d prior to adding to the list of objects.  If this method is called with a non-empty list as an argument before the parent object has been  L<load|Rose::DB::Object/load>ed or L<save|Rose::DB::Object/save>d, a fatal error will occur.

The argument(s) must be a list or reference to an array containing items in one or more of the following formats:

=over 4

=item * An object of type C<class>.

=item * A reference to a hash containing method name/value pairs.

=item * A single scalar primary key value.

=back

The latter two formats will be used to construct an object of type C<class>.  A single primary key value is only a valid argument format if the C<class> in question has a single-column primary key.  A hash reference argument must contain sufficient information for the object to be uniquely identified.

These objects are linked to the parent object (by setting the appropriate key attributes) and then added to the database.

When adding each object, if the object does not already exists in the database, it will be inserted.  If the object was previously L<load|Rose::DB::Object/load>ed from or L<save|Rose::DB::Object/save>d to the database, it will be updated.  Otherwise, it will be L<load|Rose::DB::Object/load>ed.

The parent object's list of related objects is then set to undef, causing the related objects to be reloaded from the database the next time they're needed.

=item B<add_on_save>

Creates a method that will add to a list of L<Rose::DB::Object>-derived objects that are related to the current object by a key formed from attributes of the current object.  The objects will be added to the database when the parent object is L<save|Rose::DB::Object/save>d.  The objects do not have to already exist in the database; they will be inserted if needed.

This method returns the list of objects to be added when called in list context, and the number of items to be added when called in scalar context.

If passed an empty list, the method does nothing and the parent object's L<error|Rose::DB::Object/error> attribute is set.

Otherwise, the argument(s) must be a list or reference to an array containing items in one or more of the following formats:

=over 4

=item * An object of type C<class>.

=item * A reference to a hash containing method name/value pairs.

=item * A single scalar primary key value.

=back

The latter two formats will be used to construct an object of type C<class>.  A single primary key value is only a valid argument format if the C<class> in question has a single-column primary key.  A hash reference argument must contain sufficient information for the object to be uniquely identified.

These objects are linked to the parent object (by setting the appropriate key attributes, whether or not they're defined in the parent object) and are scheduled to be added to the database when the parent object is L<save|Rose::DB::Object/save>d.  They are also added to the parent object's current list of related objects, if the list is defined at the time of the call.

When adding each object when the parent is L<save|Rose::DB::Object/save>d, if the object does not already exists in the database, it will be inserted.  If the object was previously L<load|Rose::DB::Object/load>ed from or L<save|Rose::DB::Object/save>d to the database, it will be updated.  Otherwise, it will be L<load|Rose::DB::Object/load>ed.

=back

=back

Example setup:

    # CLASS     DB TABLE
    # -------   --------
    # Program   programs
    # Bug       bugs

    package Program;

    our @ISA = qw(Rose::DB::Object);
    ...
    # You will almost never call the method-maker directly
    # like this.  See the Rose::DB::Object::Metadata docs
    # for examples of more common usage.
    use Rose::DB::Object::MakeMethods::Generic
    (
      objects_by_key =>
      [
        find_bugs => 
        {
          interface => 'find',
          class     => 'Bug',
          key_columns =>
          {
            # Map Program column names to Bug column names
            id      => 'program_id',
            version => 'version',
          },
          manager_args => { sort_by => 'date_submitted DESC' },
        },

        bugs => 
        {
          interface => '...', # get_set, get_set_now, get_set_on_save
          class     => 'Bug',
          key_columns =>
          {
            # Map Program column names to Bug column names
            id      => 'program_id',
            version => 'version',
          },
          manager_args => { sort_by => 'date_submitted DESC' },
          query_args   => { state => { ne => 'closed' } },
        },

        add_bugs => 
        {
          interface => '...', # add_now or add_on_save
          class     => 'Bug',
          key_columns =>
          {
            # Map Program column names to Bug column names
            id      => 'program_id',
            version => 'version',
          },
          manager_args => { sort_by => 'date_submitted DESC' },
          query_args   => { state => { ne => 'closed' } },
        },
      ]
    );
    ...

Example - find interface:

    # Read from the programs table
    $prog = Program->new(id => 5)->load;

    # Read from the bugs table
    $bugs = $prog->find_bugs;

    # Calls (essentially):
    #
    # Rose::DB::Object::Manager->get_objects(
    #   db           => $prog->db, # share_db defaults to true
    #   object_class => 'Bug',
    #   query =>
    #   [
    #     program_id => 5,     # value of $prog->id
    #     version    => '3.0', # value of $prog->version
    #   ],
    #   sort_by => 'date_submitted DESC');

    # Augment query
    $bugs = $prog->find_bugs({ state => 'open' });

    # Calls (essentially):
    #
    # Rose::DB::Object::Manager->get_objects(
    #   db           => $prog->db, # share_db defaults to true
    #   object_class => 'Bug',
    #   query =>
    #   [
    #     program_id => 5,     # value of $prog->id
    #     version    => '3.0', # value of $prog->version
    #     state      => 'open',
    #   ],
    #   sort_by => 'date_submitted DESC');
    ...

    # Augment query and replace sort_by value
    $bugs = $prog->find_bugs(query   => [ state => 'defunct' ], 
                             sort_by => 'name');

    # Calls (essentially):
    #
    # Rose::DB::Object::Manager->get_objects(
    #   db           => $prog->db, # share_db defaults to true
    #   object_class => 'Bug',
    #   query =>
    #   [
    #     program_id => 5,     # value of $prog->id
    #     version    => '3.0', # value of $prog->version
    #     state      => 'defunct',
    #   ],
    #   sort_by => 'name');
    ...

Example - get_set interface:

    # Read from the programs table
    $prog = Program->new(id => 5)->load;

    # Read from the bugs table
    $bugs = $prog->bugs;

    # Calls (essentially):
    #
    # Rose::DB::Object::Manager->get_objects(
    #   db           => $prog->db, # share_db defaults to true
    #   object_class => 'Bug',
    #   query =>
    #   [
    #     program_id => 5,     # value of $prog->id
    #     version    => '3.0', # value of $prog->version
    #     state      => { ne => 'closed' },
    #   ],
    #   sort_by => 'date_submitted DESC');
    ...
    $prog->version($new_version); # Does not hit the db
    $prog->bugs(@new_bugs);       # Does not hit the db

    # @new_bugs can contain any mix of these types:
    #
    # @new_bugs =
    # (
    #   123,                 # primary key value
    #   { id => 456 },       # method name/value pairs
    #   Bug->new(id => 789), # object
    # );

    # Write to the programs table only.  The bugs table is not
    # updated. See the get_set_now and get_set_on_save method
    # types for ways to write to the bugs table.
    $prog->save;

Example - get_set_now interface:

    # Read from the programs table
    $prog = Program->new(id => 5)->load;

    # Read from the bugs table
    $bugs = $prog->bugs;

    $prog->name($new_name); # Does not hit the db

    # Writes to the bugs table, deleting existing bugs and
    # replacing them with @new_bugs (which must be an array
    # of Bug objects, either existing or new)
    $prog->bugs(@new_bugs); 

    # @new_bugs can contain any mix of these types:
    #
    # @new_bugs =
    # (
    #   123,                 # primary key value
    #   { id => 456 },       # method name/value pairs
    #   Bug->new(id => 789), # object
    # );

    # Write to the programs table
    $prog->save;

Example - get_set_on_save interface:

    # Read from the programs table
    $prog = Program->new(id => 5)->load;

    # Read from the bugs table
    $bugs = $prog->bugs;

    $prog->name($new_name); # Does not hit the db
    $prog->bugs(@new_bugs); # Does not hit the db

    # @new_bugs can contain any mix of these types:
    #
    # @new_bugs =
    # (
    #   123,                 # primary key value
    #   { id => 456 },       # method name/value pairs
    #   Bug->new(id => 789), # object
    # );

    # Write to the programs table and the bugs table, deleting any
    # existing bugs and replacing them with @new_bugs (which must be
    # an array of Bug objects, either existing or new)
    $prog->save;

Example - add_now interface:

    # Read from the programs table
    $prog = Program->new(id => 5)->load;

    # Read from the bugs table
    $bugs = $prog->bugs;

    $prog->name($new_name); # Does not hit the db

    # Writes to the bugs table, adding @new_bugs to the current
    # list of bugs for this program
    $prog->add_bugs(@new_bugs);

    # @new_bugs can contain any mix of these types:
    #
    # @new_bugs =
    # (
    #   123,                 # primary key value
    #   { id => 456 },       # method name/value pairs
    #   Bug->new(id => 789), # object
    # );

    # Read from the bugs table, getting the full list of bugs, 
    # including the ones that were added above.
    $bugs = $prog->bugs;

    # Write to the programs table only
    $prog->save;

Example - add_on_save interface:

    # Read from the programs table
    $prog = Program->new(id => 5)->load;

    # Read from the bugs table
    $bugs = $prog->bugs;

    $prog->name($new_name);      # Does not hit the db
    $prog->add_bugs(@new_bugs);  # Does not hit the db
    $prog->add_bugs(@more_bugs); # Does not hit the db

    # @new_bugs and @more_bugs can contain any mix of these types:
    #
    # @new_bugs =
    # (
    #   123,                 # primary key value
    #   { id => 456 },       # method name/value pairs
    #   Bug->new(id => 789), # object
    # );

    # Write to the programs table and the bugs table, adding
    # @new_bugs to the current list of bugs for this program
    $prog->save;

=item B<objects_by_map>

Create methods that fetch L<Rose::DB::Object>-derived objects via an intermediate L<Rose::DB::Object>-derived class that maps between two other L<Rose::DB::Object>-derived classes.  See the L<Rose::DB::Object::Metadata::Relationship::ManyToMany> documentation for a more complete example of this type of method in action.

=over 4

=item Options

=over 4

=item B<hash_key NAME>

The key inside the hash-based object to use for the storage of the fetched objects.  Defaults to the name of the method.

=item B<interface NAME>

Choose the interface.  The C<get_set> interface is the default.

=item B<manager_args HASHREF>

A reference to a hash of arguments passed to the C<manager_class> when fetching objects.  If C<manager_args> includes a "sort_by" argument, be sure to prefix each column name with the appropriate table name.  (See the L<synopsis|/SYNOPSIS> for examples.)

=item B<manager_class CLASS>

The name of the L<Rose::DB::Object::Manager>-derived class that the C<map_class> will use to fetch records.  Defaults to L<Rose::DB::Object::Manager>.

=item B<manager_method NAME>

The name of the class method to call on C<manager_class> in order to fetch the objects.  Defaults to C<get_objects>.

=item B<manager_count_method NAME>

The name of the class method to call on C<manager_class> in order to count the objects.  Defaults to C<get_objects_count>.

=item B<map_class CLASS>

The name of the L<Rose::DB::Object>-derived class that maps between the other two L<Rose::DB::Object>-derived classes.  This class must have a foreign key and/or "many to one" relationship for each of the two tables that it maps between.

=item B<map_from NAME>

The name of the "many to one" relationship or foreign key in C<map_class> that points to the object of the class that this relationship exists in.  Setting this value is only necessary if the C<map_class> has more than one foreign key or "many to one" relationship that points to one of the classes that it maps between.

=item B<map_to NAME>

The name of the "many to one" relationship or foreign key in C<map_class> that points to the "foreign" object to be fetched.  Setting this value is only necessary if the C<map_class> has more than one foreign key or "many to one" relationship that points to one of the classes that it maps between.

=item B<relationship OBJECT>

The L<Rose::DB::Object::Metadata::Relationship> object that describes the "key" through which the "objects_by_key" are fetched.  This option is required.

=item B<share_db BOOL>

If true, the L<db|Rose::DB::Object/db> attribute of the current object is shared with all of the objects fetched.  Defaults to true.

=item B<query_args ARRAYREF>

A reference to an array of arguments added to the value of the C<query> parameter passed to the call to C<manager_class>'s C<manager_method> class method.

=back

=item Interfaces

=over 4

=item B<count>

Creates a method that will attempt to count L<Rose::DB::Object>-derived objects that are related to the current object through the C<map_class>, plus any additional parameters passed to the method call.  Note that this method counts the objects I<in the database at the time of the call>.  This may be different than the number of objects attached to the current object or otherwise in memory.

Since the objects counted are partially determined by the arguments passed to the method, the count is not retained.  It is simply returned.  Each call counts the specified objects again, even if the arguments are the same as the previous call.

If the first argument is a reference to a hash or array, it is converted to a reference to an array (if necessary) and taken as the value of the C<query> parameter.  All arguments are passed on to the C<manager_class>'s C<manager_count_method> method, augmented by the mapping to the current object.  Query parameters are added to the existing contents of the C<query> parameter.  Other parameters replace existing parameters if the existing values are simple scalars, or augment existing parameters if the existing values are references to hashes or arrays.

The count may fail for several reasons.  The count will not even be attempted if any of the key attributes in the current object are undefined.  Instead, undef (in scalar context) or an empty list (in list context) will be returned.  If the call to C<manager_class>'s C<manager_count_method> method returns undef, the behavior is determined by the L<metadata object|Rose::DB::Object/meta>'s L<error_mode|Rose::DB::Object::Metadata/error_mode>.  If the mode is C<return>, that false value (in scalar context) or an empty list (in list context) is returned.

If the count succeeds, the number is returned.  (If the count finds zero objects, the count will be 0.  This is still considered success.)

=item B<find>

Creates a method that will attempt to fetch L<Rose::DB::Object>-derived that are related to the current object through the C<map_class>, plus any additional parameters passed to the method call.  Since the objects fetched are partially determined by the arguments passed to the method, the list of objects is not retained.  It is simply returned.  Each call fetches the requested objects again, even if the arguments are the same as the previous call.

If the first argument is a reference to a hash or array, it is converted to a reference to an array (if necessary) and taken as the value of the C<query> parameter.  All arguments are passed on to the C<manager_class>'s C<manager_method> method, augmented by the mapping to the current object.  Query parameters are added to the existing contents of the C<query> parameter.  Other parameters replace existing parameters if the existing values are simple scalars, or augment existing parameters if the existing values are references to hashes or arrays.

The fetch may fail for several reasons.  The fetch will not even be attempted if any of the key attributes in the current object are undefined.  Instead, undef (in scalar context) or an empty list (in list context) will be returned.  If the call to C<manager_class>'s C<manager_method> method returns false, the behavior is determined by the L<metadata object|Rose::DB::Object/meta>'s L<error_mode|Rose::DB::Object::Metadata/error_mode>.  If the mode is C<return>, that false value (in scalar context) or an empty list (in list context) is returned.

If the fetch succeeds, a list (in list context) or a reference to the array of objects (in scalar context) is returned.  (If the fetch finds zero objects, the list or array reference will simply be empty.  This is still considered success.)

=item B<iterator>

Behaves just like B<find> but returns an L<iterator|Rose::DB::Object::Iterator> rather than an array or arrayref.

=item B<get_set>

Creates a method that will attempt to fetch L<Rose::DB::Object>-derived objects that are related to the current object through the C<map_class>.

If passed a single argument of undef, the C<hash_key> used to store the objects is set to undef.  Otherwise, the argument(s) must be a list or reference to an array containing items in one or more of the following formats:

=over 4

=item * An object of type C<class>.

=item * A reference to a hash containing method name/value pairs.

=item * A single scalar primary key value.

=back

The latter two formats will be used to construct an object of type C<class>.  A single primary key value is only a valid argument format if the C<class> in question has a single-column primary key.  A hash reference argument must contain sufficient information for the object to be uniquely identified.

The list of object is assigned to C<hash_key>.  Note that these objects are B<not> added to the database.  Use the C<get_set_now> or C<get_set_on_save> interface to do that.

If called with no arguments and the hash key used to store the list of objects is defined, the list (in list context) or a reference to that array (in scalar context) of objects is returned.  Otherwise, the objects are fetched.

When fetching objects from the database, if the call to C<manager_class>'s C<manager_method> method returns false, that false value (in scalar context) or an empty list (in list context) is returned.

If the fetch succeeds, a list (in list context) or a reference to the array of objects (in scalar context) is returned.  (If the fetch finds zero objects, the list or array reference will simply be empty.  This is still considered success.)

=item B<get_set_now>

Creates a method that will attempt to fetch L<Rose::DB::Object>-derived objects that are related to the current object through the C<map_class>, and will also save objects to the database and map them to the parent object when called with arguments.  The objects do not have to already exist in the database; they will be inserted if needed.

If passed a single argument of undef, the list of objects is set to undef, causing it to be reloaded the next time the method is called with no arguments.  (Pass a reference to an empty array to cause all of the existing objects to be "unmapped"--that is, to have their entries in the mapping table deleted from the database.)  Any pending C<set_on_save> or C<add_on_save> actions are discarded.

Otherwise, the argument(s) must be a list or reference to an array containing items in one or more of the following formats:

=over 4

=item * An object of type C<class>.

=item * A reference to a hash containing method name/value pairs.

=item * A single scalar primary key value.

=back

The latter two formats will be used to construct an object of type C<class>.  A single primary key value is only a valid argument format if the C<class> in question has a single-column primary key.  A hash reference argument must contain sufficient information for the object to be uniquely identified.

The list of object is assigned to C<hash_key>, the old entries are deleted from the mapping table in the database, and the new objects are added to the database, along with their corresponding mapping entries.  Any pending C<set_on_save> or C<add_on_save> actions are discarded.

When adding each object, if the object does not already exists in the database, it will be inserted.  If the object was previously L<load|Rose::DB::Object/load>ed from or L<save|Rose::DB::Object/save>d to the database, it will be updated.  Otherwise, it will be L<load|Rose::DB::Object/load>ed.

The parent object must have been L<load|Rose::DB::Object/load>ed or L<save|Rose::DB::Object/save>d prior to setting the list of objects.  If this method is called with arguments before the object has been  L<load|Rose::DB::Object/load>ed or L<save|Rose::DB::Object/save>d, a fatal error will occur.

If called with no arguments and the hash key used to store the list of objects is defined, the list (in list context) or a reference to that array (in scalar context) of objects is returned.  Otherwise, the objects are fetched.

When fetching, if the call to C<manager_class>'s C<manager_method> method returns false, that false value (in scalar context) or an empty list (in list context) is returned.

If the fetch succeeds, a list (in list context) or a reference to the array of objects (in scalar context) is returned.  (If the fetch finds zero objects, the list or array reference will simply be empty.  This is still considered success.)

=item B<get_set_on_save>

Creates a method that will attempt to fetch L<Rose::DB::Object>-derived objects that are related to the current object through the C<map_class>, and will also save objects to the database and map them to the parent object when the "parent" object is L<save|Rose::DB::Object/save>d.  The objects do not have to already exist in the database; they will be inserted if needed.

If passed a single argument of undef, the list of objects is set to undef, causing it to be reloaded the next time the method is called with no arguments.  (Pass a reference to an empty array to cause all of the existing objects to be "unmapped"--that is, to have their entries in the mapping table deleted from the database.)  Any pending C<set_on_save> or C<add_on_save> actions are discarded.

Otherwise, the argument(s) must be a list or reference to an array containing items in one or more of the following formats:

=over 4

=item * An object of type C<class>.

=item * A reference to a hash containing method name/value pairs.

=item * A single scalar primary key value.

=back

The latter two formats will be used to construct an object of type C<class>.  A single primary key value is only a valid argument format if the C<class> in question has a single-column primary key.  A hash reference argument must contain sufficient information for the object to be uniquely identified.

The list of object is assigned to C<hash_key>. The mapping table records that mapped the old objects to the parent object are scheduled to be deleted from the database and new ones are scheduled to be added to the database when the parent is L<save|Rose::DB::Object/save>d.  Any previously pending C<set_on_save> or C<add_on_save> actions are discarded.

When adding each object when the parent is L<save|Rose::DB::Object/save>d, if the object does not already exists in the database, it will be inserted.  If the object was previously L<load|Rose::DB::Object/load>ed from or  L<save|Rose::DB::Object/save>d to the database, it will be updated.  Otherwise, it will be L<load|Rose::DB::Object/load>ed.

If called with no arguments and the hash key used to store the list of objects is defined, the list (in list context) or a reference to that array (in scalar context) of objects is returned.  Otherwise, the objects are fetched.

When fetching, if the call to C<manager_class>'s C<manager_method> method returns false, that false value (in scalar context) or an empty list (in list context) is returned.

If the fetch succeeds, a list (in list context) or a reference to the array of objects (in scalar context) is returned.  (If the fetch finds zero objects, the list or array reference will simply be empty.  This is still considered success.)

=item B<add_now>

Creates a method that will add to a list of L<Rose::DB::Object>-derived objects that are related to the current object through the C<map_class>, and will also save objects to the database and map them to the parent object.  The objects do not have to already exist in the database; they will be inserted if needed.

This method returns the list of objects added when called in list context, and the number of objects added when called in scalar context.  If one or more objects could not be added, undef (in scalar context) or an empty list (in list context) is returned and the parent object's L<error|Rose::DB::Object/error> attribute is set.

If passed an empty list, the method does nothing and the parent object's L<error|Rose::DB::Object/error> attribute is set.

If passed any arguments, the parent object must have been L<load|Rose::DB::Object/load>ed or L<save|Rose::DB::Object/save>d prior to adding to the list of objects.  If this method is called with a non-empty list as an argument before the parent object has been  L<load|Rose::DB::Object/load>ed or L<save|Rose::DB::Object/save>d, a fatal error will occur.

The argument(s) must be a list or reference to an array containing items in one or more of the following formats:

=over 4

=item * An object of type C<class>.

=item * A reference to a hash containing method name/value pairs.

=item * A single scalar primary key value.

=back

The latter two formats will be used to construct an object of type C<class>.  A single primary key value is only a valid argument format if the C<class> in question has a single-column primary key.  A hash reference argument must contain sufficient information for the object to be uniquely identified.

The parent object's list of related objects is then set to undef, causing the related objects to be reloaded from the database the next time they're needed.

=item B<add_on_save>

Creates a method that will add to a list of L<Rose::DB::Object>-derived objects that are related to the current object through the C<map_class>, and will also save objects to the database and map them to the parent object when the "parent" object is L<save|Rose::DB::Object/save>d.  The objects and map records will be added to the database when the parent object is L<save|Rose::DB::Object/save>d.  The objects do not have to already exist in the database; they will be inserted if needed.

This method returns the list of objects to be added when called in list context, and the number of items to be added when called in scalar context.

If passed an empty list, the method does nothing and the parent object's L<error|Rose::DB::Object/error> attribute is set.

Otherwise, the argument(s) must be a list or reference to an array containing items in one or more of the following formats:

=over 4

=item * An object of type C<class>.

=item * A reference to a hash containing method name/value pairs.

=item * A single scalar primary key value.

=back

The latter two formats will be used to construct an object of type C<class>.  A single primary key value is only a valid argument format if the C<class> in question has a single-column primary key.  A hash reference argument must contain sufficient information for the object to be uniquely identified.

These objects are scheduled to be added to the database and mapped to the parent object when the parent object is L<save|Rose::DB::Object/save>d.  They are also added to the parent object's current list of related objects, if the list is defined at the time of the call.

=back

=back

For a complete example of this method type in action, see the L<Rose::DB::Object::Metadata::Relationship::ManyToMany> documentation.

=item B<object_by_key>

Create a get/set methods for a single L<Rose::DB::Object>-derived object loaded based on a primary key formed from attributes of the current object.

=over 4

=item Options

=over 4

=item B<class CLASS>

The name of the L<Rose::DB::Object>-derived class of the object to be loaded.  This option is required.

=item B<foreign_key OBJECT>

The L<Rose::DB::Object::Metadata::ForeignKey> object that describes the "key" through which the "object_by_key" is fetched.  This (or the C<relationship> parameter) is required when using the "delete_now", "delete_on_save", and "get_set_on_save" interfaces.

=item B<hash_key NAME>

The key inside the hash-based object to use for the storage of the object.  Defaults to the name of the method.

=item B<if_not_found CONSEQUENCE>

This setting determines what happens when the key_columns have defined values, but the foreign object they point to is not found.  Valid values for CONSEQUENCE are C<fatal>, which will throw an exception if the foreign object is not found, and C<ok> which will merely cause the relevant method(s) to return undef.  The default is C<fatal>. 

=item B<key_columns HASHREF>

A reference to a hash that maps column names in the current object to those of the primary key in the object to be loaded.  This option is required.

=item B<interface NAME>

Choose the interface.  The default is C<get_set>.

=item B<relationship OBJECT>

The L<Rose::DB::Object::Metadata::Relationship>-derived object that describes the relationship through which the object is fetched.  This (or the C<foreign_key> parameter) is required when using the "delete_now", "delete_on_save", and "get_set_on_save" interfaces.

=item B<referential_integrity BOOL>

If true, then a fatal error will occur when a method in one of the "get*" interfaces is called and no related object is found.  The default is determined by the L<referential_integrity|Rose::DB::Object::Metadata::ForeignKey/referential_integrity> attribute of the C<foreign_key> object, or true if no C<foreign_key> parameter is passed.

This parameter conflicts with the C<required> parameter.  Only one of the two should be passed.

=item B<required BOOL>

If true, then a fatal error will occur when a method in one of the "get*" interfaces is called and no related object is found.  The default is determined by the L<required|Rose::DB::Object::Metadata::Relationship::OneToOne/required> attribute of the C<relationship> object, or true if no C<relationship> parameter is passed.

This parameter conflicts with the C<referential_integrity> parameter.  Only one of the two should be passed.

=item B<share_db BOOL>

If true, the L<db|Rose::DB::Object/db> attribute of the current object is shared with the object loaded.  Defaults to true.

=back

=item Interfaces

=over 4

=item B<delete_now>

Deletes a L<Rose::DB::Object>-derived object from the database based on a primary key formed from attributes of the current object.  If C<referential_integrity> or C<required> is true, then the "parent" object will have all of its attributes that refer to the "foreign" object (except any columns that are also part of the primary key) set to null , and it will be saved into the database.  This needs to be done first because a database that enforces referential integrity will not allow a row to be deleted if it is still referenced by a foreign key in another table.

Any previously pending C<get_set_on_save> action is discarded.

The entire process takes place within a transaction if the database supports it.  If not currently in a transaction, a new one is started and then committed on success and rolled back on failure.

Returns true if the foreign object was deleted successfully or did not exist in the database, false if any of the keys that refer to the foreign object were undef, and triggers the normal L<Rose::DB::Object> L<error handling|Rose::DB::Object::Metadata/error_mode> in the case of any other kind of failure.

=item B<delete_on_save>

Deletes a L<Rose::DB::Object>-derived object from the database when the "parent" object is L<save|Rose::DB::Object/save>d, based on a primary key formed from attributes of the current object.  If C<referential_integrity> or C<required> is true, then the "parent" object will have all of its attributes that refer to the "foreign" object (except any columns that are also part of the primary key) set to null immediately, but the actual delete will not be done until the parent is saved.

Any previously pending C<get_set_on_save> action is discarded.

The entire process takes place within a transaction if the database supports it.  If not currently in a transaction, a new one is started and then committed on success and rolled back on failure.

Returns true if the foreign object was deleted successfully or did not exist in the database, false if any of the keys that refer to the foreign object were undef, and triggers the normal L<Rose::DB::Object> L<error handling|Rose::DB::Object::Metadata/error_mode> in the case of any other kind of failure.

=item B<get_set>

Creates a method that will attempt to create and load a L<Rose::DB::Object>-derived object based on a primary key formed from attributes of the current object.

If passed a single argument of undef, the C<hash_key> used to store the object is set to undef.  If C<referential_integrity> or C<required> is true, then the columns that participate in the key are set to undef.  (If any key column is part of the primary key, however, it is not set to undef.)  Otherwise, the argument must be one of the following:

=over 4

=item * An object of type C<class>

=item * A list of method name/value pairs.

=item * A reference to a hash containing method name/value pairs.

=item * A single scalar primary key value.

=back

The latter three argument types will be used to construct an object of type C<class>.  A single primary key value is only valid if the C<class> in question has a single-column primary key.  A hash reference argument must contain sufficient information for the object to be uniquely identified.

The object is assigned to C<hash_key> after having its C<key_columns> set to their corresponding values in the current object.

If called with no arguments and the C<hash_key> used to store the object is defined, the object is returned.  Otherwise, the object is created and loaded.

The load may fail for several reasons.  The load will not even be attempted if any of the key attributes in the current object are undefined.  Instead, undef will be returned.

If the call to the newly created object's L<load|Rose::DB::Object/load> method returns false, then the normal L<Rose::DB::Object> L<error handling|Rose::DB::Object::Metadata/error_mode> is triggered.  The false value returned by the call to the L<load|Rose::DB::Object/load> method is returned (assuming no exception was raised).

If the load succeeds, the object is returned.

=item B<get_set_now>

Creates a method that will attempt to create and load a L<Rose::DB::Object>-derived object based on a primary key formed from attributes of the current object, and will also save the object to the database when called with an appropriate object as an argument.

If passed a single argument of undef, the C<hash_key> used to store the object is set to undef.  If C<referential_integrity> or C<required> is true, then the columns that participate in the key are set to undef.  (If any key column is part of the primary key, however, it is not set to undef.) Otherwise, the argument must be one of the following:

=over 4

=item * An object of type C<class>

=item * A list of method name/value pairs.

=item * A reference to a hash containing method name/value pairs.

=item * A single scalar primary key value.

=back

The latter three argument types will be used to construct an object of type C<class>.  A single primary key value is only a valid argument format if the C<class> in question has a single-column primary key.  A hash reference argument must contain sufficient information for the object to be uniquely identified.

The object is assigned to C<hash_key> after having its C<key_columns> set to their corresponding values in the current object.  The object is then immediately L<save|Rose::DB::Object/save>d to the database.

If the object does not already exists in the database, it will be inserted.  If the object was previously L<load|Rose::DB::Object/load>ed from or L<save|Rose::DB::Object/save>d to the database, it will be updated.  Otherwise, it will be L<load|Rose::DB::Object/load>ed.

The parent object must have been L<load|Rose::DB::Object/load>ed or L<save|Rose::DB::Object/save>d prior to setting the list of objects.  If this method is called with arguments before the object has been  L<load|Rose::DB::Object/load>ed or L<save|Rose::DB::Object/save>d, a fatal error will occur.

If called with no arguments and the C<hash_key> used to store the object is defined, the object is returned.  Otherwise, the object is created and loaded.

The load may fail for several reasons.  The load will not even be attempted if any of the key attributes in the current object are undefined.  Instead, undef will be returned.

If the call to the newly created object's L<load|Rose::DB::Object/load> method returns false, then the normal L<Rose::DB::Object> L<error handling|Rose::DB::Object::Metadata/error_mode> is triggered.  The false value returned by the call to the L<load|Rose::DB::Object/load> method is returned (assuming no exception was raised).

If the load succeeds, the object is returned.

=item B<get_set_on_save>

Creates a method that will attempt to create and load a L<Rose::DB::Object>-derived object based on a primary key formed from attributes of the current object, and save the object when the "parent" object is L<save|Rose::DB::Object/save>d.

If passed a single argument of undef, the C<hash_key> used to store the object is set to undef.  If C<referential_integrity> or C<required> is true, then the columns that participate in the key are set to undef.  (If any key column is part of the primary key, however, it is not set to undef.) Otherwise, the argument must be one of the following:

=over 4

=item * An object of type C<class>

=item * A list of method name/value pairs.

=item * A reference to a hash containing method name/value pairs.

=item * A single scalar primary key value.

=back

The latter three argument types will be used to construct an object of type C<class>.  A single primary key value is only a valid argument format if the C<class> in question has a single-column primary key.  A hash reference argument must contain sufficient information for the object to be uniquely identified.

The object is assigned to C<hash_key> after having its C<key_columns> set to their corresponding values in the current object.  The object will be saved into the database when the "parent" object is L<save|Rose::DB::Object/save>d.  Any previously pending C<get_set_on_save> action is discarded.

If the object does not already exists in the database, it will be inserted.  If the object was previously L<load|Rose::DB::Object/load>ed from or L<save|Rose::DB::Object/save>d to the database, it will be updated.  Otherwise, it will be L<load|Rose::DB::Object/load>ed.

If called with no arguments and the C<hash_key> used to store the object is defined, the object is returned.  Otherwise, the object is created and loaded from the database.

The load may fail for several reasons.  The load will not even be attempted if any of the key attributes in the current object are undefined.  Instead, undef will be returned.

If the call to the newly created object's L<load|Rose::DB::Object/load> method returns false, then the normal L<Rose::DB::Object> L<error handling|Rose::DB::Object::Metadata/error_mode> is triggered.  The false value returned by the call to the L<load|Rose::DB::Object/load> method is returned (assuming no exception was raised).

If the load succeeds, the object is returned.

=back

=back

Example setup:

    # CLASS     DB TABLE
    # -------   --------
    # Product   products
    # Category  categories

    package Product;

    our @ISA = qw(Rose::DB::Object);
    ...

    # You will almost never call the method-maker directly
    # like this.  See the Rose::DB::Object::Metadata docs
    # for examples of more common usage.
    use Rose::DB::Object::MakeMethods::Generic
    (
      object_by_key =>
      [
        category => 
        {
          interface   => 'get_set',
          class       => 'Category',
          key_columns =>
          {
            # Map Product column names to Category column names
            category_id => 'id',
          },
        },
      ]
    );
    ...

Example - get_set interface:

    $product = Product->new(id => 5, category_id => 99);

    # Read from the categories table
    $category = $product->category; 

    # $product->category call is roughly equivalent to:
    #
    # $cat = Category->new(id => $product->category_id
    #                      db => $prog->db);
    #
    # $ret = $cat->load;
    # return $ret  unless($ret);
    # return $cat;

    # Does not write to the db
    $product->category(Category->new(...));

    $product->save; # writes to products table only

Example - get_set_now interface:

    # Read from the products table
    $product = Product->new(id => 5)->load;

    # Read from the categories table
    $category = $product->category;

    # Write to the categories table:
    # (all possible argument formats show)

    # Object argument
    $product->category(Category->new(...));

    # Primary key value
    $product->category(123); 

    # Method name/value pairs in a hashref
    $product->category(id => 123); 

    # Method name/value pairs in a hashref
    $product->category({ id => 123 }); 

    # Write to the products table
    $product->save; 

Example - get_set_on_save interface:

    # Read from the products table
    $product = Product->new(id => 5)->load;

    # Read from the categories table
    $category = $product->category;

    # These do not write to the db:

    # Object argument
    $product->category(Category->new(...));

    # Primary key value
    $product->category(123); 

    # Method name/value pairs in a hashref
    $product->category(id => 123); 

    # Method name/value pairs in a hashref
    $product->category({ id => 123 });

    # Write to both the products and categories tables
    $product->save;

Example - delete_now interface:

    # Read from the products table
    $product = Product->new(id => 5)->load;

    # Write to both the categories and products tables
    $product->delete_category();

Example - delete_on_save interface:

    # Read from the products table
    $product = Product->new(id => 5)->load;

    # Does not write to the db
    $product->delete_category(); 

    # Write to both the products and categories tables
    $product->save;

=item B<scalar>

Create get/set methods for scalar attributes.

=over 4

=item Options

=over 4

=item B<default VALUE>

Determines the default value of the attribute.

=item B<check_in ARRAYREF>

A reference to an array of valid values.  When setting the attribute, if the new value is not equal (string comparison) to one of the valid values, a fatal error will occur.

=item B<hash_key NAME>

The key inside the hash-based object to use for the storage of this
attribute.  Defaults to the name of the method.

=item B<init_method NAME>

The name of the method to call when initializing the value of an undefined attribute.  Defaults to the method name with the prefix C<init_> added.  This option implies C<with_init>.

=item B<interface NAME>

Choose the interface.  The C<get_set> interface is the default.

=item B<length INT>

The maximum number of characters in the string.

=item B<overflow BEHAVIOR>

Determines the behavior when the value is greater than the number of characters specified by the C<length> option.  Valid values for BEHAVIOR are:

=over 4

=item B<fatal>

Throw an exception.

=item B<truncate>

Truncate the value to the correct length.

=item B<warn>

Print a warning message.

=back

=item B<with_init BOOL>

Modifies the behavior of the C<get_set> and C<get> interfaces.  If the attribute is undefined, the method specified by the C<init_method> option is called and the attribute is set to the return value of that
method.

=back

=item Interfaces

=over 4

=item B<get_set>

Creates a get/set method for an object attribute.  When called with an argument, the value of the attribute is set.  The current value of the attribute is returned.

=item B<get>

Creates an accessor method for an object attribute that returns the current value of the attribute.

=item B<set>

Creates a mutator method for an object attribute.  When called with an argument, the value of the attribute is set.  If called with no arguments, a fatal error will occur.

=back

=back

Example:

    package MyDBObject;

    our @ISA = qw(Rose::DB::Object);

    use Rose::DB::Object::MakeMethods::Generic
    (
      scalar => 
      [
        name => { default => 'Joe' },
        type => 
        {
          with_init => 1,
          check_in  => [ qw(AA AAA C D) ],
        }
        set_type =>
        {
          check_in  => [ qw(AA AAA C D) ],        
        }
      ],
    );

    sub init_type { 'C' }
    ...

    $o = MyDBObject->new(...);

    print $o->name; # Joe
    print $o->type; # C

    $o->name('Bob'); # set
    $o->type('AA');  # set

    eval { $o->type('foo') }; # fatal error: invalid value

    print $o->name, ' is ', $o->type; # get

=item B<set>

Create get/set methods for "set" attributes.   A "set" column in a database table contains an unordered group of values.  Not all databases support a "set" column type.  Check the L<Rose::DB|Rose::DB/"DATABASE SUPPORT"> documentation for your database type.

=over 4

=item Options

=over 4

=item B<default ARRAYREF>

Determines the default value of the attribute.  The value should be a reference to an array.

=item B<hash_key NAME>

The key inside the hash-based object to use for the storage of this
attribute.  Defaults to the name of the method.

=item B<interface NAME>

Choose the interface.  The default is C<get_set>.

=item B<values ARRAYREF>

A reference to an array of valid values for the set.  If present, attempting to use an invalid value will cause a fatal error.

=back

=item Interfaces

=over 4

=item B<get_set>

Creates a get/set method for a "set" object attribute.  A "set" column in a database table contains an unordered group of values.  On the Perl side of the fence, an ordered list (an array) is used to store the values, but keep in mind that the order is not significant, nor is it guaranteed to be preserved.

When setting the attribute, the value is passed through the L<parse_set|Rose::DB::Informix/parse_set> method of the object's L<db|Rose::DB::Object/db> attribute.

When saving to the database, if the attribute value is defined, the method will pass the attribute value through the L<format_set|Rose::DB::Informix/format_set> method of the object's L<db|Rose::DB::Object/db> attribute before returning it.

When not saving to the database, the method returns the set as a list in list context, or as a reference to the array in scalar context.

=item B<get>

Creates an accessor method for a "set" object attribute.  A "set" column in a database table contains an unordered group of values.  On the Perl side of the fence, an ordered list (an array) is used to store the values, but keep in mind that the order is not significant, nor is it guaranteed to be preserved.

When saving to the database, if the attribute value is defined, the method will pass the attribute value through the L<format_set|Rose::DB::Informix/format_set> method of the object's L<db|Rose::DB::Object/db> attribute before returning it.

When not saving to the database, the method returns the set as a list in list context, or as a reference to the array in scalar context.

=item B<set>

Creates a mutator method for a "set" object attribute.  A "set" column in a database table contains an unordered group of values.  On the Perl side of the fence, an ordered list (an array) is used to store the values, but keep in mind that the order is not significant, nor is it guaranteed to be preserved.

When setting the attribute, the value is passed through the L<parse_set|Rose::DB::Informix/parse_set> method of the object's L<db|Rose::DB::Object/db> attribute.

When saving to the database, if the attribute value is defined, the method will pass the attribute value through the L<format_set|Rose::DB::Informix/format_set> method of the object's L<db|Rose::DB::Object/db> attribute before returning it.

When not saving to the database, the method returns the set as a list in list context, or as a reference to the array in scalar context.

=back

=back

Example:

    package Person;

    our @ISA = qw(Rose::DB::Object);
    ...
    use Rose::DB::Object::MakeMethods::Generic
    (
      set => 
      [
        'nicknames',
        'set_nicks' => { interface => 'set', hash_key => 'nicknames' },

        'parts' => { default => [ qw(arms legs) ] },
      ],
    );
    ...

    @parts = $person->parts; # ('arms', 'legs')
    $parts = $person->parts; # [ 'arms', 'legs' ]

    $person->nicknames('Jack', 'Gimpy');   # set with list
    $person->nicknames([ 'Slim', 'Gip' ]); # set with array ref

    $person->set_nicks('Jack', 'Gimpy');   # set with list
    $person->set_nicks([ 'Slim', 'Gip' ]); # set with array ref

=item B<varchar>

Create get/set methods for variable-length character string attributes.

=over 4

=item Options

=over 4

=item B<default VALUE>

Determines the default value of the attribute.

=item B<hash_key NAME>

The key inside the hash-based object to use for the storage of this attribute.  Defaults to the name of the method.

=item B<init_method NAME>

The name of the method to call when initializing the value of an undefined attribute.  Defaults to the method name with the prefix C<init_> added.  This option implies C<with_init>.

=item B<interface NAME>

Choose the interface.  The C<get_set> interface is the default.

=item B<length INT>

The maximum number of characters in the string.

=item B<overflow BEHAVIOR>

Determines the behavior when the value is greater than the number of characters specified by the C<length> option.  Valid values for BEHAVIOR are:

=over 4

=item B<fatal>

Throw an exception.

=item B<truncate>

Truncate the value to the correct length.

=item B<warn>

Print a warning message.

=back

=item B<with_init BOOL>

Modifies the behavior of the C<get_set> and C<get> interfaces.  If the attribute is undefined, the method specified by the C<init_method> option is called and the attribute is set to the return value of that
method.

=back

=item Interfaces

=over 4

=item B<get_set>

Creates a get/set accessor method for a fixed-length character string attribute.  When setting, any strings longer than C<length> will be truncated.  If C<length> is omitted, the string will be left unmodified.

=back

=back

Example:

    package MyDBObject;

    our @ISA = qw(Rose::DB::Object);

    use Rose::DB::Object::MakeMethods::Generic
    (
      varchar => 
      [
        'name' => { length => 3 },
      ],
    );

    ...

    $o->name('John'); # truncates on set
    print $o->name;   # 'Joh'

=back

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
