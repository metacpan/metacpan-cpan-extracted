package SQL::Translator::Parser::OpenAPI;
use 5.008001;
use strict;
use warnings;
use JSON::Validator::OpenAPI;

our $VERSION = "0.02";
use constant DEBUG => $ENV{SQLTP_OPENAPI_DEBUG};
use String::CamelCase qw(camelize decamelize wordsplit);
use Lingua::EN::Inflect::Number qw(to_PL);
use SQL::Translator::Schema::Constants;

my %TYPE2SQL = (
  integer => 'int',
  int32 => 'int',
  int64 => 'bigint',
  float => 'float',
  number => 'double',
  double => 'double',
  string => 'varchar',
  byte => 'byte',
  binary => 'binary',
  boolean => 'bit',
  date => 'date',
  'date-time' => 'datetime',
  password => 'varchar',
);

# from GraphQL::Debug
sub _debug {
  my $func = shift;
  require Data::Dumper;
  require Test::More;
  local ($Data::Dumper::Sortkeys, $Data::Dumper::Indent, $Data::Dumper::Terse);
  $Data::Dumper::Sortkeys = $Data::Dumper::Indent = $Data::Dumper::Terse = 1;
  Test::More::diag("$func: ", Data::Dumper::Dumper([ @_ ]));
}

# heuristic 1: strip out single-item objects
sub _strip_thin {
  my ($defs) = @_;
  my @thin = grep { keys(%{ $defs->{$_}{properties} }) <= 1 } keys %$defs;
  if (DEBUG) {
    _debug("OpenAPI($_) thin, ignoring", $defs->{$_}{properties})
      for sort @thin;
  }
  @thin;
}

# heuristic 2: find objects with same propnames, drop those with longer names
sub _strip_dup {
  my ($defs) = @_;
  my %name2sig = map {
    ($_ => join "\0", sort keys %{ $defs->{$_}{properties} })
  } keys %$defs;
  my %sig2names;
  push @{ $sig2names{$name2sig{$_}} }, $_ for keys %name2sig;
  DEBUG and _debug("OpenAPI sig2names", \%sig2names);
  my @nondups = grep @{ $sig2names{$_} } == 1, keys %sig2names;
  delete @sig2names{@nondups};
  my @dups;
  for my $sig (keys %sig2names) {
    my @names = sort { length $a <=> length $b } @{ $sig2names{$sig} };
    DEBUG and _debug("OpenAPI dup($sig)", \@names);
    shift @names; # keep the first i.e. shortest
    push @dups, @names;
  }
  @dups;
}

# heuristic 3: find objects with set of propnames that is subset of
#   another object's propnames
sub _strip_subset {
  my ($defs) = @_;
  my %allprops;
  for my $defname (keys %$defs) {
    $allprops{$_} = 1 for keys %{ $defs->{$defname}{properties} };
  }
  my @allpropnames = sort keys %allprops;
  my $count = 0;
  my %prop2count;
  for my $propname (@allpropnames) {
    $prop2count{$propname} = $count;
    $count++;
  }
  my %def2mask;
  for my $defname (keys %$defs) {
    $def2mask{$defname} |= (1 << $prop2count{$_})
      for keys %{ $defs->{$defname}{properties} };
  }
  my %subsets;
  for my $defname (keys %$defs) {
    my $thismask = $def2mask{$defname};
    for my $supersetname (grep $_ ne $defname, keys %$defs) {
      my $supermask = $def2mask{$supersetname};
      next unless ($thismask & $supermask) == $thismask;
      DEBUG and _debug("mask $defname subset $supersetname");
      $subsets{$defname} = 1;
    }
  }
  keys %subsets;
}

sub _prop2sqltype {
  my ($prop) = @_;
  my $format_type = $prop->{format} || $prop->{type};
  my $lookup = $TYPE2SQL{$format_type || ''};
  DEBUG and _debug("_prop2sqltype($format_type)($lookup)", $prop);
  $lookup;
}

sub _make_not_null {
  my ($table, $field) = @_;
  $field->is_nullable(0);
  $table->add_constraint(type => $_, fields => $field)
    for (NOT_NULL);
}

sub _make_pk {
  my ($table, $field) = @_;
  $field->is_primary_key(1);
  $field->is_auto_increment(1);
  $table->add_constraint(type => $_, fields => $field)
    for (PRIMARY_KEY, UNIQUE);
  _make_not_null($table, $field);
}

sub _def2tablename {
  to_PL decamelize $_[0];
}

sub _ref2def {
  my ($ref) = @_;
  $ref =~ s:^#/definitions/:: or return;
  $ref;
}

sub _make_fk {
  my ($table, $field, $foreign_tablename, $foreign_id) = @_;
  $table->add_constraint(
    type => FOREIGN_KEY, fields => $field,
    reference_table => $foreign_tablename,
    reference_fields => $foreign_id,
  );
}

sub _fk_hookup {
  my ($table, $propname, $ref) = @_;
  my $fk_id = $propname . '_id';
  my $foreign_ref = _ref2def($ref);
  DEBUG and _debug("_def2table($propname)($fk_id)(ref)($foreign_ref)", $ref);
  my $foreign_table = _def2tablename($foreign_ref);
  DEBUG and _debug("ref($foreign_table)");
  my $field = $table->add_field(name => $fk_id, data_type => 'int');
  _make_fk($table, $field, $foreign_table, 'id');
  $field;
}

sub _def2table {
  my ($name, $def, $schema) = @_;
  my $props = $def->{properties};
  my $tname = _def2tablename($name);
  DEBUG and _debug("_def2table($name)($tname)", $props);
  my $table = $schema->add_table(
    name => $tname, comments => $def->{description},
  );
  if (!$props->{id}) {
    # we need a relational id
    $props->{id} = { type => 'integer' };
  }
  my %prop2required = map { ($_ => 1) } @{ $def->{required} || [] };
  for my $propname (sort keys %$props) {
    my $field;
    DEBUG and _debug("_def2table($propname)");
    if (my $ref = $props->{$propname}{'$ref'}) {
      $field = _fk_hookup($table, $propname, $ref);
    } elsif (($props->{$propname}{type} // '') eq 'array') {
      # if $ref, inject FK into it pointing at us
      # if simple type, make a table with that and FK it to us
    } else {
      my $sqltype = _prop2sqltype($props->{$propname});
      $field = $table->add_field(name => $propname, data_type => $sqltype);
      if ($propname eq 'id') {
        _make_pk($table, $field);
      }
    }
    if ($field and $prop2required{$propname} and $propname ne 'id') {
      _make_not_null($table, $field);
    }
  }
  $table;
}

sub parse {
  my ($tr, $data) = @_;
  my $openapi_schema = JSON::Validator::OpenAPI->new->schema($data)->schema;
  my %defs = %{ $openapi_schema->get("/definitions") };
  DEBUG and _debug('OpenAPI.definitions', \%defs);
  my $schema = $tr->schema;
  my @thin = _strip_thin(\%defs);
  DEBUG and _debug("thin ret", \@thin);
  delete @defs{@thin};
  my @dup = _strip_dup(\%defs);
  DEBUG and _debug("dup ret", \@dup);
  delete @defs{@dup};
  my @subset = _strip_subset(\%defs);
  DEBUG and _debug("dup subset", [ sort @subset ]);
  delete @defs{@subset};
  DEBUG and _debug("remaining", [ sort keys %defs ]);
  for my $name (sort keys %defs) {
    my $table = _def2table($name, $defs{$name}, $schema);
    DEBUG and _debug("table", $table);
  }
  1;
}

=encoding utf-8

=head1 NAME

SQL::Translator::Parser::OpenAPI - convert OpenAPI schema to SQL::Translator schema

=begin markdown

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.org/mohawk2/SQL-Translator-Parser-OpenAPI.svg?branch=master)](https://travis-ci.org/mohawk2/SQL-Translator-Parser-OpenAPI) |

[![CPAN version](https://badge.fury.io/pl/SQL-Translator-Parser-OpenAPI.svg)](https://metacpan.org/pod/SQL::Translator::Parser::OpenAPI) [![Coverage Status](https://coveralls.io/repos/github/mohawk2/SQL-Translator-Parser-OpenAPI/badge.svg?branch=master)](https://coveralls.io/github/mohawk2/SQL-Translator-Parser-OpenAPI?branch=master)

=end markdown

=head1 SYNOPSIS

  use SQL::Translator;
  use SQL::Translator::Parser::OpenAPI;

  my $translator = SQL::Translator->new;
  $translator->parser("OpenAPI");
  $translator->producer("YAML");
  $translator->translate($file);

  # or...
  $ sqlt -f OpenAPI -t MySQL <my-openapi.json >my-mysqlschema.sql

=head1 DESCRIPTION

This module implements a L<SQL::Translator::Parser> to convert
a L<JSON::Validator::OpenAPI> specification to a L<SQL::Translator::Schema>.

It uses, from the given API spec, the given "definitions" to generate
tables in an RDBMS with suitable columns and types.

To try to make the data model represent the "real" data, it applies heuristics:

=over

=item *

to remove object definitions that only have one property

=item *

to find object definitions that have all the same properties as another,
and remove all but the shortest-named one

=item *

to remove object definitions whose properties are a strict subset
of another

=back

=head1 ARGUMENTS

None at present.

=head1 PACKAGE FUNCTIONS

=head2 parse

Standard as per L<SQL::Translator::Parser>. The input $data is a scalar
that can be understood as a L<JSON::Validator
specification|JSON::Validator/schema>.

=head1 DEBUGGING

To debug, set environment variable C<SQLTP_OPENAPI_DEBUG> to a true value.

=head1 AUTHOR

Ed J, C<< <etj at cpan.org> >>

=head1 LICENSE

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<SQL::Translator>.

L<SQL::Translator::Parser>.

L<JSON::Validator::OpenAPI>.

=cut

1;
