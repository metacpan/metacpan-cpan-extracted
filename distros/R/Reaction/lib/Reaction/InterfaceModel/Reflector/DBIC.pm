package Reaction::InterfaceModel::Reflector::DBIC;

use aliased 'Reaction::InterfaceModel::Action::DBIC::ResultSet::Create';
use aliased 'Reaction::InterfaceModel::Action::DBIC::ResultSet::DeleteAll';
use aliased 'Reaction::InterfaceModel::Action::DBIC::Result::Update';
use aliased 'Reaction::InterfaceModel::Action::DBIC::Result::Delete';

use aliased 'Reaction::InterfaceModel::Collection::Virtual::ResultSet';
use aliased 'Reaction::InterfaceModel::Object';
use aliased 'Reaction::InterfaceModel::Action';
use Reaction::Class;
use Class::MOP;

use Catalyst::Utils;

use namespace::clean -except => [ qw(meta) ];

has make_classes_immutable => (isa => "Bool", is => "rw", required => 1, default => sub{ 1 });

#user defined actions and prototypes
has object_actions     => (isa => "HashRef", is => "rw", lazy_build => 1);
has collection_actions => (isa => "HashRef", is => "rw", lazy_build => 1);

#which actions to create by default
has default_object_actions     => (isa => "ArrayRef", is => "rw", lazy_build => 1);
has default_collection_actions => (isa => "ArrayRef", is => "rw", lazy_build => 1);

#builtin actions and prototypes
has builtin_object_actions     => (isa => "HashRef", is => "rw", lazy_build => 1);
has builtin_collection_actions => (isa => "HashRef", is => "rw", lazy_build => 1);
sub _build_object_actions { {} };
sub _build_collection_actions { {} };
sub _build_default_object_actions { [ qw/Update Delete/ ] };
sub _build_default_collection_actions { [ qw/Create DeleteAll/ ] };
sub _build_builtin_object_actions {
  {
    Update => { name => 'Update', base => Update },
    Delete => { name => 'Delete', base => Delete, attributes => [] },
  };
};
sub _build_builtin_collection_actions {
  {
    Create    => {name => 'Create',    base => Create    },
    DeleteAll => {name => 'DeleteAll', base => DeleteAll, attributes => [] }
  };
};
sub _all_object_actions {
 my $self = shift;
  return $self->merge_hashes
    ($self->builtin_object_actions, $self->object_actions);
};
sub _all_collection_actions {
  my $self = shift;
  return $self->merge_hashes
    ($self->builtin_collection_actions, $self->collection_actions);
};
sub dm_name_from_class_name {
  my($self, $class) = @_;
  confess("wrong arguments") unless $class;
  $class =~ s/::/_/g;
  $class = "_" . $self->_class_to_attribute_name($class) . "_store";
  return $class;
};
sub dm_name_from_source_name {
  my($self, $source) = @_;
  confess("wrong arguments") unless $source;
  $source =~ s/([a-z0-9])([A-Z])/${1}_${2}/g ;
  $source = "_" . $self->_class_to_attribute_name($source) . "_store";
  return $source;
};
sub class_name_from_source_name {
  my ($self, $model_class, $source_name) = @_;
  confess("wrong arguments") unless $model_class && $source_name;
  return join "::", $model_class, $source_name;
};
sub class_name_for_collection_of {
  my ($self, $object_class) = @_;
  confess("wrong arguments") unless $object_class;
  return "${object_class}::Collection";
};
sub merge_hashes {
  my($self, $left, $right) = @_;
  return Catalyst::Utils::merge_hashes($left, $right);
};
sub parse_reflect_rules {
  my ($self, $rules, $haystack) = @_;
  confess('$rules must be an array reference')    unless ref $rules    eq 'ARRAY';
  confess('$haystack must be an array reference') unless ref $haystack eq 'ARRAY';

  my $needles = {};
  my (@exclude, @include, $global_opts);
  if(@$rules == 2 && $rules->[0] eq '-exclude'){
    push(@exclude, (ref $rules->[1] eq 'ARRAY' ? @{$rules->[1]} : $rules->[1]));
  } else {
    for my $rule ( @$rules ){
      if (ref $rule eq 'ARRAY' && $rule->[0] eq '-exclude'){
        push(@exclude, (ref $rule->[1] eq 'ARRAY' ? @{$rule->[1]} : $rule->[1]));
      } elsif( ref $rule eq 'HASH' ){
        $global_opts = ref $global_opts eq 'HASH' ?
          $self->merge_hashes($global_opts, $rule) : $rule;
      } else {
        push(@include, $rule);
      }
    }
  }
  my $check_exclude = sub{
    for my $rule (@exclude){
      return 1 if(ref $rule eq 'Regexp' ? $_[0] =~ /$rule/ : $_[0] eq $rule);
    }
    return;
  };

  @$haystack = grep { !$check_exclude->($_) } @$haystack;
  $self->merge_reflect_rules(\@include, $needles, $haystack, $global_opts);
  return $needles;
};
sub merge_reflect_rules {
  my ($self, $rules, $needles, $haystack, $local_opts) = @_;
  for my $rule ( @$rules ){
    if(!ref $rule && ( grep {$rule eq $_} @$haystack ) ){
      $needles->{$rule} = defined $needles->{$rule} ?
        $self->merge_hashes($needles->{$rule}, $local_opts) : $local_opts;
    } elsif( ref $rule eq 'Regexp' ){
      for my $match ( grep { /$rule/ } @$haystack ){
        $needles->{$match} = defined $needles->{$match} ?
          $self->merge_hashes($needles->{$match}, $local_opts) : $local_opts;
      }
    } elsif( ref $rule eq 'ARRAY' ){
      my $opts;
      $opts = pop(@$rule) if @$rule > 1 and ref $rule->[$#$rule] eq 'HASH';
      $opts = $self->merge_hashes($local_opts, $opts) if defined $local_opts;
      $self->merge_reflect_rules($rule, $needles, $haystack, $opts);
    }
  }
};
sub reflect_schema {
  my ($self, %opts) = @_;
  my $base    = delete $opts{base} || Object;
  my $roles   = delete $opts{roles} || [];
  my $model   = delete $opts{model_class};
  my $schema  = delete $opts{schema_class};
  my $dm_name = delete $opts{domain_model_name};
  my $dm_args = delete $opts{domain_model_args} || {};
  $dm_name ||= $self->dm_name_from_class_name($schema);

  #load all necessary classes
  confess("model_class and schema_class are required parameters")
    unless($model && $schema);
  Class::MOP::load_class( $base );
  Class::MOP::load_class( $schema );
  my $meta = $self->_load_or_create(
    $model,
    superclasses => [$base],
    ( @$roles ? (roles => $roles) : ()),
  );

  # sources => undef,              #default to qr/./
  # sources => [],                 #default to nothing
  # sources => qr//,               #DWIM, treated as [qr//]
  # sources => [{...}]             #DWIM, treat as [qr/./, {...} ]
  # sources => [[-exclude => ...]] #DWIM, treat as [qr/./, [-exclude => ...]]
  my $haystack = [ $schema->sources ];

  my $rules = delete $opts{sources};
  if(!defined $rules){
    $rules = [qr/./];
  } elsif( ref $rules eq 'Regexp'){
    $rules = [ $rules ];
  } elsif( ref $rules eq 'ARRAY' && @$rules){
    #don't add a qr/./ rule if we have at least one match rule
    push(@$rules, qr/./) unless grep {(ref $_ eq 'ARRAY' && $_->[0] ne '-exclude')
                                        || !ref $_  || ref $_ eq 'Regexp'} @$rules;
  }

  my $sources = $self->parse_reflect_rules($rules, $haystack);

  my $make_immutable = $meta->is_immutable || $self->make_classes_immutable;
  $meta->make_mutable if $meta->is_immutable;

  $meta->add_domain_model
    ($dm_name, is => 'rw', isa => $schema, required => 1, %$dm_args);

  for my $source_name (keys %$sources){
    my $source_opts = $sources->{$source_name} || {};
    $self->reflect_source(
                          source_name  => $source_name,
                          parent_class => $model,
                          schema_class => $schema,
                          source_class => $schema->class($source_name),
                          parent_domain_model_name => $dm_name,
                          %$source_opts
                         );
  }

  $meta->make_immutable if $make_immutable;
  return $meta;
};
sub _compute_source_options {
  my ($self, %opts) = @_;
  my $schema       = delete $opts{schema_class};
  my $source_name  = delete $opts{source_name};
  my $source_class = delete $opts{source_class};
  my $parent       = delete $opts{parent_class};
  my $parent_dm    = delete $opts{parent_domain_model_name};

  #this is the part where I hate my life for promissing all sorts of DWIMery
  confess("parent_class and source_name or source_class are required parameters")
    unless($parent && ($source_name || $source_class));

OUTER: until( $schema && $source_name && $source_class && $parent_dm ){
    if( $schema && !$source_name){
      next OUTER if $source_name = $schema->source($source_class)->source_name;
    } elsif( $schema && !$source_class){
      next OUTER if $source_class = eval { $schema->class($source_name) };
    }

    my @haystack = $parent_dm ? $parent->meta->find_attribute_by_name($parent_dm) : ();

    #there's a lot of guessing going on, but it should work fine on most cases
  INNER: for my $needle (@haystack){
      my $isa = $needle->_isa_metadata;
      next INNER unless Class::MOP::load_class( $isa->_isa_metadata );
      next INNER unless $isa->isa('DBIx::Class::Schema');

      if( $source_name ){
        my $src_class = eval{ $isa->class($source_name) };
        next INNER unless $src_class;
        next INNER if($source_class && $source_class ne $src_class);
        $schema = $isa;
        $parent_dm = $needle->name;
        $source_class = $src_class;
        next OUTER;
      }
    }


    confess("Could not determine options automatically from: schema " .
            "'${schema}', source_name '${source_name}', source_class " .
            "'${source_class}', parent_domain_model_name '${parent_dm}'");
  }

  return {
          source_name  => $source_name,
          schema_class => $schema,
          source_class => $source_class,
          parent_class => $parent,
          parent_domain_model_name => $parent_dm,
         };
};
sub _class_to_attribute_name {
  my ( $self, $str ) = @_;
  confess("wrong arguments passed for _class_to_attribute_name") unless $str;
  return join('_', map lc, split(/::|(?<=[a-z0-9])(?=[A-Z])/, $str))
};
sub add_source {
  my ($self, %opts) = @_;

  my $model      = delete $opts{model_class};
  my $reader     = delete $opts{reader};
  my $source     = delete $opts{source_name};
  my $dm_name    = delete $opts{domain_model_name};
  my $collection = delete $opts{collection_class};
  my $name       = delete $opts{attribute_name} || $source;

  confess("model_class and source_name are required parameters")
    unless $model && $source;
  my $meta = $model->meta;

  unless( $collection ){
    my $object = $self->class_name_from_source_name($model, $source);
    $collection = $self->class_name_for_collection_of($object);
  }
  unless( $reader ){
    $reader = $source;
    $reader =~ s/([a-z0-9])([A-Z])/${1}_${2}/g ;
    $reader = $self->_class_to_attribute_name($reader) . "_collection";
  }
  unless( $dm_name ){
    my @haystack = $meta->domain_models;
    if( @haystack > 1 ){
      @haystack = grep { $_->_isa_metadata->isa('DBIx::Class::Schema') } @haystack;
    }
    if(@haystack == 1){
      $dm_name = $haystack[0]->name;
    } elsif(@haystack > 1){
      confess("Failed to automatically determine domain_model_name. More than one " .
              "possible match (".(join ", ", map{"'".$_->name."'"} @haystack).")");
    } else {
      confess("Failed to automatically determine domain_model_name. No matches.");
    }
  }

  my %attr_opts =
    (
     lazy           => 1,
     required       => 1,
     isa            => $collection,
     reader         => $reader,
     predicate      => "has_" . $self->_class_to_attribute_name($name) ,
     domain_model   => $dm_name,
     orig_attr_name => $source,
     default        => sub {
       $collection->new
         (
          _source_resultset => $_[0]->$dm_name->resultset($source),
          _parent           => $_[0],
         );
     },
    );

  my $make_immutable = $meta->is_immutable;
  $meta->make_mutable   if $make_immutable;
  my $attr = $meta->add_attribute($name, %attr_opts);
  $meta->make_immutable if $make_immutable;

  return $attr;
};
sub reflect_source {
  my ($self, %opts) = @_;
  my $collection  = delete $opts{collection} || {};
  %opts = %{ $self->merge_hashes(\%opts, $self->_compute_source_options(%opts)) };

  my $obj_meta = $self->reflect_source_object(%opts);
  my $col_meta = $self->reflect_source_collection
    (
     object_class => $obj_meta->name,
     source_class => $opts{source_class},
     schema => $opts{schema_class},
     %$collection
    );

  $self->add_source(
                    %opts,
                    model_class       => delete $opts{parent_class},
                    domain_model_name => delete $opts{parent_domain_model_name},
                    collection_class  => $col_meta->name,
                   );
};
sub reflect_source_collection {
  my ($self, %opts) = @_;
  my $base    = delete $opts{base} || ResultSet;
  my $roles   = delete $opts{roles} || [];
  my $class   = delete $opts{class};
  my $object  = delete $opts{object_class};
  my $source  = delete $opts{source_class};
  my $action_rules = delete $opts{actions};
  my $schema = delete $opts{schema};

  confess('object_class and source_class are required parameters')
    unless $object && $source;
  $class ||= $self->class_name_for_collection_of($object);

  Class::MOP::load_class( $base );
  Class::MOP::load_class( $object );

  my $meta = $self->_load_or_create(
    $class,
    superclasses => [$base],
    ( @$roles ? (roles => $roles) : ()),
  );

  my $make_immutable = $meta->is_immutable || $self->make_classes_immutable;;
  $meta->make_mutable if $meta->is_immutable;
  $meta->add_method(_build_member_type => sub{ $object } );
  #XXX as a default pass the domain model as a target_model until i come up with something
  #better through the coercion method
  my $def_act_args = sub {
    my $super = shift;
    return { (target_model => $_[0]->_source_resultset), %{ $super->(@_) } };
  };
  $meta->add_around_method_modifier('_default_action_args_for', $def_act_args);


  {
    my $all_actions = $self->_all_collection_actions;
    my $action_haystack = [keys %$all_actions];
    if(!defined $action_rules){
      $action_rules = $self->default_collection_actions;
    } elsif( (!ref $action_rules && $action_rules) || (ref $action_rules eq 'Regexp') ){
      $action_rules = [ $action_rules ];
    } elsif( ref $action_rules eq 'ARRAY' && @$action_rules){
      #don't add a qr/./ rule if we have at least one match rule
      push(@$action_rules, qr/./)
        unless grep {(ref $_ eq 'ARRAY' && $_->[0] ne '-exclude')
                       || !ref $_  || ref $_ eq 'Regexp'} @$action_rules;
    }

    # XXX this is kind of a dirty hack to support custom actions that are not
    # previously defined and still be able to use the parse_reflect_rules mechanism
    my @custom_actions = grep {!exists $all_actions->{$_}}
      map{ $_->[0] } grep {ref $_ eq 'ARRAY' && $_->[0] ne '-exclude'} @$action_rules;
    push(@$action_haystack, @custom_actions);
    my $actions = $self->parse_reflect_rules($action_rules, $action_haystack);
    for my $action (keys %$actions){
      my $action_opts = $self->merge_hashes
        ($all_actions->{$action} || {}, $actions->{$action} || {});

      #NOTE: If the name of the action is not specified in the prototype then use it's
      #hash key as the name. I think this is sane beahvior, but I've actually been thinking
      #of making Action prototypes their own separate objects
      $self->reflect_source_action(
                                   schema => $schema,
                                   name         => $action,
                                   object_class => $object,
                                   source_class => $source,
                                   %$action_opts,
                                  );

      # XXX i will move this to use the coercion method soon. this will be
      #  GoodEnough until then. I still need to think a little about the type coercion
      #  thing so i don't make a mess of it
      my $act_args = sub {   #override target model for this action
        my $super = shift;
        return { %{ $super->(@_) },
                 ($_[1] eq $action ? (target_model => $_[0]->_source_resultset) : () ) };
      };
      $meta->add_around_method_modifier('_default_action_args_for', $act_args);
    }
  }
  $meta->make_immutable if $make_immutable;
  return $meta;
};
sub reflect_source_object {
  my($self, %opts) = @_;
  %opts = %{ $self->merge_hashes(\%opts, $self->_compute_source_options(%opts)) };

  my $base = delete $opts{base} || Object;
  my $roles = delete $opts{roles} || [];
  my $class = delete $opts{class};
  my $dm_name = delete $opts{domain_model_name};
  my $dm_opts = delete $opts{domain_model_args} || {};

  my $source_name  = delete $opts{source_name};
  my $schema       = delete $opts{schema_class};
  my $source_class = delete $opts{source_class};
  my $parent       = delete $opts{parent_class};
  my $parent_dm    = delete $opts{parent_domain_model_name};

  my $action_rules = delete $opts{actions};
  my $attr_rules   = delete $opts{attributes};

  $class ||= $self->class_name_from_source_name($parent, $source_name);

  Class::MOP::load_class($parent);
  Class::MOP::load_class($schema) if $schema;
  Class::MOP::load_class($source_class);

  my $meta = $self->_load_or_create(
    $class,
    superclasses => [$base],
    ( @$roles ? (roles => $roles) : ()),
  );

  #create the domain model
  $dm_name ||= $self->dm_name_from_source_name($source_name);

  $dm_opts->{isa}        = $source_class;
  $dm_opts->{is}       ||= 'rw';
  $dm_opts->{required} ||= 1;

  my $make_immutable = $meta->is_immutable || $self->make_classes_immutable;;
  $meta->make_mutable if $meta->is_immutable;

  my $dm_attr   = $meta->add_domain_model($dm_name, %$dm_opts);
  my $dm_reader = $dm_attr->get_read_method;

  unless( $class->can('inflate_result') ){
    my $inflate_method = sub {
      my $class = shift; my ($src) = @_;
      $src = $src->resolve if $src->isa('DBIx::Class::ResultSourceHandle');
      $class->new($dm_name, $src->result_class->inflate_result(@_));
    };
    $meta->add_method('inflate_result', $inflate_method);
  }

  #XXX this is here to allow action prototypes to work with ListView
  # maybe Collections hsould have this kind of thing too to allow you to reconstruct them?
  #i like the possibility to be honest... as aset of key/value pairs they could be URId
  #XXX move to using 'handles' for this?
  $meta->add_method('__id', sub {shift->$dm_reader->id} )
    unless $class->can('__id');
  #XXX this one is for Action, ChooseOne and ChooseMany need this shit
  $meta->add_method('__ident_condition', sub {shift->$dm_reader->ident_condition} )
    unless $class->can('__ident_condition');

  #XXX this is just a disaster
  $meta->add_method('display_name', sub {shift->$dm_reader->display_name} )
    if( $source_class->can('display_name') && !$class->can('display_name'));

  #XXX as a default pass the domain model as a target_model until i come up with something
  #better through the coercion method
  my $def_act_args = sub {
    my $super = shift;
    confess "no dm reader: $dm_reader on $_[0]" unless $_[0]->can($dm_reader);
    return { (target_model => $_[0]->$dm_reader), %{ $super->(@_) } };
  };
  $meta->add_around_method_modifier('_default_action_args_for', $def_act_args);

  {
    # attributes => undef,              #default to qr/./
    # attributes => [],                 #default to nothing
    # attributes => qr//,               #DWIM, treated as [qr//]
    # attributes => [{...}]             #DWIM, treat as [qr/./, {...} ]
    # attributes => [[-exclude => ...]] #DWIM, treat as [qr/./, [-exclude => ...]]
    my $attr_haystack =
      [ map { $_->name } $source_class->meta->get_all_attributes ];

    if(!defined $attr_rules){
      $attr_rules = [qr/./];
    } elsif( (!ref $attr_rules && $attr_rules) || (ref $attr_rules eq 'Regexp') ){
      $attr_rules = [ $attr_rules ];
    } elsif( ref $attr_rules eq 'ARRAY' && @$attr_rules){
      #don't add a qr/./ rule if we have at least one match rule
      push(@$attr_rules, qr/./) unless
        grep {(ref $_ eq 'ARRAY' && $_->[0] ne '-exclude')
                || !ref $_  || ref $_ eq 'Regexp'} @$attr_rules;
    }

    my $attributes = $self->parse_reflect_rules($attr_rules, $attr_haystack);
    for my $attr_name (keys %$attributes){
      $self->reflect_source_object_attribute(
                                             schema => $schema,
                                             class             => $class,
                                             source_class      => $source_class,
                                             parent_class      => $parent,
                                             attribute_name    => $attr_name,
                                             domain_model_name => $dm_name,
                                             %{ $attributes->{$attr_name} || {}},
                                            );
    }
  }

  {
    my $all_actions = $self->_all_object_actions;
    my $action_haystack = [keys %$all_actions];
    if(!defined $action_rules){
      $action_rules = $self->default_object_actions;
    } elsif( (!ref $action_rules && $action_rules) || (ref $action_rules eq 'Regexp') ){
      $action_rules = [ $action_rules ];
    } elsif( ref $action_rules eq 'ARRAY' && @$action_rules){
      #don't add a qr/./ rule if we have at least one match rule
      push(@$action_rules, qr/./)
        unless grep {(ref $_ eq 'ARRAY' && $_->[0] ne '-exclude')
                       || !ref $_  || ref $_ eq 'Regexp'} @$action_rules;
    }

    # XXX this is kind of a dirty hack to support custom actions that are not
    # previously defined and still be able to use the parse_reflect_rules mechanism
    my @custom_actions = grep {!exists $all_actions->{$_}} map{ $_->[0] }
      grep {ref $_ eq 'ARRAY' && $_->[0] ne '-exclude'} @$action_rules;
    push(@$action_haystack, @custom_actions);
    my $actions = $self->parse_reflect_rules($action_rules, $action_haystack);
    for my $action (keys %$actions){
      my $action_opts = $self->merge_hashes
        ($all_actions->{$action} || {}, $actions->{$action} || {});

      #NOTE: If the name of the action is not specified in the prototype then use it's
      #hash key as the name. I think this is sane beahvior, but I've actually been thinking
      #of making Action prototypes their own separate objects
      $self->reflect_source_action(
                                   schema => $schema,
                                   name         => $action,
                                   object_class => $class,
                                   source_class => $source_class,
                                   %$action_opts,
                                  );

      # XXX i will move this to use the coercion method soon. this will be
      #  GoodEnough until then. I still need to think a little about the type coercion
      #  thing so i don't make a mess of it
      my $act_args = sub {   #override target model for this action
        my $super = shift;
        confess "no dm reader: $dm_reader on $_[0]" unless $_[0]->can($dm_reader);
        return { %{ $super->(@_) },
                 ($_[1] eq $action ? (target_model => $_[0]->$dm_reader) : () ) };
      };
      $meta->add_around_method_modifier('_default_action_args_for', $act_args);
    }
  }

  $meta->make_immutable if $make_immutable;
  return $meta;
};

# needs class, attribute_name domain_model_name
sub reflect_source_object_attribute {
  my ($self, %opts) = @_;
  unless( $opts{attribute_name} && $opts{class} && $opts{parent_class}
          && ( $opts{source_class} || $opts{domain_model_name} ) ){
    confess( "Error: class, parent_class, attribute_name, and either " .
             "domain_model_name or source_class are required parameters" );
  }

  my $meta =  $opts{class}->meta;
  my $attr_opts = $self->parameters_for_source_object_attribute(%opts);

  my $make_immutable = $meta->is_immutable;
  $meta->make_mutable if $meta->is_immutable;

  my $attr = $meta->add_attribute($opts{attribute_name}, %$attr_opts);

  $meta->make_immutable if $make_immutable;
  return $attr;
};

# needs class, attribute_name domain_model_name
sub parameters_for_source_object_attribute {
  my ($self, %opts) = @_;

  my $class        = delete $opts{class};
  my $attr_name    = delete $opts{attribute_name};
  my $dm_name      = delete $opts{domain_model_name};
  my $source_class = delete $opts{source_class};
  my $parent_class = delete $opts{parent_class};
  my $schema = $opts{schema};
  confess("parent_class is a required argument") unless $parent_class;
  confess("You must supply at least one of domain_model_name and source_class")
    unless $dm_name || $source_class;

  my $source = $schema->source($source_class);
  my $from_attr = $source_class->meta->find_attribute_by_name($attr_name);
  my $reader = $from_attr->get_read_method;
  die("Could not find reader for attribute '$attr_name' on $source_class")
    unless $reader;

  #default options. lazy build but no outsider method
  my %attr_opts = ( is => 'ro', lazy => 1, required => 1,
                    clearer   => "_clear_${attr_name}",
                    predicate => {
                        "has_${attr_name}" =>
                            sub { defined(shift->$dm_name->$reader) }
                    },
                    domain_model   => $dm_name,
                    orig_attr_name => $attr_name,
                  );
  $attr_opts{coerce} = 1 if $from_attr->should_coerce;

  #m2m / has_many
  my $m2m_meta;
  if(my $coderef = $source->result_class->can('_m2m_metadata')){
    $m2m_meta = $source->result_class->$coderef;
  }

  my $constraint_is_ArrayRef =
    $from_attr->type_constraint->name eq 'ArrayRef' ||
      $from_attr->type_constraint->is_subtype_of('ArrayRef');

  if( my $rel_info = $source->relationship_info($attr_name) ){
    my $rel_accessor = $rel_info->{attrs}->{accessor};
    my $rel_moniker  = $schema->source($rel_info->{class})->source_name;

    if($rel_accessor eq 'multi' && $constraint_is_ArrayRef) {
      #has_many
      my $sm = $self->class_name_from_source_name($parent_class, $rel_moniker);
      #type constraint is a collection, and default builds it
      my $isa = $attr_opts{isa} = $self->class_name_for_collection_of($sm);
      $attr_opts{default} = eval "sub {
        my \$rs = shift->${dm_name}->related_resultset('${attr_name}');
        return ${isa}->new(_source_resultset => \$rs);
      }";
    } elsif( $rel_accessor eq 'single' || $rel_accessor eq 'filter' ) {
      #belongs_to
      #type constraint is the foreign IM object, default inflates it
      my $isa = $attr_opts{isa} = $self->class_name_from_source_name($parent_class, $rel_moniker);
      $attr_opts{default} = eval "sub {
        if (defined(my \$o = shift->${dm_name}->${reader})) {
          return ${isa}->inflate_result(\$o->result_source, { \$o->get_columns });
        }
        return undef;
      }";
    }
  } elsif( $constraint_is_ArrayRef && $attr_name =~ m/^(.*)_list$/ ) {
    #m2m magic
    my $mm_name = $1;
    my $link_table = "links_to_${mm_name}_list";
    my ($hm_source, $far_side);
    eval { $hm_source = $source->related_source($link_table); }
      || confess "Can't find ${link_table} has_many for ${mm_name}_list";
    eval { $far_side = $hm_source->related_source($mm_name); }
      || confess "Can't find ${mm_name} belongs_to on ".$hm_source->result_class
        ." traversing many-many for ${mm_name}_list";

    my $sm = $self->class_name_from_source_name($parent_class,$far_side->source_name);
    my $isa = $attr_opts{isa} = $self->class_name_for_collection_of($sm);

    #proper collections will remove the result_class uglyness.
    $attr_opts{default} = eval "sub {
      my \$rs = shift->${dm_name}->related_resultset('${link_table}')->related_resultset('${mm_name}');
      return ${isa}->new(_source_resultset => \$rs);
    }";
  } elsif( $constraint_is_ArrayRef && defined $m2m_meta && exists $m2m_meta->{$attr_name} ){
    #m2m if using introspectable m2m component
    my $rel = $m2m_meta->{$attr_name}->{relation};
    my $far_rel   = $m2m_meta->{$attr_name}->{foreign_relation};
    my $far_source = $source->related_source($rel)->related_source($far_rel);
    my $sm = $self->class_name_from_source_name($parent_class, $far_source->source_name);
    my $isa = $attr_opts{isa} = $self->class_name_for_collection_of($sm);

    my $rs_meth = $m2m_meta->{$attr_name}->{rs_method};
    $attr_opts{default} = eval "sub {
      return ${isa}->new(_source_resultset => shift->${dm_name}->${rs_meth});
    }";
  } else {
    #no rel
    $attr_opts{isa} = $from_attr->_isa_metadata;
    my $default_code = "sub{ shift->${dm_name}->${reader} }";
    $attr_opts{default} = eval $default_code;
    die "Could not generate default for attribute, code '$default_code' did not compile with: $@" if $@;
  }
  return \%attr_opts;
};
sub reflect_source_action {
  my($self, %opts) = @_;
  my $name = delete $opts{name};
  my $base = delete $opts{base} || Action;
  my $roles = delete $opts{roles} || [];
  my $class = delete $opts{class};
  my $object = delete $opts{object_class};
  my $source = delete $opts{source_class};
  my $schema = delete $opts{schema};

  confess("name, object_class and source_class are required arguments")
    unless $source && $name && $object;

  my $attr_rules = delete $opts{attributes};
  $class ||= $object->_default_action_class_for($name);

  Class::MOP::load_class( $base   );
  Class::MOP::load_class( $object );
  Class::MOP::load_class( $source );

  #print STDERR "\n\t", ref $attr_rules eq 'ARRAY' ? @$attr_rules : $attr_rules,"\n";
  # attributes => undef,              #default to qr/./
  # attributes => [],                 #default to nothing
  # attributes => qr//,               #DWIM, treated as [qr//]
  # attributes => [{...}]             #DWIM, treat as [qr/./, {...} ]
  # attributes => [[-exclude => ...]] #DWIM, treat as [qr/./, [-exclude => ...]]
  my $attr_haystack = [ map { $_->name } $object->parameter_attributes ];
  if(!defined $attr_rules){
    $attr_rules = [qr/./];
  } elsif( (!ref $attr_rules && $attr_rules) || (ref $attr_rules eq 'Regexp') ){
    $attr_rules = [ $attr_rules ];
  } elsif( ref $attr_rules eq 'ARRAY' && @$attr_rules){
    #don't add a qr/./ rule if we have at least one match rule
    push(@$attr_rules, qr/./) unless
      grep {(ref $_ eq 'ARRAY' && $_->[0] ne '-exclude')
              || !ref $_  || ref $_ eq 'Regexp'} @$attr_rules;
  }

  #print STDERR "${name}\t${class}\t${base}\n";
  #print STDERR "\t${object}\t${source}\n";
  #print STDERR "\t",@$attr_rules,"\n";

  my $o_meta = $object->meta;
  my $s_meta = $source->meta;
  my $attributes = $self->parse_reflect_rules($attr_rules, $attr_haystack);

  #create the class
  my $meta = $self->_load_or_create(
    $class,
    superclasses => [$base],
    ( @$roles ? (roles => $roles) : ()),
  );
  my $make_immutable = $meta->is_immutable || $self->make_classes_immutable;
  $meta->make_mutable if $meta->is_immutable;

  for my $attr_name (keys %$attributes){
    my $attr_opts   = $attributes->{$attr_name} || {};
    my $o_attr      = $o_meta->find_attribute_by_name($attr_name);
    my $s_attr_name = $o_attr->orig_attr_name || $attr_name;
    my $s_attr      = $s_meta->find_attribute_by_name($s_attr_name);
    confess("Unable to find attribute for '${s_attr_name}' via '${source}'")
      unless defined $s_attr;
    next unless $s_attr->get_write_method
      && $s_attr->get_write_method !~ /^_/; #only rw attributes!

    my $attr_params = $self->parameters_for_source_object_action_attribute
      (
       schema => $schema,
       object_class   => $object,
       source_class   => $source,
       attribute_name => $attr_name
      );
    $meta->add_attribute( $attr_name => %$attr_params);
  }

  $meta->make_immutable if $make_immutable;
  return $meta;
};
sub parameters_for_source_object_action_attribute {
  my ($self, %opts) = @_;

  my $object       = delete $opts{object_class};
  my $attr_name    = delete $opts{attribute_name};
  my $source_class = delete $opts{source_class};
  my $schema = delete $opts{schema};
  my $source = $schema->source($source_class);
  confess("object_class and attribute_name are required parameters")
    unless $attr_name && $object;

  my $o_meta  = $object->meta;
  my $dm_name = $o_meta->find_attribute_by_name($attr_name)->domain_model;
  $source_class ||= $o_meta->find_attribute_by_name($dm_name)->_isa_metadata;
  my $from_attr = $source_class->meta->find_attribute_by_name($attr_name);

  #print STDERR "$attr_name is type: " . $from_attr->meta->name . "\n";

  confess("${attr_name} is not writeable and can not be reflected")
    unless $from_attr->get_write_method;

  my %attr_opts = (
                   is        => 'rw',
                   isa       => $from_attr->_isa_metadata,
                   required  => $from_attr->is_required,
                   ($from_attr->is_required
                     ? () : (clearer => "clear_${attr_name}")),
                   predicate => "has_${attr_name}",
                  );

  if ($attr_opts{required}) {
      if($from_attr->has_default) {
        $attr_opts{lazy} = 1;
        $attr_opts{default} = $from_attr->default;
      } else {
        $attr_opts{lazy_fail} = 1;
      }
  }


  my $m2m_meta;
  if(my $coderef = $source_class->result_class->can('_m2m_metadata')){
    $m2m_meta = $source_class->result_class->$coderef;
  }
  #test for relationships
  my $constraint_is_ArrayRef =
    $from_attr->type_constraint->name eq 'ArrayRef' ||
      $from_attr->type_constraint->is_subtype_of('ArrayRef');

  if (my $rel_info = $source->relationship_info($attr_name)) {
    my $rel_accessor = $rel_info->{attrs}->{accessor};

    if($rel_accessor eq 'multi' && $constraint_is_ArrayRef) {
      confess "${attr_name} is a rw has_many, this won't work.";
    } elsif( $rel_accessor eq 'single' || $rel_accessor eq 'filter') {
      $attr_opts{valid_values} = sub {
        shift->target_model->result_source->related_source($attr_name)->resultset;
      };
    }
  } elsif ( $constraint_is_ArrayRef && $attr_name =~ m/^(.*)_list$/) {
    my $mm_name = $1;
    my $link_table = "links_to_${mm_name}_list";
    $attr_opts{default} = sub { [] };
    $attr_opts{valid_values} = sub {
      shift->target_model->result_source->related_source($link_table)
        ->related_source($mm_name)->resultset;
    };
  } elsif( $constraint_is_ArrayRef && defined $m2m_meta && exists $m2m_meta->{$attr_name} ){
    #m2m if using introspectable m2m component
    my $rel = $m2m_meta->{$attr_name}->{relation};
    my $far_rel   = $m2m_meta->{$attr_name}->{foreign_relation};
    $attr_opts{default} = sub { [] };
    $attr_opts{valid_values} = sub {
      shift->target_model->result_source->related_source($rel)
        ->related_source($far_rel)->resultset;
    };
  }
  #use Data::Dumper;
  #print STDERR "\n" .$attr_name ." - ". $object . "\n";
  #print STDERR Dumper(\%attr_opts);
  return \%attr_opts;
};

sub _load_or_create {
  my ($self, $class, %options) = @_;

  if( $self->_maybe_load_class($class) ){
    return $class->meta;
  }
  my $base;
  if( exists $options{superclasses} ){
    ($base) = @{ $options{superclasses} };
  } else {
    $base = 'Reaction::InterfaceModel::Action';
  }
  return $base->meta->create($class, %options);
}

sub _maybe_load_class {
  my ($self, $class) = @_;
  my $file = $class . '.pm';
  $file =~ s{::}{/}g;
  my $ret = eval { Class::MOP::load_class($class) };
  if ($INC{$file} && $@) {
    confess "Error loading ${class}: $@";
  }
  return $ret;
}

__PACKAGE__->meta->make_immutable;


1;

#--------#---------#---------#---------#---------#---------#---------#---------#
__END__;

=head1 NAME

Reaction::InterfaceModel::Reflector::DBIC -
Automatically Generate InterfaceModels from DBIx::Class models

=head1 DESCRIPTION

The InterfaceModel reflectors are classes that are meant to aid you in easily
generating Reaction::InterfaceModel classes that represent their underlying
DBIx::Class domain models by introspecting your L<DBIx::Class::ResultSource>s
and creating a collection of L<Reaction::InterfaceModel::Object> and
L<Reaction::InterfaceModel::Collection> classes for you to use.

The default base class of all Object classes will be
 L<Reaction::InterfaceModel::Object> and the default Collection type will be
L<Reaction::InterfaceModel::Collection::Virtual::ResultSet>.

Additionally, the reflector can create InterfaceModel actions that interact
with the supplied L<Reaction::UI::Controller::Collection::CRUD>, allowing you
to easily set up a highly customizable CRUD interface in minimal time.

At this time, supported collection actions consist of:

=over 4

=item B<> L<Reaction::InterfaceModel::Action::DBIC::ResultSet::Create>

Creates a new item in the collection and underlying ResultSet.

=item B<> L<Reaction::InterfaceModel::Action::DBIC::ResultSet::DeleteAll>

Deletes all the items in a collection and it's underlying resultset using
C<delete_all>

=back

And supported object actions are :

=over 4

=item B<Update> - via L<Reaction::InterfaceModel::Action::DBIC::Result::Update>

Updates an existing object.

=item B<Delete> - via L<Reaction::InterfaceModel::Action::DBIC::Result::Delete>

Deletes an existing object.

=back

=head1 SYNOPSIS

    package MyApp::IM::TestModel;
    use base 'Reaction::InterfaceModel::Object';
    use Reaction::Class;
    use Reaction::InterfaceModel::Reflector::DBIC;
    my $reflector = Reaction::InterfaceModel::Reflector::DBIC->new;

    #Reflect everything
    $reflector->reflect_schema
      (
       model_class  => __PACKAGE__,
       schema_class => 'MyApp::Schema',
      );

=head2 Selectively including and excluding sources

    #reflect everything except for the FooBar and FooBaz classes
    $reflector->reflect_schema
      (
       model_class  => __PACKAGE__,
       schema_class => 'MyApp::Schema',
       sources => [-exclude => [qw/FooBar FooBaz/] ],
       # you could also do:
       sources => [-exclude => qr/(?:FooBar|FooBaz)/,
       # or even
       sources => [-exclude => [qr/FooBar/, qr/FooBaz/],
      );

    #reflect only the Foo family of sources
    $reflector->reflect_schema
      (
       model_class  => __PACKAGE__,
       schema_class => 'MyApp::Schema',
       sources => qr/^Foo/,
      );

=head2 Selectively including and excluding fields in sources

    #Reflect Foo and Baz in their entirety and exclude the field 'avatar' in the Bar ResultSource
    $reflector->reflect_schema
      (
       model_class  => __PACKAGE__,
       schema_class => 'MyApp::Schema',
       sources => [qw/Foo Baz/,
                   [ Bar => {attributes => [[-exclude => 'avatar']] } ],
                   # or exclude by regex
                   [ Bar => {attributes => [-exclude => qr/avatar/] } ],
                   # or simply do not include it...
                   [ Bar => {attributes => [qw/id name description/] } ],
                  ],
      );

=head1 ATTRIBUTES

=head2 make_classes_immutable

=head2 object_actions

=head2 collection_actions

=head2 default_object_actions

=head2 default_collection_actions

=head2 builtin_object_actions

=head2 builtin_collection_actions

=head1 METHODS

=head2 new

=head2 _all_object_actions

=head2 _all_collection_actions

=head2 dm_name_from_class_name

=head2 dm_name_from_source_name

=head2 class_name_from_source_name

=head2 class_name_for_collection_of

=head2 merge_hashes

=head2 parse_reflect_rules

=head2 merge_reflect_rules

=head2 reflect_schema

=head2 _compute_source_options

=head2 add_source

=head2 reflect_source

=head2 reflect_source_collection

=head2 reflect_source_object

=head2 reflect_source_object_attribute

=head2 parameters_for_source_object_attribute

=head2 reflect_source_action

=head2 parameters_for_source_object_action_attribute

=head1 TODO

Allow the reflector to dump the generated code out as files, eliminating the need to
reflect on startup every time. This will likely take quite a bit of work though. The
main work is already in place, but the grunt work is still left. At the moment there
is no closures that can't be dumped out as code with a little bit of work.

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
