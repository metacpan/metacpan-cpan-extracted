package Rose::DB::Object::Manager;

use strict;

use Carp();

use List::Util qw(first);
#use List::MoreUtils qw(uniq);
use Scalar::Util qw(weaken refaddr);

use Rose::DB::Object::Iterator;
use Rose::DB::Object::QueryBuilder qw(build_select build_where_clause);
use Rose::DB::Object::Constants
  qw(PRIVATE_PREFIX STATE_LOADING STATE_IN_DB MODIFIED_COLUMNS);

# XXX: A value that is unlikely to exist in a primary key column value
use constant PK_JOIN => "\0\2,\3\0";

our $VERSION = '0.813';

our $Debug = 0;

#
# Class data
#

use Rose::Class::MakeMethods::Generic
(
  inheritable_scalar =>
  [
    'error',
    'total', 
    'error_mode',
    '_object_class',
    '_base_name',
    '_default_manager_method_types',
    'default_objects_per_page',
    'default_limit_with_subselect',
    'default_nested_joins',
    'dbi_prepare_cached',
    'strict_ops',
  ],
);

__PACKAGE__->error_mode('fatal');
__PACKAGE__->default_objects_per_page(20);
__PACKAGE__->default_limit_with_subselect(1);
__PACKAGE__->default_nested_joins(1);
__PACKAGE__->dbi_prepare_cached(0);
__PACKAGE__->strict_ops(0);
__PACKAGE__->default_manager_method_types(qw(objects iterator count delete update));

sub handle_error
{
  my($class, $object) = @_;

  my $mode = $class->error_mode;

  return  if($mode eq 'return');

  my $level = $Carp::CarpLevel;
  local $Carp::CarpLevel = $level + 1;  

  if($mode eq 'croak' || $mode eq 'fatal')
  {
    Carp::croak $object->error;
  }
  elsif($mode eq 'carp')
  {
    Carp::carp $object->error;
  }
  elsif($mode eq 'cluck')
  {
    Carp::croak $object->error;
  }
  elsif($mode eq 'confess')
  {
    Carp::confess $object->error;
  }
  else
  {
    Carp::croak "(Invalid error mode set: '$mode') - ", $object->error;
  }

  return 1;
}

sub normalize_get_objects_args
{
  # Handle all these arg forms:
  #
  #   get_objects(a => b, c => d, ...);
  #   get_objects([ ... ], a => b, c => d, ...)
  #   get_objects({ ... }, a => b, c => d, ...)

  if(ref $_[1])
  {
    my $class = shift;

    if(ref $_[0] eq 'HASH')
    {
      return ($class, query => [ %{shift(@_)} ], @_);
    }
    elsif(ref $_[0] eq 'ARRAY')
    {
      return ($class, query => shift, @_);
    }
    else { Carp::croak 'Invalid arguments: ', join(', ', @_) }
  }

  return @_;
}

# XXX: These are duplicated from ManyToMany.pm because I don't want to use()
# XXX: that module from here if I don't have to.  Lazy or foolish?  Hm.
# XXX: Anyway, make sure they stay in sync!
use constant MAP_RECORD_METHOD => 'map_record';
use constant DEFAULT_REL_KEY   => PRIVATE_PREFIX . '_default_rel_key';

sub object_class { }

sub default_manager_method_types
{
  my($class) = shift;

  if(@_)
  {
    if(@_ == 1 && ref $_[0] eq 'ARRAY')
    {
      $class->_default_manager_method_types(@_);
    }
    else
    {
      $class->_default_manager_method_types([ @_ ]);
    }
  }

  return wantarray ? 
    @{$class->_default_manager_method_types} : $class->_default_manager_method_types;
}

sub make_manager_methods
{
  my($class) = shift;

  if(@_ == 1)
  {
    @_ = (methods => { $_[0] => [ $class->default_manager_method_types ] });
  }
  else
  {
    Carp::croak "make_manager_methods() called with an odd number of arguments"  
      unless(@_ % 2 == 0);
  }

  my %args = @_;

  local $Debug = $args{'debug'}  if(exists $args{'debug'});

  my $calling_class  = ($class eq __PACKAGE__) ? (caller)[0] : $class;
  my $target_class   = $args{'target_class'} || $calling_class;
  my $object_class   = $args{'object_class'};
  my $class_invocant = UNIVERSAL::isa($target_class, __PACKAGE__) ? 
                         $target_class : __PACKAGE__;

  unless($object_class)
  {
    if(UNIVERSAL::isa($target_class, 'Rose::DB::Object::Manager'))
    {
      $object_class = $target_class->object_class;
    }

    if(!$object_class && UNIVERSAL::isa($target_class, 'Rose::DB::Object'))
    {
      $object_class = $target_class;
    }
  }

  unless($object_class)
  {
    Carp::croak "Could not determine object class.  Please pass a value for ",
                "the object_class parameter", 
                (UNIVERSAL::isa($target_class, 'Rose::DB::Object::Manager') ?
                 " or override the object_class() method in $target_class" : '');
  }

  unless(UNIVERSAL::isa($object_class, 'Rose::DB::Object'))
  {
    my $error;

    TRY:
    {
      local $@;
      eval "require $object_class";
      $error = $@;
    }

    if($error)
    {
      Carp::croak "Could not load object class $object_class - $error";
    }
  }

  my $meta = $object_class->meta;
  my $cm   = $meta->convention_manager;

  my $base_name = $args{'base_name'} || $cm->auto_manager_base_name($meta->table, $object_class);

  if(!$args{'methods'})
  {
    unless($base_name)
    {
      Carp::croak "Missing methods parameter and base_name parameter, and the ",
                  "convention manager's auto_manager_base_name() method did not ",
                  "return a true value"
    }

    $args{'methods'} = 
    { 
      $base_name => [ $class->default_manager_method_types ] 
    };
  }
  elsif($args{'base_name'})
  {
    Carp::croak "Please pass the methods parameter OR the base_name parameter, not both";
  }

  Carp::croak "Invalid 'methods' parameter - should be a hash ref"
    unless(ref $args{'methods'} eq 'HASH');

  $class->_base_name($base_name);
  $class->_object_class($object_class);

  while(my($name, $types) = each %{$args{'methods'}})
  {
    $class->_base_name($name)  unless($base_name);

    my $have_full_name = ($name =~ s/\(\)$//) ? 1 : 0;

    Carp::croak "Invalid value for the '$name' parameter"
      if(ref $types && ref $types ne 'ARRAY');

    if($have_full_name && ref $types && @$types > 1)
    {
      Carp::croak "Cannot use explicit method name $name() with more ",
                  "than one method type";
    }

    foreach my $type ((ref $types ? @$types : ($types)))
    {
      no strict 'refs';

      if($type eq 'objects')
      {
        my $method_name = 
          $have_full_name ? $name : 
            ($cm->auto_manager_method_name($type, $base_name, $object_class) || "get_$name");

        foreach my $class ($target_class, $class_invocant)
        {
          my $method = "${class}::$method_name";
          my $short_method = $method_name;
          Carp::croak "A $method method already exists"
            if(defined &{$method});

          Carp::croak "The $short_method method is inherited from Rose::DB::Object::Manager ",
                      "and cannot be overriden in $target_class"
            if(Rose::DB::Object::Manager->can($short_method));
        }

        $Debug && warn "Making method: $target_class->$method_name()\n";
        *{"${target_class}::$method_name"} = sub
        {
          shift;
          $class_invocant->get_objects(@_, object_class => $object_class);
        };
      }
      elsif($type eq 'count')
      {
        my $method_name = 
          $have_full_name ? $name : 
            ($cm->auto_manager_method_name($type, $base_name, $object_class) || "get_${name}_count");

        foreach my $class ($target_class, $class_invocant)
        {
          my $method = "${class}::$method_name";
          Carp::croak "A $method method already exists"
            if(defined &{$method});
        }

        $Debug && warn "Making method: $target_class->$method_name()\n";
        *{"${target_class}::$method_name"} = sub
        {
          shift;
          $class_invocant->get_objects(
            @_, count_only => 1, object_class => $object_class)
        };
      }
      elsif($type eq 'iterator')
      {
        my $method_name = 
          $have_full_name ? $name : 
            ($cm->auto_manager_method_name($type, $base_name, $object_class) || "get_${name}_iterator");

        foreach my $class ($target_class, $class_invocant)
        {
          my $method = "${class}::$method_name";
          Carp::croak "A $method method already exists"
            if(defined &{$method});
        }

        $Debug && warn "Making method: $target_class->$method_name()\n";
        *{"${target_class}::$method_name"} = sub
        {
          shift;
          $class_invocant->get_objects(
            @_, return_iterator => 1, object_class => $object_class)
        };
      }
      elsif($type eq 'delete')
      {
        my $method_name = 
          $have_full_name ? $name : 
            ($cm->auto_manager_method_name($type, $base_name, $object_class) || "delete_$name");

        foreach my $class ($target_class, $class_invocant)
        {
          my $method = "${class}::$method_name";
          Carp::croak "A $method method already exists"
            if(defined &{$method});
        }

        $Debug && warn "Making method: $target_class->$method_name()\n";
        *{"${target_class}::$method_name"} = sub
        {
          shift;
          $class_invocant->delete_objects(@_, object_class => $object_class);
        };
      }
      elsif($type eq 'update')
      {
        my $method_name = 
          $have_full_name ? $name : 
            ($cm->auto_manager_method_name($type, $base_name, $object_class) || "update_$name");

        foreach my $class ($target_class, $class_invocant)
        {
          my $method = "${class}::$method_name";
          Carp::croak "A $method method already exists"
            if(defined &{$method});
        }

        $Debug && warn "Making method: $target_class->$method_name()\n";
        *{"${target_class}::$method_name"} = sub
        {
          shift;
          $class_invocant->update_objects(@_, object_class => $object_class);
        };
      }
      else
      {
        Carp::croak "Invalid method type: $type";
      }
    }
  }
}

sub get_objects_count
{
  my($class) = shift;
  $class->get_objects(@_, count_only => 1);
}

sub get_objects_iterator { shift->get_objects(@_, return_iterator => 1) }
sub get_objects_sql      { shift->get_objects(@_, return_sql => 1) }

use constant WITH => 555; # arbitrary

sub get_objects
{
  my($class, %args);

  if(ref $_[1])
  {
    $class = shift;

    if(ref $_[0] eq 'HASH')
    {
      %args = (query => [ %{shift(@_)} ], @_);
    }
    elsif(ref $_[0] eq 'ARRAY')
    {
      %args = (query => shift, @_);
    }
    else { Carp::croak 'Invalid arguments: ', join(', ', @_) }

    unshift(@_, $class); # restore original args  
  }
  else
  {
    ($class, %args) = @_;
  }

  $class->error(undef);

  my $object_class = delete $args{'object_class'} 
    || $class->object_class || Carp::croak "Missing object class argument";

  my $return_sql       = delete $args{'return_sql'};
  my $return_iterator  = delete $args{'return_iterator'};
  my $count_only       = delete $args{'count_only'};
  my $require_objects  = delete $args{'require_objects'};
  my $with_objects     = delete $args{'with_objects'};

  my $skip_first       = delete $args{'skip_first'} || 0;
  my $distinct         = delete $args{'distinct'};
  my $fetch            = delete $args{'fetch_only'};
  my $hints            = delete $args{'hints'} || {};
  my $select           = $args{'select'};

  # Alias by popular demand...
  $args{'query'} = delete $args{'where'}
    if($args{'where'} && !exists $args{'query'});

  $args{'strict_ops'} = $class->strict_ops  unless(exists $args{'strict_ops'});

  my $no_forced_sort = delete $args{'no_forced_sort'};

  my $table_aliases    = exists $args{'table_aliases'} ? 
    $args{'table_aliases'} : ($args{'table_aliases'} = 1);

  # Coerce for_update boolean alias into lock argument
  if(delete $args{'for_update'})
  {
    $args{'lock'}{'type'} ||= 'for update';
  }

  $with_objects    = undef  if(ref $with_objects && !@$with_objects);
  $require_objects = undef  if(ref $require_objects && !@$require_objects);

  local $Debug = $args{'debug'}  if(exists $args{'debug'});

  my $try_subselect_limit = (exists $args{'limit_with_subselect'}) ? 
    $args{'limit_with_subselect'} : $class->default_limit_with_subselect;

  my $subselect_limit = 0;

  # Can't do direct inject with custom select lists
  my $direct_inject = $select ? 0 : delete $args{'inject_results'};

  my(%fetch, %rel_name, %di_keys);

  my $meta = $object_class->meta;

  $args{'hints'} = $hints->{'t1'} || $hints->{$meta->table} || $hints;

  my $prepare_cached = 
    exists $args{'prepare_cached'} ? $args{'prepare_cached'} :
    $class->dbi_prepare_cached;

  my $db   = delete $args{'db'} || $object_class->init_db;
  my $dbh  = delete $args{'dbh'};
  my $dbh_retained = 0;

  unless($dbh)
  {
    unless($dbh = $db->retain_dbh)
    {
      $class->error($db->error);
      $class->handle_error($class);
      return undef;
    }

    $dbh_retained = 1;
  }

  # Work-around for http://rt.cpan.org//Ticket/Display.html?id=33193
  local $dbh->{'pg_expand_array'} = 0
    if($dbh->{'Driver'}{'Name'} eq 'Pg' && index($dbh->{'Driver'}{'Version'}, '2.0.') == 0);

  my $nested_joins = $args{'nested_joins'} = $db->supports_nested_joins ?
    (defined $args{'nested_joins'} ? $args{'nested_joins'} : $class->default_nested_joins) : 0;

  my $use_explicit_joins = (defined $args{'explicit_joins'}) ? 
    $args{'explicit_joins'} : !$db->likes_implicit_joins;

  my $with_map_records;

  if($with_map_records = delete $args{'with_map_records'})
  {
    unless(ref $with_map_records)
    {
      if($with_map_records =~ /^[A-Za-z_]\w*$/)
      {
        $with_map_records = { DEFAULT_REL_KEY() => $with_map_records };
      }
      elsif($with_map_records)
      {
        $with_map_records = { DEFAULT_REL_KEY() => MAP_RECORD_METHOD };
      }
      else
      {
        $with_map_records = 0;
      }
    }
  }

  my $outer_joins = ($with_objects && !$require_objects) ? 1 : 0;

  my($num_required_objects, %required_object, $num_with_objects,
     %with_objects, @belongs_to, %seen_rel, %rel_tn, %join_type);

  $with_objects    = [ $with_objects ]     if($with_objects && !ref $with_objects);
  $require_objects = [ $require_objects ]  if($require_objects && !ref $require_objects);

  #print STDERR 'WITH: ', Dumper($with_objects);
  #print STDERR 'REQUIRE: ', Dumper($require_objects);

  # XXX: Currently, the most robust join-type conflict checking only
  # XXX: happens if a least one join-type override is present.  In
  # XXX: other cases, the "with" wins.  This is "safe" but not 
  # XXX: necessarily efficient.

  # If there are any join-type overrides
  if(first { index($_, '!') > 0 || index($_, '?') > 0 }
     (($with_objects ? @$with_objects : ()),
      ($require_objects ? @$require_objects : ())))
  {
    my $i = 0;
    my $requires_start = $with_objects ? @$with_objects : 0;
    my $in_require = 0;
    my $join_type;

    # Pull out the join modifiers
    foreach my $arg (($with_objects ? @$with_objects : ()),
                     ($require_objects ? @$require_objects : ()))
    {
      $in_require = 1  if(!$in_require && $i++ == $requires_start);

      my $save_arg = $arg;
      $arg =~ tr/!?//d;

      if(index($arg, '.') < 0)
      {
        $save_arg =~ s/([!?])$//;

        no warnings 'uninitialized';
        $join_type = ($1 eq '!' || (!$1 && $in_require)) ? 'JOIN' : 'LEFT OUTER JOIN';

        Carp::croak "Conflicting suffix for '$arg' - please choose either ! or ?"
          if($join_type{$arg} && $join_type{$arg} ne $join_type);

        $join_type{$arg} = $join_type;
      }
      else
      {
        $save_arg =~ s/([!?])$//;

        no warnings 'uninitialized';
        $join_type = ($1 eq '!' || (!$1 && $in_require)) ? 'JOIN' : 'LEFT OUTER JOIN';

        Carp::croak "Conflicting suffix for '$arg' - please choose either ! or ?"
          if($join_type{$arg} && $join_type{$arg} ne $join_type);

        $join_type{$arg} = $join_type;

        while($save_arg =~ s/\.[^.]+$//)
        {
          $save_arg =~ s/([!?])$//;

          $join_type = ($1 eq '!' || (!$1 && $in_require)) ? 'JOIN' : 'LEFT OUTER JOIN';

          (my $clean_arg = $save_arg) =~ tr/!?//d;

          Carp::croak "Conflicting suffix for '$clean_arg' - please choose either ! or ?"
            if($join_type{$clean_arg} && $join_type{$clean_arg} ne $join_type);

          $join_type{$clean_arg} = $join_type;
        }
      }
    }

    if(grep { $_ eq 'LEFT OUTER JOIN' } values %join_type)
    {
      $outer_joins = 1;
    }
  }

  # Putting join conditions in the WHERE clause can change the meaning of
  # the query when outer joins are used, so disable them in that case.
  my $use_redundant_join_conditions =
    $outer_joins ? 0 : delete $args{'redundant_join_conditions'};

  #use Data::Dumper;
  #print STDERR 'JOIN TYPES: ', Dumper(\%join_type);
  #print STDERR 'POST WITH: ', Dumper($with_objects);
  #print STDERR 'POST REQUIRE: ', Dumper($require_objects);

  if($with_objects)
  {
    # Doing this implicitly is never a good idea
    #unless(defined $use_redundant_join_conditions)
    #{
    #  $use_redundant_join_conditions = $db->likes_redundant_join_conditions;
    #}

    # Copy argument (shallow copy)
    $with_objects = [ @$with_objects ]; #[ uniq @$with_objects ];

    # Expand multi-level arguments
    if(first { index($_, '.') >= 0 } @$with_objects)
    {
      my @with_objects;

      foreach my $arg (@$with_objects)
      {
        next  if($seen_rel{$arg});

        if(index($arg, '.') < 0)
        {
          $seen_rel{$arg} = WITH;
          push(@with_objects, $arg);
        }
        else
        {
          my @expanded = ($arg);
          $seen_rel{$arg} = WITH;

          while($arg =~ s/\.([^.]+)$//)
          {
            next  if($seen_rel{$arg}++);
            unshift(@expanded, $arg);
          }

          push(@with_objects, @expanded);          
        }
      }

      $with_objects = \@with_objects;
    }
    else
    {
      $seen_rel{$_} = WITH  for(@$with_objects);
    }

    $num_with_objects = @$with_objects;
    %with_objects = map { $_ => 1 } @$with_objects;
  }

  if($require_objects)
  {
    # Copy argument (shallow copy)
    $require_objects = [ @$require_objects ]; #[ uniq @$require_objects ];

    # Expand multi-level arguments
    if(first { index($_, '.') >= 0 } @$require_objects)
    {
      my @require_objects;

      foreach my $arg (@$require_objects)
      {
        if(index($arg, '.') < 0)
        {
          if(my $seen = $seen_rel{$arg})
          {
            if($seen == WITH)
            {
              Carp::croak "require_objects argument '$arg' conflicts with ",
                          "with_objects argument of the same name";
            }
            next;
          }

          $seen_rel{$arg}++;
          push(@require_objects, $arg);
        }
        else
        {
          my @expanded = ($arg);

          if(my $seen = $seen_rel{$arg})
          {
            if($seen == WITH)
            {
              Carp::croak "require_objects argument '$arg' conflicts with ",
                          "with_objects argument of the same name";
            }
            next;
          }

          $seen_rel{$arg}++;

          while($arg =~ s/\.[^.]+$//)
          {
            next  if($seen_rel{$arg});
            unshift(@expanded, $arg);
            $seen_rel{$arg}++;
          }

          push(@require_objects, @expanded);          
        }
      }

      $require_objects = \@require_objects;
    }
    else
    {
      foreach my $arg (@$require_objects)
      {
        if($seen_rel{$arg})
        {
          Carp::croak "require_objects argument '$arg' conflicts with ",
                      "with_objects argument of the same name";
        }
      }
    }

    $num_required_objects = @$require_objects;
    %required_object = map { $_ => 1 } @$require_objects;
    push(@$with_objects, @$require_objects)
  }

  my %object_args = (ref $args{'object_args'} eq 'HASH') ? %{$args{'object_args'}} : ();
  my %subobject_args;

  $args{'share_db'} = 1  unless(exists $args{'share_db'});

  if(delete $args{'share_db'})
  {
    $object_args{'db'}    = $db;
    $subobject_args{'db'} = $db;
  }

  my($fields, $fields_string, $table);

  $args{'nonlazy'} = []  unless(defined $args{'nonlazy'});
  my $nonlazy = $args{'nonlazy'};
  my %nonlazy = (ref $nonlazy ? map { $_ => 1 } @$nonlazy : ());

  my @tables     = ($meta->fq_table($db));
  my @tables_sql = ($meta->fq_table_sql($db));

  my $use_lazy_columns = (!ref $nonlazy || $nonlazy{'self'}) ? 0 : $meta->has_lazy_columns;

  my(%columns, %methods, %all_columns);

  if($use_lazy_columns)
  {
    %columns     = ($tables[0] => scalar $meta->nonlazy_columns);
    %all_columns = ($tables[0] => scalar $meta->columns);
    %methods     = ($tables[0] => scalar $meta->nonlazy_column_mutator_method_names);
    %di_keys     = ($object_class => scalar $meta->nonlazy_column_db_value_hash_keys);
  }
  else
  {
    %columns = ($tables[0] => scalar $meta->columns);
    %methods = ($tables[0] => scalar $meta->column_mutator_method_names);  
    %di_keys = ($object_class => scalar $meta->column_db_value_hash_keys);
  }

  my %classes = ($tables[0] => $object_class);
  my @classes = ($object_class);
  my %meta    = ($object_class => $meta);

  my @table_names = ($meta->table);
  my @rel_names   = ($meta->table);

  my(@joins, @subobject_methods, @mapped_object_methods, $clauses);

  my $handle_dups = 0;
  #my $deep_joins  = 0;
  my @has_dups;

  my $manual_limit = 0;

  my $num_subtables = $with_objects ? @$with_objects : 0;

  if($distinct || $fetch)
  {
    if($fetch && ref $distinct)
    {
      Carp::croak "The 'distinct' and 'fetch' parameters cannot be used ",
                  "together if they both contain lists of tables";
    }

    $args{'distinct'} = 1  if($distinct);

    %fetch = (t1 => 1, $tables[0] => 1, $meta->table => 1);

    if(ref $fetch || ref $distinct)
    {
      foreach my $arg (ref $distinct ? @$distinct : @$fetch)
      {
        $fetch{$arg} = 1;
      }
    }
  }

  # Handle "page" arguments
  if(exists $args{'page'} || exists $args{'per_page'})
  {
    if(exists $args{'limit'} || exists $args{'offset'})
    {
      Carp::croak 'Cannot include the "page" or "per_page" ',
                  'options when the "limit" or "offset" option ',
                  'is used';
    }

    my $page     = delete $args{'page'} || 1;
    my $per_page = delete $args{'per_page'} || $class->default_objects_per_page;

    $page     = 1  if($page < 1);
    $per_page = $class->default_objects_per_page  if($per_page < 1);

    $args{'limit'} = $per_page;

    if($page > 1)
    {
      $args{'offset'} = ($page - 1) * $per_page;
    }
  }

  # Pre-process sort_by args
  if(my $sort_by = $args{'sort_by'})
  {
    $sort_by = [ $sort_by ]  unless(ref $sort_by eq 'ARRAY');

    if($num_subtables == 0 && defined $table_aliases && $table_aliases == 0)
    {
      # trim t1. or primary table prefixes
      my $prefix_re = '\b(?:t1|' . $meta->table . ')\.';
      $prefix_re = qr($prefix_re);

      foreach my $sort (@$sort_by)
      {
        $sort =~ s/$prefix_re//g  unless(ref $sort);
      }
    }

    $args{'sort_by'} = $sort_by;
  }

  my $num_to_many_rels = 0;
  # Adjust for explicitly included map_record tables, which should
  # not count towards the multi_many_ok warning.
  my $num_to_many_rels_adjustment = 0;

  my($multi_many, @subobject_method_map);

  if($with_objects)
  {
    # XXX: Hack to avoid spurious ORA-00918 errors
    # XXX: http://ora-00918.ora-code.com/msg/28663.html
    if(($args{'limit'} || $args{'offset'}) && $dbh->{'Driver'}{'Name'} eq 'Oracle')
    {
      $args{'unique_aliases'} = 1;
    }

    # Copy clauses arg
    $clauses = $args{'clauses'} ? [ @{$args{'clauses'}} ] : [];

    my $i = 1;

    # Sanity check with_objects arguments, and determine if we're going to
    # have to handle duplicate data from multiple joins.  If so, note
    # which with_objects arguments refer to relationships that may return
    # more than one object.
    foreach my $name (@$with_objects)
    {
      my $tn_name = $name;

      if(index($tn_name, '.') > 0) # dot at start is invalid, so "> 0" is correct
      {
        $tn_name =~ /^(.+)\.([^.]+)$/;
      }

      $rel_tn{$tn_name} = $i + 1; # note the tN table number of this relationship

      my $key;

      # Chase down multi-level keys: e.g., colors.name.types
      if(index($name, '.') >= 0)
      {
        #$deep_joins = 1;

        my $chase_meta = $meta;

        while($name =~ /\G([^.]+)(?:\.|$)/g)
        {
          my $sub_name = $1;

          $key = $chase_meta->foreign_key($sub_name) ||
                 $chase_meta->relationship($sub_name) ||
                 Carp::confess "Invalid with_objects or require_objects argument: ",
                               "no foreign key or relationship named '$sub_name' ",
                               'found in ', $chase_meta->class;

          $chase_meta = $key->can('foreign_class') ? 
            $key->foreign_class->meta : $key->class->meta;
        }
      }
      else
      {
        $key = $meta->foreign_key($name) || $meta->relationship($name) ||
          Carp::confess "Invalid with_objects or require_objects argument: ",
                        "no foreign key or relationship named '$name' ",
                        "found in $class";
      }

      my $rel_type = $key->type;

      if($rel_type =~ /\bmany$/)
      {
        $handle_dups  = 1;
        $has_dups[$i] = 1;

        # "many to many" relationships have an extra table (the mapping table)
        if($rel_type eq 'many to many')
        {
          $i++;
          $has_dups[$i] = 1;
          # $num_subtables will be incremented elsewhere (below)

          # Adjust for explicitly included map_record tables, which should
          # not count towards the multi_many_ok warning.
          $num_to_many_rels_adjustment++;
        }

        if($args{'limit'})
        {
          if($try_subselect_limit && $db->supports_select_from_subselect && 
             (!$args{'offset'} || $db->supports_limit_with_offset) && 
             !$args{'select'})
          {
            unless($fetch && @$fetch && $fetch->[0] eq 't1')
            {
              $subselect_limit = 1;
              delete $args{'limit'};
              delete $args{'offset'};
            }
          }
          else
          {
            $manual_limit = delete $args{'limit'};
          }
        }

        # This restriction seems unnecessary now
        #if($required_object{$name} && $num_required_objects > 1 && $num_subtables > 1)
        #{
        #  Carp::croak 
        #    qq(The "require_objects" parameter cannot be used with ),
        #    qq(a "... to many" relationship ("$name" in this case) ),
        #    qq(unless that relationship is the only one listed and ),
        #    qq(the "with_objects" parameter is not used);
        #}
      }

      $i++;
    }

    $num_to_many_rels = grep { defined $_ } @has_dups;

    # Adjust for explicitly included map_record tables, which should
    # not count towards the multi_many_ok warning.
    $multi_many = (($num_to_many_rels - $num_to_many_rels_adjustment)  > 1) ? 1 : 0;

    unless($args{'multi_many_ok'})
    {
      if($multi_many)
      {
        Carp::carp
          qq(WARNING: Fetching sub-objects via more than one ),
          qq("one to many" relationship in a single query may ),
          qq(produce many redundant rows, and the query may be ),
          qq(slow.  If you're sure you want to do this, you can ),
          qq(silence this warning by using the "multi_many_ok" ),
          qq(parameter\n);
      }
    }

    $i = 1; # reset iterator for second pass through with_objects

    # Build lists of columns, classes, methods, and join conditions for all
    # of the with_objects and/or require_objects arguments.
    foreach my $arg (@$with_objects)
    {
      my($parent_meta, $parent_tn, $name);

      if(index($arg, '.') > 0) # dot at start is invalid, so "> 0" is correct
      {
        $arg =~ /^(.+)\.([^.]+)$/;
        my $parent = $1;
        $name = $2;

        # value of $i as of last iteration
        $parent_tn = defined $rel_tn{$parent} ? $rel_tn{$parent}: $i; 

        $belongs_to[$i] = $parent_tn - 1;
        $parent_meta = $classes[$parent_tn - 1]->meta;
      }
      else
      {
        $parent_meta = $meta;
        $name = $arg;
        $parent_tn = 1;
        $belongs_to[$i] = 0;
      }

      #$rel_tn{$arg} = $i + 1; # note the tN table number of this relationship

      my $rel = $parent_meta->foreign_key($name) || 
                $parent_meta->relationship($name) ||
                Carp::croak "No relationship named '$name' in class ",
                            $parent_meta->class;

      my $rel_type = $rel->type;

      if($rel_type eq 'foreign key' || $rel_type eq 'one to one' ||
         $rel_type eq 'many to one' || $rel_type eq 'one to many')
      {
        my $ft_class = $rel->class 
          or Carp::confess "$class - Missing foreign object class for '$name'";

        my $ft_columns = $rel->key_columns;

        if(!$ft_columns && $rel_type ne 'one to many')
        {
          Carp::confess "$class - Missing key columns for '$name'";
        }

        if($rel->can('query_args') && (my $query_args = $rel->query_args))
        {
          # (Re)map query parameters to the correct table
          # t1 -> No change (the primary table)
          # t2 -> The foreign table
          for(my $i = 0; $i < @$query_args; $i += 2)
          {
            my $param = $query_args->[$i];

            if(ref $param)
            {
              push(@{$args{'query'}}, $param);
              $i--;
              next;
            }

            unless($param =~ s/^t2\./t$rel_tn{$arg}./)
            {
              $param = "t$rel_tn{$arg}.$param"  unless($param =~ /^t\d+\./);
            }

            push(@{$args{'query'}}, $param, $query_args->[$i + 1]);
          }
        }

        my $ft_meta = $ft_class->meta; 

        $meta{$ft_class} = $ft_meta;

        push(@tables, $ft_meta->fq_table($db));
        push(@tables_sql, $ft_meta->fq_table_sql($db));
        push(@rel_names, $rel_name{'t' . (scalar @tables)} = $rel->name);
        push(@table_names, $ft_meta->table);
        push(@classes, $ft_class);

        # Iterator will be the tN value: the first sub-table is t2, and so on
        $i++;

        my $use_lazy_columns = (!ref $nonlazy || $nonlazy{$name}) ? 0 : $ft_meta->has_lazy_columns;

        if($use_lazy_columns)
        {
          $columns{$tables[-1]}     = $ft_meta->nonlazy_columns;
          $all_columns{$tables[-1]} = $ft_meta->columns;
          $methods{$tables[-1]}     = $ft_meta->nonlazy_column_mutator_method_names;
          $di_keys{$classes[-1]}    = $ft_meta->nonlazy_column_db_value_hash_keys;
        }
        else
        {
          $columns{$tables[-1]}  = $ft_meta->columns;   
          $methods{$tables[-1]}  = $ft_meta->column_mutator_method_names;        
          $di_keys{$classes[-1]} = $ft_meta->column_db_value_hash_keys;
        }

        $classes{$tables[-1]} = $ft_class;

        $subobject_methods[$i - 1] = 
          $direct_inject ? $rel->hash_key :
          $rel->method_name('get_set') ||
          $rel->method_name('get_set_now') ||
          $rel->method_name('get_set_on_save') ||
          Carp::confess "No 'get_set', 'get_set_now', or 'get_set_on_save' ",
                        "method found for $rel_type '$name' in class ",
                        $rel->parent->class;

        #$subobject_keys[$i - 1] = $rel->hash_key;

        # Reset each() iterator
        #keys(%$ft_columns);

        my(@redundant, @redundant_null);

        unless($ft_columns && %$ft_columns)
        {
          if($with_objects{$arg})
          {
            $joins[$i]{'type'} = $join_type{$arg} || 'LEFT OUTER JOIN';
          }
          elsif($use_explicit_joins)
          {
            $joins[$i]{'type'} = $join_type{$arg} || 'JOIN';
          }
        }

        # Add join condition(s)
        while(my($local_column, $foreign_column) = each(%$ft_columns))
        {
          # Use outer joins to handle duplicate or optional information.
          # Foreign keys that have all non-null columns are not outer-
          # joined when nested joins are enabled, however.
          if(!($rel_type eq 'foreign key' && $rel->is_required &&
               $rel->referential_integrity && $nested_joins) &&
             ($outer_joins || $with_objects{$arg}))
          {
            # Aliased table names
            push(@{$joins[$i]{'conditions'}}, "t${parent_tn}.$local_column = t$i.$foreign_column");

            if($multi_many)
            {
              my $local_method   = $parent_meta->column_mutator_method_name($local_column);
              my $foreign_method = $ft_meta->column_accessor_method_name($foreign_column);
              push(@{$subobject_method_map[$i][$belongs_to[$i - 1]]}, [ $local_method, $foreign_method ]);
            }

            # Fully-qualified table names
            #push(@{$joins[$i]{'conditions'}}, "$tables[0].$local_column = $tables[-1].$foreign_column");

            $joins[$i]{'type'} = $join_type{$arg} || 'LEFT OUTER JOIN';
            $joins[$i]{'hints'} = $hints->{"t$i"} || $hints->{$name};

            # MySQL is stupid about using its indexes when "JOIN ... ON (...)"
            # conditions are the only ones given, so the code below adds some
            # redundant WHERE conditions.  They should only be added when they
            # do not change the meaning of the query, in which case they
            # should nudge MySQL into using its indexes.  
            # The clauses: "((<ON conditions>) OR (<any columns are null>))"
            # We build the two clauses separately in the loop below, then
            # combine it all after the loop is done.
            if($use_redundant_join_conditions)
            {
              # Aliased table names
              push(@redundant, "t${parent_tn}.$local_column = t$i.$foreign_column");
              push(@redundant_null, ($has_dups[$i - 1] ?
                   "t$i.$foreign_column IS NULL" :
                   "t${parent_tn}.$local_column IS NULL"));

              # Fully-qualified table names
              #push(@redundant, "$tables[$parent_tn - 1].$local_column = $tables[-1].$foreign_column");
              #push(@redundant_null, ($has_dups[$i - 1] ?
              #     "$tables[-1].$foreign_column IS NULL" :
              #     "$tables[$parent_tn - 1].$local_column IS NULL"));
            }
          }
          else
          {
            if($use_explicit_joins)
            {
              # Aliased table names
              push(@{$joins[$i]{'conditions'}}, "t${parent_tn}.$local_column = t$i.$foreign_column");

              # Fully-qualified table names
              #push(@{$joins[$i]{'conditions'}}, "$tables[$parent_tn - 1].$local_column = $tables[-1].$foreign_column");

              $joins[$i]{'type'} = $join_type{$arg} || 'JOIN';  
              $joins[$i]{'hints'} = $hints->{"t$i"} || $hints->{$name};
            }
            else # implicit join with no ON clause
            {
              # Aliased table names
              push(@$clauses, "t${parent_tn}.$local_column = t$i.$foreign_column");

              # Fully-qualified table names
              #push(@$clauses, "$tables[$parent_tn - 1].$local_column = $tables[-1].$foreign_column");
            }
          }
        }

        $joins[$i]{'parent_tn'} = $parent_tn  if($joins[$i] && $joins[$i]{'type'} eq 'JOIN');

        # XXX: Undocumented for now...
        if($rel->can('join_args') && (my $join_args = $rel->join_args))
        {
          my $cond = 
            build_where_clause(dbh         => $dbh,
                               tables      => [ @tables[$parent_tn - 1, $i - 1] ],
                               columns     => \%columns,
                               all_columns => \%all_columns,
                               classes     => \%classes,
                               meta        => \%meta,
                               db          => $db,
                               pretty      => $Debug,
                               query       => $join_args);

          # XXX: Ugly hack...
          for($cond)
          {
            s/(?:^| )@{[ $tables[$parent_tn - 1] ]}\./t$parent_tn./mg;
            s/(?:^| )@{[ $tables[$i - 1] ]}\./t$i./mg;
            s/(?:^| )t1\./t$parent_tn./mg;
            s/(?:^| )t2\./t$i./mg;
            s/^\s\s+/ /mg;
            s/\A\s+//;
            s/\n/ /g;
          }

          push(@{$joins[$i]{'conditions'}}, $cond);
        }

        if(@redundant)
        {
          push(@$clauses, '((' . join(' AND ', @redundant) . ') OR (' .
                          join(' OR ', @redundant_null) . '))');
        }

        $joins[$i]{'conditions'} ||= [ '1 = 1' ]  if($joins[$i]);

        # Add sub-object sort conditions
        if($rel->can('manager_args') && (my $mgr_args = $rel->manager_args))
        {
          # Don't bother sorting by columns if we're not even selecting them
          if($mgr_args->{'sort_by'} && (!%fetch || 
             ($fetch{$tables[-1]} && !$fetch{$rel_names[-1]})))
          {
            my $sort_by = ref $mgr_args->{'sort_by'} eq 'ARRAY' ?
              [ @{$mgr_args->{'sort_by'}} ] : [ $mgr_args->{'sort_by'} ];

            foreach my $sort (@$sort_by)
            {
              no warnings 'uninitialized';
              $sort =~ s/^(['"`]?)(\w+)\1(\s+(?:ASC|DESC))?$/t$i.$1$2$1$3/i
                unless(ref $sort);
            }

            push(@{$args{'sort_by'}}, @$sort_by);
          }
        }
      }
      elsif($rel_type eq 'many to many')
      {
        #
        # First add table, columns, and clauses for the map table itself
        #

        my $map_class = $rel->map_class 
          or Carp::confess "$class - Missing map class for '$name'";

        my $map_meta = $map_class->meta; 

        $meta{$map_class} = $map_meta;

        push(@tables, $map_meta->fq_table($db));
        push(@tables_sql, $map_meta->fq_table_sql($db));
        # %rel_name gets the foreign table (below), not the map table here
        push(@rel_names, $rel->name);
        push(@table_names, $map_meta->table);
        push(@classes, $map_class);

        my $rel_mgr_args = $rel->manager_args || {};

        my $map_record_method;
        my $rel_map_record_method = $rel->map_record_method;

        if(my $rel_with_map_records = $rel_mgr_args->{'with_map_records'})
        {
          $map_record_method =
            ($with_map_records && exists $with_map_records->{$name}) ? $with_map_records->{$name} :
            $rel_map_record_method ? $rel_map_record_method : MAP_RECORD_METHOD;
        }
        elsif($with_map_records)
        {
          $map_record_method =
            exists $with_map_records->{$name} ? $with_map_records->{$name} : 
            $with_map_records->{DEFAULT_REL_KEY()} || 0;
        }

        if($map_record_method)
        {
          my $use_lazy_columns = (!ref $nonlazy || $nonlazy{$name}) ? 0 : $map_meta->has_lazy_columns;

          if($use_lazy_columns)
          {
            $columns{$tables[-1]}     = $map_meta->nonlazy_columns;
            $all_columns{$tables[-1]} = $map_meta->columns;
            $methods{$tables[-1]}     = $map_meta->nonlazy_column_mutator_method_names;
            $di_keys{$classes[-1]}    = $map_meta->nonlazy_column_db_value_hash_keys;
          }
          else
          {
            $columns{$tables[-1]}  = $map_meta->columns;   
            $methods{$tables[-1]}  = $map_meta->column_mutator_method_names;        
            $di_keys{$classes[-1]} = $map_meta->column_db_value_hash_keys;
          }
        }
        else
        {
          $columns{$tables[-1]} = []; # Don't fetch map class columns
          $methods{$tables[-1]} = [];
        }

        $classes{$tables[-1]} = $map_class;

        my $column_map = $rel->column_map;

        # Iterator will be the tN value: the first sub-table is t2, and so on.
        # Increase once for map table.
        $i++;

        # Increase the tN table number of this relationship as well
        $rel_tn{$arg} = $i + 1; 

        $belongs_to[$i] = $belongs_to[$i - 1];

        $mapped_object_methods[$i - 1] = $map_record_method || 0;

        if($map_record_method)
        {
          my $ft_class = $rel->foreign_class 
            or Carp::confess "$class - Missing foreign class for '$name'";

          if($ft_class->can($map_record_method))
          {
            if($direct_inject && (my $map_record_key = $ft_class->meta->map_record_method_key($map_record_method)))
            {
              $mapped_object_methods[$i - 1] = $map_record_key;
            }
          }
          else
          {
            my $map_record_key =
              Rose::DB::Object::Metadata::Relationship::ManyToMany::make_map_record_method(
                $ft_class, $map_record_method, $map_class);

            if($direct_inject && $mapped_object_methods[$i - 1])
            {
              $mapped_object_methods[$i - 1] = $map_record_key;
            }
          }
        }

        # Add join condition(s)
        while(my($local_column, $foreign_column) = each(%$column_map))
        {
          # Use outer joins to handle duplicate or optional information.
          if($outer_joins || $with_objects{$arg})
          {
            # Aliased table names
            push(@{$joins[$i]{'conditions'}}, "t$i.$local_column = t${parent_tn}.$foreign_column");

            # Fully-qualified table names
            #push(@{$joins[$i]{'conditions'}}, "$tables[-1].$local_column = $tables[$parent_tn - 1].$foreign_column");

            $joins[$i]{'type'} = $join_type{$arg} || 'LEFT OUTER JOIN';
            $joins[$i]{'hints'} = $hints->{"t$i"} || $hints->{$name};
          }
          else
          {
            if($use_explicit_joins)
            {
              # Aliased table names
              push(@{$joins[$i]{'conditions'}}, "t$i.$local_column = t${parent_tn}.$foreign_column");

              # Fully-qualified table names
              #push(@{$joins[$i]{'conditions'}}, "$tables[-1].$local_column = $tables[$parent_tn - 1].$foreign_column");

              $joins[$i]{'type'} = $join_type{$arg} || 'JOIN';
              $joins[$i]{'hints'} = $hints->{"t$i"} || $hints->{$name};
            }
            else # implicit join with no ON clause
            {
              # Aliased table names
              push(@$clauses, "t$i.$local_column = t${parent_tn}.$foreign_column");

              # Fully-qualified table names
              #push(@$clauses, "$tables[-1].$local_column = $tables[$parent_tn - 1].$foreign_column");
            }
          }
        }

        $joins[$i]{'parent_tn'} = $parent_tn  if($joins[$i] && $joins[$i]{'type'} eq 'JOIN');

        #
        # Now add table, columns, and clauses for the foreign object
        #

        $num_subtables++; # Account for the extra table

        my $ft_class = $rel->foreign_class 
          or Carp::confess "$class - Missing foreign class for '$name'";

        my $ft_meta = $ft_class->meta; 
        $meta{$ft_class} = $ft_meta;

        my $map_to = $rel->map_to 
          or Carp::confess "Missing map_to value for relationship '$name' ",
                           "in clas $class";

        my $foreign_rel = 
          $map_meta->foreign_key($map_to)  || $map_meta->relationship($map_to) ||
            Carp::confess "No foreign key or relationship named '$map_to' ",
                          "found in $map_class";        

        my $ft_columns = $foreign_rel->key_columns 
          or Carp::confess "$ft_class - Missing key columns for '$map_to'";

        push(@tables, $ft_meta->fq_table($db));
        push(@tables_sql, $ft_meta->fq_table_sql($db));
        push(@rel_names, $rel_name{'t' . (scalar @tables)} = $rel->name);
        push(@table_names, $ft_meta->table);
        push(@classes, $ft_class);

        my $use_lazy_columns = (!ref $nonlazy || $nonlazy{$name}) ? 0 : $ft_meta->has_lazy_columns;

        if($use_lazy_columns)
        {
          $columns{$tables[-1]}     = $ft_meta->nonlazy_columns;
          $all_columns{$tables[-1]} = $ft_meta->columns;
          $methods{$tables[-1]}     = $ft_meta->nonlazy_column_mutator_method_names;
          $di_keys{$classes[-1]}    = $ft_meta->nonlazy_column_db_value_hash_keys;
        }
        else
        {
          $columns{$tables[-1]}  = $ft_meta->columns;   
          $methods{$tables[-1]}  = $ft_meta->column_mutator_method_names;        
          $di_keys{$classes[-1]} = $ft_meta->column_db_value_hash_keys;
        }

        $classes{$tables[-1]} = $ft_class;

        # Iterator will be the tN value: the first sub-table is t2, and so on.
        # Increase again for foreign table.
        $i++;

        $subobject_methods[$i - 1] =
          $direct_inject ? $rel->hash_key :
          $rel->method_name('get_set') ||
          $rel->method_name('get_set_now') ||
          $rel->method_name('get_set_on_save') ||
          Carp::confess "No 'get_set', 'get_set_now', or 'get_set_on_save' ",
                        "method found for relationship '$name' in class ",
                        "$class";

        #$subobject_keys[$i - 1] = $rel->hash_key;

        # Reset each() iterator
        #keys(%$ft_columns);

        # Add join condition(s)
        while(my($local_column, $foreign_column) = each(%$ft_columns))
        {
          # Use left joins if the map table used an outer join above
          if($outer_joins || $with_objects{$arg})
          {
            # Aliased table names
            push(@{$joins[$i]{'conditions'}}, 't' . ($i - 1) . ".$local_column = t$i.$foreign_column");

            # Fully-qualified table names
            #push(@{$joins[$i]{'conditions'}}, "$tables[-2].$local_column = $tables[-1].$foreign_column");

            $joins[$i]{'type'} = $join_type{$arg} || 'LEFT OUTER JOIN';
            $joins[$i]{'hints'} = $hints->{"t$i"} || $hints->{$name};
          }
          else
          {
            if($use_explicit_joins)
            {
              # Aliased table names
              push(@{$joins[$i]{'conditions'}}, 't' . ($i - 1) . ".$local_column = t$i.$foreign_column");

              # Fully-qualified table names
              #push(@{$joins[$i]{'conditions'}}, "$tables[-2].$local_column = $tables[-1].$foreign_column");

              $joins[$i]{'type'} = $join_type{$arg} || 'JOIN';
              $joins[$i]{'hints'} = $hints->{"t$i"} || $hints->{$name};
            }
            else # implicit join with no ON clause
            {
              # Aliased table names
              push(@$clauses, 't' . ($i - 1) . ".$local_column = t$i.$foreign_column");

              # Fully-qualified table names
              #push(@$clauses, "$tables[-2].$local_column = $tables[-1].$foreign_column");
            }
          }
        }

        $joins[$i]{'parent_tn'} = $i - 1  if($joins[$i] && $joins[$i]{'type'} eq 'JOIN');

        # Add sub-object sort conditions
        if($rel->can('manager_args') && (my $mgr_args = $rel->manager_args))
        {
          # Don't bother sorting by columns if we're not even selecting them
          if($mgr_args->{'sort_by'} && (!%fetch || 
             ($fetch{$tables[-1]} && !$fetch{$rel_names[-1]})))
          {
            my $sort_by = ref $mgr_args->{'sort_by'} eq 'ARRAY' ?
              [ @{$mgr_args->{'sort_by'}} ] : [ $mgr_args->{'sort_by'} ];

            # translate un-prefixed simple columns
            foreach my $sort (@$sort_by)
            {
              no warnings 'uninitialized';
              $sort =~ s/^(['"`]?)(\w+)\1(\s+(?:ASC|DESC))?$/t$i.$1$2$1$3/i
                unless(ref $sort);
            }

            push(@{$args{'sort_by'}}, @$sort_by);
          }
        }
      }
      else
      {
        Carp::croak "Don't know how to auto-join relationship '$name' of type '$rel_type'";
      }
    }

    $args{'clauses'} = $clauses; # restore clauses arg
  }

  # Flesh out list of fetch tables and cull columns for those tables
  if(%fetch)
  {
    foreach my $i (1 .. $#tables) # skip first table, which is always selected
    {
      my $tn = 't' . ($i + 1);
      my $rel_name = $rel_name{$tn} || '';

      (my $trimmed_table = $tables[$i]) =~ s/^[^.]+\.//;

      unless($fetch{$tn} || $fetch{$tables[$i]} || $fetch{$trimmed_table} || 
             $fetch{$rel_names[$i]} || $fetch{$rel_name})
      {
        $columns{$tables[$i]} = [];
        $methods{$tables[$i]} = [];
      }
    }
  }

  $args{'table_map'} = { reverse %rel_tn };

  my %tn;

  if($select)
  {
    if($fetch)
    {
      Carp::croak "The 'select' and 'fetch' parameters cannot be used together";
    }

    $select = [ split(/\s*,\s*/, $select) ]  unless(ref $select);

    my $i = 1;
    %tn = map { $_ => $i++ } @table_names; # @tables;
    my $expand_dotstar = 0;

    foreach my $item (@$select)
    {
      my($column, $tn);

      next  if(ref $item eq 'SCALAR');

      if(index($item, '.') < 0 && $item !~ /\s+ AS \s+ \w+ \s* \Z/xi)
      {
        $expand_dotstar = 1  if($item eq '*');
        $column = $item;
        $item = "t1.$item"  if($table_aliases > 0);
        $tn = 1;
      }
      elsif($item =~ /^t(\d+)\.(.+)$/)
      {
        $tn     = $1;
        $item   = $2 unless($table_aliases);
        $column = $2;
        $expand_dotstar = 1  if($item =~ /^t\d+\.\*$/);
      }
      elsif($item =~ /^(['"]?)([^.(]+)\1\.(['"]?)(.+)(\3)$/)
      {
        my $num = $tn{$2} || $rel_tn{$2};
        $item = "t$num.$3$4$5";
        $tn = $num;
        $column = $4;
        $expand_dotstar = 1  if($item =~ /^t\d+\.\*$/);
      }

      if(defined $tn)
      {
        my $meta = $meta{$classes{$tables[$tn - 1]}};

        if($meta->column($column) && (my $alias = $meta->column($column)->alias))
        {
          $item .= ' AS ' . $alias  unless($alias eq $column);
        }
      }
    }

    # Expand tN.* specifiers, if necessary
    if($expand_dotstar)
    {
      my @select;

      foreach my $item (@$select)
      {
        next  if(ref $item eq 'SCALAR');

        unless($item =~ /^(?: t(\d+)\. )? \* $/x)
        {
          push(@select, $item);
          next;
        }

        my $tn = $1 || 1;
        my $meta = $meta{$classes{$tables[$tn - 1]}};
        my $prefix = $table_aliases ? "t$tn." : '';

        foreach my $column ($meta->columns)
        {
          if(my $alias = $column->alias)
          {
            push(@select, "$prefix$column AS $alias");
          }
          else
          {
            push(@select, "$prefix$column");
          }
        }
      }

      $select = \@select;
    }

    $args{'select'} = $select;
  }

  if($count_only)
  {
    delete $args{'limit'};
    delete $args{'offset'};
    delete $args{'sort_by'};

    my($sql, $bind, @bind_params);

    # Do we have to use DISTINCT to count?
    my $use_distinct = (delete $args{'distinct'} || $with_objects) ? 1 : 0;

    if(!$use_distinct && $require_objects)
    {
      foreach my $name (@$require_objects)
      {
        # Ignore error here since it'll be caught and handled later anyway
        my $key = 
          $meta->foreign_key($name) || $meta->relationship($name) || next;

        my $rel_type = $key->type;

        if(index($key->type, 'many') >= 0)
        {
          $use_distinct = 1;
          last;
        }
      }
    }

    BUILD_SQL:
    {
      my($select, $wrap);

      my $pk_columns = $meta->primary_key_column_names;

      if(!$use_distinct || @$pk_columns == 1 || 
         $db->supports_multi_column_count_distinct)
      {
        my $select_arg = delete $args{'select'};

        $select = $use_distinct ? 
          'COUNT(DISTINCT ' .  join(', ', ($select_arg ? @$select_arg : (map { "t1.$_" } @$pk_columns))) . ')' :
          'COUNT(*)';
      }
      else
      {
        $select = $use_distinct ? 
          'DISTINCT ' . join(', ', map { "t1.$_" } @$pk_columns) : 'COUNT(*)';
        $wrap = 1;
      }

      local $Carp::CarpLevel = $Carp::CarpLevel + 1;

      ($sql, $bind) =
        build_select(dbh          => $dbh,
                     select       => $select,
                     tables       => \@tables,
                     tables_sql   => \@tables_sql,
                     columns      => \%columns,
                     all_columns  => \%all_columns,
                     classes      => \%classes,
                     joins        => \@joins,
                     meta         => \%meta,
                     db           => $db,
                     pretty       => $Debug,
                     bind_params  => \@bind_params,
                     object_class => $object_class,
                     %args);

      if($wrap)
      {
        $sql = "SELECT COUNT(*) FROM ($sql) sq";
      }
    }

    if($return_sql)
    {
      $db->release_dbh  if($dbh_retained);
      return wantarray ? ($sql, $bind) : $sql;
    }

    my $count = 0;

    my $error;

    TRY:
    {
      local $@;

      eval
      {
        local $dbh->{'RaiseError'} = 1;
        $Debug && warn "$sql (", join(', ', @$bind), ")\n";
        my $sth = $prepare_cached ? $dbh->prepare_cached($sql, undef, 3) : 
                                    $dbh->prepare($sql);

        if(@bind_params)
        {
          my $i = 1;

          foreach my $value (@$bind)
          {
            $sth->bind_param($i, $value, $bind_params[$i - 1]);
            $i++;
          }

          $sth->execute;
        }
        else
        {
          $sth->execute(@$bind);
        }

        ($count) = $sth->fetchrow_array;
        $sth->finish;
      };

      $error = $@;
    }

    if($error)
    {
      $class->total(undef);
      $class->error(ref $error ? $error : "get_objects() - $error");
      $class->handle_error($class);
      return undef;
    }

    $class->total($count);
    return $count;
  }

  # Post-process sort_by args
  if(my $sort_by = $args{'sort_by'})
  {
    # Alter sort_by SQL, replacing table and relationship names with aliases.
    # This is to prevent databases like PostgreSQL from "adding missing FROM
    # clause"s.  See: http://sql-info.de/postgresql/postgres-gotchas.html#1_5
    if($table_aliases)
    {
      my $i = 0;

      foreach my $table (@tables)
      {
        $i++; # Table aliases are 1-based

        my $table_unquoted = $db->unquote_table_name($table);

        # Conditionalize schema part, if necessary
        $table_unquoted =~ s/^([^.]+\.)/(?:\Q$1\E)?/;

        foreach my $sort (grep { !ref } @$sort_by)
        {
          no warnings 'uninitialized';
          unless($sort =~ s/^(['"`]?)(\w+)\1(\s+(?:ASC|DESC))?$/t1.$1$2$1$3/i ||
                 $sort =~ s/\b$table_unquoted\./t$i./g)
          {
            if(my $rel_name = $rel_name{"t$i"})
            {
              $sort =~ s/\b$rel_name\./t$i./g  unless($rel_name =~ /^t\d+$/);
            }
          }
        }
      }

      # When selecting sub-objects via a "... to many" relationship, force
      # a sort by t1's primary key unless sorting by some other column in
      # t1.  This is required to ensure that all result rows from each row
      # in t1 are grouped together.  But don't do it when we're selecting
      # columns from just one table.  (Compare to 3 because the primary table
      # name, fully-qualified name, and the "t1" alias are always in the list.)
      if($num_to_many_rels > 0 && (!%fetch || (keys %fetch || 0) > 3) && !$no_forced_sort)
      {
        my $do_prefix = 1;

        foreach my $sort (@$sort_by)
        {
          if(!ref $sort && $sort =~ /^t1\./)
          {
            $do_prefix = 0;
            last;
          }
        }

        if($do_prefix)
        {
          unshift(@$sort_by, join(', ', map { "t1.$_" } $meta->primary_key_column_names));
        }
      }
    }
    else # otherwise, trim t1. prefixes
    {
      my $prefix_re = '\b(?:t1|' . $meta->table . ')\.';
      $prefix_re = qr($prefix_re);

      foreach my $sort (@$sort_by)
      {
        $sort =~ s/$prefix_re//g  unless(ref $sort);
      }
    }

    # TODO: remove duplicate/redundant sort conditions
    $args{'sort_by'} = $sort_by;
  }
  elsif($num_to_many_rels > 0 && (!%fetch || (keys %fetch || 0) > 3) && !$no_forced_sort)
  {
    # When selecting sub-objects via a "... to many" relationship, force a
    # sort by t1's primary key to ensure that all result rows from each
    # row in t1 are grouped together.  But don't do it when we're selecting
    # columns from just one table. (Compare to 3 because the primary table
    # name, fully-qualified name, and the "t1" alias are always in the list.)
    $args{'sort_by'} = [ join(', ', map { "t1.$_" } $meta->primary_key_column_names) ];
  }

  if(defined $args{'offset'})
  {
    Carp::croak "Offset argument is invalid without a limit argument"
      unless($args{'limit'} || $manual_limit);

    if($db->supports_limit_with_offset && !$manual_limit && !$subselect_limit)
    {
      $db->format_limit_with_offset($args{'limit'}, $args{'offset'}, \%args);
      #$args{'limit'} = $db->format_limit_with_offset($args{'limit'}, $args{'offset'});
      #delete $args{'offset'};
      $skip_first = 0;
    }
    elsif($manual_limit)
    {
      $skip_first += delete $args{'offset'};
    }
    else
    {
      $skip_first += delete $args{'offset'};
      $args{'limit'} += $skip_first;
      $db->format_limit_with_offset($args{'limit'}, undef, \%args);
      #$args{'limit'} = $db->format_limit_with_offset($args{'limit'});
    }
  }
  elsif($args{'limit'})
  {
    $db->format_limit_with_offset($args{'limit'}, undef, \%args);
    #$args{'limit'} = $db->format_limit_with_offset($args{'limit'});
  }

  my($count, @objects, $iterator);

  my($sql, $bind, @bind_params);

  BUILD_SQL:
  {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;

    ($sql, $bind) =
      build_select(dbh          => $dbh,
                   tables       => \@tables,
                   tables_sql   => \@tables_sql,
                   columns      => \%columns,
                   all_columns  => \%all_columns,
                   classes      => \%classes,
                   joins        => \@joins,
                   meta         => \%meta,
                   db           => $db,
                   pretty       => $Debug,
                   bind_params  => \@bind_params,
                   object_class => $object_class,
                   %args);

    if($subselect_limit)
    {
      my($class, %sub_args) = @_;

      # The sort clause is important, so it can't be deleted, but it 
      # also can't contain references to any table but t1.
      if($args{'sort_by'} && $num_subtables > 0)
      {
        my @sort_by;

        foreach my $arg (@{$args{'sort_by'}})
        {
          push(@sort_by, $arg)  if(index((ref $arg ? $$arg : $arg), 't1.') == 0);
        }

        $sub_args{'sort_by'} = \@sort_by;
      }

      # Not safe to delete this if the query references columns in these tables
      #delete $sub_args{'with_objects'};

      $sub_args{'fetch_only'}  = [ 't1' ];
      $sub_args{'from_and_where_only'} = 1;

      my @t1_bind_params;
      $sub_args{'bind_params'} = \@t1_bind_params;

      my($t1_sql, $t1_bind) = $class->get_objects_sql(%sub_args);

      my $columns = $sub_args{'select'};

      unless($columns)
      {
        my $multi_table = 
          ($sub_args{'with_objects'} && (!ref $sub_args{'with_objects'} || @{$sub_args{'with_objects'}})) ||
          ($sub_args{'require_objects'} && (!ref $sub_args{'require_objects'} || @{$sub_args{'require_objects'}}));

        if($multi_table)
        {
          $table_aliases = 1;
        }
        else
        {
          $table_aliases = $multi_table  unless(defined $table_aliases);
        }

        $columns = $table_aliases ?
          join(', ', map { "t1.$_" } @{$columns{$tables[0]}}) :
          join(', ', map { $_ } @{$columns{$tables[0]}});
      }

      my $distinct = ($num_with_objects && scalar @{[ @has_dups[1 .. $num_with_objects] ]}) ? ' DISTINCT' : '';

      $t1_sql = "SELECT$distinct $columns FROM\n$t1_sql";
      $t1_sql =~ s/^/    /mg  if($Debug);
      $t1_sql = $db->format_select_from_subselect($t1_sql);

      $sql =~ s/(\nFROM\n\s*)\S.+\s+t1\b/$1$t1_sql t1/;

      unshift(@$bind, @$t1_bind);

      if(@t1_bind_params)
      {
        unshift(@bind_params, @t1_bind_params);
      }
    }
  }

  if($return_sql)
  {
    $db->release_dbh  if($dbh_retained);
    return wantarray ? ($sql, $bind) : $sql;
  }

  my $error;

  TRY:
  {
    local $@;

    eval
    {
      local $dbh->{'RaiseError'} = 1;

      $Debug && warn "$sql (", join(', ', @$bind), ")\n";
      # $meta->prepare_select_options (defunct)
      my $sth = $prepare_cached ? $dbh->prepare_cached($sql, undef, 3) : 
                                  $dbh->prepare($sql) or die $dbh->errstr;

      $sth->{'RaiseError'} = 1;

      if(@bind_params)
      {
        my $i = 1;

        foreach my $value (@$bind)
        {
          $sth->bind_param($i, $value, $bind_params[$i - 1]);
          $i++;
        }

        $sth->execute;
      }
      else
      {
        $sth->execute(@$bind);
      }

      my %row;

      my $col_num   = 1;
      my $table_num = 0;

      if($select)
      {      
        foreach my $orig_item (@$select)
        {
          my($class, $table_num, $column);

          my $item = (ref $orig_item eq 'SCALAR') ? $$orig_item : $orig_item;

          if($item =~ s/\s+AS\s+(\w.+)$//i)
          {
            $column = $1;
          }

          if(index($item, '.') < 0)
          {
            $table_num = 0;
            $class = $classes[$table_num];
            $column ||= $item;
          }
          elsif($item =~ /^t(\d+)\.(.+)$/)
          {
            $table_num = $1 - 1;
            $class = $classes[$table_num];
            $column ||= $2;
          }
          elsif($item =~ /^(['"]?)([^.(]+)\1\.(['"]?)(.+)\3$/)
          {
            my $table = $2;
            $class = $classes{$table};
            $column ||= $4;
            my $table_num = $tn{$table} || $rel_tn{$table};
          }
          else
          {
            $table_num = 0;
            $class = $classes[$table_num];
            $column ||= $item;
          }

          $sth->bind_col($col_num++, \$row{$class,$table_num}{$column});
        }
      }
      else
      {
        if($direct_inject)
        {
          my $driver = $db->driver || 'unknown';

          foreach my $table (@tables)
          {
            my $class   = $classes{$table};
            my $key_map = $di_keys{$class};

            foreach my $column (@{$methods{$table}})
            {
              if($key_map->{$column} eq $column)
              {
                $sth->bind_col($col_num++, \$row{$class,$table_num}{$column});
              }
              else # attribute uses a db-formatted key
              {
                $sth->bind_col($col_num++, \$row{$class,$table_num}{$key_map->{$column},$driver});
              }
            }

            $table_num++;
          }
        }
        else
        {
          foreach my $table (@tables)
          {
            my $class = $classes{$table};

            foreach my $column (@{$methods{$table}})
            {
              $sth->bind_col($col_num++, \$row{$class,$table_num}{$column});
            }

            $table_num++;
          }
        }
      }

      if($return_iterator)
      {
        $iterator = Rose::DB::Object::Iterator->new(active => 1);

        my $count = 0;

        # More trading of code duplication for performance: build custom
        # subroutines depending on how much work needs to be done for
        # each iteration.

        if($with_objects)
        {
          # Ug, we have to handle duplicate data due to "...to many" relationships
          # fetched via outer joins.
          if($handle_dups)# || $deep_joins)
          {
            my(@seen, %seen, @sub_objects);

            #my @pk_columns = $meta->primary_key_column_names;
            my $pk_columns = $meta->primary_key_column_names_or_aliases;

            # Get list of primary key columns for each sub-table
            my @sub_pk_columns;

            foreach my $i (1 .. $num_subtables)
            {
              #$sub_pk_columns[$i + 1] = [ $classes[$i]->meta->primary_key_column_names ];
              $sub_pk_columns[$i + 1] = $classes[$i]->meta->primary_key_column_names_or_aliases;
            }

            my($last_object, %subobjects, %parent_objects);

            weaken(my $witerator = $iterator);

            $iterator->_next_code(sub
            {
              my($self) = shift;

              my $object = 0;
              my $object_is_ready = 0;

              my(@objects, $error);

              TRY:
              {
                local $@;

                eval
                {
                  ROW: for(;;)
                  {
                    last ROW  unless($sth);

                    while($sth->fetch)
                    {
                      my $pk = join(PK_JOIN, map { $row{$object_class,0}{$_} } @$pk_columns);

                      # If this is a new main (t1) table row that we haven't seen before
                      unless($seen[0]{$pk}++)
                      {
                        # First, finish building the last object, if it exists
                        if($last_object)
                        {
                          #$Debug && warn "Finish $object_class $last_object->{'id'}\n";

                          if($direct_inject)
                          {
                            while(my($ident, $parent) = each(%parent_objects))
                            {
                              while(my($method, $subobjects) = each(%{$subobjects{$ident}}))
                              {
                                $parent->{$method} = $subobjects;
                              }
                            }                      
                          }
                          else
                          {
                            while(my($ident, $parent) = each(%parent_objects))
                            {
                              local $parent->{STATE_LOADING()} = 1;

                              while(my($method, $subobjects) = each(%{$subobjects{$ident}}))
                              {
                                $parent->$method($subobjects);
                              }
                            }
                          }

                          %subobjects = ();
                          %parent_objects = ();

                          # Add the object to the final list of objects that we'll return
                          push(@objects, $last_object);

                          $object_is_ready = 1;
                        }

                        #$Debug && warn "Make $object_class $pk\n";

                        # Now, create the object from this new main table row
                        if($direct_inject)
                        {
                          $object = bless { STATE_IN_DB() => 1, %{$row{$object_class,0}}, %object_args }, $object_class;
                        }
                        else
                        {
                          $object = $object_class->new(%object_args);

                          local $object->{STATE_LOADING()} = 1;
                          $object->init(%{$row{$object_class,0}});
                          $object->{STATE_IN_DB()} = 1;
                        }

                        $last_object = $object; # This is the "last object" from now on
                        @sub_objects = ();      # The list of sub-objects is per-object
                        splice(@seen, 1);       # Sub-objects seen is also per-object,
                                                # so trim it, but leave the t1 table info
                        %seen = ();             # Wipe sub-object parent tracking.
                      }

                      $object ||= $last_object or die "Missing object for primary key '$pk'";

                      my $map_record;

                      foreach my $i (1 .. $num_subtables)
                      {
                        my $mapped_object_method = $mapped_object_methods[$i];
                        next  if(defined $mapped_object_method && !$mapped_object_method);

                        my $class  = $classes[$i];
                        my $tn = $i + 1;

                        # Null primary key columns are not allowed
                        my $sub_pk = join(PK_JOIN, grep { defined } map { $row{$class,$i}{$_} } @{$sub_pk_columns[$tn]});
                        next  unless(length $sub_pk);

                        my $subobject = $seen[$i]{$sub_pk};

                        unless($subobject)
                        {
                          # Make sub-object
                          if($direct_inject)
                          {
                            $subobject = bless { STATE_IN_DB() => 1, %{$row{$class,$i}}, %subobject_args }, $class;
                          }
                          else
                          {    
                            $subobject = $class->new(%subobject_args);
                            local $subobject->{STATE_LOADING()} = 1;
                            $subobject->init(%{$row{$class,$i}});
                            $subobject->{STATE_IN_DB()} = 1;
                          }

                          $seen[$i]{$sub_pk} = $subobject;
                        }

                        # If this object belongs to an attribute that can have more
                        # than one object then just save it for later in the
                        # per-object sub-objects list.
                        if($has_dups[$i])
                        {
                          if($mapped_object_methods[$i])
                          {
                            $map_record = $subobject;
                          }
                          else
                          {
                            if($map_record)
                            {
                              my $method = $mapped_object_methods[$i - 1] or next;

                              if($direct_inject)
                              {
                                $subobject->{$method} = $map_record;
                              }
                              else
                              {
                                local $subobject->{STATE_LOADING()} = 1;
                                $subobject->$method($map_record);
                              }

                              $map_record = 0;
                            }

                            next  if(defined $mapped_object_methods[$i]);

                            if($has_dups[$i] && (my $bt = $belongs_to[$i]))
                            {
                              #$subobjects_belong_to[$i] = $#{$sub_objects[$bt]};

                              my $parent_object = $sub_objects[$bt];

                              # XXX: Special heavyweight subobject pairing in multi-many queries
                              if($multi_many && ref $parent_object eq 'ARRAY' && @$parent_object > 1)
                              {
                                my $maps = $subobject_method_map[$i + 1][$bt];
                                my %check;

                                foreach my $map (@$maps)
                                {
                                  my $subobject_method = $map->[1];
                                  $check{$subobject_method} = $subobject->$subobject_method();
                                }

                                PARENT: foreach my $check_parent (reverse @$parent_object)
                                {
                                  foreach my $map (@$maps)
                                  {
                                    my $parent_method = $map->[0];
                                    next PARENT  unless($check_parent->$parent_method() eq $check{$map->[1]});
                                  }

                                  $parent_object = $check_parent;
                                  last PARENT;
                                }
                              }

                              # XXX: This relies on parent objects coming before child
                              # objects in the list of tables in the FROM clause.
                              $parent_object = $parent_object->[-1] #$parent_object->[$subobjects_belong_to[$i]]
                                if(ref $parent_object eq 'ARRAY');

                              my $method = $subobject_methods[$i];

                              my $ident = refaddr $parent_object;
                              next  if($seen{$ident,$method}{$sub_pk}++);
                              $parent_objects{$ident} = $parent_object;
                              push(@{$subobjects{$ident}{$method}}, $subobject);
                            }
                            else
                            {
                              my $ident = refaddr $object;
                              my $method = $subobject_methods[$i];
                              next  if($seen{$ident,$method}{$sub_pk}++);
                              $parent_objects{$ident} = $object;
                              push(@{$subobjects{$ident}{$method}}, $subobject);
                            }

                            push(@{$sub_objects[$i]}, $subobject);
                          }
                        }
                        else # Otherwise, just assign it
                        {
                          $sub_objects[$i] = $subobject;
                          my $parent_object;

                          if(my $bt = $belongs_to[$i])
                          {
                            $parent_object = $sub_objects[$bt];
                            # XXX: This relies on parent objects coming before
                            # child objects in the list of tables in the FROM
                            # clause.
                            $parent_object = $parent_object->[-1]  if(ref $parent_object eq 'ARRAY');
                          }
                          else
                          {
                            $parent_object = $object;
                          }

                          my $method = $subobject_methods[$i];

                          # Only assign "... to one" values once
                          next  if($seen{refaddr $parent_object,$method}++);

                          if($direct_inject)
                          {
                            $parent_object->{$method} = $subobject;
                          }
                          else
                          {
                            local $parent_object->{STATE_LOADING()} = 1;
                            $parent_object->$method($subobject);
                          }
                        }
                      }

                      if($skip_first)
                      {
                        next ROW  if($seen[0]{$pk} > 1);
                        ++$count  if($seen[0]{$pk} == 1);
                        next ROW  if($count <= $skip_first);

                        $skip_first = 0;
                        @objects = ();        # Discard all skipped objects...
                        $object_is_ready = 0; # ...so none are ready now
                        next ROW;
                      }

                      if($object_is_ready)
                      {
                        $self->{'_count'}++;
                        last ROW;
                      }

                      no warnings;
                      if($manual_limit && $self->{'_count'} == $manual_limit)
                      {
                        $self->finish;
                        last ROW;
                      }
                    }

                    # Handle the left-over "last object" that needs to be finished and
                    # added to the final list of objects to return.
                    if($last_object && !$object_is_ready)
                    {
                      #$Debug && warn "Finish straggler $object_class $last_object->{'id'}\n";

                      if($direct_inject)
                      {
                        while(my($ident, $parent) = each(%parent_objects))
                        {
                          while(my($method, $subobjects) = each(%{$subobjects{$ident}}))
                          {
                            $parent->{$method} = $subobjects;
                          }
                        }
                      }
                      else
                      {
                        while(my($ident, $parent) = each(%parent_objects))
                        {
                          local $parent->{STATE_LOADING()} = 1;

                          while(my($method, $subobjects) = each(%{$subobjects{$ident}}))
                          {
                            $parent->$method($subobjects);
                          }
                        }
                      }

                      push(@objects, $last_object);

                      # Set everything up to return this object, then be done
                      $last_object = undef;
                      $self->{'_count'}++;
                      $sth = undef;
                      last ROW;
                    }

                    last ROW;
                  }
                };

                $error = $@;
              }

              if($error)
              {
                $self->error(ref $error ? $error : "next() - $error");
                $class->handle_error($self);
                return undef;
              }

              @objects = ()  if($skip_first);

              if(@objects)
              {
                no warnings; # undef count okay
                if($manual_limit && $self->{'_count'} == $manual_limit)
                {
                  $self->total($self->{'_count'});
                  $self->finish;
                }

                #$Debug && warn "Return $object_class $objects[-1]{'id'}\n";
                return shift(@objects);
              }

              #$Debug && warn "Return 0\n";
              return 0;
            });

          }
          else # no duplicate rows to handle
          {
            $iterator->_next_code(sub
            {
              my($self) = shift;

              my $object = 0;

              my $error;

              TRY:
              {
                local $@;

                eval
                {
                  ROW: for(;;)
                  {
                    unless($sth->fetch)
                    {
                      return 0;
                    }

                    next ROW  if($skip_first && ++$count <= $skip_first);

                    if($direct_inject)
                    {
                      $object = bless { STATE_IN_DB() => 1, %{$row{$object_class,0}}, %object_args }, $object_class;
                    }
                    else
                    {
                      $object = $object_class->new(%object_args);

                      local $object->{STATE_LOADING()} = 1;
                      $object->init(%{$row{$object_class,0}});
                      $object->{STATE_IN_DB()} = 1;
                    }

                    my @sub_objects;

                    if($with_objects)
                    {
                      foreach my $i (1 .. $num_subtables)
                      {
                        my $method = $subobject_methods[$i];
                        my $class  = $classes[$i];

                        # Skip undefined subobjects
                        next  unless(grep { defined } values %{$row{$class,$i}});

                        my $subobject;

                        if($direct_inject)
                        {
                          $subobject = bless { STATE_IN_DB() => 1, %{$row{$class,$i}}, %subobject_args }, $class;
                        }
                        else
                        {
                          $subobject = $class->new(%subobject_args);
                          local $subobject->{STATE_LOADING()} = 1;
                          $subobject->init(%{$row{$class,$i}});
                          $subobject->{STATE_IN_DB()} = 1;
                        }

                        $sub_objects[$i] = $subobject;

                        if($direct_inject)
                        {
                          if(my $bt = $belongs_to[$i])
                          {
                            $sub_objects[$bt]->{$method} = $subobject;
                          }
                          else
                          {
                            $object->{$method} = $subobject;
                          }
                        }
                        else
                        {
                          if(my $bt = $belongs_to[$i])
                          {
                            local $sub_objects[$bt]->{STATE_LOADING()} = 1;
                            $sub_objects[$bt]->$method($subobject);
                          }
                          else
                          {
                            local $object->{STATE_LOADING()} = 1;
                            $object->$method($subobject);
                          }
                        }
                      }
                    }

                    $skip_first = 0;
                    $self->{'_count'}++;
                    last ROW;
                  }
                };

                $error = $@;
              }

              if($error)
              {
                $self->error(ref $error ? $error : "next() - $error");
                $class->handle_error($self);
                return undef;
              }

              return $skip_first ? undef : $object;
            });
          }
        }
        else # no sub-objects at all
        {
          $iterator->_next_code(sub
          {
            my($self) = shift;

            my $object = 0;

            my $error;

            TRY:
            {
              local $@;

              eval
              {
                ROW: for(;;)
                {
                  unless($sth->fetch)
                  {
                    #$self->total($self->{'_count'});
                    return 0;
                  }

                  next ROW  if($skip_first && ++$count <= $skip_first);

                  if($direct_inject)
                  {
                    $object = bless { STATE_IN_DB() => 1, %{$row{$object_class,0}}, %object_args }, $object_class;
                  }
                  else
                  {
                    $object = $object_class->new(%object_args);

                    local $object->{STATE_LOADING()} = 1;
                    $object->init(%{$row{$object_class,0}});
                    $object->{STATE_IN_DB()} = 1;
                  }

                  $skip_first = 0;
                  $self->{'_count'}++;
                  last ROW;
                }
              };

              $error = $@;
            }

            if($error)
            {
              $self->error(ref $error ? $error : "next() - $error");
              $class->handle_error($self);
              return undef;
            }

            return $object;
          });
        }

        $iterator->_finish_code(sub
        {
          $sth->finish      if($sth);
          $db->release_dbh  if($db && $dbh_retained);
          $sth = undef;
          $db = undef;
        });

        $iterator->_destroy_code(sub
        {
          $db->release_dbh  if($db && $dbh_retained);
          $sth = undef;
          $db = undef;
        });

        return $iterator;
      }

      $count = 0;

      if($with_objects)
      {
        # This "if" clause is a totally separate code path for handling
        # duplicates rows.  I'm doing this for performance reasons.
        if($handle_dups)# || $deep_joins)
        {
          my(@seen, %seen, @sub_objects);

          #my @pk_columns = $meta->primary_key_column_names;
          my $pk_columns = $meta->primary_key_column_names_or_aliases;

          # Get list of primary key columns for each sub-table
          my @sub_pk_columns;

          foreach my $i (1 .. $num_subtables)
          {
            #$sub_pk_columns[$i + 1] = [ $classes[$i]->meta->primary_key_column_names ];
            $sub_pk_columns[$i + 1] = $classes[$i]->meta->primary_key_column_names_or_aliases;
          }

          my($last_object, %subobjects, %parent_objects);

          ROW: while($sth->fetch)
          {
            my $pk = join(PK_JOIN, map { $row{$object_class,0}{$_} } @$pk_columns);

            my $object;

            # If this is a new main (t1) table row that we haven't seen before
            unless($seen[0]{$pk}++)
            {
              # First, finish building the last object, if it exists
              if($last_object)
              {
                if($direct_inject)
                {
                  while(my($ident, $parent) = each(%parent_objects))
                  {
                    while(my($method, $subobjects) = each(%{$subobjects{$ident}}))
                    {
                      $parent->{$method} = $subobjects; # XXX
                    }
                  }              
                }
                else
                {
                  while(my($ident, $parent) = each(%parent_objects))
                  {
                    local $parent->{STATE_LOADING()} = 1;

                    while(my($method, $subobjects) = each(%{$subobjects{$ident}}))
                    {
                      $parent->$method($subobjects);
                    }
                  }
                }

                %subobjects = ();
                %parent_objects = ();

                # Add the object to the final list of objects that we'll return
                push(@objects, $last_object);

                if(!$skip_first && $manual_limit && @objects == $manual_limit)
                {
                  last ROW;
                }
              }

              # Now, create the object from this new main table row
              if($direct_inject)
              {
                $object = bless { STATE_IN_DB() => 1, %{$row{$object_class,0}}, %object_args }, $object_class;
              }
              else
              {
                $object = $object_class->new(%object_args);

                local $object->{STATE_LOADING()} = 1;
                $object->init(%{$row{$object_class,0}});
                $object->{STATE_IN_DB()} = 1;
              }

              $last_object = $object; # This is the "last object" from now on.
              @sub_objects = ();      # The list of sub-objects is per-object.
              splice(@seen, 1);       # Sub-objects seen is also per-object,
                                      # so trim it, but leave the t1 table info.
              %seen = ();             # Wipe sub-object parent tracking.
            }

            $object ||= $last_object or die "Missing object for primary key '$pk'";

            my $map_record;

            foreach my $i (1 .. $num_subtables)
            {
              my $mapped_object_method = $mapped_object_methods[$i];
              next  if(defined $mapped_object_method && !$mapped_object_method);

              my $class  = $classes[$i];
              my $tn = $i + 1;

              # Null primary key columns are not allowed
              my $sub_pk = join(PK_JOIN, grep { defined } map { $row{$class,$i}{$_} } @{$sub_pk_columns[$tn]});
              next  unless(length $sub_pk);

              my $subobject = $seen[$i]{$sub_pk};

              unless($subobject)
              {
                # Make sub-object
                if($direct_inject)
                {
                  $subobject = bless { STATE_IN_DB() => 1, %{$row{$class,$i}}, %subobject_args },  $class;
                }
                else
                {    
                  $subobject = $class->new(%subobject_args);
                  local $subobject->{STATE_LOADING()} = 1;
                  $subobject->init(%{$row{$class,$i}});
                  $subobject->{STATE_IN_DB()} = 1;
                }

                $seen[$i]{$sub_pk} = $subobject;
              }

              # If this object belongs to an attribute that can have more
              # than one object then just save it for later in the
              # per-object sub-objects list.
              if($has_dups[$i])
              {
                if($mapped_object_method)
                {
                  $map_record = $subobject;
                }
                else
                {
                  if($map_record)
                  {
                    my $method = $mapped_object_methods[$i - 1] or next;

                    if($direct_inject)
                    {
                      $subobject->{$method} = $map_record;
                    }
                    else
                    {
                      local $subobject->{STATE_LOADING()} = 1;
                      $subobject->$method($map_record);
                    }

                    $map_record = 0;
                  }

                  next  if(defined $mapped_object_methods[$i]);

                  if($has_dups[$i] && (my $bt = $belongs_to[$i]))
                  {
                    #$subobjects_belong_to[$i] = $#{$sub_objects[$bt]};

                    my $parent_object = $sub_objects[$bt];

                    # XXX: Special heavyweight subobject pairing in multi-many queries
                    if($multi_many && ref $parent_object eq 'ARRAY' && @$parent_object > 1)
                    {
                      my $maps = $subobject_method_map[$i + 1][$bt];
                      my %check;

                      foreach my $map (@$maps)
                      {
                        my $subobject_method = $map->[1];
                        $check{$subobject_method} = $subobject->$subobject_method();
                      }

                      PARENT: foreach my $check_parent (reverse @$parent_object)
                      {
                        foreach my $map (@$maps)
                        {
                          my $parent_method = $map->[0];
                          next PARENT  unless($check_parent->$parent_method() eq $check{$map->[1]});
                        }

                        $parent_object = $check_parent;
                        last PARENT;
                      }
                    }

                    # XXX: This relies on parent objects coming before child
                    # objects in the list of tables in the FROM clause.
                    $parent_object = $parent_object->[-1] #$parent_object->[$subobjects_belong_to[$i]]
                      if(ref $parent_object eq 'ARRAY');

                    my $method = $subobject_methods[$i];

                    my $ident = refaddr $parent_object;
                    next  if($seen{$ident,$method}{$sub_pk}++);
                    $parent_objects{$ident} = $parent_object;
                    push(@{$subobjects{$ident}{$method}}, $subobject);
                  }
                  else
                  {
                    my $ident = refaddr $object;
                    my $method = $subobject_methods[$i];
                    next  if($seen{$ident,$method}{$sub_pk}++);
                    $parent_objects{$ident} = $object;
                    push(@{$subobjects{$ident}{$method}}, $subobject);
                  }

                  push(@{$sub_objects[$i]}, $subobject);
                }
              }
              else # Otherwise, just assign it
              {
                push(@{$sub_objects[$i]}, $subobject);

                my $parent_object;

                if(my $bt = $belongs_to[$i])
                {
                  $parent_object = $sub_objects[$bt];
                  # XXX: This relies on parent objects coming before child
                  # objects in the list of tables in the FROM clause.
                  $parent_object = $parent_object->[-1]  if(ref $parent_object eq 'ARRAY');
                }
                else
                {
                  $parent_object = $object;
                }

                my $method = $subobject_methods[$i];

                # Only assign "... to one" values once
                next  if($seen{refaddr $parent_object,$method}++);

                if($direct_inject)
                {
                  $parent_object->{$method} = $subobject;
                }
                else
                {
                  local $parent_object->{STATE_LOADING()} = 1;
                  $parent_object->$method($subobject);
                }
              }
            }

            if($skip_first)
            {
              next ROW  if($seen[0]{$pk} > 1);
              next ROW  if(@objects < $skip_first);

              $skip_first = 0;
              @objects = (); # Discard all skipped objects
              next ROW;
            }
          }

          # Handle the left-over "last object" that needs to be finished and
          # added to the final list of objects to return.
          if($last_object && !$skip_first)
          {
            if($direct_inject)
            {
              while(my($ident, $parent) = each(%parent_objects))
              {
                while(my($method, $subobjects) = each(%{$subobjects{$ident}}))
                {
                  $parent->{$method} = $subobjects; # XXX
                }
              }
            }
            else
            {
              while(my($ident, $parent) = each(%parent_objects))
              {
                local $parent->{STATE_LOADING()} = 1;

                while(my($method, $subobjects) = each(%{$subobjects{$ident}}))
                {
                  $parent->$method($subobjects);
                }
              }
            }

            unless($manual_limit && @objects >= $manual_limit)
            {
              push(@objects, $last_object);
            }
          }

          @objects = ()  if($skip_first);
        }
        else # simple sub-objects case: nothing worse than one-to-one relationships
        {
          if($skip_first)
          {
            while($sth->fetch)
            {
              next  if(++$count < $skip_first);
              last;
            }
          }

          while($sth->fetch)
          {
            my $object;

            if($direct_inject)
            {
              $object = bless { STATE_IN_DB() => 1, %{$row{$object_class,0}}, %object_args }, $object_class;
            }
            else
            {
              $object = $object_class->new(%object_args);

              local $object->{STATE_LOADING()} = 1;
              $object->init(%{$row{$object_class,0}});
              $object->{STATE_IN_DB()} = 1;
            }

            my @sub_objects;

            foreach my $i (1 .. $num_subtables)
            {
              my $method = $subobject_methods[$i];
              my $class  = $classes[$i];

              # Skip undefined subobjects
              next  unless(grep { defined } values %{$row{$class,$i}});

              my $subobject;

              if($direct_inject)
              {
                $subobject = bless { STATE_IN_DB() => 1, %{$row{$class,$i}}, %subobject_args }, $class;
              }
              else
              {
                $subobject = $class->new(%subobject_args);
                local $subobject->{STATE_LOADING()} = 1;
                $subobject->init(%{$row{$class,$i}});
                $subobject->{STATE_IN_DB()} = 1;
              }

              $sub_objects[$i] = $subobject;

              if($direct_inject)
              {
                if(my $bt = $belongs_to[$i])
                {
                  $sub_objects[$bt]->{$method} = $subobject;
                }
                else
                {
                  $object->{$method} = $subobject;
                }
              }
              else
              {
                if(my $bt = $belongs_to[$i])
                {
                  local $sub_objects[$bt]->{STATE_LOADING()} = 1;
                  $sub_objects[$bt]->$method($subobject);
                }
                else
                {
                  local $object->{STATE_LOADING()} = 1;
                  $object->$method($subobject);
                }
              }
            }

            push(@objects, $object);
          }
        }
      }
      else # even simpler: no sub-objects at all
      {
        if($skip_first)
        {
          while($sth->fetch)
          {
            next  if(++$count < $skip_first);
            last;
          }
        }

        if($direct_inject)
        {
          my $key_map = $di_keys{$object_class};

          while($sth->fetch)
          {
            push(@objects, bless { STATE_IN_DB() => 1, %{$row{$object_class,0}}, %object_args }, $object_class);
          }
        }
        else
        {
          while($sth->fetch)
          {
            my $object = $object_class->new(%object_args);

            local $object->{STATE_LOADING()} = 1;
            $object->init(%{$row{$object_class,0}});
            $object->{STATE_IN_DB()} = 1;

            push(@objects, $object);
          }
        }
      }

      $sth->finish;
    };

    $error = $@;
  }

  return $iterator  if($iterator);

  $db->release_dbh  if($dbh_retained);

  if($error)
  {
    $class->error(ref $error ? $error : "get_objects() - $error");
    $class->handle_error($class);
    return undef;
  }

  return \@objects;
}

sub _map_action
{
  my($class, $action, @objects) = @_;

  $class->error(undef);

  foreach my $object (@objects)
  {
    unless($object->$action())
    {
      $class->error($object->error);
      $class->handle_error($class);
      return;
    }
  }

  return 1;
}

sub save_objects   { shift->_map_action('save', @_)   }

sub delete_objects
{
  my($class, %args);

  if(ref $_[1])
  {
    $class = shift;

    if(ref $_[0] eq 'HASH')
    {
      %args = (where => [ %{shift(@_)} ], @_);
    }
    elsif(ref $_[0] eq 'ARRAY')
    {
      %args = (where => shift, @_);
    }
    else { Carp::croak 'Invalid arguments: ', join(', ', @_) }

    unshift(@_, $class); # restore original args  
  }
  else
  {
    ($class, %args) = @_;
  }

  $class->error(undef);

  my $object_class = $args{'object_class'} || $class->object_class 
    or Carp::croak "Missing object class argument";

  my $meta = $object_class->meta;

  my $prepare_cached = 
    exists $args{'prepare_cached'} ? $args{'prepare_cached'} :
    $class->dbi_prepare_cached;

  my $db  = $args{'db'} ||= $object_class->init_db;
  my $dbh = $args{'dbh'};
  my $dbh_retained = 0;

  unless($dbh)
  {
    unless($dbh = $db->retain_dbh)
    {
      $class->error($db->error);
      $class->handle_error($class);
      return undef;
    }

    $args{'dbh'} = $dbh;
    $dbh_retained = 1;
  }

  $args{'query'} = delete $args{'where'};

  unless(($args{'query'} && @{$args{'query'}}) || 
         ($args{'clauses'} && @{$args{'clauses'}}) ||
         delete $args{'all'})
  {
    Carp::croak "$class - Refusing to delete all rows from the table '",
                $meta->fq_table($db), "' without an explict ",
                "'all => 1' parameter. (No 'where' or 'clauses' parameters ",
                "were passed to limit the scope of the delete operation.)";
  }

  if($args{'query'} && @{$args{'query'}} && $args{'all'})
  {
    Carp::croak "Illegal use of the 'where' and 'all' parameters in the same call";
  }

  # Yes, I'm re-using get_objects() code like crazy, and often
  # in weird ways.  Shhhh, it's a secret.

  my @bind_params;
  $args{'bind_params'} = \@bind_params;

  # Avert your eyes...
  my($where, $bind) = 
    $class->get_objects(%args, return_sql => 1, where_only => 1, table_aliases => undef);

  my $sql = 'DELETE FROM ' . $meta->fq_table_sql($db) .
            ($where ? " WHERE\n$where" : '');

  my($count, $error);

  TRY:
  {
    local $@;

    eval
    {
      local $dbh->{'RaiseError'} = 1;  
      $Debug && warn "$sql - bind params: ", join(', ', @$bind), "\n";

      # $meta->prepare_bulk_delete_options (defunct)
      my $sth = $prepare_cached ? $dbh->prepare_cached($sql, undef, 3) : 
                                  $dbh->prepare($sql) or die $dbh->errstr;

      if(@bind_params)
      {
        my $i = 1;

        foreach my $value (@$bind)
        {
          $sth->bind_param($i, $value, $bind_params[$i - 1]);
          $i++;
        }

        $sth->execute;
      }
      else
      {
        $sth->execute(@$bind);
      }

      $count = $sth->rows || 0;
    };

    $error = $@;
  }

  if($error)
  {
    $class->error(ref $error ? $error : "delete_objects() - $error");
    $class->handle_error($class);
    return undef;
  }

  return $count;
}

sub update_objects
{
  my($class, %args) = @_;

  $class->error(undef);

  my $object_class = $args{'object_class'} || $class->object_class 
    or Carp::croak "Missing object class argument";

  my $meta = $object_class->meta;

  my $prepare_cached = 
    exists $args{'prepare_cached'} ? $args{'prepare_cached'} :
    $class->dbi_prepare_cached;

  my $db  = $args{'db'} ||= $object_class->init_db;
  my $dbh = $args{'dbh'};
  my $dbh_retained = 0;

  unless($dbh)
  {
    unless($dbh = $db->retain_dbh)
    {
      $class->error($db->error);
      $class->handle_error($class);
      return undef;
    }

    $args{'dbh'} = $dbh;
    $dbh_retained = 1;
  }

  unless(($args{'where'} && @{$args{'where'}}) || delete $args{'all'})
  {
    Carp::croak "$class - Refusing to update all rows in the table '",
                $meta->fq_table_sql($db), "' without an explict ",
                "'all => 1' parameter";
  }

  if($args{'where'} && @{$args{'where'}} && $args{'all'})
  {
    Carp::croak "Illegal use of the 'where' and 'all' parameters in the same call";
  }

  my $where = delete $args{'where'};
  my $set   = delete $args{'set'} 
    or Carp::croak "Missing requires 'set' parameter";

  $set = [ %$set ]  if(ref $set eq 'HASH');

  # Yes, I'm re-using get_objects() code like crazy, and often
  # in weird ways.  Shhhh, it's a secret.

  my @bind_params;
  $args{'bind_params'} = \@bind_params;

  $args{'query'} = $set;

  # Avert your eyes...
  my($set_sql, $set_bind) = 
    $class->get_objects(%args,
                        return_sql    => 1,
                        where_only    => 1,
                        logic         => ',', 
                        set           => 1, 
                        table_aliases => 0);

  my $sql;

  my $where_bind = [];

  if($args{'query'} = $where)
  {
    my $where_sql;

    ($where_sql, $where_bind) = 
      $class->get_objects(%args, 
                          return_sql    => 1,
                          where_only    => 1,
                          table_aliases => 0);

    $sql = 'UPDATE ' . $meta->fq_table_sql($db) . 
           "\nSET\n$set_sql\nWHERE\n$where_sql";
  }
  else
  {
    $sql = 'UPDATE ' . $meta->fq_table_sql($db) . "\nSET\n$set_sql";
  }

  my($count, $error);

  TRY:
  {
    local $@;

    eval
    {
      local $dbh->{'RaiseError'} = 1;  
      $Debug && warn "$sql (", join(', ', @$set_bind, @$where_bind), ")\n";

      # $meta->prepare_bulk_update_options (defunct)
      my $sth = $prepare_cached ? $dbh->prepare_cached($sql, undef, 3) : 
                                  $dbh->prepare($sql) or die $dbh->errstr;

      if(@bind_params)
      {
        my $i = 1;

        foreach my $value (@$set_bind, @$where_bind)
        {
          $sth->bind_param($i, $value, $bind_params[$i - 1]);
          $i++;
        }

        $sth->execute;
      }
      else
      {
        $sth->execute(@$set_bind, @$where_bind);
      }

      $count = $sth->rows || 0;
    };

    $error = $@;
  }

  if($error)
  {
    $class->error(ref $error ? $error : "update_objects() - $error");
    $class->handle_error($class);
    return undef;
  }

  return $count;
}

sub make_manager_method_from_sql
{
  my($class) = shift;

  my %args;

  if(@_ == 2)
  {
    %args = (method => $_[0], sql => $_[1]);
  }
  else { %args = @_ }

  my $named_args = delete $args{'params'};

  my $method = delete $args{'method'} or  Carp::croak "Missing method name";
  my $code;

  $args{'_methods'} = {}; # Will fill in on first run

  my $worker_method = $args{'iterator'} ?
    'get_objects_iterator_from_sql' : 'get_objects_from_sql';

  if($named_args)
  {    
    my @params = @$named_args; # every little bit counts

    $code = sub 
    {
      my($self, %margs) = @_;
      $self->$worker_method(
        %args,
        args => [ delete @margs{@params} ], 
        %margs);
    };
  }
  else
  {
    $code = sub { shift->$worker_method(%args, args => \@_) };
  }

  no strict 'refs';
  *{"${class}::$method"} = $code;

  return $code;
}

sub get_objects_from_sql
{
  my($class) = shift;

  my(%args, $sql);

  if(@_ == 1) { $sql = shift }
  else
  {
    %args = @_;
    $sql = $args{'sql'};
  }

  Carp::croak "Missing SQL"  unless($sql);

  my $object_class = $args{'object_class'} || $class->object_class ||
    Carp::croak "Missing object class";

  my $meta = $object_class->meta 
    or Carp::croak "Could not get meta for $object_class";

  my $prepare_cached = 
    exists $args{'prepare_cached'} ? $args{'prepare_cached'} :
    $class->dbi_prepare_cached;

  my $methods   = $args{'_methods'};
  my $exec_args = $args{'args'} || [];
  my $attr      = $args{'prepare_options'};

  my $have_methods = ($args{'_methods'} && %{$args{'_methods'}}) ? 1 : 0;

  my $db  = delete $args{'db'} || $object_class->init_db;
  my $dbh = delete $args{'dbh'};
  my $dbh_retained = 0;

  unless($dbh)
  {
    unless($dbh = $db->retain_dbh)
    {
      $class->error($db->error);
      $class->handle_error($class);
      return undef;
    }

    $dbh_retained = 1;
  }

  my %object_args =
  (
    (exists $args{'share_db'} ? $args{'share_db'} : 1) ? (db => $db) : ()
  );

  my(@objects, $error);

  TRY:
  {
    local $@;

    eval
    {
      local $dbh->{'RaiseError'} = 1;

      $Debug && warn "$sql (", join(', ', @$exec_args), ")\n";
      my $sth = $prepare_cached ? $dbh->prepare_cached($sql, $attr, 3) : 
                                  $dbh->prepare($sql, $attr) or die $dbh->errstr;

      $sth->execute(@$exec_args);

      while(my $row = $sth->fetchrow_hashref)
      {
        unless($have_methods)
        {
          foreach my $col (keys %$row)
          {
            if($meta->column($col))
            {
              $methods->{$col} = $meta->column_mutator_method_name($col);
            }
            elsif($object_class->can($col))
            {
              $methods->{$col} = $col;
            }
            elsif($meta->column(lc $col))
            {
              $methods->{$col} = $meta->column_mutator_method_name(lc $col);
            }
            elsif($object_class->can(lc $col))
            {
              $methods->{$col} = lc $col;
            }
          }

          $have_methods = 1;
        }

        my $object = $object_class->new(%object_args);

        local $object->{STATE_LOADING()} = 1;
        $object->{STATE_IN_DB()} = 1;

        while(my($col, $val) = each(%$row))
        {
          my $method = $methods->{$col} || $col;
          $object->$method($val);
        }

        $object->{MODIFIED_COLUMNS()} = {};

        push(@objects, $object);
      }
    };

    $error = $@;
  }

  $db->release_dbh  if($dbh_retained);

  if($error)
  {
    $class->total(undef);
    $class->error(ref $error ? $error : "get_objects_from_sql() - $error");
    $class->handle_error($class);
    return undef;
  }

  return \@objects;
}

sub get_objects_iterator_from_sql
{
  my($class) = shift;

  my(%args, $sql);

  if(@_ == 1) { $sql = shift }
  else
  {
    %args = @_;
    $sql = $args{'sql'};
  }

  Carp::croak "Missing SQL"  unless($sql);

  my $object_class = $args{'object_class'} || $class->object_class ||
    Carp::croak "Missing object class";

  weaken(my $meta = $object_class->meta
    or Carp::croak "Could not get meta for $object_class");

  my $prepare_cached = 
    exists $args{'prepare_cached'} ? $args{'prepare_cached'} :
    $class->dbi_prepare_cached;

  my $methods   = $args{'_methods'};
  my $exec_args = $args{'args'} || [];
  my $attr      = $args{'prepare_options'};

  my $have_methods = ($args{'_methods'} && %{$args{'_methods'}}) ? 1 : 0;

  my $db  = delete $args{'db'} || $object_class->init_db;
  my $dbh = delete $args{'dbh'};
  my $dbh_retained = 0;

  unless($dbh)
  {
    unless($dbh = $db->retain_dbh)
    {
      $class->error($db->error);
      $class->handle_error($class);
      return undef;
    }

    $dbh_retained = 1;
  }

  my %object_args =
  (
    (exists $args{'share_db'} ? $args{'share_db'} : 1) ? (db => $db) : ()
  );

  my($sth, $error);

  TRY:
  {
    local $@;

    eval
    {
      local $dbh->{'RaiseError'} = 1;

      $Debug && warn "$sql (", join(', ', @$exec_args), ")\n";
      $sth = $prepare_cached ? $dbh->prepare_cached($sql, $attr, 3) : 
                               $dbh->prepare($sql, $attr) or die $dbh->errstr;

      $sth->execute(@$exec_args);
    };

    $error = $@;
  }

  if($error)
  {
    $db->release_dbh  if($dbh_retained);
    $class->total(undef);
    $class->error(ref $error ? $error : "get_objects_iterator_from_sql() - $error");
    $class->handle_error($class);
    return undef;
  }

  my $iterator = Rose::DB::Object::Iterator->new(active => 1);

  $iterator->_next_code(sub
  {
    my($self) = shift;

    my $object = 0;

    my $error;

    TRY:
    {
      local $@;

      eval
      {
        ROW: for(;;)
        {
          my $row = $sth->fetchrow_hashref or return 0;

          unless($have_methods)
          {
            foreach my $col (keys %$row)
            {
              if($meta->column($col))
              {
                $methods->{$col} = $meta->column_mutator_method_name($col);
              }
              elsif($object_class->can($col))
              {
                $methods->{$col} = $col;
              }
              elsif($meta->column(lc $col))
              {
                $methods->{$col} = $meta->column_mutator_method_name(lc $col);
              }
              elsif($object_class->can(lc $col))
              {
                $methods->{$col} = lc $col;
              }
            }

            $have_methods = 1;
          }

          $object = $object_class->new(%object_args);

          local $object->{STATE_LOADING()} = 1;
          $object->{STATE_IN_DB()} = 1;

          while(my($col, $val) = each(%$row))
          {
            my $method = $methods->{$col};
            $object->$method($val);
          }

          $object->{MODIFIED_COLUMNS()} = {};

          $self->{'_count'}++;
          last ROW;
        }
      };

      $error = $@;
    }

    if($error)
    {
      $self->error(ref $error ? $error : "next() - $error");
      $class->handle_error($self);
      return undef;
    }

    return $object;
  });

  $iterator->_finish_code(sub
  {
    $sth->finish      if($sth);
    $db->release_dbh  if($db && $dbh_retained);
    $sth = undef;
    $db = undef;
  });

  $iterator->_destroy_code(sub
  {
    $db->release_dbh  if($db && $dbh_retained);
    $sth = undef;
    $db = undef;
  });

  return $iterator;
}

sub perl_class_definition
{
  my($class) = shift;

  my $object_class = $class->object_class || $class->_object_class;

  no strict 'refs';
  my @isa = @{"${class}::ISA"};

  my $use_bases = "use base qw(@isa);";

  return<<"EOF";
package $class;

use strict;

$use_bases

use $object_class;

sub object_class { '@{[ $class->object_class || $class->_object_class ]}' }

__PACKAGE__->make_manager_methods('@{[ $class->_base_name ]}');

1;
EOF
}

1;

__END__

=head1 NAME

Rose::DB::Object::Manager - Fetch multiple Rose::DB::Object-derived objects from the database using complex queries.

=head1 SYNOPSIS

  ##
  ## Given the following Rose::DB::Object-derived classes...
  ##

  package Category;

  use base 'Rose::DB::Object';

  __PACKAGE__->meta->setup
  (
    table   => 'categories',
    columns =>
    [
      id          => { type => 'int', primary_key => 1 },
      name        => { type => 'varchar', length => 255 },
      description => { type => 'text' },
    ],

    unique_key => 'name',
  );

  ...

  package CodeName;

  use base 'Rose::DB::Object';

  __PACKAGE__->meta->setup
  (
    table   => 'code_names',
    columns =>
    [
      id          => { type => 'int', primary_key => 1 },
      product_id  => { type => 'int' },
      name        => { type => 'varchar', length => 255 },
      applied     => { type => 'date', not_null => 1 },
    ],

    foreign_keys =>
    [
      product =>
      {
        class       => 'Product',
        key_columns => { product_id => 'id' },
      },
    ],
  );

  ...

  package Product;

  use base 'Rose::DB::Object';

  __PACKAGE__->meta->setup
  (
    table   => 'products',
    columns =>
    [
      id          => { type => 'int', primary_key => 1 },
      name        => { type => 'varchar', length => 255 },
      description => { type => 'text' },
      category_id => { type => 'int' },
      region_num  => { type => 'int' },

      status => 
      {
        type      => 'varchar', 
        check_in  => [ 'active', 'inactive' ],
        default   => 'inactive',
      },

      start_date  => { type => 'datetime' },
      end_date    => { type => 'datetime' },

      date_created  => { type => 'timestamp', default => 'now' },  
      last_modified => { type => 'timestamp', default => 'now' },
    ],

    unique_key => 'name',

    foreign_keys =>
    [
      category =>
      {
        class       => 'Category',
        key_columns =>
        {
          category_id => 'id',
        }
      },
    ],

    relationships =>
    [
      code_names =>
      {
        type  => 'one to many',
        class => 'CodeName',
        column_map   => { id => 'product_id' },
        manager_args => 
        {
          sort_by => CodeName->meta->table . '.applied DESC',
        },
      },
    ],
  );

  ...

  ##
  ## Create a manager class
  ##

  package Product::Manager;

  use base 'Rose::DB::Object::Manager';

  sub object_class { 'Product' }

  __PACKAGE__->make_manager_methods('products');

  # The call above creates the methods shown below.  (The actual 
  # method bodies vary slightly, but this is the gist of it...)
  #
  # sub get_products
  # {
  #   shift->get_objects(@_, object_class => 'Product');
  # }
  #
  # sub get_products_iterator
  # {
  #   shift->get_objects_iterator(@_, object_class => 'Product');
  # }
  #
  # sub get_products_count
  # {
  #   shift->get_objects_count(@_, object_class => 'Product');
  # }
  #
  # sub update_products
  # {
  #   shift->update_objects(@_, object_class => 'Product');
  # }
  #
  # sub delete_products
  # {
  #   shift->delete_objects(@_, object_class => 'Product');
  # }

  ...

  ##
  ## Use the manager class
  ##

  #
  # Get a reference to an array of objects
  #

  $products = 
    Product::Manager->get_products
    (
      query =>
      [
        category_id => [ 5, 7, 22 ],
        status      => 'active',
        start_date  => { lt => '15/12/2005 6:30 p.m.' },
        name        => { like => [ '%foo%', '%bar%' ] },
      ],
      sort_by => 'category_id, start_date DESC',
      limit   => 100,
      offset  => 80,
    );

  foreach my $product (@$products)
  {
    print $product->id, ' ', $product->name, "\n";
  }

  #
  # Get objects iterator
  #

  $iterator = 
    Product::Manager->get_products_iterator
    (
      query =>
      [
        category_id => [ 5, 7, 22 ],
        status      => 'active',
        start_date  => { lt => '15/12/2005 6:30 p.m.' },
        name        => { like => [ '%foo%', '%bar%' ] },
      ],
      sort_by => 'category_id, start_date DESC',
      limit   => 100,
      offset  => 80,
    );

  while($product = $iterator->next)
  {
    print $product->id, ' ', $product->name, "\n";
  }

  print $iterator->total;

  #
  # Get objects count
  #

  $count =
    Product::Manager->get_products_count
    (
      query =>
      [
        category_id => [ 5, 7, 22 ],
        status      => 'active',
        start_date  => { lt => '15/12/2005 6:30 p.m.' },
        name        => { like => [ '%foo%', '%bar%' ] },
      ],
    ); 

   die Product::Manager->error  unless(defined $count);

  print $count; # or Product::Manager->total()

  #
  # Get objects and sub-objects in a single query
  #

  $products = 
    Product::Manager->get_products
    (
      with_objects => [ 'category', 'code_names' ],
      query =>
      [
        category_id => [ 5, 7, 22 ],
        status      => 'active',
        start_date  => { lt => '15/12/2005 6:30 p.m.' },

        # We need to disambiguate the "name" column below since it
        # appears in more than one table referenced by this query. 
        # When more than one table is queried, the tables have numbered
        # aliases starting from the "main" table ("products").  The
        # "products" table is t1, "categories" is t2, and "code_names"
        # is t3.  You can read more about automatic table aliasing in
        # the documentation for the get_objects() method below.
        #
        # "category.name" and "categories.name" would work too, since
        # table and relationship names are also valid prefixes.

        't2.name'   => { like => [ '%foo%', '%bar%' ] },
      ],
      sort_by => 'category_id, start_date DESC',
      limit   => 100,
      offset  => 80,
    );

  foreach my $product (@$products)
  {
    # The call to $product->category does not hit the database
    print $product->name, ': ', $product->category->name, "\n";

    # The call to $product->code_names does not hit the database
    foreach my $code_name ($product->code_names)
    {
      # This call doesn't hit the database either
      print $code_name->name, "\n";
    }
  }

  #
  # Update objects
  #

  $num_rows_updated =
    Product::Manager->update_products(
      set =>
      {
        end_date   => DateTime->now,
        region_num => { sql => 'region_num * -1' }
        status     => 'defunct',
      },
      where =>
      [
        start_date => { lt => '1/1/1980' },
        status     => [ 'active', 'pending' ],
      ]);

  #
  # Delete objects
  #

  $num_rows_deleted =
    Product::Manager->delete_products(
      where =>
      [
        status  => [ 'stale', 'old' ],
        name    => { like => 'Wax%' },
        or =>
        [
          start_date => { gt => '2008-12-30' },
          end_date   => { gt => 'now' },
        ],
      ]);

=head1 DESCRIPTION

L<Rose::DB::Object::Manager> is a base class for classes that select rows from tables fronted by L<Rose::DB::Object>-derived classes.  Each row in the table(s) queried is converted into the equivalent L<Rose::DB::Object>-derived object.

Class methods are provided for fetching objects all at once, one at a time through the use of an iterator, or just getting the object count.  Subclasses are expected to create syntactically pleasing wrappers for L<Rose::DB::Object::Manager> class methods, either manually or with the L<make_manager_methods|/make_manager_methods> method.  A very minimal example is shown in the L<synopsis|/SYNOPSIS> above.

=head1 CLASS METHODS

=over 4

=item B<dbi_prepare_cached [BOOL]>

Get or set a boolean value that indicates whether or not this class will use L<DBI>'s L<prepare_cached|DBI/prepare_cached> method by default (instead of the L<prepare|DBI/prepare> method) when preparing SQL queries.  The default value is false.

=item B<default_limit_with_subselect [BOOL]>

Get or set a boolean value that determines whether or not this class will consider using a sub-query to express C<limit>/C<offset> constraints when fetching sub-objects related through one of the "...-to-many" relationship types.  Not all databases support this syntax, and not all queries can use it even in supported databases.  If this parameter is true, the feature will be used when possible, by default.  The default value is true.

=item B<default_manager_method_types [ LIST | ARRAYREF ]>

Get or set the default list of method types used by the L<make_manager_methods|/make_manager_methods> method.  The default list is C<objects>, C<iterator>, C<count>, C<delete>, and C<update>.

=item B<default_nested_joins [BOOL]>

Get or set a boolean value that determines whether or not this class will consider using nested JOIN syntax when fetching related objects.  Not all databases support this syntax, and not all queries can use it even in supported databases.  If this parameter is true, the feature will be used when possible, by default.  The default value is true.

=item B<default_objects_per_page [NUM]>

Get or set the default number of items per page, as returned by the L<get_objects|/get_objects> method when used with the C<page> and/or C<per_page> parameters.  The default value is 20.

=item B<delete_objects [ PARAMS | ARRAYREF | HASHREF ]>

Delete rows from a table fronted by a L<Rose::DB::Object>-derived class based on PARAMS, where PARAMS are name/value pairs.  Returns the number of rows deleted, or undef if there was an error.

If the first argument is a reference to a hash or array, it is converted to a reference to an array (if necessary) and taken as the value of the C<where> parameter. 

Valid parameters are:

=over 4

=item B<all BOOL>

If set to a true value, this parameter indicates an explicit request to delete all rows from the table.  If both the C<all> and the C<where> parameters are passed, a fatal error will occur.

=item B<db DB>

A L<Rose::DB>-derived object used to access the database.  If omitted, one will be created by calling the L<init_db|Rose::DB::Object/init_db> method of the L<object_class|/object_class>. 

=item B<prepare_cached BOOL>

If true, then L<DBI>'s L<prepare_cached|DBI/prepare_cached> method will be used (instead of the L<prepare|DBI/prepare> method) when preparing the SQL statement that will delete the objects.  If omitted, the default value is determined by the L<dbi_prepare_cached|/dbi_prepare_cached> class method.

=item B<object_class CLASS>

The name of the L<Rose::DB::Object>-derived class that fronts the table from which rows are to be deleted.  This parameter is required; a fatal error will occur if it is omitted.  Defaults to the value returned by the L<object_class|/object_class> class method.

=item B<where ARRAYREF>

The query parameters, passed as a reference to an array of name/value pairs.  These pairs are used to formulate the "where" clause of the SQL query that is used to delete the rows from the table.  Arbitrarily nested boolean logic is supported.

For the complete list of valid parameter names and values, see the documentation for the C<query> parameter of the L<build_select|Rose::DB::Object::QueryBuilder/build_select> function in the L<Rose::DB::Object::QueryBuilder> module.

If this parameter is omitted, this method will refuse to delete all rows from the table and a fatal error will occur.  To delete all rows from a table, you must pass the C<all> parameter with a true value.  If both the C<all> and the C<where> parameters are passed, a fatal error will occur.

=back

=item B<error>

Returns the text message associated with the last error, or false if there was no error.

=item B<error_mode [MODE]>

Get or set the error mode for this class.  The error mode determines what happens when a method of this class encounters an error.  The default setting is "fatal", which means that methods will L<croak|Carp/croak> if they encounter an error.

B<PLEASE NOTE:> The error return values described in the method documentation in the rest of this document are only relevant when the error mode is set to something "non-fatal."  In other words, if an error occurs, you'll never see any of those return values if the selected error mode L<die|perlfunc/die>s or L<croak|Carp/croak>s or otherwise throws an exception when an error occurs.

Valid values of MODE are:

=over 4

=item carp

Call L<Carp::carp|Carp/carp> with the value of the object L<error|Rose::DB::Object/error> as an argument.

=item cluck

Call L<Carp::cluck|Carp/cluck> with the value of the object L<error|Rose::DB::Object/error> as an argument.

=item confess

Call L<Carp::confess|Carp/confess> with the value of the object L<error|Rose::DB::Object/error> as an argument.

=item croak

Call L<Carp::croak|Carp/croak> with the value of the object L<error|Rose::DB::Object/error> as an argument.

=item fatal

An alias for the "croak" mode.

=item return

Return a value that indicates that an error has occurred, as described in the documentation for each method.

=back

In all cases, the class's C<error> attribute will also contain the error message.

=item B<get_objects [ PARAMS | HASHREF | ARRAYREF ]>

Get L<Rose::DB::Object>-derived objects based on PARAMS, where PARAMS are name/value pairs.  Returns a reference to a (possibly empty) array, or undef if there was an error.  

If the first argument is a reference to a hash or array, it is converted to a reference to an array (if necessary) and taken as the value of the C<query> parameter. 

Each table that participates in the query will be aliased.  Each alias is in the form "tN" where "N" is an ascending number starting with 1.  The tables are numbered as follows.

=over 4

=item * The primary table is always "t1"

=item * The table(s) that correspond to each relationship or foreign key named in the C<with_objects> parameter are numbered in order, starting with "t2"

=item * The table(s) that correspond to each relationship or foreign key named in the C<require_objects> parameter are numbered in order, starting where the C<with_objects> table aliases left off.

=back

"Many to many" relationships have two corresponding tables, and therefore will use two "tN" numbers.  All other supported of relationship types only have just one table and will therefore use a single "tN" number.

For example, imagine that the C<Product> class shown in the L<synopsis|/SYNOPSIS> also has a "many to many" relationship named "colors."  Now consider this call:

    $products = 
      Product::Manager->get_products(
        require_objects => [ 'category' ],
        with_objects    => [ 'code_names', 'colors' ],
        multi_many_ok   => 1,
        query           => [ status => 'defunct' ],
        sort_by         => 't1.name');

The "products" table is "t1" since it's the primary table--the table behind the C<Product> class that C<Product::Manager> manages.  Next, the C<with_objects> tables are aliased.  The "code_names" table is "t2".  Since "colors" is a "many to many" relationship, it gets two numbers: "t3" and "t4".  Finally, the C<require_objects> tables are numbered: the table behind the foreign key "category" is "t5".  Here's an annotated version of the example above:

    # Table aliases in the comments
    $products = 
      Product::Manager->get_products(
                           # t5
        require_objects => [ 'category' ],
                           # t2            t3, t4
        with_objects    => [ 'code_names', 'colors' ],
        multi_many_ok   => 1,
        query           => [ status => 'defunct' ],
        sort_by         => 't1.name'); # "products" is "t1"

Also note that the C<multi_many_ok> parameter was used in order to suppress the warning that occurs when more than one "... to many" relationship is included in the combination of C<require_objects> and C<with_objects> ("code_names" (one to many) and "colors" (many to many) in this case).  See the documentation for C<multi_many_ok> below.

The "tN" table aliases are for convenience, and to isolate end-user code from the actual table names.  Ideally, the actual table names should only exist in one place in the entire code base: in the class definitions for each L<Rose::DB::OBject>-derived class.

That said, when using L<Rose::DB::Object::Manager>, the actual table names can be used as well.  But be aware that some databases don't like a mix of table aliases and real table names in some kinds of queries.

Valid parameters to L<get_objects|/get_objects> are:

=over 4

=item B<allow_empty_lists BOOL>

If set to true, C<query> parameters with empty lists as values are allowed.  For example:

    @ids = (); # empty list

    Product::Manager->get_products(
      query =>
      [
        id => \@ids,
        ...
      ]);

By default, passing an empty list as a value will cause a fatal error.

=item B<db DB>

A L<Rose::DB>-derived object used to access the database.  If omitted, one will be created by calling the L<init_db|Rose::DB::Object/init_db> method of the C<object_class>.

=item B<debug BOOL>

If true, print the generated SQL to STDERR.

=item B<distinct [ BOOL | ARRAYREF ]>

If set to any kind of true value, then the "DISTINCT" SQL keyword will be added to the "SELECT" statement.  Specific values trigger the behaviors described below.

If set to a simple scalar value that is true, then only the columns in the primary table ("t1") are fetched from the database.

If set to a reference to an array of table names, "tN" table aliases, or relationship or foreign key names, then only the columns from the corresponding tables will be fetched.  In the case of relationships that involve more than one table, only the "most distant" table is considered.  (e.g., The map table is ignored in a "many to many" relationship.)  Columns from the primary table ("t1") are always selected, regardless of whether or not it appears in the list.

This parameter conflicts with the C<fetch_only> parameter in the case where both provide a list of table names or aliases.  In this case, if the value of the C<distinct> parameter is also reference to an array table names or aliases, then a fatal error will occur.

=item B<fetch_only ARRAYREF>

ARRAYREF should be a reference to an array of table names or "tN" table aliases. Only the columns from the corresponding tables will be fetched.  In the case of relationships that involve more than one table, only the "most distant" table is considered.  (e.g., The map table is ignored in a "many to many" relationship.)  Columns from the primary table ("t1") are always selected, regardless of whether or not it appears in the list.

This parameter conflicts with the C<distinct> parameter in the case where both provide a list of table names or aliases.  In this case, then a fatal error will occur.

=item B<for_update BOOL>

If true, this parameter is translated to be the equivalent of passing the L<lock|/lock> parameter and setting the C<type> to C<for update>.  For example, this:

    for_update => 1

is equivalent to this:

    lock => { type => 'for update' }

See the L<lock|/lock> parameter below for more information.

=item B<hints HASHREF>

A reference to a hash of hints that influence the SQL generated to fetch the objects.  Hints are just "suggestions" and may be ignored, depending on the actual features of the database being queried.  Use the L<debug|/debug> parameter to see the generated SQL.  Most of the current hints apply to MySQL only.  See the relevant documentation for more details:

L<http://dev.mysql.com/doc/refman/5.0/en/select.html>

The hints hash is keyed by tN table aliases or relationship names.  The value of each key is a reference to a hash of hint directives.  In the absence of any key for "t1" or the name of the primary table, the entire hints hash is considered applicable to the primary table.

Valid hint directives are:

=over 4

=item B<all_rows BOOL>

If true, direct the database to choose the query plan that returns all the records as quickly as possible.

=item B<big_result BOOL>

If true, indicate to the database that the result set is expected to be big.

=item B<buffer_result BOOL>

If true, force the result to be put into a temporary table.

=item B<cache BOOL>

If true, ask the database to store the result in its query cache.

=item B<calc_found_rows BOOL>

If true, ask the database to internally calculate the number of rows found, ignoring any L<limit|/limit> or L<offset|/offset> arguments.

=item B<comment TEXT>

Add a comment after the "SELECT" keyword in the query.  TEXT should B<not> be surrounded by any comment delimiters.  The appropriate delimiters will be added automatically.

=item B<first_rows BOOL>

If true, direct the database to choose the query plan that returns the first result record as soon as possible.

=item B<force_index [ INDEX | ARRAYREF ]>

Force the use of the named indexes, specified by an index name or a reference to an array of index names.

=item B<high_priority BOOL>

If true, give this query higher priority.

=item B<ignore_index [ INDEX | ARRAYREF ]>

Ignore the named indexes, specified by an index name or a reference to an array of index names.

=item B<no_cache BOOL>

If true, ask the database not to store the result in its query cache.

=item B<small_result BOOL>

If true, indicate to the database that the result set is expected to be small.

=item B<straight_join BOOL>

If true, ask the database to join the tables in the order that they are listed in the "FROM" clause of the SQL statement.

=item B<strict_ops BOOL>

If true, any comparison operator used in the C<query> that is not listed in the L<Rose::DB::Object::QueryBuilder> documentation will cause a fatal error.  The default value is determined by the L<strict_ops|/strict_ops> class method.

=item B<use_index [ INDEX | ARRAYREF ]>

Prefer to use the named indexes, specified by an index name or a reference to an array of index names.

=back

=item B<inject_results BOOL>

If true, then the data returned from the database will be directly "injected" into the objects returned by this method, bypassing the constructor and column mutator methods for each object class.  The default is false.  This parameter is ignored (i.e., treated as if it were false) if the C<select> parameter is passed.

This parameter is useful for situations where the performance of L<get_objects|/get_objects> is limited by the speed at which L<Rose::DB::Object>-derived objects can be created.  It's safe to set this parameter to true only if the constructor and column mutator methods for all of the classes involved do not have any side-effects (or if it's is okay to bypass any side-effects).

The default L<Rose::DB::Object> L<constructor|Rose::DB::Object/new> and the column mutator methods created by the column classes included in the L<Rose::DB::Object> module distribution do not have any side-effects and should therefore be safe to use with this parameter.

=item B<limit NUM>

Return a maximum of NUM objects.

=item B<limit_with_subselect BOOL>

This parameter controls whether or not this method will consider using a sub-query to express  C<limit>/C<offset> constraints when fetching sub-objects related through one of the "...-to-many" relationship types.  Not all databases support this syntax, and not all queries can use it even in supported databases.  If this parameter is true, the feature will be used when possible.

The default value is determined by the L<default_limit_with_subselect|/default_limit_with_subselect> class method.

=item B<lock [ TYPE | HASHREF ]>

Select the objects using some form of locking.  These lock directives have database-specific behavior and not all directives are supported by all databases.  Consult your database's documentation to find out more.  Use the L<debug|/debug> parameter to see the generated SQL.

The value should be a reference to a hash or a TYPE string, which is equivalent to setting the value of the C<type> key in the hash reference form.  For example, these are both equivalent:

    lock => 'for update'
    lock => { type => 'for update' }

Valid hash keys are:

=over 4

=item B<columns ARRAYREF>

A reference to an array of column names to lock.  The columns may be prefixed with their table name or their C<tN> alias (e.g., C<mytable.mycol> or C<t2.mycol>) or left unadorned if they are not ambiguous.  References to scalars will be de-referenced and used as-is, included literally in the SQL locking clause.

=item B<nowait BOOL>

If true, do not wait to acquire the lock.  If supported, this is usually by adding a C<NOWAIT> directive to the SQL.

=item B<on ARRAYREF>

A reference to an array of items to lock.  Depending on the database, these may be column or tables.  Both column and table names should be specified using dot-separated relationship paths.

For example, C<vendor.region.name> would lock the C<name> column in the table arrived at by traversing the C<vendor> and then the C<region> relationships, starting from the primary table (C<t1>).  Lone column names may also be used, provided they're not ambiguous.

For locking whole tables, C<vendor.region> would lock the table arrived at by traversing the C<vendor> and then the C<region> relationships.  (See the L<require_objects|/require_objects> parameter for more information on relationship traversal.)

Finally, references to scalars will be de-referenced and used as-is, included literally in the SQL locking clause.

=item B<skip_locked BOOL>

If true, skip any locked rows.  If supported, this is usually by adding a C<SKIP LOCKED> clause to the SQL.

=item B<tables ARRAYREF>

A reference to an array of tables to lock.  Table named or C<tN> aliases may be used.  References to scalars will be de-referenced and used as-is, included literally in the SQL locking clause.

=item B<type TYPE>

The type of lock to acquire.  Valid values for TYPE are C<for update> and C<shared>.  This hash key is required unless the L<for_update|/for_update> parameter was passed with a true value.

=item B<wait TIME>

Wait for the specified TIME (generally seconds) before giving up acquiring the lock. If supported, this is usually by adding a C<WAIT ...> clause to the SQL.

=back

You may pass only one of the parameters that specifies "what to lock" (i.e., C<columns>, C<on>, or C<tables>).

=item B<nested_joins BOOL>

This parameter controls whether or not this method will consider using nested JOIN syntax when fetching related objects.  Not all databases support this syntax, and not all queries will use it even in supported databases.  If this parameter is true, the feature will be used when possible.

The default value is determined by the L<default_nested_joins|/default_nested_joins> class method.

=item B<multi_many_ok BOOL>

If true, do not print a warning when attempting to do multiple LEFT OUTER JOINs against tables related by "... to many" relationships.  See the documentation for the C<with_objects> parameter for more information.

=item B<nonlazy [ BOOL | ARRAYREF ]>

By default, L<get_objects|/get_objects> will honor all L<load-on-demand columns|Rose::DB::Object::Metadata::Column/load_on_demand> when fetching objects.  Use this parameter to override that behavior and select all columns instead.

If the value is a true boolean value (typically "1"), then all columns will be fetched for all participating classes (i.e., the main object class as well as any sub-object classes).

The value can also be a reference to an array of relationship names.  The sub-objects corresponding to each relationship name will have all their columns selected.  To refer to the main class (the "t1" table), use the special name "self".

=item B<object_args HASHREF>

A reference to a hash of name/value pairs to be passed to the constructor of each C<object_class> object fetched, in addition to the values from the database.

=item B<object_class CLASS>

The name of the L<Rose::DB::Object>-derived objects to be fetched.  This parameter is required; a fatal error will occur if it is omitted.  Defaults to the value returned by the L<object_class|/object_class> class method.

=item B<offset NUM>

Skip the first NUM rows.  If the database supports some sort of "limit with offset" syntax (e.g., "LIMIT 10 OFFSET 20") then it will be used.  Otherwise, the first NUM rows will be fetched and then discarded.

This parameter can only be used along with the C<limit> parameter, otherwise a fatal error will occur.

=item B<page NUM>

Show page number NUM of objects.  Pages are numbered starting from 1.  A page number less than or equal to zero causes the page number to default to 1.

The number of objects per page can be set by the C<per_page> parameter.  If the C<per_page> parameter is supplied and this parameter is omitted, it defaults to 1 (the first page).

If this parameter is included along with either of the C<limit> or <offset> parameters, a fatal error will occur.

=item B<per_page NUM>

The number of objects per C<page>.   Defaults to the value returned by the L<default_objects_per_page|/default_objects_per_page> class method (20, by default).

If this parameter is included along with either of the C<limit> or <offset> parameters, a fatal error will occur.

=item B<prepare_cached BOOL>

If true, then L<DBI>'s L<prepare_cached|DBI/prepare_cached> method will be used (instead of the L<prepare|DBI/prepare> method) when preparing the SQL statement that will fetch the objects.  If omitted, the default value is determined by the L<dbi_prepare_cached|/dbi_prepare_cached> class method.

=item B<query ARRAYREF>

The query parameters, passed as a reference to an array of name/value pairs.  These pairs are used to formulate the "where" clause of the SQL query that, in turn, is used to fetch the objects from the database.  Arbitrarily nested boolean logic is supported.

For the complete list of valid parameter names and values, see the documentation for the C<query> parameter of the L<build_select|Rose::DB::Object::QueryBuilder/build_select> function in the L<Rose::DB::Object::QueryBuilder> module.

This class also supports an extension to the query syntax supported by L<Rose::DB::Object::QueryBuilder>.  In addition to table names and aliases, column (or column method) names may be prefixed with foreign key or relationship names.  These names may be chained, with dots (".") separating the components.

For example, imagine three tables, C<products>, C<vendors>, and C<regions>, fronted by three L<Rose::DB::Object>-derived classes, C<Product>, C<Vendor>, and C<Region>, respectively.  Each C<Product> has a C<Vendor>, and each C<Vendor> has a C<Region>.

To select only products whose vendors are in the United States, use a query argument like this:

    query => [ 'vendor.region.name' => 'US' ],

This assumes that the C<Product> class has a relationship or foreign key named "vendor" that points to the product's C<Vendor>, and that the C<Vendor> class has a foreign key or relationship named "region" that points to the vendor's C<Region>, and that 'vendor.region' (or any foreign key or relationship name chain that begins with 'vendor.region.') is an argument to the C<with_objects> or C<require_objects> parameters.

Please note that the "L<tN|Rose::DB::Object::QueryBuilder/tables>" table aliases are not allowed in front of these kinds of chained relationship parameters.  (The chain of relationship names specifies the target table, so any "tN" alias would be redundant at best, or present a conflict at worst.)

=item B<require_objects ARRAYREF>

Only fetch rows from the primary table that have all of the associated sub-objects listed in ARRAYREF, a reference to an array of L<foreign key|Rose::DB::Object::Metadata/foreign_keys> or L<relationship|Rose::DB::Object::Metadata/relationships> names defined for C<object_class>.  The supported relationship types are "L<one to one|Rose::DB::Object::Metadata::Relationship::OneToOne>," "L<one to many|Rose::DB::Object::Metadata::Relationship::OneToMany>," and  "L<many to many|Rose::DB::Object::Metadata::Relationship::ManyToMany>".

For each foreign key or relationship name listed in ARRAYREF, another table will be added to the query via an implicit inner join.  The join conditions will be constructed automatically based on the foreign key or relationship definitions.  Note that each related table must have a L<Rose::DB::Object>-derived class fronting it.

Foreign key and relationship names may be chained, with dots (".") separating each name.  For example, imagine three tables, C<products>, C<vendors>, and C<regions>, fronted by three L<Rose::DB::Object>-derived classes, C<Product>, C<Vendor>, and C<Region>, respectively.  Each C<Product> has a C<Vendor>, and each C<Vendor> has a C<Region>.

To fetch C<Product>s along with their C<Vendor>s, and their vendors' C<Region>s, provide a C<with_objects> argument like this:

    require_objects => [ 'vendor.region' ],

This assumes that the C<Product> class has a relationship or foreign key named "vendor" that points to the product's C<Vendor>, and that the C<Vendor> class has a foreign key or relationship named "region" that points to the vendor's C<Region>.

This chaining syntax can be used to traverse relationships of any kind, including "one to many" and "many to many" relationships, to an arbitrary depth.

The following optional suffixes may be added after any name in the chain in order to override the join type used:

    Suffix    Join Type
    ------    ----------
    !         Inner join
    ?         Left outer join

Each link in a C<require_objects> chain uses an inner join by default.  In other words, the following C<require_objects> parameters are all equivalent:

    # These all mean the same thing
    require_objects => [ 'vendor.region'   ]
    require_objects => [ 'vendor!.region!' ]
    require_objects => [ 'vendor.region!'  ]
    require_objects => [ 'vendor!.region'  ]

Thus, it is only really useful to use the C<?> suffix in C<require_objects> parameters (though the C<!> suffixes don't do any harm).  Here's a useful example of a call with hybrid join chain:

    $products =
      Product::Manager->get_products(
        require_objects => [ 'vendor.region?' ]);

All product objects returned would have associated vendor objects, but those vendor objects may or may not have associated region objects.

Note that inner joins may be implicit and L<nested_joins|/nested_joins> may or may not be used.  When in doubt, use the L<debug|/debug> parameter to see the generated SQL.

B<Warning:> there may be a geometric explosion of redundant data returned by the database if you include more than one "... to many" relationship in ARRAYREF.  Sometimes this may still be more efficient than making additional queries to fetch these sub-objects, but that all depends on the actual data.  A warning will be emitted (via L<Carp::cluck|Carp/cluck>) if you include more than one "... to many" relationship in ARRAYREF.  If you're sure you know what you're doing, you can silence this warning by passing the C<multi_many_ok> parameter with a true value.

B<Note:> the C<require_objects> list currently cannot be used to simultaneously fetch two objects that both front the same database table, I<but are of different classes>.  One workaround is to make one class use a synonym or alias for one of the tables.  Another option is to make one table a trivial view of the other.  The objective is to get the table names to be different for each different class (even if it's just a matter of letter case, if your database is not case-sensitive when it comes to table names).

=item B<select [ CLAUSE | ARRAYREF ]>

Select only the columns specified in either a comma-separated string of column names or a reference to an array of column names.  Strings are naively split between each comma.  If you need more complex parsing, please use the array-reference argument format instead.

Column names should be prefixed by the appropriate "tN" table alias, the table name, or the foreign key or relationship name.  The prefix should be joined to the column name with a dot (".").  Examples: C<t2.name>, C<vendors.age>.

Unprefixed columns are assumed to belong to the primary table ("t1") and are explicitly prefixed as such when selecting from more than one table.  If a column name matches C</ AS \w+$/> then no prefix is applied.

If the column name is "*" (e.g., C<t1.*>) then all columns from that table are selected.

If an item in the referenced array is itself a reference to a scalar, then that item will be dereferenced and passed through unmodified.

If selecting sub-objects via the C<with_objects> or C<require_objects> parameters, you must select the primary key columns from each sub-object table.  Failure to do so will cause those sub-objects I<not> to be created.

Be warned that you should provide some way to determine which column or method and which class an item belongs to: a tN prefix, a column name, or at the very least an "... AS ..." alias clause.

If any C<with_objects> or C<require_objects> arguments are included in this call, the C<select> list must include at least the primary key column(s) from each table that contributes to the named relationships.

This parameter conflicts with the C<fetch_only> parameter.  A fatal error will occur if both are used in the same call.

If this parameter is omitted, then all columns from all participating tables are selected (optionally modified by the C<nonlazy> parameter).

=item B<share_db BOOL>

If true, C<db> will be passed to each L<Rose::DB::Object>-derived object when it is constructed.  Defaults to true.

=item B<sort_by [ CLAUSE | ARRAYREF ]>

A fully formed SQL "ORDER BY ..." clause, sans the words "ORDER BY", or a reference to an array of strings or scalar references to be de-referenced as needed, joined with a comma, and appended to the "ORDER BY" clause.

If an argument is a reference to a scalar, then it is passed through to the ORDER BY clause unmodified.

Otherwise, within each string, any instance of "NAME." will be replaced with the appropriate "tN." table alias, where NAME is a table, foreign key, or relationship name.  All unprefixed simple column names are assumed to belong to the primary table ("t1").

If selecting sub-objects (via C<require_objects> or C<with_objects>) that are related through "one to many" or "many to many" relationships, the first condition in the sort order clause must be a column in the primary table (t1).  If this condition is not met, the list of primary key columns will be added to the beginning of the sort order clause automatically.

=item B<table_aliases BOOL>

When only a single table is used in q auery, this parameter controls whether or not the "tN" aliases are used.  If the parameter is not passed, then tables are aliased.  If it is passed with a false value, then tables are not aliased.  When more than one table participates in a query, the "tN" table aliases are always used and this option is ignored.

=item B<unique_aliases BOOL>

If true, and if there is no explicit value for the C<select> parameter and more than one table is participating in the query, then each selected column will be given a unique alias by prefixing it with its table alias and an underscore.  The default value is false.  Example:

    SELECT
      t1.id    AS t1_id,
      t1.name  AS t1_name,
      t2.id    AS t2_id,
      t2.name  AS t2_name
    FROM
      foo AS t1,
      bar AS t2
    WHERE
      ...

These unique aliases provide a technique of last resort for unambiguously addressing a column in a query clause.

=item B<where ARRAYREF>

This is an alias for the C<query> parameter (see above).

=item B<with_map_records [ BOOL | METHOD | HASHREF ]>

When fetching related objects through a "L<many to many|Rose::DB::Object::Metadata::Relationship::ManyToMany>" relationship, objects of the L<map class|Rose::DB::Object::Metadata::Relationship::ManyToMany/map_class> are not retrieved by default.  Use this parameter to override the default behavior.

If the value is "1", then each object fetched through a mapping table will have its associated map record available through a C<map_record()> attribute.

If a method name is provided instead, then each object fetched through a mapping table will have its associated map record available through a method of that name.

If the value is a reference to a hash, then the keys of the hash should be "many to many" relationship names, and the values should be the method names through which the maps records will be available for each relationship.

=item B<with_objects ARRAYREF>

Also fetch sub-objects (if any) associated with rows in the primary table based on a reference to an array of L<foreign key|Rose::DB::Object::Metadata/foreign_keys> or L<relationship|Rose::DB::Object::Metadata/relationships> names defined for C<object_class>.  The supported relationship types are "L<one to one|Rose::DB::Object::Metadata::Relationship::OneToOne>," "L<one to many|Rose::DB::Object::Metadata::Relationship::OneToMany>," and  "L<many to many|Rose::DB::Object::Metadata::Relationship::ManyToMany>".

For each foreign key or relationship name listed in ARRAYREF, another table will be added to the query via an explicit LEFT OUTER JOIN.  (Foreign keys whose columns are all NOT NULL are the exception, however.  They are always fetched via inner joins.)   The join conditions will be constructed automatically based on the foreign key or relationship definitions.  Note that each related table must have a L<Rose::DB::Object>-derived class fronting it.  See the L<synopsis|/SYNOPSIS> for an example.

"Many to many" relationships are a special case.  They will add two tables to the query (the "map" table plus the table with the actual data), which will offset the "tN" table numbering by one extra table.

Foreign key and relationship names may be chained, with dots (".") separating each name.  For example, imagine three tables, C<products>, C<vendors>, and C<regions>, fronted by three L<Rose::DB::Object>-derived classes, C<Product>, C<Vendor>, and C<Region>, respectively.  Each C<Product> has a C<Vendor>, and each C<Vendor> has a C<Region>.

To fetch C<Product>s along with their C<Vendor>s, and their vendors' C<Region>s, provide a C<with_objects> argument like this:

    with_objects => [ 'vendor.region' ],

This assumes that the C<Product> class has a relationship or foreign key named "vendor" that points to the product's C<Vendor>, and that the C<Vendor> class has a foreign key or relationship named "region" that points to the vendor's C<Region>.

This chaining syntax can be used to traverse relationships of any kind, including "one to many" and "many to many" relationships, to an arbitrary depth.  

The following optional suffixes may be added after any name in the chain in order to override the join type used:

    Suffix    Join Type
    ------    ----------
    !         Inner join
    ?         Left outer join

Each link in a C<with_objects> chain uses a left outer join by default.  In other words, the following C<with_objects> parameters are all equivalent:

    # These all mean the same thing
    with_objects => [ 'vendor.region'   ]
    with_objects => [ 'vendor?.region?' ]
    with_objects => [ 'vendor.region?'  ]
    with_objects => [ 'vendor?.region'  ]

Thus, it is only really useful to use the C<!> suffix in C<with_objects> parameters (though the C<?> suffixes don't do any harm).  Here's a useful example of a call with hybrid join chain:

    $products =
      Product::Manager->get_products(
        with_objects => [ 'vendor!.region' ]);

All product objects returned would have associated vendor objects, but those vendor object may or may not have associated region objects.

Note that inner joins may be implicit and L<nested_joins|/nested_joins> may or may not be used.  When in doubt, use the L<debug|/debug> parameter to see the generated SQL.

B<Warning:> there may be a geometric explosion of redundant data returned by the database if you include more than one "... to many" relationship in ARRAYREF.  Sometimes this may still be more efficient than making additional queries to fetch these sub-objects, but that all depends on the actual data.  A warning will be emitted (via L<Carp::cluck|Carp/cluck>) if you include more than one "... to many" relationship in ARRAYREF.  If you're sure you know what you're doing, you can silence this warning by passing the C<multi_many_ok> parameter with a true value.

B<Note:> the C<with_objects> list currently cannot be used to simultaneously fetch two objects that both front the same database table, I<but are of different classes>.  One workaround is to make one class use a synonym or alias for one of the tables.  Another option is to make one table a trivial view of the other.  The objective is to get the table names to be different for each different class (even if it's just a matter of letter case, if your database is not case-sensitive when it comes to table names).

=back

=item B<get_objects_count [PARAMS]>

Accepts the same arguments as L<get_objects|/get_objects>, but just returns the number of objects that would have been fetched, or undef if there was an error.

=item B<get_objects_from_sql [ SQL | PARAMS ]>

Fetch objects using a custom SQL query.  Pass either a single SQL query string or name/value parameters as arguments.  Valid parameters are:

=over 4

=item B<args ARRAYREF>

A reference to an array of arguments to be passed to L<DBI>'s L<execute|DBI/execute> method when the query is run.  The number of items in this array must exactly match the number of placeholders in the SQL query.

=item B<db DB>

A L<Rose::DB>-derived object used to access the database.  If omitted, one will be created by calling the L<init_db|Rose::DB::Object/init_db> method of the C<object_class>.

=item B<object_class CLASS>

The class name of the L<Rose::DB::Object>-derived objects to be fetched.  Defaults to the value returned by the L<object_class|/object_class> class method.

=item B<prepare_cached BOOL>

If true, then L<DBI>'s L<prepare_cached|DBI/prepare_cached> method will be used (instead of the L<prepare|DBI/prepare> method) when preparing the SQL statement that will fetch the objects.  If omitted, the default value is determined by the L<dbi_prepare_cached|/dbi_prepare_cached> class method.

=item B<prepare_options HASHREF>

A reference to a hash of attributes to be passed to L<DBI>'s L<prepare|DBI/prepare> or L<prepare_cached|DBI/prepare_cached> method when preparing the SQL statement.

=item B<share_db BOOL>

If true, C<db> will be passed to each L<Rose::DB::Object>-derived object when it is constructed.  Defaults to true.

=item B<sql SQL>

The SQL query string.  This parameter is required.

=back

Each column returned by the SQL query must be either a column or method name in C<object_class>.  Column names take precedence in the case of a conflict.

Returns a reference to an array of C<object_class> objects.

Examples:

    package Product::Manager;    
    use Product;
    use base 'Rose::DB::Object::Manager';
    sub object_class { 'Product' }
    ...

    $products = Product::Manager->get_objects_from_sql(<<"EOF");
    SELECT * FROM products WHERE sku % 2 != 0 ORDER BY status, type
    EOF

    $products = 
      Product::Manager->get_objects_from_sql(
        args => [ '2005-01-01' ],
        sql  => 'SELECT * FROM products WHERE release_date > ?');

=item B<get_objects_iterator [PARAMS]>

Accepts any valid L<get_objects|/get_objects> arguments, but return a L<Rose::DB::Object::Iterator> object, or undef if there was an error.

=item B<get_objects_iterator_from_sql [PARAMS]>

Accepts any valid L<get_objects_from_sql|/get_objects_from_sql> arguments, but return a L<Rose::DB::Object::Iterator> object, or undef if there was an error.

=item B<get_objects_sql [PARAMS]>

Accepts the same arguments as L<get_objects|/get_objects>, but return the SQL query string that would have been used to fetch the objects (in scalar context), or the SQL query string and a reference to an array of bind values (in list context).

=item B<make_manager_methods PARAMS>

Create convenience wrappers for L<Rose::DB::Object::Manager>'s L<get_objects|/get_objects>, L<get_objects_iterator|/get_objects_iterator>, and L<get_objects_count|/get_objects_count> class methods in the target class.  These wrapper methods will not overwrite any existing methods in the target class.  If there is an existing method with the same name, a fatal error will occur.

PARAMS can take several forms, depending on the calling context.  For a call to L<make_manager_methods|/make_manager_methods> to succeed, the following information must be determined:

=over 4

=item * B<object class>

The class of the L<Rose::DB::Object>-derived objects to be fetched or counted.

=item * B<base name> or B<method name>

The base name is a string used as the basis of the method names.  For example, the base name "products" might be used to create methods named "get_B<products>", "get_B<products>_count", "get_B<products>_iterator", "delete_B<products>", and "update_B<products>".

In the absence of a base name, an explicit method name may be provided instead.  The method name will be used as is.

=item * B<method types>

The types of methods that should be generated.  Each method type is a wrapper for a L<Rose::DB::Object::Manager> class method.  The mapping of method type names to actual L<Rose::DB::Object::Manager> class methods defaults to the following:

    Type        Method
    --------    ----------------------
    objects     get_objects()
    iterator    get_objects_iterator()
    count       get_objects_count()
    delete      delete_objects()
    update      update_objects()

You may override the L<auto_manager_method_name|Rose::DB::Object::ConventionManager/auto_manager_method_name> method in the L<object_class|/object_class>'s L<convention manager|Rose::DB::Object::Metadata/convention_manager> class to customize one or more of these names.

=item * B<target class>

The class that the methods should be installed in.

=back

Here are all of the different ways that each of those pieces of information can be provided, either implicitly or explicitly as part of PARAMS.

=over 4

=item * B<object class>

If an C<object_class> parameter is passed in PARAMS, then its value is used as the object class.  Example:

    $class->make_manager_methods(object_class => 'Product', ...);

If the C<object_class> parameter is not passed, and if the B<target class> inherits from L<Rose::DB::Object::Manager> and has also defined an C<object_class> method, then the return value of that method is used as the object class.  Example:

  package Product::Manager;

  use Rose::DB::Object::Manager;
  our @ISA = qw(Rose::DB::Object::Manager);

  sub object_class { 'Product' }

  # Assume object_class parameter is not part of the ... below
  __PACKAGE__->make_manager_methods(...);

In this case, the object class would be C<Product>.

Finally, if none of the above conditions are met, one final option is considered.  If the B<target class> inherits from L<Rose::DB::Object>, then the object class is set to the B<target class>.

If the object class cannot be determined in one of the ways described above, then a fatal error will occur.

=item * B<base name> or B<method name>

If a C<base_name> parameter is passed in PARAMS, then its value is used as the base name for the generated methods.  Example:

    $class->make_manager_methods(base_name => 'products', ...);

If the C<base_name> parameter is not passed, and if there is only one argument passed to the method, then the lone argument is used as the base name.  Example:

    $class->make_manager_methods('products');

(Note that, since the B<object class> must be derived somehow, this will only work in one of the situations (described above) where the B<object class> can be derived from the calling context or class.)

If a C<methods> parameter is passed with a hash ref value, then each key of the hash is used as the base name for the method types listed in the corresponding value.  (See B<method types> below for more information.)

If a key of the C<methods> hash ends in "()", then it is taken as the method name and is used as is.  For example, the key "foo" will be used as a base name, but the key "foo()" will be used as a method name.

If the base name cannot be determined in one of the ways described above, then the L<auto_manager_base_name|Rose::DB::Object::ConventionManager/auto_manager_base_name> method in the L<object_class|/object_class>'s L<convention manager|Rose::DB::Object::Metadata/convention_manager> is called on to supply a base name.

=item * B<method types>

If an explicit list of method types is not passed to the method, then all of the L<default_manager_method_types|/default_manager_method_types> are created.  Example:

    # Base name is determined by convention manager auto_manager_base_name()
    # method, all default method types created
    $class->make_manager_methods();

    # Base name is "products", all default method types created
    $class->make_manager_methods('products');

    # Base name is "products", all default method types created
    $class->make_manager_methods(base_name => products', ...);

(Again, note that the B<object class> must be derived somehow.)

If a C<methods> parameter is passed, then its value must be a reference to a hash whose keys are base names or method names, and whose values are method types or references to arrays of method types.

If a key ends in "()", then it is taken as a method name and is used as is.  Otherwise, it is used as a base name.  For example, the key "foo" will be used as a base name, but the key "foo()" will be used as a method name.

If a key is a method name and its value specifies more than one method type, then a fatal error will occur.  (It's impossible to have more than one method with the same name.)

Example:

    # Make the following methods:
    #
    # * Base name: products; method types: objects, iterators
    #
    #     get_products()
    #     get_products_iterator()
    #
    # * Method name: product_count; method type: count
    #
    #     product_count()
    #
    $class->make_manager_methods(...,
      methods =>
      {
        'products'        => [ qw(objects iterator) ],
        'product_count()' => 'count'
      });

If the value of the C<methods> parameter is not a reference to a hash, or if both the C<methods> and C<base_name> parameters are passed, then a fatal error will occur.

=item * B<target class>

If a C<target_class> parameter is passed in PARAMS, then its value is used as the target class.  Example:

    $class->make_manager_methods(target_class => 'Product', ...);

If a C<target_class> parameter is not passed, and if the calling class is not L<Rose::DB::Object::Manager>, then the calling class is used as the target class.  Otherwise, the class from which the method was called is used as the target class.  Examples:

    # Target class is Product, regardless of the calling
    # context or the value of $class
    $class->make_manager_methods(target_class => 'Product', ...);

    package Foo;

    # Target class is Foo: no target_class parameter is passed
    # and the calling class is Rose::DB::Object::Manager, so 
    # the class from which the method was called (Foo) is used.
    Rose::DB::Object::Manager->make_manager_methods(
      object_class => 'Bar',
      base_name    => 'Baz');

    package Bar;

    # Target class is Foo: no target_class parameter is passed 
    # and the calling class is not Rose::DB::Object::Manager,
    # so the calling class (Foo) is used.
    Foo->make_manager_methods(object_class => 'Bar',
                              base_name    => 'Baz');

=back

There's a lot of flexibility in this method's arguments (although some might use the word "confusion" instead), but the examples can be pared down to a few common usage scenarios.

The first is the recommended technique, as seen in the L<synopsis|/SYNOPSIS>. Create a separate manager class that inherits from L<Rose::DB::Object::Manager>, override the C<object_class> method to specify the class of the objects being fetched, and then pass a lone base name argument to the call to L<make_manager_methods|/make_manager_methods>.

  package Product::Manager;

  use Rose::DB::Object::Manager;
  our @ISA = qw(Rose::DB::Object::Manager);

  sub object_class { 'Product' }

  __PACKAGE__->make_manager_methods('products');

The second example is used to install object manager methods directly into a L<Rose::DB::Object>-derived class.  I do not recommend this practice; I consider it "semantically impure" for the class that represents a single object to also be the class that's used to fetch multiple objects.  Inevitably, classes grow, and I'd like the "object manager" class to be separate from the object class itself so they can grow happily in isolation, with no potential clashes.

Also, keep in mind that L<Rose::DB::Object> and L<Rose::DB::Object::Manager> have separate L<error_mode|/error_mode> settings which must be synchronized or otherwise dealt with.  Another advantage of using a separate L<Rose::DB::Object::Manager> subclass (as described earlier) is that you can override the L<error_mode|Rose::DB::Object::Manager/error_mode> in your L<Rose::DB::Object::Manager> subclass only, rather than overriding the base class L<Rose::DB::Object::Manager error_mode|Rose::DB::Object::Manager/error_mode>, which may affect other classes.

If none of that dissuades you, here's how to do it:

  package Product;

  use Rose::DB::Object:;
  our @ISA = qw(Rose::DB::Object);

  __PACKAGE__->make_manager_methods('products');

Finally, sometimes you don't want or need to use L<make_manager_methods|/make_manager_methods> at all.  In fact, this method did not exist in earlier versions of this module.  The formerly recommended way to use this class is  still perfectly valid: subclass it and then call through to the base class methods.

  package Product::Manager;

  use Rose::DB::Object::Manager;
  our @ISA = qw(Rose::DB::Object::Manager);

  sub get_products
  {
    shift->get_objects(object_class => 'Product', @_);
  }

  sub get_products_iterator
  {
    shift->get_objects_iterator(object_class => 'Product', @_);
  }

  sub get_products_count
  {
    shift->get_objects_count(object_class => 'Product', @_);
  }

  sub delete_products
  {
    shift->delete_objects(object_class => 'Product', @_);
  }

  sub update_products
  {
    shift->update_objects(object_class => 'Product', @_);
  }

Of course, these methods will all look very similar in each L<Rose::DB::Object::Manager>-derived class.  Creating these identically structured methods is exactly what L<make_manager_methods|/make_manager_methods> automates for you.  

But sometimes you want to customize these methods, in which case the "longhand" technique above becomes essential.  For example, imagine that we want to extend the code in the L<synopsis|/SYNOPSIS>, adding support for a C<with_categories> parameter to the C<get_products()> method.  

  Product::Manager->get_products(date_created    => '10/21/2001', 
                                 with_categories => 1);

  ...

  sub get_products
  {
    my($class, %args) @_;

    if(delete $args{'with_categories'}) # boolean flag
    {
      push(@{$args{'with_objects'}}, 'category');
    }

    Rose::DB::Object::Manager->get_objects(
      %args, object_class => 'Product')
  }

Here we've coerced the caller-friendly C<with_categories> boolean flag parameter into the C<with_objects =E<gt> [ 'category' ]> pair that L<Rose::DB::Object::Manager>'s L<get_objects|/get_objects> method can understand.

This is the typical evolution of an object manager method.  It starts out as being auto-generated by L<make_manager_methods|/make_manager_methods>, then becomes customized as new arguments are added.

=item B<make_manager_method_from_sql [ NAME =E<gt> SQL | PARAMS ]>

Create a class method in the calling class that will fetch objects using a custom SQL query.  The method created will return a reference to an array of objects or a L<Rose::DB::Object::Iterator> object, depending on whether the C<iterator> parameter is set (see below).

Pass either a method name and an SQL query string or name/value parameters as arguments.  Valid parameters are:

=over 4

=item B<iterator BOOL>

If true, the method created will return a L<Rose::DB::Object::Iterator> object.

=item B<object_class CLASS>

The class name of the L<Rose::DB::Object>-derived objects to be fetched.  Defaults to the value returned by the L<object_class|/object_class> class method.

=item B<params ARRAYREF>

To allow the method that will be created to accept named parameters (name/value pairs) instead of positional parameters, provide a reference to an array of parameter names in the order that they should be passed to the call to L<DBI>'s L<execute|DBI/execute> method.

=item B<method NAME>

The name of the method to be created.  This parameter is required.

=item B<prepare_cached BOOL>

If true, then L<DBI>'s L<prepare_cached|DBI/prepare_cached> method will be used (instead of the L<prepare|DBI/prepare> method) when preparing the SQL statement that will fetch the objects.  If omitted, the default value is determined by the L<dbi_prepare_cached|/dbi_prepare_cached> class method.

=item B<share_db BOOL>

If true, C<db> will be passed to each L<Rose::DB::Object>-derived object when it is constructed.  Defaults to true.

=item B<sql SQL>

The SQL query string.  This parameter is required.

=back

Each column returned by the SQL query must be either a column or method name in C<object_class>.  Column names take precedence in the case of a conflict.

Arguments passed to the created method will be passed to L<DBI>'s L<execute|DBI/execute> method when the query is run.  The number of arguments must exactly match the number of placeholders in the SQL query.  Positional parameters are required unless the C<params> parameter is used.  (See description above.)

Returns a code reference to the method created.

Examples:

    package Product::Manager;

    use base 'Rose::DB::Object::Manager';
    ...

    # Make method that takes no arguments
    __PACKAGE__->make_manager_method_from_sql(get_odd_products =><<"EOF");
    SELECT * FROM products WHERE sku % 2 != 0 
    EOF

    # Make method that takes one positional parameter
    __PACKAGE__->make_manager_method_from_sql(get_new_products =><<"EOF");
    SELECT * FROM products WHERE release_date > ?
    EOF

    # Make method that takes named parameters
    __PACKAGE__->make_manager_method_from_sql(
      method => 'get_named_products',
      params => [ qw(type name) ],
      sql    => <<"EOF");
    SELECT * FROM products WHERE type = ? AND name LIKE ?
    EOF

    ...

    $products = Product::Manager->get_odd_products();

    $products = Product::Manager->get_new_products('2005-01-01');

    $products = 
      Product::Manager->get_named_products(
        name => 'Kite%', 
        type => 'toy');

    # Make method that takes named parameters and returns an iterator
    __PACKAGE__->make_manager_method_from_sql(
      method   => 'get_named_products_iterator',
      iterator => 1,
      params   => [ qw(type name) ],
      sql      => <<"EOF");
    SELECT * FROM products WHERE type = ? AND name LIKE ?
    EOF

    $iterator = 
      Product::Manager->get_named_products_iterator(
        name => 'Kite%', 
        type => 'toy');

    while(my $product = $iterator->next)
    {
      ... # do something with $product

      $iterator->finish  if(...); # finish early?
    }

=item B<normalize_get_objects_args [ARGS]>

This method takes ARGS in the forms accepted by L<get_objects|/get_objects> (and other similar methods) and normalizes them into name/value pairs.  Since L<get_objects|/get_objects> can take arguments in many forms, this method is useful when overriding L<get_objects|/get_objects> in a custom L<Rose::DB::Object::Manager> subclass.  Example:


    package Product::Manager;

    use base 'Rose::DB::Object::Manager'; 

    use Product;

    sub object_class { 'Product' }
    ...

    sub get_products
    {
      my($class, %args) = shift->normalize_get_objects_args(@_);

      # Detect, extract, and handle custom argument
      if(delete $args{'active_only'})
      {
        push(@{$args{'query'}}, status => 'active');
      }

      return $class->get_objects(%args); # call through to normal method
    }

Now all of the following calls will work:

    $products =
      Product::Manager->get_products([ type => 'boat' ], sort_by => 'name');

    $products =
      Product::Manager->get_products({ name => { like => '%Dog%' } });

    $products =
      Product::Manager->get_products([ id => { gt => 123 } ], active_only => 1);

=item B<object_class>

Returns the class name of the L<Rose::DB::Object>-derived objects to be managed by this class.  Override this method in your subclass.  The default implementation returns undef.

=item B<perl_class_definition>

Attempts to create the Perl source code that is equivalent to the current class.  This works best for classes created via L<Rose::DB::Object::Metadata>'s L<make_manager_class|Rose::DB::Object::Metadata/make_manager_class> method, but it will also work most of the time for classes whose methods were created using L<make_manager_methods|/make_manager_methods>.

The Perl code is returned as a string.  Here's an example:

  package My::Product::Manager;

  use My::Product;

  use Rose::DB::Object::Manager;
  our @ISA = qw(Rose::DB::Object::Manager);

  sub object_class { 'My::Product' }

  __PACKAGE__->make_manager_methods('products');

  1;

=item B<update_objects [PARAMS]>

Update rows in a table fronted by a L<Rose::DB::Object>-derived class based on PARAMS, where PARAMS are name/value pairs.  Returns the number of rows updated, or undef if there was an error.

Valid parameters are:

=over 4

=item B<all BOOL>

If set to a true value, this parameter indicates an explicit request to update all rows in the table.  If both the C<all> and the C<where> parameters are passed, a fatal error will occur.

=item B<db DB>

A L<Rose::DB>-derived object used to access the database.  If omitted, one will be created by calling the L<init_db|Rose::DB::Object/init_db> method of the C<object_class>.

=item B<object_class CLASS>

The class name of the L<Rose::DB::Object>-derived class that fronts the table whose rows will to be updated.  This parameter is required; a fatal error will occur if it is omitted.  Defaults to the value returned by the L<object_class|/object_class> class method.

=item B<set PARAMS>

The names and values of the columns to be updated.  PARAMS should be a reference to a hash.  Each key of the hash should be a column name or column get/set method name.  If a value is a simple scalar, then it is passed through the get/set method that services the column before being incorporated into the SQL query.

If a value is a reference to a scalar, then it is dereferenced and incorporated into the SQL query as-is.

If a value is a reference to a hash, then it must contain a single key named "sql" and a corresponding value that will be incorporated into the SQL query as-is.

Example:

  $num_rows_updated =
    Product::Manager->update_products(
      set =>
      {
        end_date   => DateTime->now,
        region_num => { sql => 'region_num * -1' }
        count      => \q(count + 1),
        status     => 'defunct',
      },
      where =>
      [
        status  => [ 'stale', 'old' ],
        name    => { like => 'Wax%' }
        or =>
        [
          start_date => { gt => '2008-12-30' },
          end_date   => { gt => 'now' },
        ],
      ]);

The call above would execute an SQL statement something like the one shown below (depending on the database vendor, and assuming the current date was September 20th, 2005):

    UPDATE products SET
      end_date   = '2005-09-20',
      region_num = region_num * -1,
      count      = count + 1, 
      status     = 'defunct'
    WHERE
      status IN ('stale', 'old') AND
      name LIKE 'Wax%' AND
      (
        start_date > '2008-12-30' OR
        end_date   > '2005-09-20'
      )

=item B<where PARAMS>

The query parameters, passed as a reference to an array of name/value pairs.  These PARAMS are used to formulate the "where" clause of the SQL query that is used to update the rows in the table.  Arbitrarily nested boolean logic is supported.

For the complete list of valid parameter names and values, see the documentation for the C<query> parameter of the L<build_select|Rose::DB::Object::QueryBuilder/build_select> function in the L<Rose::DB::Object::QueryBuilder> module.

If this parameter is omitted, this method will refuse to update all rows in the table and a fatal error will occur.  To update all rows in a table, you must pass the C<all> parameter with a true value.  If both the C<all> and the C<where> parameters are passed, a fatal error will occur.

=back

=item B<strict_ops [BOOL]>

Get or set a boolean value that indicates whether using a comparison operator in the C<query> that is not listed in the L<Rose::DB::Object::QueryBuilder> documentation will cause a fatal error.  The default value is false.

=back

=head1 SUPPORT

For an informal overview of L<Rose::DB::Object>, including L<Rose::DB::Object::Manager>, consult the L<Rose::DB::Object::Tutorial>.

    perldoc Rose::DB::Object::Tutorial

Any L<Rose::DB::Object::Manager> questions or problems can be posted to the L<Rose::DB::Object> mailing list.  To subscribe to the list or view the archives, go here:

L<http://groups.google.com/group/rose-db-object>

Although the mailing list is the preferred support mechanism, you can also email the author (see below) or file bugs using the CPAN bug tracking system:

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-DB-Object>

There's also a wiki and other resources linked from the Rose project home page:

L<http://rosecode.org>

=head1 AUTHOR

John C. Siracusa (siracusa@gmail.com)

=head1 LICENSE

Copyright (c) 2010 by John C. Siracusa.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
