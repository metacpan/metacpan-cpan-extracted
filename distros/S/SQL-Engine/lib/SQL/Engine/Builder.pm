package SQL::Engine::Builder;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;

our $VERSION = '0.03'; # VERSION

# METHODS

method data() {
  {}
}

method grammar(Any %args) {
  if (!$args{grammar}) {
    require SQL::Engine::Grammar;

    $args{schema} = $self->data;

    return SQL::Engine::Grammar->new(%args);
  }
  if (lc($args{grammar}) eq 'mssql') {
    require SQL::Engine::Grammar::Mssql;

    $args{schema} = $self->data;

    return SQL::Engine::Grammar::Mssql->new(%args);
  }
  elsif (lc($args{grammar}) eq 'mysql') {
    require SQL::Engine::Grammar::Mysql;

    $args{schema} = $self->data;

    return SQL::Engine::Grammar::Mysql->new(%args);
  }
  elsif (lc($args{grammar}) eq 'postgres') {
    require SQL::Engine::Grammar::Postgres;

    $args{schema} = $self->data;

    return SQL::Engine::Grammar::Postgres->new(%args);
  }
  elsif (lc($args{grammar}) eq 'sqlite') {
    require SQL::Engine::Grammar::Sqlite;

    $args{schema} = $self->data;

    return SQL::Engine::Grammar::Sqlite->new(%args);
  }
  else {
    require SQL::Engine::Grammar;

    $args{schema} = $self->data;

    return SQL::Engine::Grammar->new(%args);
  }
}

1;
