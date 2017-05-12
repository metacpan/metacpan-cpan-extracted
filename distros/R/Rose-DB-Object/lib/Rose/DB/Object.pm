package Rose::DB::Object;

use strict;

use Carp();

use Rose::DB;
use Rose::DB::Object::Metadata;

use Rose::Object;
our @ISA = qw(Rose::Object);

use Rose::DB::Object::Manager;
use Rose::DB::Object::Constants qw(:all);
use Rose::DB::Constants qw(IN_TRANSACTION);
use Rose::DB::Object::Exception;
use Rose::DB::Object::Util();

our $VERSION = '0.815';

our $Debug = 0;

#
# Object data
#

use Rose::Object::MakeMethods::Generic
(
  'scalar'  => [ 'error', 'not_found' ],
  'boolean' =>
  [
    #FLAG_DB_IS_PRIVATE,
    STATE_IN_DB,
    STATE_LOADING,
    STATE_SAVING,
  ],
);

#
# Class methods
#

sub meta_class { 'Rose::DB::Object::Metadata' }

sub meta
{  
  my($self) = shift;

  if(ref $self)
  {
    return $self->{META_ATTR_NAME()} ||= $self->meta_class->for_class(ref $self);
  }

  return $Rose::DB::Object::Metadata::Objects{$self} || 
         $self->meta_class->for_class($self);
}

#
# Object methods
#

sub db
{
  my($self) = shift;

  if(@_)
  {
    #$self->{FLAG_DB_IS_PRIVATE()} = 0;

    my $new_db = shift;

    # If potentially migrating across db types, "suck through" the
    # driver-formatted  values using the old db before swapping it 
    # with the new one.
    if($self->{LOADED_FROM_DRIVER()} && 
       $self->{LOADED_FROM_DRIVER()} ne $new_db->{'driver'})
    {
      foreach my $method ($self->meta->column_accessor_method_names)
      {
        # Need to catch return to avoid clever methods that
        # skip work when called in void context.
        my $val = $self->$method();
      }
    }

    $self->{'db'} = $new_db;

    return $new_db;
  }

  return $self->{'db'} ||= $self->_init_db;
}

sub init_db { Rose::DB->new() }

sub _init_db
{
  my($self) = shift;

  my($db, $error);

  TRY:
  {
    local $@;
    eval { $db = $self->init_db };
    $error = $@;
  }

  unless($error)
  {
    #$self->{FLAG_DB_IS_PRIVATE()} = 1;
    return $db;
  }

  if(ref $error)
  {
    $self->error($error);
  }
  else
  {
    $self->error("Could not init_db() - $error - " . ($db ? $db->error : ''));
  }

  $self->meta->handle_error($self);
  return undef;
}

sub dbh
{
  my($self) = shift;

  my $db = $self->db or return undef;

  if(my $dbh = $db->dbh(@_))
  {
    return $dbh;
  }
  else
  {
    $self->error($db->error);
    $self->meta->handle_error($self);
    return undef;
  }
}

use constant LAZY_LOADED_KEY => 
  Rose::DB::Object::Util::lazy_column_values_loaded_key();

sub load
{
  my($self) = $_[0]; # XXX: Must maintain alias to actual "self" object arg

  my %args = (self => @_); # faster than @_[1 .. $#_];

  my $db  = $self->db  or return 0;
  my $dbh = $self->dbh or return 0;

  my $meta = $self->meta;

  my $prepare_cached = 
    exists $args{'prepare_cached'} ? $args{'prepare_cached'} :
    $meta->dbi_prepare_cached;

  local $self->{STATE_SAVING()} = 1;
  local $self->{SAVING_FOR_LOAD()} = 1;

  my(@key_columns, @key_methods, @key_values);

  my $null_key  = 0;
  my $found_key = 0;

  if(my $key = delete $args{'use_key'})
  {
    my @uk = grep { $_->name eq $key } $meta->unique_keys;

    if(@uk == 1)
    {
      my $defined = 0;
      @key_columns = $uk[0]->column_names;
      @key_methods = map { $meta->column_accessor_method_name($_) } @key_columns;
      @key_values  = map { $defined++ if(defined $_); $_ } 
                     map { $self->$_() } @key_methods;

      unless($defined)
      {
        $self->error("Could not load() based on key '$key' - column(s) have undefined values");
        $meta->handle_error($self);
        return undef;
      }

      if(@key_values != $defined)
      {
        $null_key = 1;
      }
    }
    else { Carp::croak "No unique key named '$key' is defined in ", ref($self) }
  }
  else
  {
    @key_columns = $meta->primary_key_column_names;
    @key_methods = $meta->primary_key_column_accessor_names;
    @key_values  = grep { defined } map { $self->$_() } @key_methods;

    unless(@key_values == @key_columns)
    {
      my $alt_columns;

      # Prefer unique keys where we have defined values for all
      # key columns, but fall back to the first unique key found 
      # where we have at least one defined value.
      foreach my $cols ($meta->unique_keys_column_names)
      {
        my $defined = 0;
        @key_columns = @$cols;
        @key_methods = map { $meta->column_accessor_method_name($_) } @key_columns;
        @key_values  = map { $defined++ if(defined $_); $_ } 
                       map { $self->$_() } @key_methods;

        if($defined == @key_columns)
        {
          $found_key = 1;
          last;
        }

        $alt_columns ||= $cols  if($defined);
      }

      if(!$found_key && $alt_columns)
      {
        @key_columns = @$alt_columns;
        @key_methods = map { $meta->column_accessor_method_name($_) }  @key_columns;
        @key_values  = map { $self->$_() } @key_methods;
        $null_key    = 1;
        $found_key   = 1;
      }

      unless($found_key)
      {
        @key_columns = $meta->primary_key_column_names;

        my $e = 
          Rose::DB::Object::Exception->new(
            message => "Cannot load " . ref($self) . " without a primary key (" .
                       join(', ', @key_columns) . ') with ' .
                       (@key_columns > 1 ? 'non-null values in all columns' : 
                                           'a non-null value') .
                       ' or another unique key with at least one non-null value.',
            code => EXCEPTION_CODE_NO_KEY);

        $self->error($e);

        $meta->handle_error($self);
        return 0;
      }
    }
  }

  my $has_lazy_columns = $args{'nonlazy'} ? 0 : $meta->has_lazy_columns;
  my $column_names;

  if($has_lazy_columns)
  {
    $column_names = $meta->nonlazy_column_names;
    $self->{LAZY_LOADED_KEY()} = {};
  }
  else
  {
    $column_names = $meta->column_names;
  }

  # Coerce for_update boolean alias into lock argument
  if(delete $args{'for_update'})
  {
    $args{'lock'}{'type'} ||= 'for update';
  }

  #
  # Handle sub-object load in separate code path
  #

  if(my $with = $args{'with'})
  {
    my $mgr_class = $args{'manager_class'} || 'Rose::DB::Object::Manager';
    my %query;

    @query{map { "t1.$_" } @key_columns} = @key_values;

    my($objects, $error);

    TRY:
    {
      local $@;

      eval
      {
        $objects = 
          $mgr_class->get_objects(object_class   => ref $self,
                                  db             => $db,
                                  query          => [ %query ],
                                  with_objects   => $with,
                                  multi_many_ok  => 1,
                                  nonlazy        => $args{'nonlazy'},
                                  inject_results => $args{'inject_results'},
                                  lock           => $args{'lock'},
                                  (exists $args{'prepare_cached'} ?
                                  (prepare_cached =>  $args{'prepare_cached'}) : 
                                  ()))
            or Carp::confess $mgr_class->error;

        if(@$objects > 1)
        {
          die "Found ", @$objects, " objects instead of one";
        }
      };

      $error = $@;
    }

    if($error)
    {
      $self->error(ref $error ? $error : "load(with => ...) - $error");
      $meta->handle_error($self);
      return undef;
    }

    if(@$objects > 0)
    {
      # Sneaky init by object replacement
      $self = $_[0] = $objects->[0];

      # Init by copying attributes (broken; need to do fks and relationships too)
      #my $methods = $meta->column_mutator_method_names;
      #my $object  = $objects->[0];
      #
      #local $self->{STATE_LOADING()}  = 1;
      #local $object->{STATE_SAVING()} = 1;
      #
      #foreach my $method (@$methods)
      #{
      #  $self->$method($object->$method());
      #}
    }
    else
    {
      no warnings;
      $self->error("No such " . ref($self) . ' where ' . 
                   join(', ', @key_columns) . ' = ' . join(', ', @key_values));
      $self->{'not_found'} = 1;

      $self->{STATE_IN_DB()} = 0;

      my $speculative = 
        exists $args{'speculative'} ? $args{'speculative'} :     
        $meta->default_load_speculative;

      unless($speculative)
      {
        $meta->handle_error($self);
      }

      return 0;
    }

    $self->{STATE_IN_DB()} = 1;
    $self->{LOADED_FROM_DRIVER()} = $db->{'driver'};
    $self->{MODIFIED_COLUMNS()} = {};
    return $self || 1;
  }

  #
  # Handle normal load
  #

  my($loaded_ok, $error);

  $self->{'not_found'} = 0;

  TRY:
  {
    local $@;

    eval
    {
      local $self->{STATE_LOADING()} = 1;
      local $dbh->{'RaiseError'} = 1;

      my($sql, $sth);

      if($null_key)
      {
        if($has_lazy_columns)
        {
          $sql = $meta->load_sql_with_null_key(\@key_columns, \@key_values, $db);
        }
        else
        {
          $sql = $meta->load_all_sql_with_null_key(\@key_columns, \@key_values, $db);
        }
      }
      else
      {
        if($has_lazy_columns)
        {
          $sql = $meta->load_sql(\@key_columns, $db);
        }
        else
        {
          $sql = $meta->load_all_sql(\@key_columns, $db);
        }
      }

      if(my $lock = $args{'lock'})
      {
        $sql .= ' ' . $db->format_select_lock($self, $lock);
      }

      # $meta->prepare_select_options (defunct)
      $sth = $prepare_cached ? $dbh->prepare_cached($sql, undef, 3) : 
                               $dbh->prepare($sql);

      $Debug && warn "$sql - bind params: ", join(', ', grep { defined } @key_values), "\n";
      $sth->execute(grep { defined } @key_values);

      my %row;

      $sth->bind_columns(undef, \@row{@$column_names});

      $loaded_ok = defined $sth->fetch;

      # The load() query shouldn't find more than one row anyway, 
      # but DBD::SQLite demands this :-/
      # XXX: Recent versions of DBD::SQLite seem to have cured this.
      # XXX: Safe to remove?
      $sth->finish;

      if($loaded_ok)
      {
        my $methods = $meta->column_mutator_method_names_hash;

        # Empty existing object?
        #%$self = (db => $self->db, meta => $meta, STATE_LOADING() => 1);

        foreach my $name (@$column_names)
        {
          my $method = $methods->{$name};
          $self->$method($row{$name});
        }

        # Sneaky init by object replacement
        #my $object = (ref $self)->new(db => $self->db);
        #
        #foreach my $name (@$column_names)
        #{
        #  my $method = $methods->{$name};
        #  $object->$method($row{$name});
        #}
        #
        #$self = $_[0] = $object;
      }
      else
      {
        no warnings;
        $self->error("No such " . ref($self) . ' where ' . 
                     join(', ', @key_columns) . ' = ' . join(', ', @key_values));
        $self->{'not_found'} = 1;
        $self->{STATE_IN_DB()} = 0;
      }
    };

    $error = $@;
  }

  if($error)
  {
    $self->error(ref $error ? $error : "load() - $error");
    $meta->handle_error($self);
    return undef;
  }

  unless($loaded_ok)
  {
    my $speculative = 
      exists $args{'speculative'} ? $args{'speculative'} :     
      $meta->default_load_speculative;

    unless($speculative)
    {
      $meta->handle_error($self);
    }

    return 0;
  }

  $self->{STATE_IN_DB()} = 1;
  $self->{LOADED_FROM_DRIVER()} = $db->{'driver'};
  $self->{MODIFIED_COLUMNS()} = {};
  return $self || 1;
}

sub save
{
  my($self, %args) = @_;

  my $meta = $self->meta;

  my $cascade =
    exists $args{'cascade'} ? $args{'cascade'} :
    $meta->default_cascade_save;

  # Keep trigger-encumbered and cascade code in separate code path
  if($self->{ON_SAVE_ATTR_NAME()} || $cascade)
  {
    my $db  = $args{'db'} || $self->db || return 0;
    my $ret = $db->begin_work;

    $args{'db'} ||= $db;

    unless($ret)
    {
      my $error = $db->error;
      $self->error(ref $error ? $error : "Could not begin transaction before saving - $error");
      $self->meta->handle_error($self);
      return undef;
    }

    my $started_new_tx = ($ret == IN_TRANSACTION) ? 0 : 1;

    my $error;

    TRY:
    {
      local $@;

      eval
      {
        my %did_set;

        my %code_args = 
          map { ($_ => $args{$_}) } grep { exists $args{$_} } 
          qw(changes_only prepare_cached cascade);

        #
        # Do pre-save stuff
        #

        my $todo = $self->{ON_SAVE_ATTR_NAME()}{'pre'};

        foreach my $fk_name (keys %{$todo->{'fk'}})
        {
          my $code   = $todo->{'fk'}{$fk_name}{'set'} or next;
          my $object = $code->($self, \%code_args);

          # Account for objects that evaluate to false to due overloading
          unless($object || ref $object)
          {
            die $self->error;
          }

          # Track which rows were set so we can avoid deleting
          # them later in the "delete on save" code
          $did_set{'fk'}{$fk_name}{Rose::DB::Object::Util::row_id($object)} = 1;
        }

        #
        # Do the actual save
        #

        if(!$args{'insert'} && ($args{'update'} || $self->{STATE_IN_DB()}))
        {
          $ret = shift->update(@_);
        }
        else
        {
          $ret = shift->insert(@_);
        }

        #
        # Do post-save stuff
        #

        $todo = $self->{ON_SAVE_ATTR_NAME()}{'post'};

        # Foreign keys (and some fk-like relationships)
        foreach my $fk_name (keys %{$todo->{'fk'}})
        {
          foreach my $item (@{$todo->{'fk'}{$fk_name}{'delete'} || []})
          {
            my $code   = $item->{'code'};
            my $object = $item->{'object'};

            # Don't run the code to delete this object if we just set it above
            next  if($did_set{'fk'}{$fk_name}{Rose::DB::Object::Util::row_id($object)});

            $code->($self, \%code_args) or die $self->error;
          }
        }

        if($cascade)
        {
          foreach my $fk ($meta->foreign_keys)
          {
            # If this object was just set above, just save changes (there 
            # should be none) as a way to continue the cascade
            local $args{'changes_only'} = 1  if($todo->{'fk'}{$fk->name}{'set'});

            my $foreign_object = $fk->object_has_foreign_object($self) || next;

            if(Rose::DB::Object::Util::has_modified_columns($foreign_object) ||
               Rose::DB::Object::Util::has_modified_children($foreign_object))
            {
              $Debug && warn "$self - save foreign ", $fk->name, " - $foreign_object\n";
              $foreign_object->save(%args);
            }
          }
        }

        # Relationships
        foreach my $rel_name (keys %{$todo->{'rel'}})
        {
          my $code;

          # Set value(s)
          if($code  = $todo->{'rel'}{$rel_name}{'set'})
          {
            $code->($self, \%code_args) or die $self->error;
          }

          # Delete value(s)
          if($code  = $todo->{'rel'}{$rel_name}{'delete'})
          {
            $code->($self, \%code_args) or die $self->error;
          }

          # Add value(s)
          if($code  = $todo->{'rel'}{$rel_name}{'add'}{'code'})
          {
            $code->($self, \%code_args) or die $self->error;
          }
        }

        if($cascade)
        {
          foreach my $rel ($meta->relationships)
          {
            # If this object was just set above, just save changes (there 
            # should be none) as a way to continue the cascade
            local $args{'changes_only'} = 1  if($todo->{'rel'}{$rel->name}{'set'});

            my $related_objects = $rel->object_has_related_objects($self) || next;

            foreach my $related_object (@$related_objects)
            {
              if(Rose::DB::Object::Util::has_modified_columns($related_object) ||
                 Rose::DB::Object::Util::has_modified_children($related_object))
              {
                $Debug && warn "$self - save related ", $rel->name, " - $related_object\n";
                $related_object->save(%args);
              }
            }
          }
        }

        if($started_new_tx)
        {
          $db->commit or die $db->error;
        }
      };

      $error = $@;
    }

    delete $self->{ON_SAVE_ATTR_NAME()};

    if($error)
    {
      $self->error($error);
      $db->rollback or warn $db->error  if($started_new_tx);
      $self->meta->handle_error($self);
      return 0;
    }

    $self->{MODIFIED_COLUMNS()} = {};

    return $ret;
  }
  else
  {
    if(!$args{'insert'} && ($args{'update'} || $self->{STATE_IN_DB()}))
    {
      return shift->update(@_);
    }

    return shift->insert(@_);
  }
}

sub update
{
  my($self, %args) = @_;

  my $db  = $self->db  or return 0;
  my $dbh = $self->dbh or return 0;

  my $meta = $self->meta;

  my $prepare_cached = 
    exists $args{'prepare_cached'} ? $args{'prepare_cached'} :
    $meta->dbi_prepare_cached;

  my $changes_only =
    exists $args{'changes_only'} ? $args{'changes_only'} :
    $meta->default_update_changes_only;

  local $self->{STATE_SAVING()} = 1;

  my @key_columns = $meta->primary_key_column_names;
  my @key_methods = $meta->primary_key_column_accessor_names;
  my @key_values  = grep { defined } map { $self->$_() } @key_methods;

  # Special case for tables where all columns are part of the primary key
  return $self || 1  if(@key_columns == $meta->num_columns);

  # See comment below
  #my $null_key  = 0;
  #my $found_key = 0;

  unless(@key_values == @key_columns)
  {
    $self->error("Cannot update " . ref($self) . " without a primary key (" .
                 join(', ', @key_columns) . ') with ' .
                 (@key_columns > 1 ? 'non-null values in all columns' : 
                                     'a non-null value'));
    $self->meta->handle_error($self);
    return undef;
  }

  #my $ret = $db->begin_work;
  #
  #unless($ret)
  #{
  #  my $error = $db->error;
  #  $self->error(ref $error ? $error : "Could not begin transaction before updating - $error");
  #  return undef;
  #}
  #
  #my $started_new_tx = ($ret == Rose::DB::Constants::IN_TRANSACTION) ? 0 : 1;

  my $error;

  TRY:
  {
    local $@;

    eval
    {
      #local $self->{STATE_SAVING()} = 1;
      local $dbh->{'RaiseError'} = 1;

      my $sth;

      if($meta->allow_inline_column_values)
      {
        # This versions of update_sql_with_inlining is not needed (see comments
        # in Rose/DB/Object/Metadata.pm for more information)
        #my($sql, $bind) = 
        #  $meta->update_sql_with_inlining($self, \@key_columns, \@key_values);

        my($sql, $bind, $bind_params);

        if($changes_only)
        {
          # No changes to save...
          return $self || 1  unless(%{$self->{MODIFIED_COLUMNS()} || {}});
          ($sql, $bind, $bind_params) =
            $meta->update_changes_only_sql_with_inlining($self, \@key_columns);

          unless($sql) # skip key-only updates
          {
            $self->{MODIFIED_COLUMNS()} = {};
            return $self || 1;
          }
        }
        else
        {
          ($sql, $bind, $bind_params) = $meta->update_sql_with_inlining($self, \@key_columns);
        }

        if($Debug)
        {
          no warnings;
          warn "$sql - bind params: ", join(', ', @$bind, @key_values), "\n";
        }

        $sth = $dbh->prepare($sql); #, $meta->prepare_update_options);

        if($bind_params)
        {
          my $i = 1;

          foreach my $value (@$bind)
          {
            $sth->bind_param($i, $value, $bind_params->[$i - 1]);
            $i++;
          }

          my $kv_idx = 0;

          foreach my $column_name (@key_columns)
          {
            my $column = $meta->column($column_name);
            $sth->bind_param($i++, $key_values[$kv_idx++], $column->dbi_bind_param_attrs($db));
          }

          $sth->execute;
        }
        else
        {
          $sth->execute(@$bind, @key_values);
        }
      }
      else
      {
        if($changes_only)
        {
          # No changes to save...
          return $self || 1  unless(%{$self->{MODIFIED_COLUMNS()} || {}});

          my($sql, $bind, $columns) = $meta->update_changes_only_sql($self, \@key_columns, $db);

          unless($sql) # skip key-only updates
          {
            $self->{MODIFIED_COLUMNS()} = {};
            return $self || 1;
          }

          # $meta->prepare_update_options (defunct)
          my $sth = $prepare_cached ? $dbh->prepare_cached($sql, undef, 3) : 
                                      $dbh->prepare($sql);

          if($Debug)
          {
            no warnings;
            warn "$sql - bind params: ", join(', ', @$bind, @key_values), "\n";
          }

          if($meta->dbi_requires_bind_param($db))
          {
            my $i = 1;

            foreach my $column (@$columns)
            {
              my $method = $column->accessor_method_name;
              $sth->bind_param($i++,  $self->$method(), $column->dbi_bind_param_attrs($db));
            }

            my $kv_idx = 0;

            foreach my $column_name (@key_columns)
            {
              my $column = $meta->column($column_name);
              $sth->bind_param($i++, $key_values[$kv_idx++], $column->dbi_bind_param_attrs($db));
            }

            $sth->execute;
          }
          else
          {
            $sth->execute(@$bind, @key_values);
          }
        }
        elsif($meta->has_lazy_columns)
        {
          my($sql, $bind, $columns) = $meta->update_sql($self, \@key_columns, $db);

          # $meta->prepare_update_options (defunct)
          my $sth = $prepare_cached ? $dbh->prepare_cached($sql, undef, 3) : 
                                      $dbh->prepare($sql);

          if($Debug)
          {
            no warnings;
            warn "$sql - bind params: ", join(', ', @$bind, @key_values), "\n";
          }

          if($meta->dbi_requires_bind_param($db))
          {
            my $i = 1;

            foreach my $column (@$columns)
            {
              my $method = $column->accessor_method_name;
              $sth->bind_param($i++,  $self->$method(), $column->dbi_bind_param_attrs($db));
            }

            my $kv_idx = 0;

            foreach my $column_name (@key_columns)
            {
              my $column = $meta->column($column_name);
              $sth->bind_param($i++, $key_values[$kv_idx++], $column->dbi_bind_param_attrs($db));
            }

            $sth->execute;
          }
          else
          {
            $sth->execute(@$bind, @key_values);
          }
        }
        else
        {
          my $sql = $meta->update_all_sql(\@key_columns, $db);

          # $meta->prepare_update_options (defunct)
          my $sth = $prepare_cached ? $dbh->prepare_cached($sql, undef, 3) : 
                                      $dbh->prepare($sql);

          my %key = map { ($_ => 1) } @key_methods;

          my $method_names = $meta->column_accessor_method_names;

          if($Debug)
          {
            no warnings;
            warn "$sql - bind params: ", 
              join(', ', (map { $self->$_() } grep { !$key{$_} } @$method_names), 
                          grep { defined } @key_values), "\n";
          }

          if($meta->dbi_requires_bind_param($db))
          {
            my $i = 1;

            foreach my $column (grep { !$key{$_->name} } $meta->columns_ordered)
            {
              my $method = $column->accessor_method_name;
              $sth->bind_param($i++,  $self->$method(), $column->dbi_bind_param_attrs($db));
            }

            foreach my $column_name (@key_columns)
            {
              my $column = $meta->column($column_name);
              my $method = $column->accessor_method_name;
              $sth->bind_param($i++,  $self->$method(), $column->dbi_bind_param_attrs($db));
            }

            $sth->execute;
          }
          else
          {
            $sth->execute(
              (map { $self->$_() } grep { !$key{$_} } @$method_names), 
              @key_values);
          }
        }
      }
      #if($started_new_tx)
      #{
      #  $db->commit or die $db->error;
      #}
    };

    $error = $@;
  }

  if($error)
  {
    $self->error(ref $error ? $error : "update() - $error");
    #$db->rollback or warn $db->error  if($started_new_tx);
    $self->meta->handle_error($self);
    return 0;
  }

  $self->{STATE_IN_DB()} = 1;
  $self->{MODIFIED_COLUMNS()} = {};

  return $self || 1;
}

sub insert
{
  my($self, %args) = @_;

  my $db  = $self->db  or return 0;
  my $dbh = $self->dbh or return 0;

  my $meta = $self->meta;

  my $prepare_cached = 
    exists $args{'prepare_cached'} ? $args{'prepare_cached'} :
    $meta->dbi_prepare_cached;

  my $changes_only =
    exists $args{'changes_only'} ? $args{'changes_only'} :
    $meta->default_insert_changes_only;

  local $self->{STATE_SAVING()} = 1;

  my @pk_methods = $meta->primary_key_column_accessor_names;
  my @pk_values  = grep { defined } map { $self->$_() } @pk_methods;

  #my $ret = $db->begin_work;
  #
  #unless($ret)
  #{
  #  my $error = $db->error;
  #  $self->error(ref $error ? $error : "Could not begin transaction before inserting - $error");
  #  return undef;
  #}
  #
  #my $started_new_tx = ($ret > 0) ? 1 : 0;

  my $using_pk_placeholders = 0;

  unless(@pk_values == @pk_methods || $args{'on_duplicate_key_update'})
  {
    my @generated_pk_values = $meta->generate_primary_key_values($db);

    unless(@generated_pk_values)
    {
      @generated_pk_values = $meta->generate_primary_key_placeholders($db);
      $using_pk_placeholders = 1;
    }

    unless(@generated_pk_values == @pk_methods)
    {
      my $s = (@pk_values == 1 ? '' : 's');
      $self->error("Could not generate primary key$s for column$s " .
                   join(', ', @pk_methods));
      $self->meta->handle_error($self);
      return undef;
    }

    my @pk_set_methods = map { $meta->column_mutator_method_name($_) } 
                         $meta->primary_key_column_names;

    my $i = 0;

    foreach my $name (@pk_set_methods)
    {
      my $pk_value = shift @generated_pk_values;
      next  unless(defined $pk_value);
      $self->$name($pk_value);
    }
  }

  my $error;

  TRY:
  {
    local $@;

    eval
    {
      #local $self->{STATE_SAVING()} = 1;
      local $dbh->{'RaiseError'} = 1;

      #my $options = $meta->prepare_insert_options;

      my $sth;

      if($meta->allow_inline_column_values)
      {
        my($sql, $bind, $bind_params);

        if($args{'on_duplicate_key_update'})
        {
          ($sql, $bind, $bind_params) = 
            $meta->insert_and_on_duplicate_key_update_with_inlining_sql(
              $self, $db, $changes_only);
        }
        elsif($changes_only)
        {
          ($sql, $bind, $bind_params) = $meta->insert_changes_only_sql_with_inlining($self);
        }
        else
        {
          ($sql, $bind, $bind_params) = $meta->insert_sql_with_inlining($self);
        }

        if($Debug)
        {
          no warnings;
          warn "$sql - bind params: ", join(', ', @$bind), "\n";
        }

        $sth = $dbh->prepare($sql); #, $options);

        if($bind_params)
        {
          my $i = 1;

          foreach my $value (@$bind)
          {
            $sth->bind_param($i, $value, $bind_params->[$i - 1]);
            $i++;
          }

          $sth->execute;
        }
        else
        {
          $sth->execute(@$bind);
        }
      }
      else
      {
        my $column_names = $meta->column_names;

        if($args{'on_duplicate_key_update'} || $changes_only)
        {
          my($sql, $bind, $columns);

          if($args{'on_duplicate_key_update'})
          {
            ($sql, $bind, $columns) = 
              $meta->insert_and_on_duplicate_key_update_sql(
                $self, $db, $changes_only);
          }
          else
          {
            ($sql, $bind, $columns) = $meta->insert_changes_only_sql($self, $db);
          }

          if($Debug)
          {
            no warnings;
            warn $sql, " - bind params: @$bind\n";
          }

          $sth = $prepare_cached ? 
            $dbh->prepare_cached($sql, undef, 3) : 
            $dbh->prepare($sql);

          if($meta->dbi_requires_bind_param($db))
          {
            my $i = 1;

            foreach my $column (@$columns)
            {
              my $method = $column->accessor_method_name;
              $sth->bind_param($i++,  $self->$method(), $column->dbi_bind_param_attrs($db));
            }

            $sth->execute;
          }
          else
          {
            $sth->execute(@$bind);
          }
        }
        else
        {
          $sth = $prepare_cached ? 
            $dbh->prepare_cached($meta->insert_sql($db), undef, 3) : 
            $dbh->prepare($meta->insert_sql($db));

          if($Debug)
          {
            no warnings;
            warn $meta->insert_sql($db), " - bind params: ", 
              join(', ', (map {$self->$_()} $meta->column_accessor_method_names)), 
              "\n";
          }

          #$sth->execute(map { $self->$_() } $meta->column_accessor_method_names);

          if($meta->dbi_requires_bind_param($db))
          {
            my $i = 1;

            foreach my $column ($meta->columns_ordered)
            {
              my $method = $column->accessor_method_name;
              $sth->bind_param($i++,  $self->$method(), $column->dbi_bind_param_attrs($db));
            }

            $sth->execute;
          }
          else
          {
            $sth->execute(map { $self->$_() } $meta->column_accessor_method_names);
          }
        }
      }

      if(@pk_methods == 1)
      {
        my $get_pk = $pk_methods[0];

        if($using_pk_placeholders || !defined $self->$get_pk())
        {
          local $self->{STATE_LOADING()} = 1;
          my $set_pk = $meta->column_mutator_method_name($meta->primary_key_column_names);
          #$self->$set_pk($db->last_insertid_from_sth($sth, $self));
          $self->$set_pk($db->last_insertid_from_sth($sth));
          $self->{STATE_IN_DB()} = 1;
        }
        elsif(!$using_pk_placeholders && defined $self->$get_pk())
        {
          $self->{STATE_IN_DB()} = 1;
        }
      }
      elsif(@pk_values == @pk_methods)
      {
        $self->{STATE_IN_DB()} = 1;
      }
      elsif(!$using_pk_placeholders)
      {
        my $have_pk = 1;

        my @pk_set_methods = $meta->primary_key_column_mutator_names;

        my $i = 0;
        my $got_last_insert_id = 0;

        foreach my $pk (@pk_methods)
        {
          unless(defined $self->$pk())
          {
            # XXX: This clause assumes that any db that uses last_insert_id
            # XXX: can only have one such id per table.  This is currently
            # XXX: true for the supported dbs: MySQL, Pg, SQLite, Informix.
            if($got_last_insert_id)
            {
              $have_pk = 0;
              last;
            }
            elsif(my $pk_val = $db->last_insertid_from_sth($sth))
            {
              my $set_pk = $pk_set_methods[$i];
              $self->$set_pk($pk_val);
              $got_last_insert_id = 1;
            }
            else 
            {
              $have_pk = 0;
              last;
            }
          }

          $i++;
        }

        $self->{STATE_IN_DB()} = $have_pk;
      }

      #if($started_new_tx)
      #{
      #  $db->commit or die $db->error;
      #}
    };

    $error = $@;
  }

  if($error)
  {
    $self->error(ref $error ? $error : "insert() - $error");
    #$db->rollback or warn $db->error  if($started_new_tx);
    $self->meta->handle_error($self);
    return 0;
  }

  $self->{MODIFIED_COLUMNS()} = {};

  return $self || 1;
}

my %CASCADE_VALUES = (delete => 'delete', null => 'null', 1 => 'delete');

sub delete
{
  my($self, %args) = @_;

  my $meta = $self->meta;

  my $prepare_cached = 
    exists $args{'prepare_cached'} ? $args{'prepare_cached'} :
    $meta->dbi_prepare_cached;

  local $self->{STATE_SAVING()} = 1;

  my @pk_methods = $meta->primary_key_column_accessor_names;
  my @pk_values  = grep { defined } map { $self->$_() } @pk_methods;

  unless(@pk_values == @pk_methods)
  {
    $self->error("Cannot delete " . ref($self) . " without a primary key (" .
                 join(', ', @pk_methods) . ')');
    $self->meta->handle_error($self);
    return 0;
  }

  # Totally separate code path for cascaded delete
  if(my $cascade = $args{'cascade'})
  {
    unless(exists $CASCADE_VALUES{$cascade})
    {
      Carp::croak "Illegal value for 'cascade' parameter: '$cascade'.  ",
                  "Valid values are 'delete', 'null', and '1'";
    }

    $cascade = $CASCADE_VALUES{$cascade};

    my $mgr_error_mode = Rose::DB::Object::Manager->error_mode;

    my($db, $started_new_tx, $error);

    TRY:
    {
      local $@;

      eval
      {
        $db = $self->db;
        my $meta  = $self->meta;

        my $ret = $db->begin_work;

        unless(defined $ret)
        {
          die 'Could not begin transaction before deleting with cascade - ',
              $db->error;
        }

        $started_new_tx = ($ret == IN_TRANSACTION) ? 0 : 1;

        unless($self->{STATE_IN_DB()})
        {
          $self->load 
            or die "Could not load in preparation for cascading delete: ", 
                   $self->error;
        }

        Rose::DB::Object::Manager->error_mode('fatal');

        my @one_to_one_rels;

        # Process all the rows for each "... to many" relationship
        REL: foreach my $relationship ($meta->relationships)
        {
          my $rel_type = $relationship->type;

          if($rel_type eq 'one to many')
          {
            my $column_map = $relationship->column_map;
            my @query;

            foreach my $local_column (keys %$column_map)
            {
              my $foreign_column = $column_map->{$local_column};

              my $method = $meta->column_accessor_method_name($local_column);
              my $value =  $self->$method();

              # XXX: Comment this out to allow null keys
              next REL  unless(defined $value);

              push(@query, $foreign_column => $value);
            }

            if($cascade eq 'delete')
            {
              Rose::DB::Object::Manager->delete_objects(
                db           => $db,
                object_class => $relationship->class,
                where        => \@query);
            }
            elsif($cascade eq 'null')
            {
              my %set = map { $_ => undef } values(%$column_map);

              Rose::DB::Object::Manager->update_objects(
                db           => $db,
                object_class => $relationship->class,
                set          => \%set,
                where        => \@query);        
            }
            else { Carp::confess "Illegal cascade value '$cascade' snuck through" }
          }
          elsif($rel_type eq 'many to many')
          {
            my $map_class  = $relationship->map_class;
            my $map_from   = $relationship->map_from;

            my $map_from_relationship = 
              $map_class->meta->foreign_key($map_from)  ||
              $map_class->meta->relationship($map_from) ||
              Carp::confess "No foreign key or 'many to one' relationship ",
                            "named '$map_from' in class $map_class";

            my $key_columns = $map_from_relationship->key_columns;
            my @query;

            # "Local" here means "local to the mapping table"
            foreach my $local_column (keys %$key_columns)
            {
              my $foreign_column = $key_columns->{$local_column};

              my $method = $meta->column_accessor_method_name($foreign_column);
              my $value  = $self->$method();

              # XXX: Comment this out to allow null keys
              next REL  unless(defined $value);

              push(@query, $local_column => $value);
            }

            if($cascade eq 'delete')
            {
              Rose::DB::Object::Manager->delete_objects(
                db           => $db,
                object_class => $map_class,
                where        => \@query);
            }
            elsif($cascade eq 'null')
            {
              my %set = map { $_ => undef } keys(%$key_columns);

              Rose::DB::Object::Manager->update_objects(
                db           => $db,
                object_class => $map_class,
                set          => \%set,
                where        => \@query);        
            }
            else { Carp::confess "Illegal cascade value '$cascade' snuck through" }
          }
          elsif($rel_type eq 'one to one')
          {
            push(@one_to_one_rels, $relationship);
          }
        }

        # Delete the object itself
        my $dbh = $db->dbh or die "Could not get dbh: ", $self->error;
        #local $self->{STATE_SAVING()} = 1;
        local $dbh->{'RaiseError'} = 1;

        # $meta->prepare_delete_options (defunct)
        my $sth = $prepare_cached ? $dbh->prepare_cached($meta->delete_sql($db), undef, 3) : 
                                    $dbh->prepare($meta->delete_sql($db));

        $Debug && warn $meta->delete_sql($db), " - bind params: ", join(', ', @pk_values), "\n";
        $sth->execute(@pk_values);

        unless($sth->rows > 0)
        {
          $self->error("Did not delete " . ref($self) . ' where ' . 
                       join(', ', @pk_methods) . ' = ' . join(', ', @pk_values));
        }

        # Process all rows referred to by "one to one" foreign keys
        FK: foreach my $fk ($meta->foreign_keys)
        {
          next  unless($fk->relationship_type eq 'one to one');

          my $key_columns = $fk->key_columns;
          my @query;

          foreach my $local_column (keys %$key_columns)
          {
            my $foreign_column = $key_columns->{$local_column};

            my $method = $meta->column_accessor_method_name($local_column);
            my $value =  $self->$method();

            # XXX: Comment this out to allow null keys
            next FK  unless(defined $value);

            push(@query, $foreign_column => $value);
          }

          if($cascade eq 'delete')
          {
            Rose::DB::Object::Manager->delete_objects(
              db           => $db,
              object_class => $fk->class,
              where        => \@query);
          }
          elsif($cascade eq 'null')
          {
            my %set = map { $_ => undef } values(%$key_columns);

            Rose::DB::Object::Manager->update_objects(
              db           => $db,
              object_class => $fk->class,
              set          => \%set,
              where        => \@query);        
          }
          else { Carp::confess "Illegal cascade value '$cascade' snuck through" }
        }

        # Process all the rows for each "one to one" relationship
        REL: foreach my $relationship (@one_to_one_rels)
        {
          my $column_map = $relationship->column_map;
          my @query;

          foreach my $local_column (keys %$column_map)
          {
            my $foreign_column = $column_map->{$local_column};

            my $method = $meta->column_accessor_method_name($local_column);
            my $value =  $self->$method();

            # XXX: Comment this out to allow null keys
            next REL  unless(defined $value);

            push(@query, $foreign_column => $value);
          }

          if($cascade eq 'delete')
          {
            Rose::DB::Object::Manager->delete_objects(
              db           => $db,
              object_class => $relationship->class,
              where        => \@query);
          }
          elsif($cascade eq 'null')
          {
            my %set = map { $_ => undef } values(%$column_map);

            Rose::DB::Object::Manager->update_objects(
              db           => $db,
              object_class => $relationship->class,
              set          => \%set,
              where        => \@query);        
          }
          else { Carp::confess "Illegal cascade value '$cascade' snuck through" }
        }

        if($started_new_tx)
        {
          $db->commit or die $db->error;
        }
      };

      $error = $@;
    }

    if($error)
    {
      Rose::DB::Object::Manager->error_mode($mgr_error_mode);
      $self->error(ref $error ? $error : "delete() with cascade - $error");
      $db->rollback  if($db && $started_new_tx);
      $self->meta->handle_error($self);
      return 0;
    }

    Rose::DB::Object::Manager->error_mode($mgr_error_mode);
    $self->{STATE_IN_DB()} = 0;
    return 1;
  }
  else
  {
    my $db  = $self->db or return 0;
    my $dbh = $db->dbh or return 0;

    my $error;

    TRY:
    {
      local $@;

      eval
      {
        #local $self->{STATE_SAVING()} = 1;
        local $dbh->{'RaiseError'} = 1;

        # $meta->prepare_delete_options (defunct)
        my $sth = $prepare_cached ? $dbh->prepare_cached($meta->delete_sql($db), undef, 3) : 
                                    $dbh->prepare($meta->delete_sql($db));

        $Debug && warn $meta->delete_sql($db), " - bind params: ", join(', ', @pk_values), "\n";
        $sth->execute(@pk_values);

        unless($sth->rows > 0)
        {
          $self->error("Did not delete " . ref($self) . ' where ' . 
                       join(', ', @pk_methods) . ' = ' . join(', ', @pk_values));
        }
      };

      $error = $@;
    }

    if($error)
    {
      $self->error(ref $error ? $error : "delete() - $error");
      $self->meta->handle_error($self);
      return 0;
    }

    $self->{STATE_IN_DB()} = 0;
    return 1;
  }
}

our $AUTOLOAD;

sub AUTOLOAD
{
  my $self = shift;

  my $msg = '';

  TRY:
  {
    local $@;

    # Not sure if this will ever be used, but just in case...
    eval
    {
      my @fks  = $self->meta->deferred_foreign_keys;
      my @rels = $self->meta->deferred_relationships;

      if(@fks || @rels)
      {
        my $class = ref $self;

        my $tmp_msg =<<"EOF";
Methods for the following relationships and foreign keys were deferred and
then never actually created in the class $class.

TYPE            NAME
----            ----
EOF

        my $found = 0;

        foreach my $thing (@fks, @rels)
        {
          next  unless($thing->parent->class eq $class);

          $found++;

          my $type = 
            $thing->isa('Rose::DB::Object::Metadata::Relationship') ? 'Relationship' :
            $thing->isa('Rose::DB::Object::Metadata::ForeignKey') ? 'Foreign Key' :
            '???';

          $tmp_msg .= sprintf("%-15s %s\n", $type, $thing->name);
        }

        $msg = "\n\n$tmp_msg\n"  if($tmp_msg && $found);
      }
    };

    # XXX: Ignoring errors
  }

  my $method_type = ref $self ? 'object' : 'class';

  if($AUTOLOAD =~ /^(.+)::(.+)$/)
  {
    Carp::confess qq(Can't locate $method_type method "$2" via package "$1"$msg);
  }
  else # not reached?
  {
    Carp::confess qq(Can't locate $method_type method $AUTOLOAD$msg);
  }
}

sub DESTROY { }
# {
#   my($self) = shift;
# 
#   if($self->{FLAG_DB_IS_PRIVATE()})
#   {
#     if(my $db = $self->{'db'})
#     {
#       #$Debug && warn "$self DISCONNECT\n";
#       $db->disconnect;
#     }
#   }
# }

1;

__END__

=head1 NAME

Rose::DB::Object - Extensible, high performance object-relational mapper (ORM).

=head1 SYNOPSIS

  ## For an informal overview of Rose::DB::Object, please
  ## see the Rose::DB::Object::Tutorial documentation.  The
  ## reference documentation follows.

  ## First, set up your Rose::DB data sources, otherwise you
  ## won't be able to connect to the database at all.  See 
  ## the Rose::DB documentation for more information.  For
  ## a quick start, see the Rose::DB::Tutorial documentation.

  ##
  ## Create classes - two possible approaches:
  ##

  #
  # 1. Automatic configuration
  #

  package Category;
  use base qw(Rose::DB::Object);
  __PACKAGE__->meta->setup
  (
    table => 'categories',
    auto  => 1,
  );

  ...

  package Price;
  use base qw(Rose::DB::Object);
  __PACKAGE__->meta->setup
  (
    table => 'prices',
    auto  => 1,
  );

  ...

  package Product;
  use base qw(Rose::DB::Object);
  __PACKAGE__->meta->setup
  (
    table => 'products',
    auto  => 1,
  );

  #
  # 2. Manual configuration
  #

  package Category;

  use base qw(Rose::DB::Object);

  __PACKAGE__->meta->setup
  (
    table => 'categories',

    columns =>
    [
      id          => { type => 'int', primary_key => 1 },
      name        => { type => 'varchar', length => 255 },
      description => { type => 'text' },
    ],

    unique_key => 'name',
  );

  ...

  package Price;

  use base qw(Rose::DB::Object);

  __PACKAGE__->meta->setup
  (
    table => 'prices',

    columns =>
    [
      id         => { type => 'int', primary_key => 1 },
      price      => { type => 'decimal' },
      region     => { type => 'char', length => 3 },
      product_id => { type => 'int' }
    ],

    unique_key => [ 'product_id', 'region' ],
  );

  ...

  package Product;

  use base qw(Rose::DB::Object);

  __PACKAGE__->meta->setup
  (
    table => 'products',

    columns =>
    [
      id          => { type => 'int', primary_key => 1 },
      name        => { type => 'varchar', length => 255 },
      description => { type => 'text' },
      category_id => { type => 'int' },

      status => 
      {
        type      => 'varchar', 
        check_in  => [ 'active', 'inactive' ],
        default   => 'inactive',
      },

      start_date  => { type => 'datetime' },
      end_date    => { type => 'datetime' },

      date_created     => { type => 'timestamp', default => 'now' },  
      last_modified    => { type => 'timestamp', default => 'now' },
    ],

    unique_key => 'name',

    foreign_keys =>
    [
      category =>
      {
        class       => 'Category',
        key_columns => { category_id => 'id' },
      },
    ],

    relationships =>
    [
      prices =>
      {
        type       => 'one to many',
        class      => 'Price',
        column_map => { id => 'product_id' },
      },
    ],
  );

  ...

  #
  # Example usage
  #

  $product = Product->new(id          => 123,
                          name        => 'GameCube',
                          status      => 'active',
                          start_date  => '11/5/2001',
                          end_date    => '12/1/2007',
                          category_id => 5);

  $product->save;

  ...

  $product = Product->new(id => 123);
  $product->load;

  # Load foreign object via "one to one" relationship
  print $product->category->name;

  $product->end_date->add(days => 45);

  $product->save;

  ...

  $product = Product->new(id => 456);
  $product->load;

  # Load foreign objects via "one to many" relationship
  print join ' ', $product->prices;

  ...

=head1 DESCRIPTION

L<Rose::DB::Object> is a base class for objects that encapsulate a single row in a database table.  L<Rose::DB::Object>-derived objects are sometimes simply called "L<Rose::DB::Object> objects" in this documentation for the sake of brevity, but be assured that derivation is the only reasonable way to use this class.

L<Rose::DB::Object> inherits from, and follows the conventions of, L<Rose::Object>.  See the L<Rose::Object> documentation for more information.

For an informal overview of this module distribution, consult the L<Rose::DB::Object::Tutorial>.

=head2 Restrictions

L<Rose::DB::Object> objects can represent rows in almost any database table, subject to the following constraints.

=over 4

=item * The database server must be supported by L<Rose::DB>.

=item * The database table must have a primary key.

=item * The primary key must not allow null values in any of its columns.

=back

Although the list above contains the only hard and fast rules, there may be other realities that you'll need to work around.

The most common example is the existence of a column name in the database table that conflicts with the name of a method in the L<Rose::DB::Object> API.  There are two possible workarounds: either explicitly alias the column, or define a L<mapping function|Rose::DB::Object::Metadata/column_name_to_method_name_mapper>.  See the L<alias_column|Rose::DB::Object::Metadata/alias_column> and L<column_name_to_method_name_mapper|Rose::DB::Object::Metadata/column_name_to_method_name_mapper> methods in the L<Rose::DB::Object::Metadata> documentation for more details.

There are also varying degrees of support for data types in each database server supported by L<Rose::DB>.  If you have a table that uses a data type not supported by an existing L<Rose::DB::Object::Metadata::Column>-derived class, you will have to write your own column class and then map it to a type name using L<Rose::DB::Object::Metadata>'s L<column_type_class|Rose::DB::Object::Metadata/column_type_class> method, yada yada.  (Or, of course, you can map the new type to an existing column class.)

The entire framework is extensible.  This module distribution contains straight-forward implementations of the most common column types, but there's certainly more that can be done.  Submissions are welcome.

=head2 Features

L<Rose::DB::Object> provides the following functions:

=over 4

=item * Create a row in the database by saving a newly constructed object.

=item * Initialize an object by loading a row from the database.

=item * Update a row by saving a modified object back to the database.

=item * Delete a row from the database.

=item * Fetch an object referred to by a foreign key in the current object. (i.e., "one to one" and "many to one" relationships.)

=item * Fetch multiple objects that refer to the current object, either directly through foreign keys or indirectly through a mapping table.  (i.e., "one to many" and "many to many" relationships.)

=item * Load an object along with "foreign objects" that are related through any of the supported relationship types.

=back

Objects can be loaded based on either a primary key or a unique key.  Since all tables fronted by L<Rose::DB::Object>s must have non-null primary keys, insert, update, and delete operations are done based on the primary key.

In addition, its sibling class, L<Rose::DB::Object::Manager>, can do the following:

=over 4

=item * Fetch multiple objects from the database using arbitrary query conditions, limits, and offsets.

=item * Iterate over a list of objects, fetching from the database in response to each step of the iterator.

=item * Fetch objects along with "foreign objects" (related through any of the supported relationship types) in a single query by automatically generating the appropriate SQL join(s).

=item * Count the number of objects that match a complex query.

=item * Update objects that match a complex query.

=item * Delete objects that match a complex query.

=back

L<Rose::DB::Object::Manager> can be subclassed and used separately (the recommended approach), or it can create object manager methods within a L<Rose::DB::Object> subclass.  See the L<Rose::DB::Object::Manager> documentation for more information.

L<Rose::DB::Object> can parse, coerce, inflate, and deflate column values on your behalf, providing the most convenient possible data representations on the Perl side of the fence, while allowing the programmer to completely forget about the ugly details of the data formats required by the database.  Default implementations are included for most common column types, and the framework is completely extensible.

Finally, the L<Rose::DB::Object::Loader> can be used to automatically create a suite of L<Rose::DB::Object> and L<Rose::DB::Object::Manager> subclasses based on the contents of the database.

=head2 Configuration

Before L<Rose::DB::Object> can do any useful work, you must register at least one L<Rose::DB> data source.  By default, L<Rose::DB::Object> instantiates a L<Rose::DB> object by passing no arguments to its constructor.  (See the L<db|/db> method.)  If you register a L<Rose::DB> data source using the default type and domain, this will work fine.  Otherwise, you must override the L<meta|/meta> method in your L<Rose::DB::Object> subclass and have it return the appropriate L<Rose::DB>-derived object.

To define your own L<Rose::DB::Object>-derived class, you must describe the table that your class will act as a front-end for.    This is done through the L<Rose::DB::Object::Metadata> object associated with each L<Rose::DB::Object>-derived class.  The metadata object is accessible via L<Rose::DB::Object>'s L<meta|/meta> method.

Metadata objects can be populated manually or automatically.  Both techniques are shown in the L<synopsis|/SYNOPSIS> above.  The automatic mode works by asking the database itself for the information.  There are some caveats to this approach.  See the L<auto-initialization|Rose::DB::Object::Metadata/"AUTO-INITIALIZATION"> section of the L<Rose::DB::Object::Metadata> documentation for more information.

=head2 Serial and Auto-Incremented Columns

Most databases provide a way to use a series of arbitrary integers as primary key column values.  Some support a native C<SERIAL> column data type.  Others use a special auto-increment column attribute.

L<Rose::DB::Object> supports at least one such serial or auto-incremented column type in each supported database.  In all cases, the L<Rose::DB::Object>-derived class setup is the same:

    package My::DB::Object;
    ...
    __PACKAGE__->meta->setup
    (
      columns =>
      [
        id => { type => 'serial', primary_key => 1, not_null => 1 },
        ...
      ],
      ...
    );

(Note that the column doesn't have to be named "id"; it can be named anything.)

If the database column uses big integers, use "L<bigserial|Rose::DB::Object::Metadata::Column::BigSerial>" column C<type> instead.

Given the column metadata definition above, L<Rose::DB::Object> will automatically generate and/or retrieve the primary key column value when an object is L<save()|/save>d.  Example:

    $o = My::DB::Object->new(name => 'bud'); # no id specified
    $o->save; # new id value generated here

    print "Generated new id value: ", $o->id;

This will only work, however, if the corresponding column definition in the database is set up correctly.  The exact technique varies from vendor to vendor.  Below are examples of primary key column definitions that provide auto-generated values.  There's one example for each of the databases supported by L<Rose::DB>.

=over

=item * PostgreSQL

    CREATE TABLE mytable
    (
      id   SERIAL PRIMARY KEY,
      ...
    );

=item * MySQL

    CREATE TABLE mytable
    (
      id   INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      ...
    );

=item * SQLite

    CREATE TABLE mytable
    (
      id   INTEGER PRIMARY KEY AUTOINCREMENT,
      ...
    );

=item * Informix

    CREATE TABLE mytable
    (
      id   SERIAL NOT NULL PRIMARY KEY,
      ...
    );

=item * Oracle

Since Oracle does not natively support a serial or auto-incremented column data type, an explicit sequence and trigger must be created to simulate the behavior.  The sequence should be named according to this convention: C<E<lt>tableE<gt>_E<lt>columnE<gt>_seq>.  For example, if the table is named C<mytable> and the column is named C<id>, then the sequence should be named C<mytable_id_seq>.  Here's an example database setup.

    CREATE TABLE mytable
    (
      id   INT NOT NULL PRIMARY KEY,
      ...
    );

    CREATE SEQUENCE mytable_id_seq;

    CREATE TRIGGER mytable_insert BEFORE INSERT ON mytable
    FOR EACH ROW
    BEGIN
       IF :new.id IS NULL THEN
           :new.id := mytable_id_seq.nextval;   
       END IF;
    END;

Note the conditional that checks if C<:new.id> is null, which allows the value of the C<id> column to be set explicitly.  If a non-NULL value for the C<id> column is provided, then a new value is not pulled from the sequence.

If the sequence is not named according to the C<E<lt>tableE<gt>_E<lt>columnE<gt>_seq> convention, you can specify the sequence name explicitly in the column metadata.  Example:

    columns =>
    [
      id => { type => 'serial', primary_key => 1, not_null => 1,
              sequence => 'some_other_seq' },
      ...

=back

If the table has a multi-column primary key or does not use a column type that supports auto-generated values, you can define a custom primary key generator function using the L<primary_key_generator|Rose::DB::Object::Metadata/primary_key_generator> method of the L<Rose::DB::Object::Metadata>-derived object that contains the metadata for this class.  Example:

    package MyDBObject;

    use base qw(Rose::DB::Object);

    __PACKAGE__->meta->setup
    (
      table => 'mytable',

      columns =>
      [
        k1   => { type => 'int', not_null => 1 },
        k2   => { type => 'int', not_null => 1 },
        name => { type => 'varchar', length => 255 },
        ...
      ],

      primary_key_columns => [ 'k1', 'k2' ],

      primary_key_generator => sub
      {
        my($meta, $db) = @_;

        # Generate primary key values somehow
        my $k1 = ...;
        my $k2 = ...;

        return $k1, $k2;
      },
    );

See the L<Rose::DB::Object::Metadata> documentation for more information on custom primary key generators.

=head2 Inheritance

Simple, single inheritance between L<Rose::DB::Object>-derived classes is supported.  (Multiple inheritance is not currently supported.)  The first time the L<metadata object|/meta> for a given class is accessed, it is created by making a one-time "deep copy" of the base class's metadata object (as long that the base class has one or more L<columns|Rose::DB::Object::Metadata/columns> set).  This includes all columns, relationships, foreign keys, and other metadata from the base class.  From that point on, the subclass may add to or modify its metadata without affecting any other class.

B<Tip:> When using perl 5.8.0 or later, the L<Scalar::Util::Clone> module is highly recommended.  If it's installed, it will be used to more efficiently clone base-class metadata objects.

If the base class has already been L<initialized|Rose::DB::Object::Metadata/initialize>, the subclass must explicitly specify whether it wants to create a new set of column and relationship methods, or merely inherit the methods from the base class.  If the subclass contains any metadata modifications that affect method creation, then it must create a new set of methods to reflect those changes.  

Finally, note that column types cannot be changed "in-place."  To change a column type, delete the old column and add a new one with the same name.  This can be done in one step with the L<replace_column|Rose::DB::Object::Metadata/replace_column> method.

Example:

  package BaseClass;
  use base 'Rose::DB::Object';

  __PACKAGE__->meta->setup
  (
    table => 'objects',

    columns =>
    [
      id    => { type => 'int', primary_key => 1 },
      start => { type => 'scalar' },
    ],
  );

  ...

  package SubClass;
  use base 'BaseClass';

  # Set a default value for this column.
  __PACKAGE__->meta->column('id')->default(123);

  # Change the "start" column into a datetime column.
  __PACKAGE__->meta->replace_column(start => { type => 'datetime' });

  # Initialize, replacing any inherited methods with newly created ones
  __PACKAGE__->meta->initialize(replace_existing => 1);

  ...

  $b = BaseClass->new;

  $id = $b->id; # undef

  $b->start('1/2/2003');
  print $b->start; # '1/2/2003' (plain string)


  $s = SubClass->new;

  $id = $s->id; # 123

  $b->start('1/2/2003'); # Value is converted to a DateTime object
  print $b->start->strftime('%B'); # 'January'

To preserve all inherited methods in a subclass, do this instead:

  package SubClass;
  use base 'BaseClass';
  __PACKAGE__->meta->initialize(preserve_existing => 1);

=head2 Error Handling

Error handling for L<Rose::DB::Object>-derived objects is controlled by the L<error_mode|Rose::DB::Object::Metadata/error_mode> method of the L<Rose::DB::Object::Metadata> object associated with the class (accessible via the L<meta|/meta> method).  The default setting is "fatal", which means that L<Rose::DB::Object> methods will L<croak|Carp/croak> if they encounter an error.

B<PLEASE NOTE:> The error return values described in the L<object method|/"OBJECT METHODS"> documentation are only relevant when the error mode is set to something "non-fatal."  In other words, if an error occurs, you'll never see any of those return values if the selected error mode L<die|perlfunc/die>s or L<croak|Carp/croak>s or otherwise throws an exception when an error occurs.

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Returns a new L<Rose::DB::Object> constructed according to PARAMS, where PARAMS are name/value pairs.  Any object method is a valid parameter name.

=back

=head1 CLASS METHODS

=over 4

=item B<init_db>

Returns the L<Rose::DB>-derived object used to access the database in the absence of an explicit L<db|/db> value.  The default implementation simply calls L<Rose::DB-E<gt>new()|Rose::DB/new> with no arguments.

Override this method in your subclass in order to use a different default data source.  B<Note:> This method must be callable as both an object method and a class method.

=item B<meta>

Returns the L<Rose::DB::Object::Metadata>-derived object associated with this class.  This object describes the database table whose rows are fronted by this class: the name of the table, its columns, unique keys, foreign keys, etc.

See the L<Rose::DB::Object::Metadata> documentation for more information.

=item B<meta_class>

Return the name of the L<Rose::DB::Object::Metadata>-derived class used to store this object's metadata.  Subclasses should override this method if they want to use a custom L<Rose::DB::Object::Metadata> subclass.  (See the source code for L<Rose::DB::Object::Std> for an example of this.)

=back

=head1 OBJECT METHODS

=over 4

=item B<db [DB]>

Get or set the L<Rose::DB> object used to access the database that contains the table whose rows are fronted by the L<Rose::DB::Object>-derived class.

If it does not already exist, this object is created with a simple, argument-less call to C<Rose::DB-E<gt>new()>.  To override this default in a subclass, override the L<init_db|/init_db> method and return the L<Rose::DB> to be used as the new default.

=item B<init_db>

Returns the L<Rose::DB>-derived object used to access the database in the absence of an explicit L<db|/db> value.  The default implementation simply calls L<Rose::DB-E<gt>new()|Rose::DB/new> with no arguments.

Override this method in your subclass in order to use a different default data source.  B<Note:> This method must be callable as both an object method and a class method.

=item B<dbh [DBH]>

Get or set the L<DBI> database handle contained in L<db|/db>.

=item B<delete [PARAMS]>

Delete the row represented by the current object.  The object must have been previously loaded from the database (or must otherwise have a defined primary key value) in order to be deleted.  Returns true if the row was deleted or did not exist, false otherwise.

PARAMS are optional name/value pairs.  Valid PARAMS are:

=over 4

=item B<cascade TYPE>

Also process related rows.  TYPE must be "delete", "null", or "1".  The value "1" is an alias for "delete".  Passing an illegal TYPE value will cause a fatal error.

For each "one to many" relationship, all of the rows in the foreign ("many") table that reference the current object ("one") will be deleted in "delete" mode, or will have the column(s) that reference the current object set to NULL in "null" mode.

For each "many to many" relationship, all of the rows in the "mapping table" that reference the current object will deleted in "delete" mode, or will have the columns that reference the two tables that the mapping table maps between set to NULL in "null" mode.

For each "one to one" relationship or foreign key with a "one to one" L<relationship type|Rose::DB::Object::Metadata::ForeignKey/relationship_type>, all of the rows in the foreign table that reference the current object will deleted in "delete" mode, or will have the column(s) that reference the current object set to NULL in "null" mode.

In all modes, if the L<db|/db> is not currently in a transaction, a new transaction is started.  If any part of the cascaded delete fails, the transaction is rolled back.

=item B<prepare_cached BOOL>

If true, then L<DBI>'s L<prepare_cached|DBI/prepare_cached> method will be used (instead of the L<prepare|DBI/prepare> method) when preparing the SQL statement that will delete the object.  If omitted, the default value is determined by the L<metadata object|/meta>'s L<dbi_prepare_cached|Rose::DB::Object::Metadata/dbi_prepare_cached> class method.

=back

The cascaded delete feature described above plays it safe by only deleting rows that are not referenced by any other rows (according to the metadata provided by each L<Rose::DB::Object>-derived class).  I B<strongly recommend> that you implement "cascaded delete" in the database itself, rather than using this feature.  It will undoubtedly be faster and more robust than doing it "client-side."  You may also want to cascade only to certain tables, or otherwise deviate from the "safe" plan.  If your database supports automatic cascaded delete and/or triggers, please consider using these features.

=item B<error>

Returns the text message associated with the last error that occurred.

=item B<insert [PARAMS]>

Insert the current object to the database table.  This method should only be used when you're absolutely sure that you want to B<force> the current object to be inserted, rather than updated.  It is recommended that you use the L<save|/save> method instead of this one in most circumstances.  The L<save|/save> method will "do the right thing," executing an insert or update as appropriate for the current situation.

PARAMS are optional name/value pairs.  Valid PARAMS are:

=over 4

=item B<changes_only BOOL>

If true, then only the columns whose values have been modified will be included in the insert query.  Otherwise, all columns will be included.  Note that any column that has a L<default|Rose::DB::Object::Metadata::Column/default> value set in its L<column metadata|Rose::DB::Object::Metadata::Column> is considered "modified" during an insert operation.

If omitted, the default value of this parameter is determined by the L<metadata object|/meta>'s L<default_insert_changes_only|Rose::DB::Object::Metadata/default_insert_changes_only> class method, which returns false by default.

=item B<prepare_cached BOOL>

If true, then L<DBI>'s L<prepare_cached|DBI/prepare_cached> method will be used (instead of the L<prepare|DBI/prepare> method) when preparing the SQL statement that will insert the object.  If omitted, the default value is determined by the L<metadata object|/meta>'s L<dbi_prepare_cached|Rose::DB::Object::Metadata/dbi_prepare_cached> class method.

=back

Returns true if the row was inserted successfully, false otherwise.  The true value returned on success will be the object itself.  If the object L<overload>s its boolean value such that it is not true, then a true value will be returned instead of the object itself.

=item B<load [PARAMS]>

Load a row from the database table, initializing the object with the values from that row.  An object can be loaded based on either a primary key or a unique key.

Returns true if the row was loaded successfully, undef if the row could not be loaded due to an error, or zero (0) if the row does not exist.  The true value returned on success will be the object itself.  If the object L<overload>s its boolean value such that it is not true, then a true value will be returned instead of the object itself.

When loading based on a unique key, unique keys are considered in the order in which they were defined in the L<metadata|/meta> for this class.  If the object has defined values for every column in a unique key, then that key is used.  If no such key is found, then the first key for which the object has at least one defined value is used.

PARAMS are optional name/value pairs.  Valid PARAMS are:

=over 4

=item B<for_update BOOL>

If true, this parameter is translated to be the equivalent of passing the L<lock|/lock> parameter and setting the C<type> to C<for update>.  For example, these are both equivalent:

    $object->load(for_update => 1);
    $object->load(lock => { type => 'for update' });

See the L<lock|/lock> parameter below for more information.

=item B<lock [ TYPE | HASHREF ]>

Load the object using some form of locking.  These lock directives have database-specific behavior and not all directives are supported by all databases.  The value should be a reference to a hash or a TYPE string, which is equivalent to setting the value of the C<type> key in the hash reference form.  For example, these are both equivalent:

    $object->load(lock => 'for update');
    $object->load(lock => { type => 'for update' });

Valid hash keys are:

=over 4

=item B<columns ARRAYREF>

A reference to an array of column names to lock.  References to scalars will be de-referenced and used as-is, included literally in the SQL locking clause.

=item C<nowait BOOL>

If true, do not wait to acquire the lock.    If supported, this is usually by adding a C<NOWAIT> directive to the SQL.

=item C<type TYPE>

The lock type.  Valid values for TYPE are C<for update> and C<shared>.  This parameter is required unless the L<for_update|/for_update> parameter was passed with a true value.

=item C<wait TIME>

Wait for the specified TIME (generally seconds) before giving up acquiring the lock.  If supported, this is usually by adding a C<WAIT ...> clause to the SQL.

=back

=item B<nonlazy BOOL>

If true, then all columns will be fetched from the database, even L<lazy|Rose::DB::Object::Metadata::Column/load_on_demand> columns.  If omitted, the default is false.

=item B<prepare_cached BOOL>

If true, then L<DBI>'s L<prepare_cached|DBI/prepare_cached> method will be used (instead of the L<prepare|DBI/prepare> method) when preparing the SQL query that will load the object.  If omitted, the default value is determined by the L<metadata object|/meta>'s L<dbi_prepare_cached|Rose::DB::Object::Metadata/dbi_prepare_cached> class method.

=item B<speculative BOOL>

If this parameter is passed with a true value, and if the load failed because the row was L<not found|/not_found>, then the L<error_mode|Rose::DB::Object::Metadata/error_mode> setting is ignored and zero (0) is returned.  In the absence of an explicitly set value, this parameter defaults to the value returned my the L<metadata object|/meta>'s L<default_load_speculative|Rose::DB::Object::Metadata/default_load_speculative> method.

=item B<use_key KEY>

Use the unique key L<name|Rose::DB::Object::Metadata::UniqueKey/name>d KEY to load the object.  This overrides the unique key selection process described above.  The key must have a defined value in at least one of its L<columns|Rose::DB::Object::Metadata::UniqueKey/columns>.

=item B<with OBJECTS>

Load the object and the specified "foreign objects" simultaneously.  OBJECTS should be a reference to an array of L<foreign key|Rose::DB::Object::Metadata/foreign_keys> or L<relationship|Rose::DB::Object::Metadata/relationships> names.

=back

B<SUBCLASS NOTE:> If you are going to override the L<load|/load> method in your subclass, you I<must> pass an I<alias to the actual object> as the first argument to the method, rather than passing a copy of the object reference.  Example:

    # This is the CORRECT way to override load() while still
    # calling the base class version of the method.
    sub load
    {
      my $self = $_[0]; # Copy, not shift

      ... # Do your stuff

      shift->SUPER::load(@_); # Call superclass
    }

Now here's the wrong way:

    # This is the WRONG way to override load() while still
    # calling the base class version of the method.
    sub load
    {
      my $self = shift; # WRONG! The alias to the object is now lost!

      ... # Do your stuff

      $self->SUPER::load(@_); # This won't work right!
    }

This requirement exists in order to preserve some sneaky object-replacement optimizations in the base class implementation of L<load|/load>.  At some point, those optimizations may change or go away.  But if you follow these guidelines, your code will continue to work no matter what.

=item B<not_found>

Returns true if the previous call to L<load|/load> failed because a row in the database table with the specified primary or unique key did not exist, false otherwise.

=item B<meta>

Returns the L<Rose::DB::Object::Metadata> object associated with this class.  This object describes the database table whose rows are fronted by this class: the name of the table, its columns, unique keys, foreign keys, etc.

See the L<Rose::DB::Object::Metadata> documentation for more information.

=item B<save [PARAMS]>

Save the current object to the database table.  In the absence of PARAMS, if the object was previously L<load|/load>ed from the database, the row will be L<update|/update>d.  Otherwise, a new row will be L<insert|/insert>ed.  PARAMS are name/value pairs.  Valid PARAMS are listed below.

Actions associated with sub-objects that were added or deleted using one of the "*_on_save" relationship or foreign key method types are also performed when this method is called.  If there are any such actions to perform, a new transaction is started if the L<db|/db> is not already in one, and L<rollback()|Rose::DB/rollback> is called if any of the actions fail during the L<save()|/save>.  Example:

    $product = Product->new(name => 'Sled');
    $vendor  = Vendor->new(name => 'Acme');  

    $product->vendor($vendor);

    # Product and vendor records created and linked together,
    # all within a single transaction.
    $product->save;

See the "making methods" sections of the L<Rose::DB::Object::Metadata::Relationship|Rose::DB::Object::Metadata::Relationship/"MAKING METHODS"> and L<Rose::DB::Object::Metadata::ForeignKey|Rose::DB::Object::Metadata::ForeignKey/"MAKING METHODS"> documentation for a description of the "method map" associated with each relationship and foreign key.  Only the actions initiated through one of the "*_on_save" method types are handled when L<save()|/save> is called.  See the documentation for each individual "*_on_save" method type for more specific information.

Valid parameters to L<save()|/save> are:

=over 4

=item B<cascade BOOL>

If true, then sub-objects related to this object through a foreign key or relationship that have been previously loaded using methods called on this object and that contain unsaved changes will be L<saved|/save> after the parent object is saved.  This proceeds recursively through all sub-objects.  (All other parameters to the original call to L<save|/save> are also passed on when saving sub-objects.)

All database operations are done within a single transaction.  If the L<db|/db> is not currently in a transaction, a new transaction is started.  If any part of the cascaded save fails, the transaction is rolled back.

If omitted, the default value of this parameter is determined by the L<metadata object|/meta>'s L<default_cascade_save|Rose::DB::Object::Metadata/default_cascade_save> class method, which returns false by default.

Example:

    $p = Product->new(id => 123)->load;

    print join(', ', $p->colors); # related Color objects loaded
    $p->colors->[0]->code('zzz'); # one Color object is modified

    # The Product object and the modified Color object are saved
    $p->save(cascade => 1);

=item B<changes_only BOOL>

If true, then only the columns whose values have been modified will be included in the insert or update query.  Otherwise, all eligible columns will be included.  Note that any column that has a L<default|Rose::DB::Object::Metadata::Column/default> value set in its L<column metadata|Rose::DB::Object::Metadata::Column> is considered "modified" during an insert operation.

If omitted, the default value of this parameter is determined by the L<metadata object|/meta>'s L<default_update_changes_only|Rose::DB::Object::Metadata/default_update_changes_only> class method on update, and the L<default_insert_changes_only|Rose::DB::Object::Metadata/default_insert_changes_only> class method on insert, both of which return false by default.

=item B<insert BOOL>

If set to a true value, then an L<insert|/insert> is attempted, regardless of whether or not the object was previously L<load|/load>ed from the database.

=item B<prepare_cached BOOL>

If true, then L<DBI>'s L<prepare_cached|DBI/prepare_cached> method will be used (instead of the L<prepare|DBI/prepare> method) when preparing the SQL statement that will save the object.  If omitted, the default value is determined by the L<metadata object|/meta>'s L<dbi_prepare_cached|Rose::DB::Object::Metadata/dbi_prepare_cached> class method.

=item B<update BOOL>

If set to a true value, then an L<update|/update> is attempted, regardless of whether or not the object was previously L<load|/load>ed from the database.

=back

It is an error to pass both the C<insert> and C<update> parameters in a single call.

Returns true if the row was inserted or updated successfully, false otherwise.  The true value returned on success will be the object itself.  If the object L<overload>s its boolean value such that it is not true, then a true value will be returned instead of the object itself.

If an insert was performed and the primary key is a single column that supports auto-generated values, then the object accessor for the primary key column will contain the auto-generated value.  See the L<Serial and Auto-Incremented Columns|/"Serial and Auto-Incremented Columns"> section for more information.

=item B<update [PARAMS]>

Update the current object in the database table.  This method should only be used when you're absolutely sure that you want to B<force> the current object to be updated, rather than inserted.  It is recommended that you use the L<save|/save> method instead of this one in most circumstances.  The L<save|/save> method will "do the right thing," executing an insert or update as appropriate for the current situation.

PARAMS are optional name/value pairs.  Valid PARAMS are:

=over 4

=item B<changes_only BOOL>

If true, then only the columns whose values have been modified will be updated.  Otherwise, all columns whose values have been loaded from the database will be updated.  If omitted, the default value of this parameter is determined by the L<metadata object|/meta>'s L<default_update_changes_only|Rose::DB::Object::Metadata/default_update_changes_only> class method, which returns false by default.

=item B<prepare_cached BOOL>

If true, then L<DBI>'s L<prepare_cached|DBI/prepare_cached> method will be used (instead of the L<prepare|DBI/prepare> method) when preparing the SQL statement that will insert the object.  If omitted, the default value of this parameter is determined by the L<metadata object|/meta>'s L<dbi_prepare_cached|Rose::DB::Object::Metadata/dbi_prepare_cached> class method.

=back

Returns true if the row was updated successfully, false otherwise.  The true value returned on success will be the object itself.  If the object L<overload>s its boolean value such that it is not true, then a true value will be returned instead of the object itself.

=back

=head1 RESERVED METHODS

As described in the L<Rose::DB::Object::Metadata> documentation, each column in the database table has an associated get/set accessor method in the L<Rose::DB::Object>.  Since the L<Rose::DB::Object> API already defines many methods (L<load|/load>, L<save|/save>, L<meta|/meta>, etc.), accessor methods for columns that share the name of an existing method pose a problem.  The solution is to alias such columns using L<Rose::DB::Object::Metadata>'s  L<alias_column|Rose::DB::Object::Metadata/alias_column> method. 

Here is a list of method names reserved by the L<Rose::DB::Object> API.  If you have a column with one of these names, you must alias it.

    db
    dbh
    delete
    DESTROY
    error
    init_db
    _init_db
    insert
    load
    meta
    meta_class
    not_found
    save
    update

Note that not all of these methods are public.  These methods do not suddenly become public just because you now know their names!  Remember the stated policy of the L<Rose> web application framework: if a method is not documented, it does not exist.  (And no, the list of method names above does not constitute "documentation.")

=head1 DEVELOPMENT POLICY

The L<Rose development policy|Rose/"DEVELOPMENT POLICY"> applies to this, and all C<Rose::*> modules.  Please install L<Rose> from CPAN and then run "C<perldoc Rose>" for more information.

=head1 SUPPORT

For an informal overview of L<Rose::DB::Object>, consult the L<Rose::DB::Object::Tutorial>.

    perldoc Rose::DB::Object::Tutorial

Any L<Rose::DB::Object> questions or problems can be posted to the L<Rose::DB::Object> mailing list.  To subscribe to the list or view the archives, go here:

L<http://groups.google.com/group/rose-db-object>

Although the mailing list is the preferred support mechanism, you can also email the author (see below) or file bugs using the CPAN bug tracking system:

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-DB-Object>

There's also a wiki and other resources linked from the Rose project home page:

L<http://rosecode.org>

=head1 CONTRIBUTORS

Bradley C Bailey, Graham Barr, Kostas Chatzikokolakis, David Christensen, Lucian Dragus, Justin Ellison, Perrin Harkins, Cees Hek, Benjamin Hitz, Dave Howorth, Peter Karman, Ed Loehr, Adam Mackler, Michael Reece, Thomas Whaples, Douglas Wilson, Teodor Zlatanov

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
