package Synth::Config;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Synthesizer settings librarian

our $VERSION = '0.0058';

use Moo;
use strictures 2;
use Carp qw(croak);
use GraphViz2 ();
use List::Util qw(first);
use Mojo::JSON qw(from_json to_json);
use Mojo::SQLite ();
use YAML qw(Load LoadFile);
use namespace::clean;


has model => (
  is => 'rw',
);


has dbname => (
  is       => 'ro',
  required => 1,
  default  => sub { 'synth-config.db' },
);

has _sqlite => (is => 'lazy');

sub _build__sqlite {
  my ($self) = @_;
  my $sqlite = Mojo::SQLite->new('sqlite:' . $self->dbname);
  return $sqlite->db;
}


has verbose => (
  is      => 'ro',
  isa     => sub { croak "$_[0] is not a boolean" unless $_[0] =~ /^[01]$/ },
  default => sub { 0 },
);


sub BUILD {
  my ($self, $args) = @_;
  return unless $args->{model};
  # sanitize the model name
  (my $model = $args->{model}) =~ s/\W/_/g;
  $self->model(lc $model);
  # create the model table unless it's already there
  $self->_sqlite->query(
    'create table if not exists '
    . $self->model
    . ' (
        id integer primary key autoincrement,
        settings json not null,
        name text not null
      )'
  );
  # create the model specs table unless it's already there
  $self->_sqlite->query(
    'create table if not exists specs'
    . ' (
        id integer primary key autoincrement,
        model text not null,
        spec json not null
      )'
  );
}


sub make_setting {
  my ($self, %args) = @_;
  my $id = delete $args{id};
  my $name = delete $args{name};
  croak 'No columns given' unless keys %args;
  if ($id) {
    my $result = $self->_sqlite->select(
      $self->model,
      ['settings'],
      { id => $id },
    )->expand(json => 'settings')->hash->{settings};
    for my $arg (keys %args) {
      $args{$arg} = '' unless defined $args{$arg};
    }
    my $params = { %$result, %args };
    $self->_sqlite->update(
      $self->model,
      { settings => to_json($params) },
      { id => $id },
    );
  }
  elsif ($name) {
    $id = $self->_sqlite->insert(
      $self->model,
      {
        name     => $name,
        settings => to_json(\%args),
      },
    )->last_insert_id;
  }
  return $id;
}


sub recall_setting {
  my ($self, %args) = @_;
  my $id = $args{id};
  croak 'No id given' unless $id;
  my $result = $self->_sqlite->select(
    $self->model,
    ['name', 'settings'],
    { id => $id },
  )->expand(json => 'settings')->hash;
  my $setting = $result->{settings};
  $setting->{id} = $id;
  $setting->{name} = $result->{name};
  return $setting;
}


sub search_settings {
  my ($self, %args) = @_;
  my $name = delete $args{name};
  my @where;
  push @where, "name = '$name'" if $name;
  for my $arg (keys %args) {
    next unless $args{$arg};
    $args{$arg} =~ s/'/''/g; # escape the single-quote
    push @where, q/json_extract(settings, '$./ . $arg . q/') = / . "'$args{$arg}'";
  }
  return [] unless @where;
  my $sql = q/select id,name,settings,json_extract(settings, '$.group') as mygroup, json_extract(settings, '$.parameter') as parameter from /
    . $self->model
    . ' where ' . join(' and ', @where)
    . ' order by name,mygroup,parameter';
  print "Search SQL: $sql\n" if $self->verbose;
  my $results = $self->_sqlite->query($sql);
  my @settings;
  while (my $next = $results->hash) {
    my $set = from_json($next->{settings});
    $set->{id} = $next->{id};
    $set->{name} = $next->{name};
    push @settings, $set;
  }
  return \@settings;
}


sub recall_settings {
  my ($self) = @_;
  my $sql = q/select id,name,settings,json_extract(settings, '$.group') as mygroup from /
    . $self->model
    . ' order by name,mygroup';
  my $results = $self->_sqlite->query($sql);
  my @settings;
  while (my $next = $results->hash) {
    my $set = from_json($next->{settings});
    $set->{id} = $next->{id};
    $set->{name} = $next->{name};
    push @settings, $set;
  }
  return \@settings;
}


sub recall_models {
  my ($self) = @_;
  my @models;
  my $results = $self->_sqlite->query(
    "select name from sqlite_schema where type='table' order by name"
  );
  while (my $next = $results->array) {
    next if $next->[0] =~ /^sqlite/;
    push @models, $next->[0];
  }
  return \@models;
}


sub recall_setting_names {
  my ($self) = @_;
  my @settings;
  my $results = $self->_sqlite->query(
    'select distinct name from ' . $self->model
  );
  while (my $next = $results->array) {
    push @settings, $next->[0];
  }
  return \@settings;
}


sub remove_setting {
  my ($self, %args) = @_;
  my $id = $args{id};
  croak 'No id given' unless $id;
  $self->_sqlite->delete(
    $self->model,
    { id => $id }
  );
}


sub remove_settings {
  my ($self, %args) = @_;
  my $name = $args{name};
  my $where = $name ? { name => $name } : {};
  $self->_sqlite->delete(
    $self->model,
    $where
  );
}


sub remove_model {
  my ($self) = @_;
  $self->_sqlite->query(
    'drop table ' . $self->model
  );
}


sub make_spec {
  my ($self, %args) = @_;
  my $id = delete $args{id};
  croak 'No columns given' unless keys %args;
  if ($id) {
    my $result = $self->_sqlite->select(
      'specs',
      ['spec'],
      { id => $id },
    )->expand(json => 'spec')->hash->{spec};
    for my $arg (keys %args) {
      $args{$arg} = '' unless defined $args{$arg};
    }
    my $params = { %$result, %args };
    $self->_sqlite->update(
      'specs',
      { spec => to_json($params) },
      { id => $id },
    );
  }
  else {
    $id = $self->_sqlite->insert(
      'specs',
      {
        model => $self->model,
        spec  => to_json(\%args),
      },
    )->last_insert_id;
  }
  return $id;
}


sub recall_specs {
  my ($self) = @_;
  my $sql = q/select id,model,spec,json_extract(spec, '$.group') as mygroup from /
    . 'specs'
    . " where model = '" . $self->model . "'"
    . ' order by model,mygroup';
  my $results = $self->_sqlite->query($sql);
  my $set;
  while (my $next = $results->hash) {
    $set = from_json($next->{spec});
    $set->{id} = $next->{id};
    $set->{model} = $next->{model};
  }
  return $set;
}


sub recall_spec {
  my ($self, %args) = @_;
  my $id = delete $args{id};
  croak 'No id given' unless $id;
  my $result = $self->_sqlite->select(
    'specs',
    ['spec'],
    { id => $id },
  )->expand(json => 'spec')->hash;
  my $spec = $result->{spec};
  $spec->{id} = $id;
  return $spec;
}


sub remove_spec {
  my ($self) = @_;
  $self->_sqlite->delete(
    'specs',
    { model => $self->model }
  );
}


sub import_yaml {
  my ($self, %options) = @_;

  croak 'Invalid settings file'
    if $options{file} && !-e $options{file};

  my $config = $options{file}
    ? LoadFile($options{file})
    : Load($options{string});

  my $list = $options{patches} && @{ $options{patches} }
    ? $options{patches}
    : [ map { $_->{patch} } @{ $config->{patches} } ];

  for my $patch_name (@$list) {
    my $settings = $self->search_settings(name => $patch_name);

    if ($settings && @$settings) {
      print "Removing $patch_name setting from ", $self->model, "\n"
          if $self->verbose;
      $self->remove_settings(name => $patch_name);
    }

    for my $patch (@{ $config->{patches} }) {
      my $name = $patch->{patch};
      next unless first { $_ eq $name } @$list;
      for my $set (@{ $patch->{settings} }) {
        my $group = $set->{group};
        print "Adding $name $group setting to ", $self->model, "\n"
          if $self->verbose;
        $self->make_setting(name => $name, %$set);
      }
    }
  }

  return $list;
}


sub graphviz {
  my ($self, %options) = @_;

  croak 'No settings given' unless $options{settings};

  $options{render}    ||= 0;
  $options{path}      ||= '.';
  $options{extension} ||= 'png';
  $options{shape}     ||= 'oval';
  $options{color}     ||= 'grey';

  my $g = GraphViz2->new(
    global => { directed => 1 },
    node   => { shape => $options{shape} },
    edge   => { color => $options{color} },
  );
  my (%edges, %sets, %labels);

  my $patch_name = '';
  # collect settings by group
  for my $set (@{ $options{settings} }) {
    my $from = $set->{group};
    $patch_name = $set->{name};
    push @{ $sets{$from} }, $set;
  }

  # accumulate parameter = value lines
  my %seen;
  for my $from (keys %sets) {
    my @label = ($from);
    for my $group (@{ $sets{$from} }) {
      next if $group->{control} eq 'patch';
      my $label = "$group->{parameter} = $group->{value}$group->{unit}";
      push @label, $label unless $seen{ "$from $label" }++;
    }
    $labels{$from} = join "\n", @label;
  }

  # add patch edges
  for my $set (@{ $options{settings} }) {
    next if $set->{control} ne 'patch';
    my ($from, $to, $param, $param_to) = @$set{qw(group group_to parameter param_to)};
    my $key = "$from $param to $to $param_to";
    my $label = "$param to $param_to";
    $from = $labels{$from};
    $to = $labels{$to} if exists $labels{$to};
    $g->add_edge(
      from  => $from,
      to    => $to,
      label => $label,
    ) unless $edges{$key}++;
  }

  # save a file
  if ($options{render}) {
    my $model = $self->model;
    (my $patch = $patch_name) =~ s/\W/_/g;
    # TODO render to data
    my $filename = "$options{path}/$model-$patch.$options{extension}";
    $g->run(format => $options{extension}, output_file => $filename);
  }

  return $g;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Synth::Config - Synthesizer settings librarian

=head1 VERSION

version 0.0058

=head1 SYNOPSIS

  use Synth::Config ();

  my $model = 'Modular';
  my $synth = Synth::Config->new(model => $model, verbose => 1);

  # populate the database with patch settings from a YAML file or string
  my $patches = $synth->import_yaml(
      file    => "$model.yaml", # or string => '...' # one or the other is required
      patches => ['Simple 001', 'Simple 002'],       # optional
  );

  # populate the database with individual settings
  my $patch = 'My favorite setting';
  my $id1 = $synth->make_setting(name => $patch, group => 'filter', etc => '...');
  my $id2 = $synth->make_setting(name => $patch, group => 'sequencer', etc => '...');

  my $settings = $synth->recall_settings;
  # [ { id => 1, group => 'envelope', etc => '...' }, { id => 2, group => 'sequencer', etc => '...' } ]

  # update the group key
  $synth->make_setting(id => $id1, group => 'envelope');

  $settings = $synth->search_settings(name => $patch);
  # [ { id => 1, group => 'envelope', etc => '...' }, { id => 2, group => 'sequencer', etc => '...' } ]

  $settings = $synth->search_settings(group => 'sequencer');
  # [ { id => 2, group => 'sequencer', etc => '...' } ]

  my $setting = $synth->recall_setting(id => $id1);
  # { id => 1, group => 'filter', etc => '...' }

  my $g = $synth->graphviz(settings => $setting);
  # or
  $synth->graphviz(
    settings => $setting,
    render   => 1,
  );

  my $models = $synth->recall_models;
  # [ 'moog_matriarch' ]

  my $setting_names = $synth->recall_setting_names;
  # [ 'My favorite setting' ]

  # declare the possible settings
  my %spec = (
    order      => [qw(group parameter control group_to param_to bottom top value unit is_default)],
    group      => [],
    parameter  => {},
    control    => [qw(knob switch slider patch)],
    group_to   => [],
    param_to   => [],
    bottom     => [qw(off 0 1 7AM 20)],
    top        => [qw(on 3 4 6 7 5PM 20_000 100%)],
    value      => [],
    unit       => [qw(Hz o'clock)],
    is_default => [0, 1],
  );
  my $spec_id = $synth->make_spec(%spec);
  my $spec = $synth->recall_spec(id => $spec_id);
  my $specs = $synth->recall_specs;
  # { order => [ ... ], etc => ... }

  # remove stuff!
  $synth->remove_spec;                     # remove the current model specification
  $synth->remove_setting(id => $id1);      # remove a particular setting
  $synth->remove_settings(name => $patch); # remove all settings sharing the same name
  $synth->remove_model(model => $model);   # remove the entire model

=head1 DESCRIPTION

C<Synth::Config> provides a way to import, save, recall, and visualize
synthesizer control settings in a database, and with L<GraphViz2>.

This does B<not> control the synth. It is simply a way to manually
record the parameters defined by knob, slider, switch, or patch
settings in an SQLite database. It is a "librarian", if you will.

=head1 ATTRIBUTES

=head2 model

  $model = $synth->model;

The model name of the synthesizer.

This is turned into lowercase and all non-alpha-num characters are
converted to an underline character (C<_>).

=head2 dbname

  $dbname = $synth->dbname;

Database name

Default: C<synth-config.db>

=head2 verbose

  $verbose = $synth->verbose;

Show progress.

=head1 METHODS

=head2 new

  $synth = Synth::Config->new(model => $model);

Create a new C<Synth::Config> object.

This automatically makes an SQLite database with a table named for the
given B<model>.

=for Pod::Coverage BUILD

=head2 make_setting

  my $id = $synth->make_setting(%args);

Save a named setting and return the record id.

The B<name> is required to perform an insert. If an B<id> is given, an
update is performed.

The setting is a single JSON field that can contain any key/value
pairs. These pairs B<must> include at least a C<group> to be
searchable.

Example:

  name: 'My Best Setting!'
  settings:
    group   parameter control bottom top   value unit is_default
    filters cutoff    knob    20     20000 200   Hz   1

  name: 'My Other Best Setting!'
  settings:
    group parameter control group_to param_to is_default
    mixer output    patch   filters  vcf-in   0

=head2 recall_setting

  my $setting = $synth->recall_setting(id => $id);

Return the parameters of a setting for the given B<id>.

=head2 search_settings

  my $settings = $synth->search_settings(
    some_setting    => $val1,
    another_setting => $val2,
  );

Return all the settings given a search query.

=head2 recall_settings

  my $settings = $synth->recall_settings;

Return all the settings for the synth model.

=head2 recall_models

  my $models = $synth->recall_models;

Return all the know models. This method can be called without having
specified a synth B<model> in the constructor.

=head2 recall_setting_names

  my $setting_names = $synth->recall_setting_names;

Return all the setting names for the current model.

=head2 remove_setting

  $synth->remove_setting(id => $id);

Remove a setting given an B<id>.

=head2 remove_settings

  $synth->remove_settings; # all model settings
  $synth->remove_settings(name => $name);

Remove all settings of the current model, or for given B<name>d
setting.

=head2 remove_model

  $synth->remove_model;

Remove the database table for the current object model.

=head2 make_spec

  my $id = $synth->make_spec(%args);

Save a model specification and return the record id.

If an B<id> is given, an update is performed.

The spec is a single JSON field that can contain any key/value
pairs that define the configuration - groups, parameters, values, etc.
of a model.

=head2 recall_specs

  my $specs = $synth->recall_specs;

Return the specs for the model.

=head2 recall_spec

  my $spec = $synth->recall_spec(id => $id);

Return the model configuration specification for the given B<id>.

=head2 remove_spec

  $synth->remove_spec;

Remove the database table for the current object model configuration
specification.

=head2 import_yaml

Add the settings in a L<YAML> file or string, to the database and
return the setting (patch) name.

Import a specific set of B<patches> in the settings, by providing them
in the B<options>.

Option defaults:

  file    = undef
  string  = undef
  patches = undef

=head2 graphviz

  $g = $synth->graphviz(%options);

Visualize a patch of B<settings> with the L<GraphViz2> module.

Option defaults:

  settings  = undef (required)
  render    = 0
  path      = .
  extension = png
  shape     = oval
  color     = grey

=head1 SEE ALSO

The F<t/01-methods.t> and the F<eg/*.pl> files in this distribution

L<GraphViz2>

L<List::Util>

L<Moo>

L<Mojo::JSON>

L<Mojo::SQLite>

L<YAML>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2024 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
