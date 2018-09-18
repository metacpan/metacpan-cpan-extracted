package SQL::Translator::Parser::OpenAPI;
use 5.008001;
use strict;
use warnings;
use JSON::Validator::OpenAPI;

our $VERSION = "0.04";
use constant DEBUG => $ENV{SQLTP_OPENAPI_DEBUG};
use String::CamelCase qw(camelize decamelize wordsplit);
use Lingua::EN::Inflect::Number qw(to_PL to_S);
use SQL::Translator::Schema::Constants;
use Math::BigInt;

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
my %SQL2TYPE = reverse %TYPE2SQL; # unreliable order but ok as still reversible

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
  my @thin = grep { keys(%{ $defs->{$_}{properties} }) == 1 } keys %$defs;
  if (DEBUG) {
    _debug("OpenAPI($_) thin, ignoring", $defs->{$_}{properties})
      for sort @thin;
  }
  @thin;
}

# heuristic 2: find objects with same propnames, drop those with longer names
sub _strip_dup {
  my ($defs, $def2mask, $reffed) = @_;
  my %sig2names;
  push @{ $sig2names{$def2mask->{$_}} }, $_ for keys %$def2mask;
  DEBUG and _debug("OpenAPI sig2names", \%sig2names);
  my @nondups = grep @{ $sig2names{$_} } == 1, keys %sig2names;
  delete @sig2names{@nondups};
  my @dups;
  for my $sig (keys %sig2names) {
    next if grep $reffed->{$_}, @{ $sig2names{$sig} };
    my @names = sort { (length $a <=> length $b) } @{ $sig2names{$sig} };
    DEBUG and _debug("OpenAPI dup($sig)", \@names);
    shift @names; # keep the first i.e. shortest
    push @dups, @names;
  }
  DEBUG and _debug("dup ret", \@dups);
  @dups;
}

# sorted list of all propnames
sub _get_all_propnames {
  my ($defs) = @_;
  my %allprops;
  for my $defname (keys %$defs) {
    $allprops{$_} = 1 for keys %{ $defs->{$defname}{properties} };
  }
  [ sort keys %allprops ];
}

sub defs2mask {
  my ($defs) = @_;
  my $allpropnames = _get_all_propnames($defs);
  my $count = 0;
  my %prop2count;
  for my $propname (@$allpropnames) {
    $prop2count{$propname} = $count;
    $count++;
  }
  my %def2mask;
  for my $defname (keys %$defs) {
    $def2mask{$defname} ||= Math::BigInt->new(0);
    $def2mask{$defname} |= (Math::BigInt->new(1) << $prop2count{$_})
      for keys %{ $defs->{$defname}{properties} };
  }
  \%def2mask;
}

# heuristic 3: find objects with set of propnames that is subset of
#   another object's propnames
sub _strip_subset {
  my ($defs, $def2mask, $reffed) = @_;
  my %subsets;
  for my $defname (keys %$defs) {
    DEBUG and _debug("_strip_subset $defname maybe", $reffed);
    next if $reffed->{$defname};
    my $thismask = $def2mask->{$defname};
    for my $supersetname (grep $_ ne $defname, keys %$defs) {
      my $supermask = $def2mask->{$supersetname};
      next unless ($thismask & $supermask) == $thismask;
      DEBUG and _debug("mask $defname subset $supersetname");
      $subsets{$defname} = 1;
    }
  }
  my @subset = keys %subsets;
  DEBUG and _debug("subset ret", [ sort @subset ]);
  @subset;
}

sub _prop2sqltype {
  my ($prop) = @_;
  my $format_type = $prop->{format} || $prop->{type};
  my $lookup = $TYPE2SQL{$format_type || ''};
  DEBUG and _debug("_prop2sqltype($format_type)($lookup)", $prop);
  my %retval = (data_type => $lookup);
  if (@{$prop->{enum} || []}) {
    $retval{data_type} = 'enum';
    $retval{extra} = { list => [ @{$prop->{enum}} ] };
  }
  DEBUG and _debug("_prop2sqltype(end)", \%retval);
  \%retval;
}

sub _make_not_null {
  my ($table, $field_in) = @_;
  my @fields = ref($field_in) eq 'ARRAY' ? @$field_in : $field_in;
  for my $field (@fields) {
    $field->is_nullable(0);
  }
  $table->add_constraint(type => $_, fields => \@fields)
    for (NOT_NULL);
}

sub _make_pk {
  my ($table, $field_in) = @_;
  my @fields = ref($field_in) eq 'ARRAY' ? @$field_in : $field_in;
  $_->is_primary_key(1) for @fields;
  $fields[0]->is_auto_increment(1) if @fields == 1;
  $table->add_constraint(type => $_, fields => \@fields)
    for (PRIMARY_KEY);
  my $index = $table->add_index(
    name => join('_', 'pk', map $_->name, @fields),
    fields => \@fields,
  );
  _make_not_null($table, \@fields);
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
  my ($schema, $fromtable, $fromkey, $totable, $tokey, $required) = @_;
  DEBUG and _debug("_fk_hookup $fromtable.$fromkey $totable.$tokey $required");
  my $from_obj = $schema->get_table($fromtable);
  my $to_obj = $schema->get_table($totable);
  my $tokey_obj = $to_obj->get_field($tokey);
  my $field = $from_obj->get_field($fromkey) || $from_obj->add_field(
    name => $fromkey, data_type => $tokey_obj->data_type,
  );
  die $from_obj->error if !$field;
  _make_fk($from_obj, $field, $totable, $tokey);
  _make_not_null($from_obj, $field) if $required;
  $field;
}

sub _def2table {
  my ($name, $def, $schema, $m2m) = @_;
  my $props = $def->{properties};
  my $tname = _def2tablename($name);
  DEBUG and _debug("_def2table($name)($tname)($m2m)", $props);
  my $table = $schema->add_table(
    name => $tname, comments => $def->{description},
  );
  if (!$props->{id} and !$m2m) {
    # we need a relational id
    $props->{id} = { type => 'integer' };
  }
  my %prop2required = map { ($_ => 1) } @{ $def->{required} || [] };
  my (@fixups);
  for my $propname (sort keys %$props) {
    my $field;
    my $thisprop = $props->{$propname};
    DEBUG and _debug("_def2table($propname)");
    if (my $ref = $thisprop->{'$ref'}) {
      push @fixups, {
        from => $tname,
        fromkey => $propname . '_id',
        to => _def2tablename(_ref2def($ref)),
        tokey => 'id',
        required => $prop2required{$propname},
        type => 'one',
      };
    } elsif (($thisprop->{type} // '') eq 'array') {
      if (my $ref = $thisprop->{items}{'$ref'}) {
        push @fixups, {
          from => _ref2def(_def2tablename($ref)),
          fromkey => to_S($propname) . "_id",
          to => $tname,
          tokey => 'id',
          required => 1,
          type => 'many',
        };
      }
      DEBUG and _debug("_def2table(array)($propname)", \@fixups);
    } else {
      my $sqltype = _prop2sqltype($thisprop);
      $field = $table->add_field(
        name => $propname, %$sqltype, comments => $thisprop->{description},
      );
      if ($propname eq 'id') {
        _make_pk($table, $field);
      }
    }
    if ($field and $prop2required{$propname} and $propname ne 'id') {
      _make_not_null($table, $field);
    }
  }
  if ($m2m) {
    _make_pk($table, scalar $table->get_fields);
  }
  DEBUG and _debug("table", $table, \@fixups);
  ($table, \@fixups);
}

# mutates $def
sub _merge_one {
  my ($def, $from, $ignore_required) = @_;
  DEBUG and _debug('OpenAPI._merge_one', $def, $from);
  push @{ $def->{required} }, @{ $from->{required} || [] } if !$ignore_required;
  $def->{properties} = { %{$def->{properties} || {}}, %{$from->{properties}} };
  $def->{type} = $from->{type} if $from->{type};
}

sub _merge_allOf {
  my ($defs) = @_;
  DEBUG and _debug('OpenAPI._merge_allOf', $defs);
  my %def2discrim = map {
    ($_ => 1)
  } grep $defs->{$_}{discriminator}, keys %$defs;
  my %def2referrers;
  for my $defname (sort keys %$defs) {
    my $thisdef = $defs->{$defname};
    next if !exists $thisdef->{allOf};
    for my $partial (@{ $thisdef->{allOf} }) {
      next if !(my $ref = $partial->{'$ref'});
      push @{ $def2referrers{_ref2def($ref)} }, $defname;
    }
  }
  DEBUG and _debug('OpenAPI._merge_allOf(def2referrers)', \%def2referrers);
  my %newdefs;
  my %def2ignore;
  for my $defname (sort grep $def2discrim{$_}, keys %def2referrers) {
    # assimilate instead of be assimilated by
    $def2ignore{$defname} = 1;
    my $thisdef = $defs->{$defname};
    my %new = %$thisdef;
    for my $assimilee (@{ $def2referrers{$defname} }) {
      $def2ignore{$assimilee} = 1;
      my $assimileedef = $defs->{$assimilee};
      my @all = @{ $assimileedef->{allOf} };
      for my $partial (@all) {
        next if exists $partial->{'$ref'};
        _merge_one(\%new, $partial, 1);
      }
    }
    $newdefs{$defname} = \%new;
  }
  for my $defname (sort grep !$def2ignore{$_}, keys %$defs) {
    my $thisdef = $defs->{$defname};
    my %new = %$thisdef;
    if (exists $thisdef->{allOf}) {
      my @all = @{ delete $thisdef->{allOf} };
      for my $partial (@all) {
        if (exists $partial->{'$ref'}) {
          _merge_one(\%new, $defs->{ _ref2def($partial->{'$ref'}) }, 0);
        } else {
          _merge_one(\%new, $partial, 0);
        }
      }
    }
    $newdefs{$defname} = \%new;
  }
  DEBUG and _debug('OpenAPI._merge_allOf(end)', \%newdefs);
  \%newdefs;
}

sub _find_referenced {
  my ($defs) = @_;
  DEBUG and _debug('OpenAPI._find_referenced', $defs);
  my %reffed;
  for my $defname (sort keys %$defs) {
    my $theseprops = $defs->{$defname}{properties} || {};
    for my $propname (keys %$theseprops) {
      if (my $ref = $theseprops->{$propname}{'$ref'}
        || ($theseprops->{$propname}{items} && $theseprops->{$propname}{items}{'$ref'})
      ) {
        $reffed{ _ref2def($ref) } = 1;
      }
    }
  }
  DEBUG and _debug('OpenAPI._find_referenced(end)', \%reffed);
  \%reffed;
}

sub _extract_objects {
  my ($defs) = @_;
  DEBUG and _debug('OpenAPI._extract_objects', $defs);
  my %newdefs = %$defs;
  for my $defname (sort keys %$defs) {
    my $theseprops = $defs->{$defname}{properties} || {};
    for my $propname (keys %$theseprops) {
      my $thisprop = $theseprops->{$propname};
      next if $thisprop->{'$ref'}
        or $thisprop->{items} && $thisprop->{items}{'$ref'};
      my $ref;
      if (($thisprop->{type} // '') eq 'object') {
        $ref = $thisprop;
      } elsif (
        $thisprop->{items} && ($thisprop->{items}{type} // '') eq 'object'
      ) {
        $ref = $thisprop->{items};
      } else {
        next;
      }
      my $newtype = join '', map camelize($_), $defname, $propname;
      $newdefs{$newtype} = { %$ref };
      %$ref = ('$ref' => "#/definitions/$newtype");
    }
  }
  DEBUG and _debug('OpenAPI._extract_objects(end)', [ sort keys %newdefs ], \%newdefs);
  \%newdefs;
}

sub _extract_array_simple {
  my ($defs) = @_;
  DEBUG and _debug('OpenAPI._extract_array_simple', $defs);
  my %newdefs = %$defs;
  for my $defname (sort keys %$defs) {
    my $theseprops = $defs->{$defname}{properties} || {};
    for my $propname (keys %$theseprops) {
      my $thisprop = $theseprops->{$propname};
      next if $thisprop->{'$ref'};
      next unless
        $thisprop->{items} && ($thisprop->{items}{type} // '') ne 'object';
      my $ref = $thisprop->{items};
      my $newtype = join '', map camelize($_), $defname, $propname;
      $newdefs{$newtype} = {
        type => 'object',
        properties => {
          value => { %$ref }
        },
        required => [ 'value' ],
      };
      %$ref = ('$ref' => "#/definitions/$newtype");
    }
  }
  DEBUG and _debug('OpenAPI._extract_array_simple(end)', [ sort keys %newdefs ], \%newdefs);
  \%newdefs;
}

sub _fixup_addProps {
  my ($defs) = @_;
  DEBUG and _debug('OpenAPI._fixup_addProps', $defs);
  my %def2aP = map {$_,1} grep $defs->{$_}{additionalProperties}, keys %$defs;
  DEBUG and _debug("OpenAPI._fixup_addProps(d2aP)", \%def2aP);
  for my $defname (sort keys %$defs) {
    my $theseprops = $defs->{$defname}{properties} || {};
    DEBUG and _debug("OpenAPI._fixup_addProps(arrayfix)($defname)", $theseprops);
    for my $propname (keys %$theseprops) {
      my $thisprop = $theseprops->{$propname};
      DEBUG and _debug("OpenAPI._fixup_addProps(p)($propname)", $thisprop);
      next unless $thisprop->{'$ref'}
        or $thisprop->{items} && $thisprop->{items}{'$ref'};
      DEBUG and _debug("OpenAPI._fixup_addProps(p)($propname)(y)");
      my $ref;
      if ($thisprop->{'$ref'}) {
        $ref = $thisprop;
      } elsif ($thisprop->{items} && $thisprop->{items}{'$ref'}) {
        $ref = $thisprop->{items};
      } else {
        next;
      }
      my $refname = $ref->{'$ref'};
      DEBUG and _debug("OpenAPI._fixup_addProps(p)($propname)(y2)($refname)", $ref);
      next if !$def2aP{_ref2def($refname)};
      %$ref = (type => 'array', items => { '$ref' => $refname });
      DEBUG and _debug("OpenAPI._fixup_addProps(p)($propname)(y3)", $ref);
    }
  }
  my %newdefs = %$defs;
  for my $defname (keys %def2aP) {
    my %kv = (type => 'object', properties => {
      key => { type => 'string' },
      value => { type => $defs->{$defname}{additionalProperties}{type} },
    });
    $newdefs{$defname} = \%kv;
  }
  DEBUG and _debug('OpenAPI._fixup_addProps(end)', \%newdefs);
  \%newdefs;
}

sub _absorb_nonobject {
  my ($defs) = @_;
  DEBUG and _debug('OpenAPI._absorb_nonobject', $defs);
  my %def2nonobj = map {$_,1} grep $defs->{$_}{type} ne 'object', keys %$defs;
  DEBUG and _debug("OpenAPI._absorb_nonobject(d2nonobj)", \%def2nonobj);
  for my $defname (sort keys %$defs) {
    my $theseprops = $defs->{$defname}{properties} || {};
    DEBUG and _debug("OpenAPI._absorb_nonobject(t)($defname)", $theseprops);
    for my $propname (keys %$theseprops) {
      my $thisprop = $theseprops->{$propname};
      DEBUG and _debug("OpenAPI._absorb_nonobject(p)($propname)", $thisprop);
      next unless $thisprop->{'$ref'}
        or $thisprop->{items} && $thisprop->{items}{'$ref'};
      DEBUG and _debug("OpenAPI._absorb_nonobject(p)($propname)(y)");
      my $ref;
      if ($thisprop->{'$ref'}) {
        $ref = $thisprop;
      } elsif ($thisprop->{items} && $thisprop->{items}{'$ref'}) {
        $ref = $thisprop->{items};
      } else {
        next;
      }
      my $refname = $ref->{'$ref'};
      DEBUG and _debug("OpenAPI._absorb_nonobject(p)($propname)(y2)($refname)", $ref);
      my $refdef = _ref2def($refname);
      next if !$def2nonobj{$refdef};
      %$ref = %{ $defs->{$refdef} };
      DEBUG and _debug("OpenAPI._absorb_nonobject(p)($propname)(y3)", $ref);
    }
  }
  my %newdefs = %$defs;
  delete @newdefs{ keys %def2nonobj };
  DEBUG and _debug('OpenAPI._absorb_nonobject(end)', \%newdefs);
  \%newdefs;
}

sub _tuple2name {
  my ($fixup) = @_;
  my $from = $fixup->{from};
  my $fromkey = $fixup->{fromkey};
  $fromkey =~ s#_id$##;
  camelize join '_', map to_S($_), $from, $fromkey;
}

sub _make_many2many {
  my ($fixups, $schema) = @_;
  DEBUG and _debug("tables to do", $fixups);
  my @manyfixups = grep $_->{type} eq 'many', @$fixups;
  my %from_tos;
  push @{ $from_tos{$_->{from}}{$_->{to}} }, $_ for @manyfixups;
  my %to_froms;
  push @{ $to_froms{$_->{to}}{$_->{from}} }, $_ for @manyfixups;
  my %m2m;
  my %ref2nonm2mfixup;
  $ref2nonm2mfixup{$_} = $_ for @$fixups;
  for my $from (keys %from_tos) {
    for my $to (keys %{ $from_tos{$from} }) {
      for my $fixup (@{ $from_tos{$from}{$to} }) {
        for my $other (@{ $to_froms{$from}{$to} }) {
          my ($f1, $f2) = sort { $a->{from} cmp $b->{from} } $fixup, $other;
          $m2m{_tuple2name($f1)}{_tuple2name($f2)} = [ $f1, $f2 ];
          delete $ref2nonm2mfixup{$_} for $f1, $f2;
        }
      }
    }
  }
  my @replacefixups;
  for my $n1 (sort keys %m2m) {
    for my $n2 (sort keys %{ $m2m{$n1} }) {
      my ($f1, $f2) = @{ $m2m{$n1}{$n2} };
      my ($t1_obj, $t2_obj) = map $schema->get_table($_->{to}), $f1, $f2;
      my ($table) = _def2table(
        $n1.$n2,
        {
          type => 'object',
          properties => {
            $f1->{fromkey} => {
              type => $SQL2TYPE{$t1_obj->get_field($f1->{tokey})->data_type}
            },
            $f2->{fromkey} => {
              type => $SQL2TYPE{$t2_obj->get_field($f2->{tokey})->data_type}
            },
          },
        },
        $schema,
        1,
      );
      push @replacefixups, {
        to => $f1->{from},
        tokey => 'id',
        from => $table->name,
        fromkey => $f1->{fromkey},
        required => 1,
      }, {
        to => $f2->{from},
        tokey => 'id',
        from => $table->name,
        fromkey => $f2->{fromkey},
        required => 1,
      };
    }
  }
  my @newfixups = (
    (sort {
        $a->{from} cmp $b->{from} || $a->{fromkey} cmp $b->{fromkey}
    } values %ref2nonm2mfixup),
    @replacefixups,
  );
  DEBUG and _debug("fixups still to do", \@newfixups);
  \@newfixups;
}

sub parse {
  my ($tr, $data) = @_;
  my $openapi_schema = JSON::Validator::OpenAPI->new->schema($data)->schema;
  my %defs = %{ $openapi_schema->get("/definitions") };
  DEBUG and _debug('OpenAPI.definitions', \%defs);
  my $schema = $tr->schema;
  DEBUG and $schema->translator(undef); # reduce debug output
  my @thin = _strip_thin(\%defs);
  DEBUG and _debug("thin ret", \@thin);
  delete @defs{@thin};
  %defs = %{ _merge_allOf(\%defs) };
  my $def2mask = defs2mask(\%defs);
  my $reffed = _find_referenced(\%defs);
  my @dup = _strip_dup(\%defs, $def2mask, $reffed);
  delete @defs{@dup};
  my @subset = _strip_subset(\%defs, $def2mask, $reffed);
  delete @defs{@subset};
  %defs = %{ _extract_objects(\%defs) };
  %defs = %{ _extract_array_simple(\%defs) };
  my (@fixups);
  %defs = %{ _fixup_addProps(\%defs) };
  %defs = %{ _absorb_nonobject(\%defs) };
  for my $name (sort keys %defs) {
    my ($table, $thesefixups) = _def2table($name, $defs{$name}, $schema, 0);
    push @fixups, @$thesefixups;
  }
  my ($newfixups) = _make_many2many(\@fixups, $schema);
  for my $fixup (@$newfixups) {
    _fk_hookup($schema, @{$fixup}{qw(from fromkey to tokey required)});
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

to remove object definitions that only have one property (which the
author calls "thin objects")

=item *

for definitions that have C<allOf>, either merge them together if there
is a C<discriminator>, or absorb properties from referred definitions

=item *

to find object definitions that have all the same properties as another,
and remove all but the shortest-named one

=item *

to remove object definitions whose properties are a strict subset
of another

=item *

creates object definitions for any properties that are an object

=item *

creates object definitions for any properties that are an array of simple
OpenAPI types (e.g. C<string>)

=item *

creates object definitions for any objects that are
C<additionalProperties> (i.e. freeform key/value pairs), that are
key/value rows

=item *

absorbs any definitions that are in fact not objects, into the referring
property

=item *

injects foreign-key relationships for array-of-object properties, and
creates many-to-many tables for any two-way array relationships

=back

=head1 ARGUMENTS

None at present.

=head1 PACKAGE FUNCTIONS

=head2 parse

Standard as per L<SQL::Translator::Parser>. The input $data is a scalar
that can be understood as a L<JSON::Validator
specification|JSON::Validator/schema>.

=head2 defs2mask

Given a hashref that is a JSON pointer to an OpenAPI spec's
C</definitions>, returns a hashref that maps each definition name to a
bitmask. The bitmask is set from each property name in that definition,
according to its order in the complete sorted list of all property names
in the definitions. Not exported. E.g.

  # properties:
  my $defs = {
    d1 => {
      properties => {
        p1 => 'string',
        p2 => 'string',
      },
    },
    d2 => {
      properties => {
        p2 => 'string',
        p3 => 'string',
      },
    },
  };
  my $mask = SQL::Translator::Parser::OpenAPI::defs2mask($defs);
  # all prop names, sorted: qw(p1 p2 p3)
  # $mask:
  {
    d1 => (1 << 0) | (1 << 1),
    d2 => (1 << 1) | (1 << 2),
  }

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
