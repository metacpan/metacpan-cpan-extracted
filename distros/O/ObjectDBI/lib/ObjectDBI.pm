package ObjectDBI;

use DBI;
use DBI::Const::GetInfoType;

use 5.008008;
our $VERSION = '0.15';

=head1 NAME

ObjectDBI - Perl Object Persistence in an RDBMS using DBI

=head1 SYNOPSIS

Serializes, queries, unserializes and deletes perl objects in an SQL driven,
DBI accessible RDBMS.

=head1 MODULE

Created to use RDBMS-es as perl object storage, even when very primitive
RDBMS-es are involved.  The advantage is portability of your project
(you don't have to transport a dbm or flat files with your project that
is also RDBMS-based), a certain degree of discoverability
(you can use plain SQL yourself to see what's inside the database), and
searchability (metadata and data don't get equated).  You must create
a table for this storage, and (an idea for) the SQL for that is given below:

=head1 SQL

PostgreSQL or Oracle:

  create sequence perlobjectseq;

  create table "perlobjects" (
    obj_id integer unique not null,
    obj_pid integer references perlobjects (obj_id),
    obj_gpid integer references perlobjects (obj_id),
    obj_name varchar(255),
    obj_type varchar(64),
    obj_value varchar(255)
  );

MySQL:

  create table perlobjects (
    obj_id integer unique not null auto_increment,
    obj_pid integer references perlobjects (obj_id),
    obj_gpid integer references perlobjects (obj_id),
    obj_name varchar(255),
    obj_type varchar(64),
    obj_value varchar(255)
  );

Indexes:

  create index perlobjects_name_i on perlobjects (obj_name);
  create index perlobjects_type_i on perlobjects (obj_type);
  create index perlobjects_value_i on perlobjects (obj_value);
  create index perlobjects_pid_i on perlobjects (obj_pid);
  create index perlobjects_gpid_i on perlobjects (obj_gpid);

Now before y'all start shouting;
obviously, given your particular type of RDBMS, your mileage may vary
with respect to this SQL code, and you may not have primary or foreign
keys.  You may not have indexes or sequences, and you may even have an easier
way to store infinite strings.  This is all up to you, your cleverness and your
needs.

If you plan to store perlhashes with keys of more than 255 character length
(which is an unwise thing in itself), for example, then you might consider
making 'obj_name' a bit longer.  If you plan to store values with characters
outside of the 32-126 range and you're using Postgres, then you might want
to change the data type of 'obj_value' from 'varchar' to 'bytea'.
This module isn't here to lecture you - just to make things easy.

If you're using MySQL, you'll have problems without a sequence, so you'll
have to make the 'obj_id' field auto-incrementing.  For those users,
a special piece of code is added to withdraw the id of an
object after the fact of its insertion.

If you're using a RDBMS that doesn't do sequences OR auto-incrementing,
then IDs are generated out of thin air.  Be prepared to work with large
numbers though.  If your RDBMS can't handle those - well, then I'm at
my wit's end: please provide a 'sequencefnc' to the constructor.

=head1 API

=head2 B<my $objectdbi = ObjectDBI-E<gt>new (%options)>

Returns a blessed instance of this module.
The arguments provide the object with a hash of options, which can be:

  'dbh' => DBI database handle.
  'dbiuri' => DBI database connection URI.
  'dbiuser' => DBI database connection user.
  'dbipass' => DBI database connection password.
  'dbioptions' => DBI database connection options.
  'table' => Table name used ('perlobjects' is the default).
  'sequence' => Sequence name for easily retrieving new IDs.
  'sequencesql' => Sequence SQL for retrieving a new ID.
  'sequencefnc' => A function ref to be used to retrieve a new ID.
  'overwrite' => Overwrite objects of the same type and name.
  'chunksize' => A number defining at what length values will get split.
  'debug' => Setting it at anything will make STDERR a busy stream.

About sequences: the first available method given will be used.  So please
do yourself a favour, avoid confusion, and use only one of the available
methods out of 'sequence', 'sequencesql' and 'sequencefnc'.

About chunksize: the default value is 255.  If you set it to zero, that'll
be interpreted as 'infinite'.  If you set it to anything else, make sure
it matches the storage size of the 'obj_value' field in the RDBMS.

Also about both sequences and chunksize: in the case of postgres and oracle,
autodiscovery of these items will be performed in case they're not given.

=cut

sub new {
  my $class = shift;
  my $classname = ref($class) || $class;
  my $self = {};
  my %options = @_;
  $self->{objtable} = $options{table} || 'perlobjects';
  if ($options{dbh}) {
    $self->{dbh} = $options{dbh};
  } else {
    $self->{dbh} = DBI->connect(
      $options{dbiuri},
      $options{dbiuser},
      $options{dbipass},
      $options{dbioptions}
    );
  }
  return undef if (!defined($self->{dbh}));
  $self->{sequence} = $options{sequence};
  $self->{sequencesql} = $options{sequencesql};
  $self->{sequencefnc} = $options{sequencefnc};
  $self->{overwrite} = $options{overwrite};
  $self->{chunksize} = $options{chunksize};
  $self->{dbtype} = $self->{dbh}->get_info($GetInfoType{SQL_DBMS_NAME});
  $self->{debug} = $options{debug};
  bless $self, $classname;
  $self->__auto_discover();
  return $self;
}

=head2 B<my $id = $objectdbi-E<gt>put ($ref[,$name[,$overwrite]])>

Store a reference in the database, perhaps under a certain name.
If 'overwrite' is set (either in the object or as a parameter),
and the object with given type and name already
exists, it is removed prior to this object being written.
Returns the ID of the object of the newly created object.

=cut

sub put {
  my $self = shift;
  my $ref = shift;
  my $name = shift;
  my $overwrite = shift;
  if (ref($name)) {
    $name = "$name";
  }
  if (!defined($overwrite)) { $overwrite = $self->{overwrite}; }
  my @ids;
  if ($overwrite) {
    @ids = $self->__objects_find(ref($ref), $name);
  }
  my $id = $self->__put(undef, undef, $name, $ref, {});
  if ($id) {
    $self->del_all(@ids);
  }
  return $id;
}

=head2 B<my @ids = $objectdbi-E<gt>find ([$type],[$name],[$value])>

Find IDs for objects that match type and/or name and/or value.

=cut

sub find {
  my $self = shift;
  my ($type, $name, $value) = @_;
  if (ref($type)) { $type = ref($type); }
  my @ids = $self->__objects_search($type, $name, $value);
  return wantarray ? @ids : \@ids;
}

=head2 B<my $ref = $objectdbi-E<gt>get ($id) or $objectdbi-E<gt>get ($type, $name)>

Returns the fully deserialized object with the given ID, or
find the first object that matches type and name.

=cut

sub get {
  my $self = shift;
  my $id = shift;
  if (scalar(@_) eq '1' && $id !~ /^[0-9]+$/) {
    my $name = shift;
    my $type = ref($id) ? ref($id) : $id;
    $id = $self->__objects_find($type, $name);
  }
  my $rows = $self->__object_get($id);
  my $parent = $self->__get_children($rows, undef);
  return $self->__get($rows, $parent->[0], {});
}

=head2 B<my ($type, $name, $id) = $objectdbi-E<gt>get_meta ($id)>

Returns an array of type and name for an object with given ID.

=cut

sub get_meta {
  my $self = shift;
  my $id = shift;
  return $self->__object_get_meta($id);
}

=head2 B<my @refs = $objectdbi-E<gt>get_all (@ids)>

Auxillary method.
Returns an array or array reference of objects with the given IDs.

=cut

sub get_all {
  my $self = shift;
  my @result;
  foreach my $id (@_) {
    my $object = $self->get($id);
    push @result, $object;
  }
  return wantarray ? @result : \@result;
}

=head2 B<my @ids = $objectdbi-E<gt>query ($querystring)>

Queries the database with a specific query string.  The syntax for this
query 'language' is as follows:

=over

=item

expressions are separated by logical operators ('&&', '||')
and round braces ('(' and ')') determine precedence.

=item

expressions are made up of a path, and optionally an operator ('==', '!=')
and a value.

=item

a path is a series of elements, representing hash-keys or array-indexes
separated by a forward slash ('/').

=item

both paths and values may be enclosed in single or double quotes, so as to
forego escaping of certain characters or whitespace.

=item

an element can have wildcards (an asterisk ('*')), or be a wildcard in itself.

=item

a back slash escapes all tokens, one character at a time.

=item

outside of quoted strings and path elements, whitespace is ignored.

=back

=cut

sub query {
  my $self = shift;
  my $query = shift;
  return $self->__query($query);
}

=head2 B<my @types = $objectdbi-E<gt>get_types ()>

Returns a distinct list of all object types known to the database.

=cut

sub get_types {
  my $self = shift;
  return $self->__object_get_types();
}

=head2 B<my $n = $objectdbi-E<gt>del ($id) or $objectdbi-E<gt>del ($type, $name)>

Deletes an object by the given ID, or deletes the first object which
matches type and name.  Returns zero or non zero depending on whether
the operation failed or was successful, respectively.

=cut

sub del {
  my $self = shift;
  my $id = shift;
  if (scalar(@_) eq '1' && $id !~ /^[0-9]+$/) {
    my $name = shift;
    my $type = ref($id) ? ref($id) : $id;
    $id = $self->__objects_find($type, $name);
  }
  $self->__del($id);
}

=head2 B<my $n = $objectdbi-E<gt>del_all (@ids)>

Auxillary method.
Deletes all objects with given IDs.

=cut

sub del_all {
  my $self = shift;
  my $n = 0;
  foreach my $id (@_) {
    $n += $self->del($id);
  }
  return $n;
}

=head2 B<my $n = $objectdbi-E<gt>count ([type], [query])>

Returns the amount of objects that answer to these conditions.

=cut

sub count {
  my $self = shift;
  my ($type, $query);
  if (defined($_[0])) {
    $type = $_[0];
  }
  if (defined($_[1])) {
    $query = $_[1];
  }
  my @params;
  my $sql =
    "SELECT DISTINCT(TABLE1.obj_gpid)" .
    " from $self->{objtable} as TABLE1 where 1=1";
  if ($query) {
    my @tokens = ObjectDBI::__tokenize_query($query);
    my $parsetree = ObjectDBI::__parse_query(@tokens) || return undef;
    ($sql, @params) = $self->__tree_to_sql($parsetree);
  }
  if ($type) {
    $sql =
      "SELECT DISTINCT(obj_gpid)" .
      " FROM $self->{objtable}" .
      " WHERE obj_type=?" .
      " AND obj_pid is null" .
      " INTERSECT " .
      $sql;
    unshift @params, $type;
  }
#  $sql =~ s/^SELECT DISTINCT/SELECT COUNT/;
  $sql = "SELECT COUNT(obj_gpid) FROM ($sql) FOO";
  if ($self->{debug}) {
    print STDERR "SQL: '$sql' with params: '" . join("', '", @params) . "'\n";
  }
  my $result = $self->get_dbh()->selectrow_array(
    $sql, undef, @params
  );
  return $result;
}

=head2 B<my $dbh = $objectdbi-E<gt>get_dbh ()>

Returns the DBI database handle.

=cut

sub get_dbh {
  my $self = shift;
  return $self->{dbh};
}

##---- private stuff -------------------------------------------------------##

sub __put {
  my $self = shift;
  my ($pid, $gpid, $name, $ref, $cache) = @_;
  my $type = ref($ref);
  my $id;
  if (!defined($ref)) {
    $id = $self->__object_put($pid, $gpid, $name, undef, undef);
  } elsif (my $cache_id = $cache->{"$ref"}) {
    $id = $self->__object_put($pid, $gpid, $name, '@@REF', $cache_id);
  } elsif (UNIVERSAL::isa($ref, 'ARRAY')) {
    $id = $self->__object_put($pid, $gpid, $name, $type, 'ARRAY') ||
      return undef;
    $cache->{"$ref"} = $id;
#    if (!defined($gpid)) { $gpid = $id; }
    if (!length($gpid)) { $gpid = $id; }
    for (my $i=0; $i<scalar(@{$ref}); $i++) {
      my $elt = $ref->[$i];
      return undef if (!$self->__put($id, $gpid, $i, $elt, $cache));
    }
  } elsif (UNIVERSAL::isa($ref, 'HASH')) {
    $cache->{"$ref"} = $id;
    $id = $self->__object_put($pid, $gpid, $name, $type, 'HASH') ||
      return undef;
#    if (!defined($gpid)) { $gpid = $id; }
    if (!length($gpid)) { $gpid = $id; }
    foreach my $key (keys(%{$ref})) {
      return undef if (!$self->__put($id, $gpid, $key, $ref->{$key}, $cache));
    }
  } else {
    my $value = "$ref";
    if ($self->{chunksize} && length($value) > $self->{chunksize}) {
      $id = $self->__object_put($pid, $gpid, $name, '@@SUBSTR', '') ||
        return undef;
#      if (!defined($gpid)) { $gpid = $id; }
      if (!length($gpid)) { $gpid = $id; }
      my $section = 0;
      while (length($value) > $self->{chunksize}) {
        my $subvalue = substr($value, 0, $self->{chunksize});
        $value = substr($value, $self->{chunksize});
        $self->__object_put($id, $gpid, $section++, undef, $subvalue) ||
          return undef;
      }
      $self->__object_put($id, $gpid, $section++, undef, $value) ||
        return undef;
    } else {
      $id = $self->__object_put($pid, $gpid, $name, undef, "$ref") ||
        return undef;
#      if (!defined($gpid)) { $gpid = $id; }
      if (!length($gpid)) { $gpid = $id; }
    }
  }
  return $id;
}

sub __get_children {
  my $self = shift;
  my $rows = shift;
  my $pid = shift;
  my @result;
  for (my $i=0; $i<scalar(@{$rows}); $i++) {
    my $row = $rows->[$i];
    if ($row->{pid} eq $pid) {
      push @result, splice(@{$rows}, $i--, 1);
    }
  }
  @result = sort { $a->{id} <=> $b->{id} } @result;
  return \@result;
}

sub __get {
  my $self = shift;
  my $rows = shift;
  my $row = shift;
  my $cache = shift;
  my $object;
  if ($row->{type} && $row->{value} eq 'ARRAY') {
    $object = [];
    $cache->{$row->{id}} = $object;
    if ($row->{type} ne $row->{value}) {
      bless $object, $row->{type};
    }
    my $subrows = $self->__get_children($rows, $row->{id});
    foreach my $subrow (@{$subrows}) {
      $object->[int($subrow->{name})] = $self->__get($rows, $subrow, $cache);
    }
  } elsif ($row->{type} && $row->{value} eq 'HASH') {
    $object = {};
    $cache->{$row->{id}} = $object;
    if ($row->{type} ne $row->{value}) {
      bless $object, $row->{type};
    }
    my $subrows = $self->__get_children($rows, $row->{id});
    foreach my $subrow (@{$subrows}) {
      $object->{$subrow->{name}} = $self->__get($rows, $subrow, $cache);
    }
  } elsif ($row->{type} eq '@@SUBSTR') {
    my $subrows = $self->__get_children($rows, $row->{id});
    my @subrows = sort { $a->{name} <=> $b->{name} } @{$subrows};
    my $value = '';
    foreach my $subrow (@subrows) {
      $value .= $subrow->{value};
    }
    return $value;
  } elsif ($row->{type} eq '@@REF') {
    return $cache->{$row->{value}};
#  } elsif (!defined($row->{type})) {
  } elsif (!length($row->{type})) {
    return $row->{value};
  }
  return wantarray ? ($object, $row->{name}) : $object;
}

sub __del {
  my $self = shift;
  my $id = shift;
  $self->__object_del($id);
}

sub __query {
  my $self = shift;
  my $query = shift;
  $self->__query_to_sql($query);
}

sub __tokenize_query {
  my $query = shift;
  my $curelt = '';
  my @tokens;
  while (length($query)) {
    if ($query =~ s/^\s+//) {
      if (length($curelt)) {
        push @tokens, $curelt;
        $curelt = '';
      }
    }
    if ($query =~ s/^(!=|==|\(|\)|&&|\|\||\/)//) {
      if (length($curelt)) {
        push @tokens, $curelt;
        $curelt = '';
      }
      push @tokens, $1;
    } elsif ($query =~ s/^([!=\(\)&\|])//) {
      $curelt .= $1;
    } elsif ($query =~ s/^(['"])//) {
      my $delim = $1;
      if (length($curelt)) {
        push @tokens, $curelt;
        $curelt = '';
      }
      while ($query =~ s/^([^$delim])//) {
        my $char = $1;
        if ($char eq '\\') {
          $query =~ s/^(.)//s;
          $curelt .= $1;
        } else {
          $curelt .= $char;
        }
      }
      $query =~ s/^.//;
    } else {
      while ($query =~ s/^([^!=\(\)&\|\/\s])//) {
        my $char = $1;
        if ($char eq '\\') {
          $query =~ s/^(.)//s;
          $curelt .= $1;
        } else {
          $curelt .= $char;
        }
      }
    }
  }
  if (length($curelt)) {
    push @tokens, $curelt;
  }
  return @tokens;
}

sub __parse_query {
  my @tokens = @_;
  my @operators = (
    '&&',
    '||',
    '==',
    '!=',
    '/',
  );
  foreach my $operator (@operators) {
    for (my $i=0; $i<scalar(@tokens); $i++) {
      my $token = $tokens[$i];
      next if (ref($token));
      if ($token eq '(') {
        my $begin = $i;
        my $level = 1;
        for (++$i; $i<scalar(@tokens); $i++) {
          my $token = $tokens[$i];
          if ($token eq '(') {
            ++$level;
          } elsif ($token eq ')') {
            if (--$level == 0) {
              my @bracketcontent = splice(@tokens, $begin, 1+$i-$begin);
              pop @bracketcontent;
              shift @bracketcontent;
              my $term = __parse_query(@bracketcontent) || return undef;
              $tokens[$begin] = $term;
              $i = $begin;
              last;
            }
          }
        }
        if ($level) {
          return undef; # unmatched brackets
        }
      } elsif ($token eq $operator) {
        my @operand2 = splice(@tokens, $i+1);
        my @operand1 = splice(@tokens, 0, $i);
        my $operand1 = __parse_query(@operand1) || return undef;
        my $operand2 = __parse_query(@operand2) || return undef;
        return {
          operator => $operator,
          operands => [ $operand1, $operand2 ]
        };
#      } elsif (!grep(@operators, $token)) {
#        $tokens[$i] = {
#          term => $token
#        };
      }
    }
  }
  return $tokens[0];
}

sub __tree_to_sql {
  my $self = shift;
  my $parsetree = shift;
  my $hash = shift;
  my $postprocess = 0;
  if (!defined($hash)) {
    $hash = { n => 1, tables => 1, param => 0, params => {} };
    $postprocess = 1;
  } 
  my $n = $hash->{n};
  my $result;
  if ($parsetree->{operator} eq '&&') {
    $n = $hash->{n} = 1;
    $result =
      (my $x = $self->__tree_to_sql($parsetree->{operands}[0], $hash)) .
      " AND 1=1";
    $n = $hash->{n} = 1;
    $result .=
      (my $x = $self->__tree_to_sql($parsetree->{operands}[1], $hash));
  } elsif ($parsetree->{operator} eq '||') {
    $n = $hash->{n} = 1;
    $result =
      "((1=1" .
      (my $x = $self->__tree_to_sql($parsetree->{operands}[0], $hash)) .
      ") OR (1=1";
    $n = $hash->{n} = 1;
    $result .=
      (my $x = $self->__tree_to_sql($parsetree->{operands}[1], $hash)) .
      "))";
  } elsif ($parsetree->{operator} eq '==') {
    my $operand = "$parsetree->{operands}[1]";
    my $operator = '=';
    if ($operand =~ s/\*/\%/g) {
      $operator = 'like';
    }
    $result =
      (my $x = $self->__tree_to_sql($parsetree->{operands}[0], $hash)) .
      " AND TABLE$n.obj_value $operator ?$hash->{param}";
    $hash->{params}{$hash->{param}++} = $operand;
  } elsif ($parsetree->{operator} eq '!=') {
    my $operand = "$parsetree->{operands}[1]";
    my $operator = '<>';
    if ($operand =~ s/\*/\%/g) {
      $operator = 'not like';
    }
    $result =
      (my $x = $self->__tree_to_sql($parsetree->{operands}[0], $hash)) .
      " AND TABLE$n.obj_value $operator ?$hash->{param}";
    $hash->{params}{$hash->{param}++} = $operand;
  } elsif ($parsetree->{operator} eq '/') {
    $result =
      "TABLE$n.obj_pid " .
      (my $x = $self->__tree_to_sql($parsetree->{operands}[1], $hash));
    if (++($hash->{n}) > $hash->{tables}) {
      $hash->{tables} = $hash->{n};
    }
    $result =
      (my $x = $self->__tree_to_sql($parsetree->{operands}[0], $hash)) .
      " AND TABLE$hash->{n}.obj_id=$result";
  } else {
    my $operand = "$parsetree";
    my $operator = '=';
    if ($operand =~ s/\*/\%/g) {
      $operator = 'like';
    }
    $result = " AND TABLE$n.obj_name $operator ?$hash->{param}";
    $hash->{params}{$hash->{param}++} = $operand;
  }
  my @params;
  if ($postprocess) {
    my @tables;
    for (my $i=1; $i<=$hash->{tables}; $i++) {
      push @tables, "$self->{objtable} TABLE$i";
    }
    my $tmp = $result;
    my $i=0;
    while ($tmp =~ s/^[^\?]*\?([0-9]+)//) {
      $params[$i++] = $hash->{params}{$1};
      $result =~ s/\?$1/?/;
    }
    $result =
      "SELECT DISTINCT(TABLE1.obj_gpid) FROM " . join(',', @tables) .
      " WHERE $result";
  }
  $result =~ s/where\s+and/where/i;
  $result =~ s/where\s+or/where/i;
  $result =~ s/1=1\s+and//i;
  if ($self->{debug}) {
    print STDERR "SQL: '$result' with params: '" . join("', '", @params) . "\n";
  }
  return wantarray ? ($result, @params) : $result;
}

sub __query_to_sql {
  my $self = shift;
  my $query = shift;
  my @tokens = __tokenize_query($query);
  my $parsetree = __parse_query(@tokens) || return undef;
  my ($sql, @params) = $self->__tree_to_sql($parsetree);
  return $self->__object_select_col($sql, @params);
}

##---- dbh stuff -----------------------------------------------------------##

##
## Function to do some auto discovery on known database types.
##

sub __auto_discover_postgres {
  my $self = shift;
  if (!defined($self->{sequence}) &&
      !defined($self->{sequencesql}) &&
      !defined($self->{sequencefnc})) {
    my $sequences = $self->{dbh}->selectcol_arrayref(
      "select relname from pg_class where relkind='S'"
    );
    if (scalar(@{$sequences})) {
      $self->{sequence} = $sequences->[0];
    } else {
      $self->{dbh}->do("create sequence perlobjectseq");
      $self->{sequence} = 'perlobjectseq';
    }
  }
  if (!defined($self->{chunksize})) {
    my $size = $self->{dbh}->selectrow_array(
      "select attlen from pg_attribute, pg_class" .
      " where pg_attribute.attrelid=pg_class.oid" .
      "   and pg_class.relkind='r'" .
      "   and pg_class.relname='$self->{objtable}'" .
      "   and pg_attribute.attname='obj_value'"
    );
    if ($size <= 0) {
      $self->{chunksize} = 0;
    } else {
      $self->{chunksize} = $size;
    }
  }
}

sub __auto_discover_oracle {
  my $self = shift;
  if (!defined($self->{sequence}) &&
      !defined($self->{sequencesql}) &&
      !defined($self->{sequencefnc})) {
    my $sequences = $self->{dbh}->selectcol_arrayref(
      "SELECT SEQUENCE_NAME FROM USER_SEQUENCES"
    );
    if (scalar(@{$sequences})) {
      $self->{sequence} = $sequences->[0];
    } else {
      $self->{dbh}->do("create sequence perlobjectseq");
      $self->{sequence} = 'perlobjectseq';
    }
  }
  if (!defined($self->{chunksize})) {
    my $size = $self->{dbh}->selectrow_array(
      "SELECT DATA_LENGTH FROM USER_TAB_COLUMNS" .
      " WHERE TABLE_NAME='$self->{objtable}'"
    );
    $self->{chunksize} = $size;
  }
}

sub __auto_discover_mysql {
  my $self = shift;
}

sub __auto_discover {
  my $self = shift;
  if ($self->{dbtype} =~ /^(postgresql|postgres|pg|pgsql)$/i) {
    if ($self->{debug}) {
      print STDERR "AUTODISCOVER PostgreSQL backend.\n";
    }
    $self->__auto_discover_postgres();
  } elsif ($self->{dbtype} =~ /^oracle$/i) {
    $self->__auto_discover_oracle();
    if ($self->{debug}) {
      print STDERR "AUTODISCOVER Oracle backend.\n";
    }
  } elsif ($self->{dbtype} =~ /^mysql$/i) {
    $self->__auto_discover_mysql();
    if ($self->{debug}) {
      print STDERR "AUTODISCOVER MySQL backend.\n";
    }
  }
  if (!defined($self->{chunksize})) {
    $self->{chunksize} = 255;
  }
}

sub __object_select_col {
  my $self = shift;
  my ($sql, @args) = @_;
  my $sth = $self->{dbh}->prepare($sql) || return undef;
  $sth->execute(@args) || return undef;
  my @result;
  while (my @row = $sth->fetchrow_array) {
    push @result, $row[0];
  }
  return wantarray ? @result : $result[0];
}

sub __objects_search {
  my $self = shift;
  my ($type, $name, $value) = @_;
  my $recursive = 0;
  my @cond;
  my @args;
  if ($type) {
    push @cond, "obj_type=?";
    push @args, $type;
  }
  if ($name) {
    push @cond, "obj_name=?";
    push @args, $name;
    $recursive = 1;
  }
  if ($value) {
    push @cond, "upper(obj_value) like ?";
    push @args, '%' . uc($value) . '%';
    $recursive = 1;
  }
  if (!$recursive) {
    push @cond, "obj_pid is null";
  }
  my $sql =
    "select distinct(obj_gpid) from $self->{objtable} where " . 
    join(" and ", @cond);
  if ($self->{debug}) {
    print STDERR "SQL '$sql' with params '" . join("', '", @args) . "'\n";
  }
  my @ids = $self->__object_select_col($sql, @args);
  return @ids;
}

sub __objects_find {
  my $self = shift;
  my ($type, $name) = @_;
  my $sql =
    "select obj_id from $self->{objtable}" .
    " where obj_gpid=obj_id and obj_type=? and obj_name=?";
  if ($self->{debug}) {
    print STDERR "SQL '$sql' with params '$type', '$name'\n";
  }
  my @ids = $self->__object_select_col($sql, $type, $name);
  return wantarray ? @ids : $ids[0];
}

sub __object_get {
  my $self = shift;
  my $id = int(shift());
  my $sql =
    'select obj_id, obj_pid, obj_gpid,' .
    ' obj_name, obj_type, obj_value' .
    " from $self->{objtable} where obj_gpid='$id'" .
    " order by obj_pid, obj_id";
  if ($self->{debug}) {
    print STDERR "SQL '$sql'\n";
  }
  my $rows = $self->{dbh}->selectall_arrayref($sql);
  if (!scalar(@{$rows})) {
    return undef;
  }
  my @result;
  foreach my $row (@{$rows}) {
    my $hash = {
      id => $row->[0],
      pid => $row->[1],
      gpid => $row->[2],
      name => $row->[3],
      type => $row->[4],
      value => $row->[5],
    };
    push @result, $hash;
  }
  return \@result;
}

sub __object_get_meta {
  my $self = shift;
  my $id = int(shift());
  my $sql =
    "select obj_type, obj_name, obj_id from $self->{objtable} where obj_id=$id";
  if ($self->{debug}) {
    print STDERR "SQL '$sql'\n";
  }
  return $self->{dbh}->selectrow_array($sql);
}

sub __object_get_types {
  my $self = shift;
  my $sql =
    "select distinct(obj_type) from $self->{objtable} where obj_gpid=obj_id";
  if ($self->{debug}) {
    print STDERR "SQL '$sql'\n";
  }
  return $self->{dbh}->selectcol_arrayref($sql);
}

sub __object_put_mysql {
  my $self = shift;
  my ($pid, $gpid, $name, $type, $value) = @_;
  my $sql =
    "insert into $self->{objtable}" .
    " (obj_pid, obj_gpid, obj_name, obj_type, obj_value)" .
    " values (?,?,?,?,?)";
  if ($self->{debug}) {
    print STDERR "SQL '$sql' with params '" . join("', '", @_) . "'\n";
  }
  if ($self->{dbh}->do($sql, undef, @_)) {
    my $id = $self->{dbh}->do("select last_insert_id()");
#    if (!defined($gpid)) {
    if (!length($gpid)) {
      $self->{dbh}->do(
        "update $self->{objtable} set obj_gpid=$id where obj_id=$id"
      );
    }
    return $id;
  }
  return undef;
}

sub __object_put {
  my $self = shift;
  my ($pid, $gpid, $name, $type, $value) = @_;
  if ($self->{dbtype} =~ /mysql/i) {
    return $self->__object_put_mysql($pid, $gpid, $name, $type, $value);
  } else {
    my $id = $self->__new_id();
    my $sql =
      "insert into $self->{objtable}" .
      " (obj_id, obj_pid, obj_gpid, obj_name, obj_type, obj_value)" .
      " values (?,?,?,?,?,?)";
    my @params = (
#      $id, $pid, (defined($gpid) ? $gpid : $id), $name, $type, $value
      $id, $pid, (length($gpid) ? $gpid : $id), $name, $type, $value
    );
    if ($self->{debug}) {
      print STDERR "SQL '$sql' with params '" . join("', '", @params) . "'\n";
    }
    if ($self->{dbh}->do($sql, undef, @params)) {
      return $id;
    } else {
      return undef;
    }
  }
}

sub __object_del {
  my $self = shift;
  my $id = int(shift());
  my $sql = "delete from $self->{objtable} where obj_gpid=?";
  if ($self->{debug}) {
    print STDERR "SQL '$sql' with params '$id'\n";
  }
  $self->{dbh}->do($sql, undef, $id);
} 

my $count = 0;

sub __new_id {
  my $self = shift;
  if ($self->{sequence}) {
    my $sql = "select nextval('$self->{sequence}')";
    my $type = $self->{dbtype};
    if ($type =~ /oracle/i) {
      $sql = "SELECT $self->{sequence}.NEXTVAL FROM DUAL";
    } elsif ($type =~ /pg/i || $type =~ /postgres/i) {
      $sql = "select nextval('$self->{sequence}')";
    }
    my $id = $self->{dbh}->selectrow_array($sql);
    return $id;
  } elsif ($self->{sequencesql}) {
    my $id = $self->{dbh}->selectrow_array($self->{sequencesql});
    return $id;
  } elsif ($self->{sequencefnc}) {
    my $fnc = $self->{sequencefnc};
    my $id = &$fnc();
    return $id;
  } else {
    my $id = int(sprintf("%d%.4d", time(), ++$count));
    return $id;
  }
}

sub cursor {
  my $self = shift;
  return ObjectDBI::Cursor->new($self, @_);
}

package ObjectDBI::Cursor;

=head1 CURSORS

Cursors are there to obtain lists of objects in a 'streaming' (as opposed
to 'buffered') fashion.  When the list of objects is (potentially) too long
to retrieve all at once, you'd use a cursor and iterate through it.

=head2 B<my $cursor = $objectdbi-E<gt>cursor([query], [type]);>

or

=head2 B<my $cursor = ObjectDBI::Cursor-E<gt>new($objectdbi, [query], [type]);>

Usage:

  my $cursor = $objectdbi->cursor("foo");
  while (my $ref = $cursor->next()) {
    print Dumper($ref);
  }

Bear in mind that the query given when initializing the cursor is optional.
When no query is given, you simply iterate through the entire set of objects.

=cut

sub new {
  my $class = shift;
  my $objectdbi = shift;
  if (!UNIVERSAL::isa($objectdbi, 'ObjectDBI')) {
    die "Need ObjectDBI reference as argument";
  }
  my $classname = ref($class) || $class; 
  my $self = {
    OBJECTDBI => $objectdbi,
  };
  bless $self, $classname;
  my $sql =
    "SELECT DISTINCT(TABLE1.obj_gpid)" .
    " from $objectdbi->{objtable} as TABLE1 where 1=1";
  my @params;
  $self->{PARAMS} = \@params;
  if (defined($_[0])) {
    my $query = $_[0];
    my @tokens = ObjectDBI::__tokenize_query($query);
    my $parsetree = ObjectDBI::__parse_query(@tokens) || return undef;
    ($sql, @params) = $self->{OBJECTDBI}->__tree_to_sql($parsetree);
    $self->{QUERY} = $query;
  }
  if (defined($_[1])) {
    my $type = $_[1];
    $sql =
      "SELECT DISTINCT(obj_gpid)" .
      " FROM $objectdbi->{objtable}" .
      " WHERE obj_type=?" .
      " AND obj_pid is null" .
      " INTERSECT " .
      $sql;
    unshift @params, $type;
  }
  $self->{SQL} = $sql;
#  $sql =~ s/^SELECT DISTINCT/SELECT MIN/;
  $sql = "SELECT MIN(obj_gpid) FROM ($sql) FOO";
  if ($self->{OBJECTDBI}{debug}) {
    print STDERR "SQL: '$sql' with params: '" . join("', '", @params) . "\n";
  }
  $self->{ID} =
    $objectdbi->get_dbh()->selectrow_array($sql, undef, @params);
  return $self;
}

sub next {
  my $self = shift;
  return undef if (!defined($self->{ID}));
  my $result = $self->{OBJECTDBI}->get($self->{ID});
  my @params = @{$self->{PARAMS}};
  my $sql = $self->{SQL};
  $sql .= " AND TABLE1.obj_gpid > $self->{ID}";
#  $sql =~ s/^SELECT DISTINCT/SELECT MIN/;
  $sql = "SELECT MIN(obj_gpid) FROM ($sql) FOO";
  if ($self->{OBJECTDBI}{debug}) {
    print STDERR "SQL: '$sql' with params: '" . join("', '", @params) . "'\n";
  }
  $self->{ID} = $self->{OBJECTDBI}->get_dbh()->selectrow_array(
    $sql, undef, @params
  );
  return $result;
}

=head2 B<my $err = $cursor-E<gt>skip($amount);>

or

=head2 B<my $err = $cursor-E<gt>skip_forward($amount);>

Skips this many places in the cursor.

=cut

sub skip {
  my $self = shift;
  return $self->skip_forward(@_);
}

sub skip_forward {
  my $self = shift;
  return undef if (!defined($self->{ID}));
  my $amount = int(shift(@_));
  my @params = @{$self->{PARAMS}};
  my $sql = $self->{SQL};
#  $sql =~ s/^SELECT DISTINCT/SELECT MIN/;
  $sql .= " AND TABLE1.obj_gpid > $self->{ID}";
  $sql = " SELECT obj_gpid FROM ($sql) FOO ORDER BY obj_gpid ASC";

## POSTGRES SPECIFIC
  $sql .= " LIMIT $amount";

  if ($self->{OBJECTDBI}{debug}) {
    print STDERR "SQL: '$sql' with params: '" . join("', '", @params) . "'\n";
  }
  my $ids = $self->{OBJECTDBI}->get_dbh()->selectcol_arrayref(
    $sql, undef, @params
  );
  $self->{ID} = $ids->[ $amount - 1 ];
  return 1;
}

=head2 B<my $err = $cursor-E<gt>skip_backward($amount);>

Skips this many places in the cursor in the opposite direction.

=cut

sub skip_backward {
  my $self = shift;
  return undef if (!defined($self->{ID}));
  my $amount = int(shift(@_));
  my @params = @{$self->{PARAMS}};
  my $sql = $self->{SQL};
#  $sql =~ s/^SELECT DISTINCT/SELECT MAX/;
  $sql .= " AND TABLE1.obj_gpid < $self->{ID}";
  $sql = " SELECT obj_gpid FROM ($sql) FOO ORDER BY obj_gpid DESC";
#  $sql .= " ORDER BY TABLE1.obj_gpid DESC";

## POSTGRES SPECIFIC
  $sql .= " LIMIT $amount";

  if ($self->{OBJECTDBI}{debug}) {
    print STDERR "SQL: '$sql' with params: '" . join("', '", @params) . "'\n";
  }
  my $ids = $self->{OBJECTDBI}->get_dbh()->selectcol_arrayref(
    $sql, undef, @params
  );
  $self->{ID} = $ids->[ $amount - 1 ];
  return 1;
}

=head2 B<my $err = $cursor-E<gt>first();>

Move to the first possible position of the cursor.
Doesn't need to be called when your previous call is $cursor->new(),
because a new cursor is always at its first possible position.

=cut

sub first {
  my $self = shift;
  my @params = @{$self->{PARAMS}};
  my $sql = $self->{SQL};
  $sql = "SELECT MIN(obj_gpid) FROM ($sql) FOO";
#  $sql =~ s/^SELECT DISTINCT/SELECT MIN/;
  if ($self->{OBJECTDBI}{debug}) {
    print STDERR "SQL: '$sql' with params: '" . join("', '", @params) . "\n";
  }
  $self->{ID} =
    $self->{OBJECTDBI}->get_dbh()->selectrow_array(
      $sql, undef, @{$self->{PARAMS}}
    );
  return 1;
}

=head2 B<my $err = $cursor-E<gt>last();>

Move to the last possible position of the cursor.

=cut

sub last {
  my $self = shift;
  my $sql = $self->{SQL};
  my @params = @{$self->{PARAMS}};
  my $sql = $self->{SQL};
#  $sql =~ s/^SELECT DISTINCT/SELECT MAX/;
  $sql = "SELECT MAX(obj_gpid) FROM ($sql) FOO";
  if ($self->{OBJECTDBI}{debug}) {
    print STDERR "SQL: '$sql' with params: '" . join("', '", @params) . "\n";
  }
  $self->{ID} =
    $self->{OBJECTDBI}->get_dbh()->selectrow_array(
      $sql, undef, @{$self->{PARAMS}}
    );
  return 1;
}

=head2 B<my $ref = $cursor-E<gt>next();>

Move to the next position of the cursor.  Returns the object at the current
position.

=head2 B<my $ref = $cursor-E<gt>prev();>

Move to the previous position of the cursor.  Returns the object at the current
position.

=head2 B<my $ref = $cursor-E<gt>current();>

Returns the object at the current position.

=head2 B<my ($name, $type, $id) = $cursor-E<gt>meta_data();>

Returns the meta data (name, type, id) of the object at the current position.

=cut

sub prev {
  my $self = shift;
  return undef if (!defined($self->{ID}));
  my $result = $self->{OBJECTDBI}->get($self->{ID});
  my @params = @{$self->{PARAMS}};
  $sql = $self->{SQL};
  $sql .= " AND TABLE1.obj_gpid < $self->{ID}";
#  $sql =~ s/^SELECT DISTINCT/SELECT MAX/;
  $sql = "SELECT MAX(obj_gpid) FROM ($sql) FOO";
  if ($self->{OBJECTDBI}{debug}) {
    print STDERR "SQL: '$sql' with params: '" . join("', '", @params) . "'\n";
  }
  $self->{ID} = $self->{OBJECTDBI}->get_dbh()->selectrow_array(
    $sql, undef, @params
  );
  return $result;
}

sub current {
  my $self = shift;
  return undef if (!defined($self->{ID}));
  my $result = $self->{OBJECTDBI}->get($self->{ID});
  return $result;
}

sub meta_data {
  my $self = shift;
  return undef if (!defined($self->{ID}));
  return $self->{OBJECTDBI}->__object_get_meta($self->{ID});
}

=head2 B<my $ref = $cursor-E<gt>del();>

Deletes the current element under the cursor and moves to cursor one up.
A small concurrency warning is in order here: when two conncurrent users use
cursors, and one of them start to manipulate the state of the db, the other
one *might* risk suddenly dropping out of it.

=cut

sub del {
  my $self = shift;
  return undef if (!defined($self->{ID}));
  my $result = $self->{OBJECTDBI}->get($self->{ID});
  $self->{OBJECTDBI}->__del($self->{ID});
  my @params = @{$self->{PARAMS}};
  my $sql = $self->{SQL};
  $sql .= " AND TABLE1.obj_gpid > $self->{ID}";
  $sql = "SELECT MIN(obj_gpid) FROM ($sql) FOO";
#  $sql =~ s/^SELECT DISTINCT/SELECT MIN/;
  if ($self->{OBJECTDBI}{debug}) {
    print STDERR "SQL: '$sql' with params: '" . join("', '", @params) . "'\n";
  }
  $self->{ID} = $self->{OBJECTDBI}->get_dbh()->selectrow_array(
    $sql, undef, @params
  );
  return $result;
}

1;

__END__

=head1 SAMPLE USAGE

Below are a few code examples demonstrating this package's usage.
They assume various databases on localhost; please adapt according to
your configuration.

=head2 Storing and Retrieving

  use ObjectDBI;
  use Data::Dumper;
  my $ref = bless({ foo => 'bar' }, 'Foobar');
  my $objectdbi = ObjectDBI->new(
    dbiuri => 'DBI:Oracle:SID=MYSID;host=localhost',
    dbiuser => 'user',
    dbipass => 'pass'
  ) || die "Could not connect to db";
  my $id = $objectdbi->put($ref, 'myref');
  my $ref2 = $objectdbi->get($id);
  print Dumper($ref2);

=head2 Using Queries

  use ObjectDBI;
  my $ref = { foo => { bar => 'foobar' }};
  my $objectdbi = ObjectDBI->new(
    dbiuri => 'DBI:Pg:dbname=mydb'
  ) || die "Could not connect to db";
  $objectdbi->put($ref);
  my @ids = $objectdbi->query("foo/bar=='foobar' || foo/*=='foo*'");
  print @ids;

=head2 Seeing Cross Referencing in Action

  use ObjectDBI;
  use Data::Dumper;
  my $objectdbi = ObjectDBI->new(
    dbiuri => 'DBI:Pg:dbname=mydb'
  ) || die "Could not connect to db";
  my $hash = { foo => [ 'bar' ] };
  $hash->{'foobar'} = $hash->{foo};
  print Dumper($hash);
  my $id = $objectdbi->put($hash);
  my $ref = $objectdbi->get($id);
  print Dumper($ref);

=head1 NOTES

=head2 Blessing objects vs. loading modules

Bear in mind that when an object becomes blessed during deserialization,
the module in question hasn't necessarily been loaded, and this module
will not do it for you either (since it doesn't know where you store that code).
So calling methods on a deserialized object may require you to do some
additional module usage.  Not loading a module and yet calling a method
on a blessed reference of it, can lead to cryptic error messages.

=head2 ObjectDBI vs. Perl TIE

This module doesn't implement a perl TIE interface.  There's Tie::DBI for that.
You could probably re-implement Tie::DBI on top of this module, though.

=head2 ObjectDBI vs. Tangram

I didn't know Tangram existed when I made this module.  Upon brief examination
of Tangram, I think the differences between ObjectDBI and Tangram are as
follows:

=over

=item

Tangram is huge.  ObjectDBI is simpler (and more immature, probably).

=item

Tangram is much more geared toward a Tangram-specific query language, while
ObjectDBI is geared toward storing and searching by name and type.
ObjectDBI does have a (limited) query language of its own, though.

=item

Tangram stores objects as a whole, which requires potentially unlimited
storage in a field.  Not all RDBMS supply this feature.

=item

Tangram requires you to specify what values of an object you want stored for
searching.  ObjectDBI has no such limitations and preserves the amorphousness
that is inherent to the world of perl objects.

=item

ObjectDBI database tables will be a lot bigger (as in: more rows) statistically
than Tangram database tables (which will have bigger rows).

=back

=head2 Transactions

Transactions could be implemented as follows:

  my $id;
  $objectdbi->get_dbh()->begin_work();
  if ($id = $objectdbi->put($ref)) {
    $objectdbi->get_dbh()->commit();
  } else {
    $objectdbi->get_dbh()->rollback();
  }

=head1 DEPENDENCIES

DBI => 1.3

=head1 BUGS

=over

=item

People using this library with MySQL must extra alert for bugs: I don't
and won't use it; yet I've written special code for it.
More specifically, people using something other than
Oracle or Postgres must be extra alert for bugs.  Your feedback is appreciated.

=item

When storing long values, the breaking up of them into pieces
impairs search capabilities; fragments that you're looking
for might have been broken up.

=back

=head1 TODO

=over

=item 

Break my head over that breaking up of long values.  I can't just concatenate
a random amount of strings to work with in SQL, so I'm thinking perhaps
having a backend perl stored procedure.  But that would do away with using
this library in any other way than with postgres.  Ah, I'm stuck with it.

=back

=head1 CHANGELOG

This changelog is incomplete was only started in the transition from
ObjectDBI-0.08 to ObjectDBI-0.09

0.09 Added queries to cursors.  Fixed the sql logic in __tree_to_sql.

0.10 Added two tests - hey !  I know how to make tests now !

0.11 Skip those tests, unless you're running SQL::Statement and MLDBM, or
a Postgres DB called perlobjects.  This kind of defies the purpose of testing.
Also, simplified the 'get object' query, so that more primitive databases can
handle the SQL.  Should take care of that for all queries.  Strictly on
demand though, although I can imagine that the kind of queries you can
fabricate using the query parser, can be a bit much for any top-notch
SQL optimizer.

0.12 Changed the test scripts at the behest of Slaven Rezic.  I'm really
sorry for wasting everyone's time with this, but the whole 'testing' thing
is still a bit foreign to me.

0.13 Implemented debugging of SQL statements.  A beginning is made.
Also, adjusted test 2 to be self sufficient.

0.14 Lots more cursor functionality.

=head1 COLOFON

Written by KJ Hermans (kees@pink-frog.com) Sep 2010.
