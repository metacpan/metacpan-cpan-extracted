package Mojolicious::Plugin::Form::Base;
use Mojo::Base -base;

use Data::Dumper;

has 'elements';
has 'ordered_elements';

has 'element_info' => sub {
  my ($self, $element) = @_;
  return $self->elements->{$element};
};

has 'id_field';

has 'name_field';

has 'order_by';

has 'form_debug' => 0;

sub add_elements {
  my ($self, @elems) = @_;

  my @added;
  my $elements = $self->elements;
  while (my $el = shift @elems) {
    my $element_info = {};
    if ($el =~ s/^\+//) {
      $element_info = $self->element_info($el);
    }

    # If next entry is { ... } use that for the info, if not
    # use an empty hashref
    if (ref $elems[0]) {
      my $new_info = shift(@elems);
      %$element_info = (%$element_info, %$new_info);
    }
    push(@added, $el) unless exists $elements->{$el};
    $elements->{$el} = $element_info;
  }
  push @{$self->ordered_elements}, @added;
  return $self;
}

sub from_schema {
  my $self   = shift;
  my $schema = shift;
  my $source = shift || $self->name;

  $self->order_by || $self->order_by($self->order_field($schema, $source));

  my $columns = [$schema->source($source)->columns];

  #my $result = $schema->resultset($source)->single({$order => $id});

  my $columns_info = $schema->source($source)->columns_info($columns);

  # TODO: smarter
  #my $primary_columns = [$schema->source($source)->primary_columns];
  #$self->id_field($primary_columns->[0]);
  
  my ($id_field, $name_field) = $self->id_and_name($schema, $source);
  $self->id_field || $self->id_field($id_field);
  $self->name_field || $self->name_field($name_field);

  my $relationships = [ $schema->source($source)->relationships ];

  print STDERR '$relationships: ', Dumper($relationships), "\n" if $self->form_debug;

  my $rel_elements;
  for my $relation (@$relationships) {
    my $relationship = $self->related($schema, $source, $relation);
    $rel_elements->{$relation} = $relationship if $relationship;
  }
  
  my $rel_multi;
  for my $relation (@$relationships) {
    my $relationship = $self->multi_related($schema, $source, $relation);
    $rel_multi->{$relation} = $relationship if $relationship;
  }  
  
  $self->elements         || $self->elements({});
  $self->ordered_elements || $self->ordered_elements([]);
  
  for my $column (@$columns) {
    my $element;

    if (my $rel_element = $self->exchanges_field($rel_elements, $column)) {
      $element = $rel_elements->{$rel_element};
    }
    else {
      my $type = $self->type($columns_info->{$column}->{data_type});
      my $required = $columns_info->{$column}->{is_nullable} ? '' : 'required';
      
      $element = {
        'type'     => $type,
        'name'     => $column,
        'required' => $required,
      };
      if (exists $columns_info->{$column}->{default_value} && $columns_info->{$column}->{default_value}) {
          $element->{'default'} = $columns_info->{$column}->{default_value};
      }
    }

    if ($column eq $self->id_field) { $element->{'hidden'} = 1; }

    $self->elements->{$column} = $element;
    push @{$self->ordered_elements}, $column;
  }
  
  for my $multi (keys %$rel_multi) {
    $self->elements->{$multi} = $rel_multi->{$multi};
    push @{$self->ordered_elements}, $multi;  
  }
  
  print STDERR 'id_field: ',$self->id_field,' name_field: ',$self->name_field,"\n" if $self->form_debug;
  print STDERR 'elements: ',Dumper($self->elements),"\n" if $self->form_debug;
  return $self;
}

sub exchanges_field {
  my ($self, $rel_elements, $column) = @_;
  for my $rel_element (keys %$rel_elements) {
    if (exists $rel_elements->{$rel_element}->{'exchanges_field'}
      && $rel_elements->{$rel_element}->{'exchanges_field'} eq $column)
    {
      return $rel_element;
    }
  }
  return;
}

sub related {
  my ($self, $schema, $source, $relation) = @_;
  return undef unless $source;

  #'cond' => { 'foreign.group_id' => 'self.global_role_id' },

  my $rel_info = $schema->source($source)->relationship_info($relation);

  # print STDERR '$rel_info: ', Dumper($rel_info), "\n";

  # TODO: accessor 'multi' (???)
  return undef unless ($rel_info->{attrs}->{accessor} eq 'single');

  my $rel_source =
    $schema->source($source)->related_source($relation)->{'source_name'};

  my @rel_fields = $self->id_and_name($schema, $rel_source);

  my @conditions = %{$rel_info->{cond}};

  my @self_fields = map { /(\w+)$/; $1 } grep {/^(self\.|)(\w+)$/} @conditions;
  my @foreign_fields =
    map { /(\w+)$/; $1 } grep {/^(foreign\.|)(\w+)$/} @conditions;

  my $field_to_exchange = $self_fields[0];
  my $rel_key           = $foreign_fields[0];

  my ($name_field) = grep { $_ !~ /^$rel_key$/ } @rel_fields;

  my $related_element = {
    'type'            => 'Block',
    'nested_name'     => $relation,
    'exchanges_field' => $field_to_exchange,
    'key'             => $rel_key,
    'elements'        => [
      {
        'type' => 'Text',
        'name' => $name_field,
      },
    ],
  };
  return $related_element;
}

sub multi_related {
  my ($self, $schema, $source, $relation) = @_;
  return undef unless $source;

  #'cond' => { 'foreign.group_id' => 'self.global_role_id' },

  my $rel_info = $schema->source($source)->relationship_info($relation);

  # print STDERR '$rel_info: ', Dumper($rel_info), "\n";

  # TODO: accessor 'multi' (???)
  return undef unless ($rel_info->{attrs}->{accessor} eq 'multi');

  my $rel_source =
    $schema->source($source)->related_source($relation)->{'source_name'};

  my @rel_fields = $self->id_and_name($schema, $rel_source);

  my @conditions = %{$rel_info->{cond}};

  my @self_fields = map { /(\w+)$/; $1 } grep {/^(self\.|)(\w+)$/} @conditions;
  my @foreign_fields =
    map { /(\w+)$/; $1 } grep {/^(foreign\.|)(\w+)$/} @conditions;

  my $field_to_exchange = $self_fields[0];
  my $rel_key           = $foreign_fields[0];

  my ($name_field) = grep { $_ !~ /^$rel_key$/ } @rel_fields;

  my $related_element = {
    'type'            => 'Multi',
    'nested_name'     => $relation,
    'exchanges_field' => $field_to_exchange,
    'key'             => $rel_key,
    'elements'        => [
      {
        'type' => 'Text',
        'name' => $name_field,
      },
    ],
  };
  return $related_element;
}

sub order_field {
  my ($self, $schema, $source) = @_;
  return undef unless $source;

  my @columns = $schema->source($source)->columns;
  my @source_ids = grep {/name/} @columns;

  my @primary_columns = $schema->source($source)->primary_columns;
  push @source_ids, @primary_columns;

  #my $table_name = $schema->class($source)->table;
  my $table_name = lc $source;
  push @source_ids, grep {/${table_name}_id/} @columns;

  return $source_ids[0] if (scalar @source_ids);
  return $columns[0]    if (scalar @columns);
}

sub id_and_name {
  my ($self, $schema, $source) = @_;
  return undef unless $source;
  my @columns = $schema->source($source)->columns;

  my @source_ids;
  my @primary_columns = $schema->source($source)->primary_columns;
  push @source_ids, $primary_columns[0];
  push @source_ids, grep {/name/} @columns;

  #push @source_ids, $primary_columns[1] unless (scalar @source_ids >= 2);
  push @source_ids, $columns[1] unless (scalar @source_ids >= 2);

  return @source_ids;
}

sub name {
  my $self       = shift;
  my $class_name = ref $self;
  $class_name =~ s/^.*::(\w+)$/$1/;
  return $class_name;
}

sub type {
  my $self = shift;
  my $data_type = shift || 'text';

  my $data2elem = {
    'integer' => 'number',
    'varchar' => 'text',
    'tinyint' => 'checkbox',
    'enum'    => 'enum',
  };
  return $data2elem->{$data_type} ? $data2elem->{$data_type} : 'text';
}

1;
