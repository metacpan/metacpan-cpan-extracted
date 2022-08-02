package SQL::Abstract::More;
use strict;
use warnings;

# no "use parent ..." here -- the inheritance is specified dynamically in the
# import() method -- inheriting either from SQL::Abstract or SQL::Abstract::Classic

use MRO::Compat;
use mro 'c3'; # implements next::method

use Params::Validate  qw/validate SCALAR SCALARREF CODEREF ARRAYREF HASHREF
                                  UNDEF  BOOLEAN/;
use Scalar::Util      qw/blessed reftype/;


# remove all previously defined or imported functions
use namespace::clean;

# declare error-reporting functions from SQL::Abstract
sub puke(@); sub belch(@);  # these will be defined later in import()

our $VERSION = '1.39';
our @ISA;

sub import {
  my $class = shift;

  # parent class specified from environment variable, or default value
  my $parent_sqla = $ENV{SQL_ABSTRACT_MORE_EXTENDS} || 'SQL::Abstract::Classic';

  # parent class specified through -extends => .. when calling import()
  $parent_sqla = $_[1] if @_ >= 2 && $_[0] eq '-extends';

  # syntactic sugar : 'Classic' is expanded into SQLA::Classic
  $parent_sqla = 'SQL::Abstract::Classic' if $parent_sqla eq 'Classic';

  # make sure that import() does never get called with different parents
  if (my $already_isa = $ISA[0]) {
    $already_isa eq $parent_sqla
      or die "cannot use SQL::Abstract::More -extends => '$parent_sqla', "
           . "this module was already loaded with -extends => '$already_isa'";

    # the rest of the import() job was already performed, so just return from here
    return;
  }

  # load the parent, inherit from it, import puke() and belch()
  eval qq{use parent '$parent_sqla';
          *puke  = \\&${parent_sqla}::puke;
          *belch = \\&${parent_sqla}::belch;
         };

  # local override of some methods for insert() and update()
  _setup_insert_inheritance($parent_sqla);
  _setup_update_inheritance($parent_sqla);
}



#----------------------------------------------------------------------
# Utility functions -- not methods -- declared _after_
# namespace::clean so that they can remain visible by external
# modules. In particular, DBIx::DataModel imports these functions.
#----------------------------------------------------------------------

# shallow_clone(): copies of the top-level keys and values, blessed into the same class
sub shallow_clone {
  my ($orig, %override) = @_;

  my $class = ref $orig
    or puke "arg must be an object";
  my $clone = {%$orig, %override};
  return bless $clone, $class;
}


# does(): cheap version of Scalar::Does
my %meth_for = (
  ARRAY  => '@{}',
  HASH   => '%{}',
  SCALAR => '${}',
  CODE   => '&{}',
 );
sub does ($$) {
  my ($data, $type) = @_;
  my $reft = reftype $data;
  return defined $reft && $reft eq $type
      || blessed $data && overload::Method($data, $meth_for{$type});
}



#----------------------------------------------------------------------
# global variables
#----------------------------------------------------------------------

# builtin methods for "Limit-Offset" dialects
my %limit_offset_dialects = (
  LimitOffset => sub {my ($self, $limit, $offset) = @_;
                      $offset ||= 0;
                      return "LIMIT ? OFFSET ?", $limit, $offset;},
  LimitXY     => sub {my ($self, $limit, $offset) = @_;
                      $offset ||= 0;
                      return "LIMIT ?, ?", $offset, $limit;},
  LimitYX     => sub {my ($self, $limit, $offset) = @_;
                      $offset ||= 0;
                      return "LIMIT ?, ?", $limit, $offset;},
  RowNum      => sub {
    my ($self, $limit, $offset) = @_;
    # HACK below borrowed from SQL::Abstract::Limit. Not perfect, though,
    # because it brings back an additional column. Should borrow from 
    # DBIx::Class::SQLMaker::LimitDialects, which does the proper job ...
    # but it says : "!!! THIS IS ALSO HORRIFIC !!! /me ashamed"; so
    # I'll only take it as last resort; still exploring other ways.
    # See also L<DBIx::DataModel> : within that ORM an additional layer is
    # added to take advantage of Oracle scrollable cursors.
    my $sql = "SELECT * FROM ("
            .   "SELECT subq_A.*, ROWNUM rownum__index FROM (%s) subq_A "
            .   "WHERE ROWNUM <= ?"
            .  ") subq_B WHERE rownum__index >= ?";

    no warnings 'uninitialized'; # in case $limit or $offset is undef
    # row numbers start at 1
    return $sql, $offset + $limit, $offset + 1;
  },
 );

# builtin join operators with associated sprintf syntax
my %common_join_syntax = (
  '<=>' => '%s INNER JOIN %s ON %s',
   '=>' => '%s LEFT OUTER JOIN %s ON %s',
  '<='  => '%s RIGHT OUTER JOIN %s ON %s',
  '=='  => '%s NATURAL JOIN %s',
  '>=<' => '%s FULL OUTER JOIN %s ON %s',
);
my %right_assoc_join_syntax = %common_join_syntax;
s/JOIN %s/JOIN (%s)/ foreach values %right_assoc_join_syntax;

# specification of parameters accepted by the new() method
my %params_for_new = (
  table_alias          => {type => SCALAR|CODEREF,   default  => '%s AS %s'},
  column_alias         => {type => SCALAR|CODEREF,   default  => '%s AS %s'},
  limit_offset         => {type => SCALAR|CODEREF,   default  => 'LimitOffset'},
  join_syntax          => {type => HASHREF,          default  =>
                                                        \%common_join_syntax},
  join_assoc_right     => {type => BOOLEAN,          default  => 0},
  max_members_IN       => {type => SCALAR,           optional => 1},
  multicols_sep        => {type => SCALAR|SCALARREF, optional => 1},
  has_multicols_in_SQL => {type => BOOLEAN,          optional => 1},
  sql_dialect          => {type => SCALAR,           optional => 1},
  select_implicitly_for=> {type => SCALAR|UNDEF,     optional => 1},
);

# builtin collection of parameters, for various databases
my %sql_dialects = (
 MsAccess  => { join_assoc_right     => 1,
                join_syntax          => \%right_assoc_join_syntax},
 BasisJDBC => { column_alias         => "%s %s",
                max_members_IN       => 255                      },
 MySQL_old => { limit_offset         => "LimitXY"                },
 Oracle    => { limit_offset         => "RowNum",
                max_members_IN       => 999,
                table_alias          => '%s %s',
                column_alias         => '%s %s',
                has_multicols_in_SQL => 1,                       },
);


# operators for compound queries
my @set_operators = qw/union union_all intersect minus except/;

# specification of parameters accepted by select, insert, update, delete
my %params_for_select = (
  -columns      => {type => SCALAR|ARRAYREF,         default  => '*'},
  -from         => {type => SCALAR|SCALARREF|ARRAYREF},
  -where        => {type => SCALAR|ARRAYREF|HASHREF, optional => 1},
  (map {-$_ => {type => ARRAYREF, optional => 1}} @set_operators),
  -group_by     => {type => SCALAR|ARRAYREF,         optional => 1},
  -having       => {type => SCALAR|ARRAYREF|HASHREF, optional => 1},
  -order_by     => {type => SCALAR|ARRAYREF|HASHREF, optional => 1},
  -page_size    => {type => SCALAR,                  optional => 1},
  -page_index   => {type => SCALAR,                  optional => 1,
                                                     depends  => '-page_size'},
  -limit        => {type => SCALAR,                  optional => 1},
  -offset       => {type => SCALAR,                  optional => 1,
                                                     depends  => '-limit'},
  -for          => {type => SCALAR|UNDEF,            optional => 1},
  -want_details => {type => BOOLEAN,                 optional => 1},
);
my %params_for_insert = (
  -into         => {type => SCALAR},
  -values       => {type => SCALAR|ARRAYREF|HASHREF, optional => 1},
  -select       => {type => HASHREF,                 optional => 1},
  -columns      => {type => ARRAYREF,                optional => 1},
  -returning    => {type => SCALAR|ARRAYREF|HASHREF, optional => 1},
  -add_sql      => {type => SCALAR,                  optional => 1},
);
my %params_for_update = (
  -table        => {type => SCALAR|SCALARREF|ARRAYREF},
  -set          => {type => HASHREF},
  -where        => {type => SCALAR|ARRAYREF|HASHREF, optional => 1},
  -order_by     => {type => SCALAR|ARRAYREF|HASHREF, optional => 1},
  -limit        => {type => SCALAR,                  optional => 1},
  -returning    => {type => SCALAR|ARRAYREF|HASHREF, optional => 1},
  -add_sql      => {type => SCALAR,                  optional => 1},
);
my %params_for_delete = (
  -from         => {type => SCALAR},
  -where        => {type => SCALAR|ARRAYREF|HASHREF, optional => 1},
  -order_by     => {type => SCALAR|ARRAYREF|HASHREF, optional => 1},
  -limit        => {type => SCALAR,                  optional => 1},
  -add_sql      => {type => SCALAR,                  optional => 1},
);
my %params_for_WITH = (
  -table        => {type => SCALAR},
  -columns      => {type => SCALAR|ARRAYREF,         optional => 1},
  -as_select    => {type => HASHREF},
  -final_clause => {type => SCALAR,                  optional => 1},
);



#----------------------------------------------------------------------
# object creation
#----------------------------------------------------------------------

sub new {
  my $class = shift;
  my %params = does($_[0], 'HASH') ? %{$_[0]} : @_;

  # extract params for this subclass
  my %more_params;
  foreach my $key (keys %params_for_new) {
    $more_params{$key} = delete $params{$key} if exists $params{$key};
  }

  # import params from SQL dialect, if any
  my $dialect = delete $more_params{sql_dialect};
  if ($dialect) {
    my $dialect_params = $sql_dialects{$dialect}
      or puke "no such sql dialect: $dialect";
    $more_params{$_} ||= $dialect_params->{$_} foreach keys %$dialect_params;
  }

  # check parameters for this class
  my @more_params = %more_params;
  my $more_self   = validate(@more_params, \%params_for_new);

  # check some of the params for parent -- because SQLA doesn't do it :-(
  !$params{quote_char} || exists $params{name_sep}
    or belch "when 'quote_char' is present, 'name_sep' should be present too";

  # call parent constructor
  my $self = $class->next::method(%params);

  # inject into $self
  $self->{$_} = $more_self->{$_} foreach keys %$more_self;

  # arguments supplied as scalars are transformed into coderefs
  ref $self->{column_alias} or $self->_make_sub_column_alias;
  ref $self->{table_alias}  or $self->_make_sub_table_alias;
  ref $self->{limit_offset} or $self->_choose_LIMIT_OFFSET_dialect;

  # regex for parsing join specifications
  my @join_ops = sort {length($b) <=> length($a) || $a cmp $b}
                      keys %{$self->{join_syntax}};
  my $joined_ops = join '|', map quotemeta, @join_ops;
  $self->{join_regex} = qr[
     ^              # initial anchor 
     ($joined_ops)? # $1: join operator (i.e. '<=>', '=>', etc.))
     ([[{])?        # $2: opening '[' or '{'
     (.*?)          # $3: content of brackets
     []}]?          # closing ']' or '}'
     $              # final anchor
   ]x;

  return $self;
}



#----------------------------------------------------------------------
# support for WITH or WITH RECURSIVE
#----------------------------------------------------------------------

sub with_recursive {
  my $self = shift;

  my $new_instance = $self->with(@_);
  $new_instance->{WITH}{sql} =~ s/^WITH\b/WITH RECURSIVE/;

  return $new_instance;
}

sub with {
  my $self = shift;

  ! $self->{WITH}
    or puke "calls to the with() or with_recursive() method cannot be chained";

  @_
    or puke "->with() : missing arguments";

  # create a copy of the current object with an additional attribute WITH
  my $clone = shallow_clone($self, WITH => {sql => "", bind => []});

  # assemble SQL and bind values for each table expression
  my @table_expressions = does($_[0], 'ARRAY') ? @_ : ( [ @_]);
  foreach my $table_expression (@table_expressions) {
    my %args = validate(@$table_expression, \%params_for_WITH);
    my ($sql, @bind) = $self->select(%{$args{-as_select}});
    $clone->{WITH}{sql} .= ", " if $clone->{WITH}{sql};
    $clone->{WITH}{sql} .= $args{-table};
    $clone->{WITH}{sql} .= "(" . join(", ", @{$args{-columns}}) . ")" if $args{-columns};
    $clone->{WITH}{sql} .= " AS ($sql) ";
    $clone->{WITH}{sql} .= $args{-final_clause} . " "                 if $args{-final_clause};
    push @{$clone->{WITH}{bind}}, @bind;
  }

  # add the initial keyword WITH 
  substr($clone->{WITH}{sql}, 0, 0, 'WITH ');

  return $clone;
}


sub _prepend_WITH_clause {
  my ($self, $ref_sql, $ref_bind) = @_;

  return if !$self->{WITH};

  substr($$ref_sql, 0, 0, $self->{WITH}{sql});
  unshift @$ref_bind, @{$self->{WITH}{bind}};

}


#----------------------------------------------------------------------
# the select method
#----------------------------------------------------------------------

sub select {
  my $self = shift;

  # if got positional args, this is not our job, just delegate to the parent
  return $self->next::method(@_) if !&_called_with_named_args;

  my %aliased_columns;

  # parse arguments
  my %args = validate(@_, \%params_for_select);

  # compute join info if the datasource is a join
  my $join_info = $self->_compute_join_info($args{-from});
  $args{-from}  = \($join_info->{sql}) if $join_info;

  # reorganize columns; initial members starting with "-" are extracted
  # into a separate list @post_select, later re-injected into the SQL
  my @cols = ref $args{-columns} ? @{$args{-columns}} : $args{-columns};
  my @post_select;
  push @post_select, shift @cols while @cols && $cols[0] =~ s/^-//;
  foreach my $col (@cols) {
    # extract alias, if any
    if ($col =~ /^\s*         # ignore insignificant leading spaces
                 (.*[^|\s])   # any non-empty string, not ending with ' ' or '|'
                 \|           # followed by a literal '|'
                 (\w+)        # followed by a word (the alias))
                 \s*          # ignore insignificant trailing spaces
                 $/x) {
      $aliased_columns{$2} = $1;
      $col = $self->column_alias($1, $2);
    }
  }
  $args{-columns} = \@cols;

  # reorganize pagination
  if ($args{-page_index} || $args{-page_size}) {
    not exists $args{$_} or puke "-page_size conflicts with $_"
      for qw/-limit -offset/;
    $args{-limit} = $args{-page_size};
    if ($args{-page_index}) {
      $args{-offset} = ($args{-page_index} - 1) * $args{-page_size};
    }
  }

  # generate initial ($sql, @bind), without -order_by (will be handled later)
  my @old_API_args = @args{qw/-from -columns -where/}; #
  my ($sql, @bind) = $self->next::method(@old_API_args);
  unshift @bind, @{$join_info->{bind}} if $join_info;

  # add @post_select clauses if needed (for ex. -distinct)
  my $post_select = join " ", @post_select;
  $sql =~ s[^SELECT ][SELECT $post_select ]i if $post_select;

  # add set operators (UNION, INTERSECT, etc) if needed
  foreach my $set_op (@set_operators) {
    if ($args{-$set_op}) {
      my %sub_args = @{$args{-$set_op}};
      $sub_args{$_} ||= $args{$_} for qw/-columns -from/;
      local $self->{WITH}; # temporarily disable the WITH part during the subquery
      my ($sql1, @bind1) = $self->select(%sub_args);
      (my $sql_op = uc($set_op)) =~ s/_/ /g;
      $sql .= " $sql_op $sql1";
      push @bind, @bind1;
    }
  }

  # add GROUP BY if needed
  if ($args{-group_by}) {
    my $sql_grp = $self->where(undef, $args{-group_by});
    $sql_grp =~ s/\bORDER\b/GROUP/;
    $sql .= $sql_grp;
  }

  # add HAVING if needed (often together with -group_by, but not always)
  if ($args{-having}) {
    my ($sql_having, @bind_having) = $self->where($args{-having});
    $sql_having =~ s/\bWHERE\b/HAVING/;
    $sql.= " $sql_having";
    push @bind, @bind_having;
  }

  # add ORDER BY if needed
  if (my $order = $args{-order_by}) {

    my ($sql_order, @orderby_bind) = $self->_order_by($order);
    $sql .= $sql_order;
    push @bind, @orderby_bind;
  }

  # add LIMIT/OFFSET if needed
  if (defined $args{-limit}) {
    my ($limit_sql, @limit_bind) 
      = $self->limit_offset(@args{qw/-limit -offset/});
    $sql = $limit_sql =~ /%s/ ? sprintf $limit_sql, $sql
                              : "$sql $limit_sql";
    push @bind, @limit_bind;
  }

  # add FOR clause if needed
  my $for = exists $args{-for} ? $args{-for} : $self->{select_implicitly_for};
  $sql .= " FOR $for" if $for;

  # initial WITH clause
  $self->_prepend_WITH_clause(\$sql, \@bind);

  # return results
  if ($args{-want_details}) {
    return {sql             => $sql,
            bind            => \@bind,
            aliased_tables  => ($join_info && $join_info->{aliased_tables}),
            aliased_columns => \%aliased_columns          };
  }
  else {
    return ($sql, @bind);
  }
}

#----------------------------------------------------------------------
# insert
#----------------------------------------------------------------------

sub _setup_insert_inheritance {
  my ($parent_sqla) = @_;

  # if the parent has method '_expand_insert_value' (SQL::Abstract >= v2.0),
  # we need to override it in this subclass
  if ($parent_sqla->can('_expand_insert_value')) {
    *_expand_insert_value = sub {
      my ($self, $v) = @_;

      my $k = our $Cur_Col_Meta;

      if (ref($v) eq 'ARRAY') {
        if ($self->{array_datatypes} || $self->is_bind_value_with_type($v)) {
          return +{ -bind => [ $k, $v ] };
        }
        my ($sql, @bind) = @$v;
        $self->_assert_bindval_matches_bindtype(@bind);
        return +{ -literal => $v };
      }
      if (ref($v) eq 'HASH') {
        if (grep !/^-/, keys %$v) {
          belch "HASH ref as bind value in insert is not supported";
          return +{ -bind => [ $k, $v ] };
        }
      }
      if (!defined($v)) {
        return +{ -bind => [ $k, undef ] };
      }
      return $self->expand_expr($v);
    };
  }

  # otherwise, if the parent is an old SQL::Abstract or it is SQL::Abstract::Classic
  elsif ($parent_sqla->can('_insert_values')) {

    # if the parent has no method '_insert_value', this is the old
    # monolithic _insert_values() method. We must override it
    if (!$parent_sqla->can('_insert_value')) {
      *_insert_values = sub {
         my ($self, $data) = @_;

         my (@values, @all_bind);
         foreach my $column (sort keys %$data) {
           my ($values, @bind) = $self->_insert_value($column, $data->{$column});
           push @values, $values;
           push @all_bind, @bind;
         }
         my $sql = $self->_sqlcase('values')." ( ".join(", ", @values)." )";
         return ($sql, @all_bind);
      };
    }

    # now override the _insert_value() method
    *_insert_value = sub {

      # unfortunately, we can't just override the ARRAYREF part, so the whole
      # parent method is copied here

      my ($self, $column, $v) = @_;

      my (@values, @all_bind);
      $self->_SWITCH_refkind($v, {

        ARRAYREF => sub {
          if ($self->{array_datatypes} # if array datatype are activated
                || $self->is_bind_value_with_type($v)) { # or if this is a bind val
            push @values, '?';
            push @all_bind, $self->_bindtype($column, $v);
          }
          else {                  # else literal SQL with bind
            my ($sql, @bind) = @$v;
            $self->_assert_bindval_matches_bindtype(@bind);
            push @values, $sql;
            push @all_bind, @bind;
          }
        },

        ARRAYREFREF => sub {        # literal SQL with bind
          my ($sql, @bind) = @${$v};
          $self->_assert_bindval_matches_bindtype(@bind);
          push @values, $sql;
          push @all_bind, @bind;
        },

        # THINK : anything useful to do with a HASHREF ?
        HASHREF => sub {       # (nothing, but old SQLA passed it through)
          #TODO in SQLA >= 2.0 it will die instead
          belch "HASH ref as bind value in insert is not supported";
          push @values, '?';
          push @all_bind, $self->_bindtype($column, $v);
        },

        SCALARREF => sub {          # literal SQL without bind
          push @values, $$v;
        },

        SCALAR_or_UNDEF => sub {
          push @values, '?';
          push @all_bind, $self->_bindtype($column, $v);
        },

      });

      my $sql = CORE::join(", ", @values);
      return ($sql, @all_bind);
    }
  }
}



sub insert {
  my $self = shift;

  my @old_API_args;
  my $returning_into;
  my $sql_to_add;
  my $fix_RT134127;

  if (&_called_with_named_args) {
    # extract named args and translate to old SQLA API
    my %args = validate(@_, \%params_for_insert);
    $old_API_args[0] = $args{-into}
      or puke "insert(..) : need -into arg";

    if ($args{-values}) {

      # check mutually exclusive parameters
      !$args{$_}
        or puke "insert(-into => .., -values => ...) : cannot use $_ => "
        for qw/-select -columns/;

      $old_API_args[1] = $args{-values};
    }
    elsif ($args{-select}) {
      local $self->{WITH}; # temporarily disable the WITH part during the subquery
      my ($sql, @bind) = $self->select(%{$args{-select}});
      $old_API_args[1] = \ [$sql, @bind];
      if (my $cols = $args{-columns}) {
        $old_API_args[0] .= "(" . CORE::join(", ", @$cols) . ")";
      }
      $fix_RT134127 = 1 if ($SQL::Abstract::VERSION || 0) >= 2.0;
    }
    else {
      puke "insert(-into => ..) : need either -values arg or -select arg";
    }

    # deal with -returning arg
    ($returning_into, my $old_API_options) 
      = $self->_compute_returning($args{-returning});
    push @old_API_args, $old_API_options if $old_API_options;

    # SQL to add after the INSERT keyword
    $sql_to_add = $args{-add_sql};
  }
  else {
    @old_API_args = @_;
  }

  # get results from parent method
  my ($sql, @bind) = $self->next::method(@old_API_args);

  # temporary fix for RT#134127 due to a change of behaviour of insert() in SQLA V2.0
  # .. waiting for SQLA to fix RT#134128
  $sql =~ s/VALUES SELECT/SELECT/ if $fix_RT134127;

  # inject more stuff if using Oracle's "RETURNING ... INTO ..."
  if ($returning_into) {
    $sql .= ' INTO ' . join(", ", ("?") x @$returning_into);
    push @bind, @$returning_into;
  }

  # SQL to add after the INSERT keyword
  $sql =~ s/\b(INSERT)\b/$1 $sql_to_add/i if $sql_to_add;

  # initial WITH clause
  $self->_prepend_WITH_clause(\$sql, \@bind);

  return ($sql, @bind);
}

#----------------------------------------------------------------------
# update
#----------------------------------------------------------------------


sub _setup_update_inheritance {
  my ($parent_sqla) = @_;

  # if the parent has method '_expand_update_set_value' (SQL::Abstract >= v2.0),
  # we need to override it in this subclass
  if ($parent_sqla->can('_expand_update_set_values')) {
    *_parent_update            = $parent_sqla->can('update');
    *_expand_update_set_values = sub {
      my ($self, undef, $data) = @_;
      $self->expand_expr({ -list => [
        map {
          my ($k, $set) = @$_;
          $set = { -bind => $_ } unless defined $set;
          +{ -op => [ '=', { -ident => $k }, $set ] };
        }
        map {
          my $k = $_;
          my $v = $data->{$k};
          (ref($v) eq 'ARRAY'
            ? ($self->{array_datatypes} || $self->is_bind_value_with_type($v)
                ? [ $k, +{ -bind => [ $k, $v ] } ]
                : [ $k, +{ -literal => $v } ])
            : do {
                local our $Cur_Col_Meta = $k;
                [ $k, $self->_expand_expr($v) ]
              }
          );
        } sort keys %$data
      ] });
    };
  }


  # otherwise, if the parent is an old SQL::Abstract or it is SQL::Abstract::Classic
  else {
    # if the parent has method '_update_set_values()', it is a SQLA version >=1.85.
    # We can just use its update() method as _parent_update().
    if ($parent_sqla->can('_update_set_values')) {
      *_parent_update = $parent_sqla->can('update');
    }

    # otherwise, it's the old monolithic update() method. We need to supply our own
    # version as _parent_update().
    else {
      *_parent_update = sub {
         my $self    = shift;
         my $table   = $self->_table(shift);
         my $data    = shift || return;
         my $where   = shift;
         my $options = shift;

         # first build the 'SET' part of the sql statement
         puke "Unsupported data type specified to \$sql->update"
           unless ref $data eq 'HASH';

         my ($sql, @all_bind) = $self->_update_set_values($data);
         $sql = $self->_sqlcase('update ') . $table . $self->_sqlcase(' set ')
                 . $sql;

         if ($where) {
           my($where_sql, @where_bind) = $self->where($where);
           $sql .= $where_sql;
           push @all_bind, @where_bind;
         }

         if ($options->{returning}) {
           my ($returning_sql, @returning_bind) = $self->_update_returning($options);
           $sql .= $returning_sql;
           push @all_bind, @returning_bind;
         }

         return wantarray ? ($sql, @all_bind) : $sql;
       };
      *_update_returning = sub {
         my ($self, $options) = @_;

         my $f = $options->{returning};

         my $fieldlist = $self->_SWITCH_refkind($f, {
           ARRAYREF     => sub {join ', ', map { $self->_quote($_) } @$f;},
           SCALAR       => sub {$self->_quote($f)},
           SCALARREF    => sub {$$f},
         });
         return $self->_sqlcase(' returning ') . $fieldlist;
      };
    }

    # now override or supply the _update_set_value() method
    *_update_set_values = sub {
      my ($self, $data) = @_;

      my (@set, @all_bind);
      for my $k (sort keys %$data) {
        my $v = $data->{$k};
        my $r = ref $v;
        my $label = $self->_quote($k);

        $self->_SWITCH_refkind($v, {
          ARRAYREF => sub {
            if ($self->{array_datatypes}                  # array datatype
                || $self->is_bind_value_with_type($v)) {  # or bind value with type
              push @set, "$label = ?";
              push @all_bind, $self->_bindtype($k, $v);
            }
            else {                          # literal SQL with bind
              my ($sql, @bind) = @$v;
              $self->_assert_bindval_matches_bindtype(@bind);
              push @set, "$label = $sql";
              push @all_bind, @bind;
            }
          },
          ARRAYREFREF => sub { # literal SQL with bind
            my ($sql, @bind) = @${$v};
            $self->_assert_bindval_matches_bindtype(@bind);
            push @set, "$label = $sql";
            push @all_bind, @bind;
          },
          SCALARREF => sub {  # literal SQL without bind
            push @set, "$label = $$v";
          },
          HASHREF => sub {
            my ($op, $arg, @rest) = %$v;

            puke 'Operator calls in update must be in the form { -op => $arg }'
              if (@rest or not $op =~ /^\-(.+)/);

            local $self->{_nested_func_lhs} = $k;
            my ($sql, @bind) = $self->_where_unary_op($1, $arg);

            push @set, "$label = $sql";
            push @all_bind, @bind;
          },
          SCALAR_or_UNDEF => sub {
            push @set, "$label = ?";
            push @all_bind, $self->_bindtype($k, $v);
          },
        });
      }
      # generate sql
      my $sql = CORE::join ', ', @set;
      return ($sql, @all_bind);
    };
  }
}

sub update {
  my $self = shift;

  my $join_info;
  my @old_API_args;
  my $returning_into;
  my %args;
  if (&_called_with_named_args) {
    %args = validate(@_, \%params_for_update);

    # compute join info if the datasource is a join
    $join_info = $self->_compute_join_info($args{-table});
    $args{-table} = \($join_info->{sql}) if $join_info;

    @old_API_args = @args{qw/-table -set -where/};

    # deal with -returning arg
    ($returning_into, my $old_API_options) 
      = $self->_compute_returning($args{-returning});
    push @old_API_args, $old_API_options if $old_API_options;
  }
  else {
    @old_API_args = @_;
  }

  # call parent method and merge with bind values from $join_info
  my ($sql, @bind) = $self->_parent_update(@old_API_args);

  unshift @bind, @{$join_info->{bind}} if $join_info;

  # handle additional args if needed
  $self->_handle_additional_args_for_update_delete(\%args, \$sql, \@bind, qr/UPDATE/);

  # inject more stuff if using Oracle's "RETURNING ... INTO ..."
  if ($returning_into) {
    $sql .= ' INTO ' . join(", ", ("?") x @$returning_into);
    push @bind, @$returning_into;
  }

  # initial WITH clause
  $self->_prepend_WITH_clause(\$sql, \@bind);

  return ($sql, @bind);
}






#----------------------------------------------------------------------
# delete
#----------------------------------------------------------------------

sub delete {
  my $self = shift;

  my @old_API_args;
  my %args;
  if (&_called_with_named_args) {
    %args = validate(@_, \%params_for_delete);
    @old_API_args = @args{qw/-from -where/};
  }
  else {
    @old_API_args = @_;
  }

  # call parent method
  my ($sql, @bind) = $self->next::method(@old_API_args);

  # maybe need to handle additional args
  $self->_handle_additional_args_for_update_delete(\%args, \$sql, \@bind, qr/DELETE/);

  # initial WITH clause
  $self->_prepend_WITH_clause(\$sql, \@bind);

  return ($sql, @bind);
}




#----------------------------------------------------------------------
# auxiliary methods for insert(), update() and delete()
#----------------------------------------------------------------------

sub _compute_returning {
  my ($self, $arg_returning) = @_; 

  my ($returning_into, $old_API_options);

  if ($arg_returning) {
    # if present, "-returning" may be a scalar, arrayref or hashref; the latter
    # is interpreted as .. RETURNING ... INTO ...


    if (does $arg_returning, 'HASH') {
      my @keys = sort keys %$arg_returning
        or puke "-returning => {} : the hash is empty";

      $old_API_options = {returning => \@keys};
      $returning_into  = [@{$arg_returning}{@keys}];
    }
    else {
      $old_API_options = {returning => $arg_returning};
    }
  }

  return ($returning_into, $old_API_options);
}


sub _handle_additional_args_for_update_delete {
  my ($self, $args, $sql_ref, $bind_ref, $keyword_regex) = @_;

  if (defined $args->{-order_by}) {
    my ($sql_ob, @bind_ob) = $self->_order_by($args->{-order_by});
    $$sql_ref .= $sql_ob;
    push @$bind_ref, @bind_ob;
  }
  if (defined $args->{-limit}) {
    # can't call $self->limit_offset(..) because there shouldn't be any offset
    $$sql_ref .= $self->_sqlcase(' limit ?');
    push @$bind_ref, $args->{-limit};
  }
  if (defined $args->{-add_sql}) {
    $$sql_ref =~ s/\b($keyword_regex)\b/$1 $args->{-add_sql}/i;
  }
}


sub _order_by {
  my ($self, $order) = @_;

  # force scalar into an arrayref
  $order = [$order] if not ref $order;

  # restructure array data
  if (does $order, 'ARRAY') {
    my @clone = @$order;      # because we will modify items

    # '-' and '+' prefixes are translated into {-desc/asc => } hashrefs
    foreach my $item (@clone) {
      next if !$item or ref $item;
      $item =~ s/^-//  and $item = {-desc => $item} and next;
      $item =~ s/^\+// and $item = {-asc  => $item};
    }
    $order = \@clone;
  }

  return $self->next::method($order);
}

#----------------------------------------------------------------------
# other public methods
#----------------------------------------------------------------------

# same pattern for 3 invocation methods
foreach my $attr (qw/table_alias column_alias limit_offset/) {
  no strict 'refs';
  *{$attr} = sub {
    my $self = shift;
    my $method = $self->{$attr}; # grab reference to method body
    $self->$method(@_);          # invoke
  };
}

# readonly accessor methods
foreach my $key (qw/join_syntax  join_assoc_right
                    max_members_IN multicols_sep  has_multicols_in_SQL/) {
  no strict 'refs';
  *{$key} = sub {shift->{$key}};
}


# invocation method for 'join'
sub join {
  my $self = shift;

  # start from the right if right-associative
  @_ = reverse @_ if $self->{join_assoc_right};

  # shift first single item (a table) before reducing pairs (op, table)
  my $combined = shift;
  $combined    = $self->_parse_table($combined)      unless ref $combined;

  # reduce pairs (op, table)
  while (@_) {
    # shift 2 items : next join specification and next table
    my $join_spec  = shift;
    my $table_spec = shift or puke "improper number of operands";

    $join_spec  = $self->_parse_join_spec($join_spec) unless ref $join_spec;
    $table_spec = $self->_parse_table($table_spec)    unless ref $table_spec;
    $combined   = $self->_single_join($combined, $join_spec, $table_spec);
  }

  return $combined; # {sql=> .., bind => [..], aliased_tables => {..}}
}


# utility for merging several "where" clauses
sub merge_conditions {
  my $self = shift;
  my %merged;

  foreach my $cond (@_) {
    if    (does $cond, 'HASH')  {
      foreach my $col (sort keys %$cond) {
        $merged{$col} = $merged{$col} ? [-and => $merged{$col}, $cond->{$col}]
                                      : $cond->{$col};
      }
    }
    elsif (does $cond, 'ARRAY') {
      $merged{-nest} = $merged{-nest} ? {-and => [$merged{-nest}, $cond]}
                                      : $cond;
    }
    elsif ($cond) {
      $merged{$cond} = \"";
    }
  }
  return \%merged;
}

# utility for calling either bind_param or bind_param_inout
our $INOUT_MAX_LEN = 99; # chosen arbitrarily; see L<DBI/bind_param_inout>
sub bind_params {
  my ($self, $sth, @bind) = @_;
  $sth->isa('DBI::st') or puke "sth argument is not a DBI statement handle";
  foreach my $i (0 .. $#bind) {
    my $val = $bind[$i];
    if (does $val, 'SCALAR') {
      # a scalarref is interpreted as an INOUT parameter
      $sth->bind_param_inout($i+1, $val, $INOUT_MAX_LEN);
    }
    elsif (does $val, 'ARRAY' and
             my ($bind_meth, @args) = $self->is_bind_value_with_type($val)) {
      # either 'bind_param' or 'bind_param_inout', with 2 or 3 args
      $sth->$bind_meth($i+1, @args);
    }
    else {
      # other cases are passed directly to DBI::bind_param
      $sth->bind_param($i+1, $val);
    }
  }
}

sub is_bind_value_with_type {
  my ($self, $val) = @_;

  # compatibility with DBIx::Class syntax of shape [\%args => $val],
  # see L<DBIx::Class::ResultSet/"DBIC BIND VALUES">
  if (   @$val == 2
      && does($val->[0], 'HASH')
      && grep {$val->[0]{$_}} qw/dbd_attrs sqlt_size
                                 sqlt_datatype dbic_colname/) {
    my $args = $val->[0];
    if (my $attrs = $args->{dbd_attrs}) {
      return (bind_param => $val->[1], $attrs);
    }
    elsif (my $size = $args->{sqlt_size}) {
      return (bind_param_inout => $val, $size);
    }
    # other options like 'sqlt_datatype', 'dbic_colname' are not supported
    else {
      puke "unsupported options for bind type : "
           . CORE::join(", ", sort keys %$args);
    }

    # NOTE : the following DBIx::Class shortcuts are not supported
    #  [ $name => $val ] === [ { dbic_colname => $name }, $val ]
    #  [ \$dt  => $val ] === [ { sqlt_datatype => $dt }, $val ]
    #  [ undef,   $val ] === [ {}, $val ]
  }

  # in all other cases, this is not a bind value with type
  return ();
}

#----------------------------------------------------------------------
# private utility methods for 'join'
#----------------------------------------------------------------------

sub _compute_join_info {
  my ($self, $table_arg) = @_;

  if (does($table_arg, 'ARRAY') && $table_arg->[0] eq '-join') {
    my @join_args = @$table_arg;
    shift @join_args;                # drop initial '-join'
    return $self->join(@join_args);
  }
  else {
    return;
  }
}

sub _parse_table {
  my ($self, $table) = @_;

  # extract alias, if any (recognized as "table|alias")
  ($table, my $alias) = split /\|/, $table, 2;

  # build a table spec
  return {
    sql            => $self->table_alias($table, $alias),
    bind           => [],
    name           => ($alias || $table),
    aliased_tables => {$alias ? ($alias => $table) : ()},
   };
}

sub _parse_join_spec {
  my ($self, $join_spec) = @_;

  # parse the join specification
  $join_spec
    or puke "empty join specification";
  my ($op, $bracket, $cond_list) = ($join_spec =~ $self->{join_regex})
    or puke "incorrect join specification : $join_spec\n$self->{join_regex}";
  $op        ||= '<=>';
  $bracket   ||= '{';
  $cond_list ||= '';

  # extract constants (strings between quotes), replaced by placeholders
  my $regex = qr/'       # initial quote
                 (       # begin capturing group
                  [^']*    # any non-quote chars
                  (?:        # begin non-capturing group
                     ''        # pair of quotes
                     [^']*     # any non-quote chars
                  )*         # this non-capturing group 0 or more times
                 )       # end of capturing group
                 '       # ending quote
                /x;
  my $placeholder = '_?_'; # unlikely to be counfounded with any value 
  my @constants;
  while ($cond_list =~ s/$regex/$placeholder/) {
    push @constants, $1;
  };
  s/''/'/g for @constants;  # replace pairs of quotes by single quotes

  # accumulate conditions as pairs ($left => \"$op $right")
  my @conditions;
  my @using;
  foreach my $cond (split /,\s*/, $cond_list) {
    # parse the condition (left and right operands + comparison operator)
    my ($left, $cmp, $right) = split /([<>=!^]{1,2})/, $cond;
    if ($cmp && $right) {
      # if operands are not qualified by table/alias name, add sprintf hooks
      $left  = '%1$s.' . $left   unless $left  =~ /\./;
      $right = '%2$s.' . $right  unless $right =~ /\./ or $right eq $placeholder;

      # add this pair into the list; right operand is either a bind value
      # or an identifier within the right table
      $right = $right eq $placeholder ? shift @constants : {-ident => $right};
      push @conditions, $left, {$cmp => $right};
    }
    elsif ($cond =~ /^\w+$/) {
      push @using, $cond;
    }
    else {puke "can't parse join condition: $cond"}
  }

  # build join hashref
  my $join_hash = {operator  => $op};
  $join_hash->{using} = \@using                        if @using;
  $join_hash->{condition}
    = $bracket eq '[' ? [@conditions] : {@conditions}  if @conditions;

  return $join_hash;
}

sub _single_join {
  my $self = shift;

  # if right-associative, restore proper left-right order in pair
  @_ = reverse @_ if $self->{join_assoc_right};
  my ($left, $join_spec, $right) = @_;

  # syntax for assembling all elements
  my $syntax = $self->{join_syntax}{$join_spec->{operator}};

  my ($sql, @bind);

  { no if $] ge '5.022000', warnings => 'redundant';
    # because sprintf instructions  may _intentionally_ omit %.. parameters

    if ($join_spec->{using}) {
      not $join_spec->{condition}
        or puke "join specification has both {condition} and {using} fields";

      $syntax =~ s/\bON\s+%s/USING (%s)/;
      $sql = CORE::join ",", @{$join_spec->{using}};
    }
    elsif ($join_spec->{condition}) {
      not $join_spec->{using}
        or puke "join specification has both {condition} and {using} fields";

      # compute the "ON" clause
      ($sql, @bind) = $self->where($join_spec->{condition});
      $sql =~ s/^\s*WHERE\s+//;

      # substitute left/right tables names for '%1$s', '%2$s'
      $sql = sprintf $sql, $left->{name}, $right->{name};
    }

    # build the final sql
    $sql = sprintf $syntax, $left->{sql}, $right->{sql}, $sql;
  }

  # add left/right bind parameters (if any) into the list
  unshift @bind, @{$left->{bind}}, @{$right->{bind}};

  # build result and return
  my %result = (sql => $sql, bind => \@bind);
  $result{name} = ($self->{join_assoc_right} ? $left : $right)->{name};
  $result{aliased_tables} = $left->{aliased_tables};
  foreach my $alias (keys %{$right->{aliased_tables}}) {
    $result{aliased_tables}{$alias} = $right->{aliased_tables}{$alias};
  }

  return \%result;
}


#----------------------------------------------------------------------
# override of parent's "_where_field_IN"
#----------------------------------------------------------------------

sub _where_field_IN {
  my ($self, $k, $op, $vals) = @_;

  # special algorithm if the key is multi-columns (contains a multicols_sep)
  if ($self->{multicols_sep}) {
    my @cols = split m[$self->{multicols_sep}], $k;
    if (@cols > 1) {
      if ($self->{has_multicols_in_SQL}) {
        # DBMS accepts special SQL syntax for multicolumns
        return $self->_multicols_IN_through_SQL(\@cols, $op, $vals);
      }
      else {
        # DBMS doesn't accept special syntax, so we must use boolean logic
        return $self->_multicols_IN_through_boolean(\@cols, $op, $vals);
      }
    }
  }

  # special algorithm if the number of values exceeds the allowed maximum
  my $max_members_IN = $self->{max_members_IN};
  if ($max_members_IN && does($vals, 'ARRAY')
                      &&  @$vals > $max_members_IN) {
    my @vals = @$vals;
    my @slices;
    while (my @slice = splice(@vals, 0, $max_members_IN)) {
      push @slices, \@slice;
    }
    my @clauses = map {{-$op, $_}} @slices;
    my $connector = $op =~ /^not/i ? '-and' : '-or';
    unshift @clauses, $connector;
    my ($sql, @bind) = $self->where({$k => \@clauses});
    $sql =~ s/\s*where\s*\((.*)\)/$1/i;
    return ($sql, @bind);
  }


  # otherwise, call parent method
  $vals = [@$vals] if blessed $vals; # because SQLA dies on blessed arrayrefs
  return $self->next::method($k, $op, $vals);
}


sub _multicols_IN_through_SQL {
  my ($self, $cols, $op, $vals) = @_;

  # build initial sql
  my $n_cols   = @$cols;
  my $sql_cols = CORE::join(',', map {$self->_quote($_)} @$cols);
  my $sql      = "($sql_cols) " . $self->_sqlcase($op);

  # dispatch according to structure of $vals
  return $self->_SWITCH_refkind($vals, {

    ARRAYREF => sub {    # list of tuples
      # deal with special case of empty list (like the parent class)
      my $n_tuples = @$vals;
      if (!$n_tuples) {
        my $sql = ($op =~ /\bnot\b/i) ? $self->{sqltrue} : $self->{sqlfalse};
        return ($sql);
      }

      # otherwise, build SQL and bind values for the list of tuples
      my @bind;
      foreach my $val (@$vals) {
        does($val, 'ARRAY')
          or $val = [split  m[$self->{multicols_sep}], $val];
        @$val == $n_cols
          or puke "op '$op' with multicols: tuple with improper number of cols";
        push @bind, @$val;
      }
      my $single_tuple = "(" . CORE::join(',', (('?') x $n_cols)) . ")";

      my $all_tuples   = CORE::join(', ', (($single_tuple) x $n_tuples));
      $sql            .= " ($all_tuples)";
      return ($sql, @bind);
    },

    SCALARREF => sub {   # literal SQL
      $sql .= " ($$vals)";
      return ($sql);
    },

    ARRAYREFREF => sub { # literal SQL with bind
      my ($inner_sql, @bind) = @$$vals;
      $sql .= " ($inner_sql)";
      return ($sql, @bind);
    },

    FALLBACK => sub {
      puke "op '$op' with multicols requires a list of tuples or literal SQL";
    },

   });
}


sub _multicols_IN_through_boolean {
  my ($self, $cols, $op, $vals) = @_;

  # can't handle anything else than a list of tuples
  does($vals, 'ARRAY') && @$vals
    or puke "op '$op' with multicols requires a non-empty list of tuples";

  # assemble SQL
  my $n_cols   = @$cols;
  my $sql_cols = CORE::join(' AND ', map {$self->_quote($_) . " = ?"} @$cols);
  my $sql      = "(" . CORE::join(' OR ', (("($sql_cols)") x @$vals)) . ")";
  $sql         = "NOT $sql" if $op =~ /\bnot\b/i;

  # assemble bind values
  my @bind;
  foreach my $val (@$vals) {
    does($val, 'ARRAY')
      or $val = [split  m[$self->{multicols_sep}], $val];
    @$val == $n_cols
      or puke "op '$op' with multicols: tuple with improper number of cols";
    push @bind, @$val;
  }

  # return the whole thing
  return ($sql, @bind);
}



#----------------------------------------------------------------------
# override of parent's methods for decoding arrayrefs
#----------------------------------------------------------------------

sub _where_hashpair_ARRAYREF {
  my ($self, $k, $v) = @_;

  if ($self->is_bind_value_with_type($v)) {
    $self->_assert_no_bindtype_columns;
    my $sql = CORE::join ' ', $self->_convert($self->_quote($k)),
                              $self->_sqlcase($self->{cmp}),
                              $self->_convert('?');
    my @bind = ($v);
    return ($sql, @bind);
  }
  else {
    return $self->next::method($k, $v);
  }
}


sub _where_field_op_ARRAYREF {
  my ($self, $k, $op, $vals) = @_;

  if ($self->is_bind_value_with_type($vals)) {
    $self->_assert_no_bindtype_columns;
    my $sql = CORE::join ' ', $self->_convert($self->_quote($k)),
                              $self->_sqlcase($op),
                              $self->_convert('?');
    my @bind = ($vals);
    return ($sql, @bind);
  }
  else {
    return $self->next::method($k, $op, $vals);
  }
}

sub _assert_no_bindtype_columns {
  my ($self) = @_;
  $self->{bindtype} ne 'columns'
    or puke 'values of shape [$val, \%type] are not compatible'
          . 'with ...->new(bindtype => "columns")';
}



#----------------------------------------------------------------------
# method creations through closures
#----------------------------------------------------------------------

sub _make_sub_column_alias {
  my ($self) = @_;
  my $syntax = $self->{column_alias};
  $self->{column_alias} = sub {
    my ($self, $name, $alias) = @_;
    return $name if !$alias;

    # quote $name unless it is an SQL expression (then the user should quote it)
    $name = $self->_quote($name) unless $name =~ /[()]/;

    # assemble syntax
    my $sql = sprintf $syntax, $name, $self->_quote($alias);

    # return a string ref to avoid quoting by SQLA
    return \$sql;
  };
}


sub _make_sub_table_alias {
  my ($self) = @_;
  my $syntax = $self->{table_alias};
  $self->{table_alias} = sub {
    my ($self, $name, $alias) = @_;
    return $name if !$alias;

    # assemble syntax
    my $sql = sprintf $syntax, $self->_quote($name), $self->_quote($alias);

    return $sql;
  };
}



sub _choose_LIMIT_OFFSET_dialect {
  my $self = shift;
  my $dialect = $self->{limit_offset};
  my $method = $limit_offset_dialects{$dialect}
    or puke "no such limit_offset dialect: $dialect";
  $self->{limit_offset} = $method;
}


#----------------------------------------------------------------------
# utility to decide if the method was called with named or positional args
#----------------------------------------------------------------------

sub _called_with_named_args {
  return $_[0] && !ref $_[0]  && substr($_[0], 0, 1) eq '-';
}


1; # End of SQL::Abstract::More

__END__

=head1 NAME

SQL::Abstract::More - extension of SQL::Abstract with more constructs and more flexible API

=head1 DESCRIPTION

This module generates SQL from Perl data structures.  It is a subclass of
L<SQL::Abstract::Classic> or L<SQL::Abstract>, fully compatible with the parent
class, but with some improvements :

=over

=item *

methods take arguments as I<named parameters> instead of positional parameters.
This is more flexible for identifying and assembling various SQL clauses,
like C<-where>, C<-order_by>, C<-group_by>, etc.

=item *

additional SQL constructs like C<-union>, C<-group_by>, C<join>, C<with recursive>, etc.
are supported

=item *

C<WHERE .. IN> clauses can range over multiple columns (tuples)

=item *

values passed to C<select>, C<insert> or C<update> can directly incorporate
information about datatypes, in the form of arrayrefs of shape
C<< [{dbd_attrs => \%type}, $value] >>

=item *

several I<SQL dialects> can adapt the generated SQL to various DBMS vendors

=back

This module was designed for the specific needs of
L<DBIx::DataModel>, but is published as a standalone distribution,
because it may possibly be useful for other needs.

Unfortunately, this module cannot be used with L<DBIx::Class>, because
C<DBIx::Class> creates its own instance of C<SQL::Abstract>
and has no API to let the client instantiate from any other class.

=head1 SYNOPSIS

  use SQL::Abstract::More;                             # will inherit from SQL::Abstract::Classic;
  #or
  use SQL::Abstract::More -extends => 'SQL::Abstract'; # will inherit from SQL::Abstract;

  my $sqla = SQL::Abstract::More->new();
  my ($sql, @bind);

  # ex1: named parameters, select DISTINCT, ORDER BY, LIMIT/OFFSET
  ($sql, @bind) = $sqla->select(
   -columns  => [-distinct => qw/col1 col2/],
   -from     => 'Foo',
   -where    => {bar => {">" => 123}},
   -order_by => [qw/col1 -col2 +col3/],  # BY col1, col2 DESC, col3 ASC
   -limit    => 100,
   -offset   => 300,
  );

  # ex2: column aliasing, join
  ($sql, @bind) = $sqla->select(
    -columns => [         qw/Foo.col_A|a           Bar.col_B|b /],
    -from    => [-join => qw/Foo           fk=pk   Bar         /],
  );

  # ex3: INTERSECT (or similar syntax for UNION)
  ($sql, @bind) = $sqla->select(
    -columns => [qw/col1 col2/],
    -from    => 'Foo',
    -where   => {col1 => 123},
    -intersect => [ -columns => [qw/col3 col4/],
                    -from    => 'Bar',
                    -where   => {col3 => 456},
                   ],
  );

  # ex4: passing datatype specifications
  ($sql, @bind) = $sqla->select(
   -from     => 'Foo',
   -where    => {bar => [{dbd_attrs => {ora_type => ORA_XMLTYPE}}, $xml]},
  );
  my $sth = $dbh->prepare($sql);
  $sqla->bind_params($sth, @bind);
  $sth->execute;

  # ex5: multicolumns-in
  $sqla = SQL::Abstract::More->new(
    multicols_sep        => '/',
    has_multicols_in_SQL => 1,
  );
  ($sql, @bind) = $sqla->select(
   -from     => 'Foo',
   -where    => {"foo/bar/buz" => {-in => ['1/a/X', '2/b/Y', '3/c/Z']}},
  );

  # ex6: merging several criteria
  my $merged = $sqla->merge_conditions($cond_A, $cond_B, ...);
  ($sql, @bind) = $sqla->select(..., -where => $merged, ..);

  # ex7: insert / update / delete
  ($sql, @bind) = $sqla->insert(
    -add_sql => 'OR IGNORE',        # SQLite syntax
    -into    => $table,
    -values  => {col => $val, ...},
  );
  ($sql, @bind) = $sqla->insert(
    -into    => $table,
    -columns => [qw/a b/],
    -select  => {-from => 'Bar', -columns => [qw/x y/], -where => ...},
  );
  ($sql, @bind) = $sqla->update(
    -table => $table,
    -set   => {col => $val, ...},
    -where => \%conditions,
  );
  ($sql, @bind) = $sqla->delete (
    -from  => $table
    -where => \%conditions,
  );

  # ex8 : initial WITH clause -- example borrowed from https://sqlite.org/lang_with.html
  ($sql, @bind) = $sqla->with_recursive(
    [ -table     => 'parent_of',
      -columns   => [qw/name parent/],
      -as_select => {-columns => [qw/name mom/],
                     -from    => 'family',
                     -union   => [-columns => [qw/name dad/], -from => 'family']},
     ],

    [ -table     => 'ancestor_of_alice',
      -columns   => [qw/name/],
      -as_select => {-columns   => [qw/parent/],
                     -from      => 'parent_of',
                     -where     => {name => 'Alice'},
                     -union_all => [-columns => [qw/parent/],
                                    -from    => [qw/-join parent_of {name} ancestor_of_alice/]],
                 },
     ],
    )->select(
     -columns  => 'family.name',
     -from     => [qw/-join ancestor_of_alice {name} family/],
     -where    => {died => undef},
     -order_by => 'born',
    );


=head1 CLASS METHODS

=head2 import

The C<import()> method is called automatically when a client writes C<use SQL::Abstract::More>.

At this point there is a choice to make about the class to inherit from. Originally
this module was designed as an extension of L<SQL::Abstract> in its versions prior to 1.81.
Then L<SQL::Abstract> was rewritten with a largely different architecture, published
under v2.000001. A fork of the previous version is now published under L<SQL::Abstract::Classic>.
C<SQL::Abstract::More> can inherit from either version; initially it used  L<SQL::Abstract>
as the default parent, but now the default is back to L<SQL::Abstract::Classic> for better
compatibility with previous behaviours (see for example L<https://rt.cpan.org/Ticket/Display.html?id=143837>).

The choice of the parent class is made
according to the following rules :

=over

=item *

L<SQL::Abstract::Classic> is the default parent.

=item *

another parent can be specified through the C<-extends> keyword:

  use SQL::Abstract::More -extends => 'SQL::Abstract';

=item *

C<Classic> is a shorthand to C<SQL::Abstract::Classic>

  use SQL::Abstract::More -extends => 'Classic';

=item *

If the environment variable C<SQL_ABSTRACT_MORE_EXTENDS> is defined,
its value is used as an implicit C<-extends>

   BEGIN {$ENV{SQL_ABSTRACT_MORE_EXTENDS} = 'Classic';
          use SQL::Abstract::More; # will inherit from SQL::Abstract::Classic;
         }

=item *

Multiple calls to C<import()> must all resolve to the same parent; otherwise
an exception is raised.

=back


=head2 new

  my $sqla = SQL::Abstract::More->new(%options);

where C<%options> may contain any of the options for the parent
class (see L<SQL::Abstract/new>), plus the following :

=over

=item table_alias

A C<sprintf> format description for generating table aliasing clauses.
The default is C<%s AS %s>.
Can also be supplied as a method coderef (see L</"Overriding methods">).

=item column_alias

A C<sprintf> format description for generating column aliasing clauses.
The default is C<%s AS %s>.
Can also be supplied as a method coderef.

=item limit_offset

Name of a "limit-offset dialect", which can be one of
C<LimitOffset>, C<LimitXY>, C<LimitYX> or C<RowNum>; 
see L<SQL::Abstract::Limit> for an explanation of those dialects.
Here, unlike the L<SQL::Abstract::Limit> implementation,
limit and offset values are treated as regular values,
with placeholders '?' in the SQL; values are postponed to the
C<@bind> list.

The argument can also be a coderef (see below
L</"Overriding methods">). That coderef takes C<$self, $limit, $offset>
as arguments, and should return C<($sql, @bind)>. If C<$sql> contains
C<%s>, it is treated as a C<sprintf> format string, where the original
SQL is injected into C<%s>.


=item join_syntax

A hashref where keys are abbreviations for join
operators to be used in the L</join> method, and 
values are associated SQL clauses with placeholders
in C<sprintf> format. The default is described
below under the L</join> method.


=item join_assoc_right

A boolean telling if multiple joins should be associative 
on the right or on the left. Default is false (i.e. left-associative).

=item max_members_IN

An integer specifying the maximum number of members in a "IN" clause.
If the number of given members is greater than this maximum, 
C<SQL::Abstract::More> will automatically split it into separate
clauses connected by 'OR' (or connected by 'AND' if used with the
C<-not_in> operator).

  my $sqla = SQL::Abstract::More->new(max_members_IN => 3);
  ($sql, @bind) = $sqla->select(
   -from     => 'Foo',
   -where    => {foo => {-in     => [1 .. 5]}},
                 bar => {-not_in => [6 .. 10]}},
  );
  # .. WHERE (     (foo IN (?,?,?) OR foo IN (?, ?))
  #            AND (bar NOT IN (?,?,?) AND bar NOT IN (?, ?)) )


=item multicols_sep

A string or compiled regular expression used as a separator for
"multicolumns". This separator can then be used on the left-hand side
and right-hand side of an C<IN> operator, like this :

  my $sqla = SQL::Abstract::More->new(multicols_sep => '/');
  ($sql, @bind) = $sqla->select(
   -from     => 'Foo',
   -where    => {"x/y/z" => {-in => ['1/A/foo', '2/B/bar']}},
  );

Alternatively, tuple values on the right-hand side can also be given
as arrayrefs instead of plain scalars with separators :

   -where    => {"x/y/z" => {-in => [[1, 'A', 'foo'], [2, 'B', 'bar']]}},

but the left-hand side must stay a plain scalar because an array reference
wouldn't be a proper key for a Perl hash; in addition, the presence
of the separator in the string is necessary to trigger the special
algorithm for multicolumns.

The generated SQL depends on the boolean flag C<has_multicols_in_SQL>,
as explained in the next paragraph.

=item has_multicols_in_SQL

A boolean flag that controls which kind of SQL will be generated for
multicolumns. If the flag is B<true>, this means that the underlying DBMS
supports multicolumns in SQL, so we just generate tuple expressions.
In the example from the previous paragraph, the SQL and bind values
would be :

   # $sql  : "WHERE (x, y, z) IN ((?, ?, ?), (?, ?, ?))"
   # @bind : [ qw/1 A foo 2 B bar/ ]

It is also possible to use a subquery, like this :

  ($sql, @bind) = $sqla->select(
   -from     => 'Foo',
   -where    => {"x/y/z" => {-in => \[ 'SELECT (a, b, c) FROM Bar '
                                       . 'WHERE a > ?', 99]}},
  );
  # $sql  : "WHERE (x, y, z) IN (SELECT (a, b, c) FROM Bar WHERE a > ?)"
  # @bind : [ 99 ]

If the flag is B<false>, the condition on tuples will be
automatically converted using boolean logic :

   # $sql  : "WHERE (   (x = ? AND y = ? AND z = ?) 
                     OR (x = ? AND y = ? AND z = ?))"
   # @bind : [ qw/1 A foo 2 B bar/ ]

If the flag is false, subqueries are not allowed.


=item select_implicitly_for

A value that will be automatically added as a C<-for> clause in
calls to L</select>. This default clause can always be overridden
by an explicit C<-for> in a given select :

  my $sqla = SQL::Abstract->new(-select_implicitly_for => 'READ ONLY');
  ($sql, @bind) = $sqla->select(-from => 'Foo');
    # SELECT * FROM FOO FOR READ ONLY
  ($sql, @bind) = $sqla->select(-from => 'Foo', -for => 'UPDATE');
    # SELECT * FROM FOO FOR UPDATE
  ($sql, @bind) = $sqla->select(-from => 'Foo', -for => undef);
    # SELECT * FROM FOO

=item sql_dialect

This is actually a "meta-argument" : it injects a collection
of regular arguments, tuned for a specific SQL dialect.
Dialects implemented so far are :

=over

=item MsAccess

For Microsoft Access. Overrides the C<join> syntax to be right-associative.

=item BasisJDBC

For Livelink Collection Server (formerly "Basis"), accessed
through a JDBC driver. Overrides the C<column_alias> syntax.
Sets C<max_members_IN> to 255.

=item MySQL_old

For old versions of MySQL. Overrides the C<limit_offset> syntax.
Recent versions of MySQL do not need that because they now
implement the regular "LIMIT ? OFFSET ?" ANSI syntax.

=item Oracle

For Oracle. Overrides the C<limit_offset> to use the "RowNum" dialect
(beware, this injects an additional column C<rownum__index> into your
resultset). Also sets C<max_members_IN> to 999.

=back

=back

=head3 Overriding methods

Several arguments to C<new()> can be references to method
implementations instead of plain scalars : this allows you to
completely redefine a behaviour without the need to subclass.  Just
supply a regular method body as a code reference : for example, if you
need another implementation for LIMIT-OFFSET, you could write

  my $sqla = SQL::Abstract::More->new(
    limit_offset => sub {
      my ($self, $limit, $offset) = @_;
      defined $limit or die "NO LIMIT!"; #:-)
      $offset ||= 0;
      my $last = $offset + $limit;
      return ("ROWS ? TO ?", $offset, $last); # ($sql, @bind)
     });


=head1 INSTANCE METHODS

=head2 select

  # positional parameters, directly passed to the parent class
  ($sql, @bind) = $sqla->select($table, $columns, $where, $order);

  # named parameters, handled in this class 
  ($sql, @bind) = $sqla->select(
    -columns  => \@columns,
      # OR: -columns => [-distinct => @columns],
    -from     => $table || \@joined_tables,
    -where    => \%where,
    -union    => [ %select_subargs ], # OR -intersect, -minus, etc
    -order_by => \@order,
    -group_by => \@group_by,
    -having   => \%having_criteria,
    -limit => $limit, -offset => $offset,
      # OR: -page_size => $size, -page_index => $index,
    -for      => $purpose,
   );

  my $details = $sqla->select(..., want_details => 1);
  # keys in %$details: sql, bind, aliased_tables, aliased_columns

If called with positional parameters, as in L<SQL::Abstract>, 
C<< select() >> just forwards the call to the parent class. Otherwise, if
called with named parameters, as in the example above, some additional
SQL processing is performed.

The following named arguments can be specified :

=over

=item C<< -columns => \@columns >> 

C<< \@columns >>  is a reference to an array
of SQL column specifications (i.e. column names, 
C<*> or C<table.*>, functions, etc.).

A '|' in a column is translated into a column aliasing clause:
this is convenient when
using perl C<< qw/.../ >> operator for columns, as in

  -columns => [ qw/table1.longColumn|t1lc table2.longColumn|t2lc/ ]

SQL column aliasing is then generated through the L</column_alias> method.
If L<SQL::Abstract/quote_char> is defined, aliased columns will be quoted,
unless they contain parentheses, in which case they are considered as
SQL expressions for which the user should handle the quoting himself.
For example if C<quote_char> is "`", 

  -columns => [ qw/foo.bar|fb length(buz)|lbuz/ ]

will produce

  SELECT `foo`.`bar` AS fb, length(buz) AS lbuz

and not

  SELECT `foo`.`bar` AS fb, length(`buz`) AS lbuz


Initial items in C<< @columns >> that start with a minus sign
are shifted from the array, i.e. they are not considered as column
names, but are re-injected later into the SQL (without the minus sign), 
just after the C<SELECT> keyword. This is especially useful for 

  $sqla->select(..., -columns => [-DISTINCT => @columns], ...);

However, it may also be useful for other purposes, like
vendor-specific SQL variants :

   # MySQL features
  ->select(..., -columns => [-STRAIGHT_JOIN    => @columns], ...);
  ->select(..., -columns => [-SQL_SMALL_RESULT => @columns], ...);

   # Oracle hint
  ->select(..., -columns => ["-/*+ FIRST_ROWS (100) */" => @columns], ...);

The argument to C<-columns> can also be a string instead of 
an arrayref, like for example
C<< "c1 AS foobar, MAX(c2) AS m_c2, COUNT(c3) AS n_c3" >>;
however this is mainly for backwards compatibility. The 
recommended way is to use the arrayref notation as explained above :

  -columns => [ qw/  c1|foobar   MAX(c2)|m_c2   COUNT(c3)|n_c3  / ]

If omitted, C<< -columns >> takes '*' as default argument.

=item C<< -from => $table || \@joined_tables >> 


=item C<< -where => $criteria >>

Like in L<SQL::Abstract>, C<< $criteria >> can be 
a plain SQL string like C<< "col1 IN (3, 5, 7, 11) OR col2 IS NOT NULL" >>;
but in most cases, it will rather be a reference to a hash or array of
conditions that will be translated into SQL clauses, like
for example C<< {col1 => 'val1', col2 => 'val2'} >>.
The structure of that hash or array can be nested to express complex
boolean combinations of criteria; see
L<SQL::Abstract/"WHERE CLAUSES"> for a detailed description.

When using hashrefs or arrayrefs, leaf values can be "bind values with types";
see the L</"BIND VALUES WITH TYPES"> section below.

=item C<< -union => [ %select_subargs ] >>

=item C<< -union_all => [ %select_subargs ] >>

=item C<< -intersect => [ %select_subargs ] >>

=item C<< -except => [ %select_subargs ] >>

=item C<< -minus => [ %select_subargs ] >>

generates a compound query using set operators such as C<UNION>,
C<INTERSECT>, etc. The argument C<%select_subargs> contains a nested
set of parameters like for the main select (i.e. C<-columns>,
C<-from>, C<-where>, etc.); however, arguments C<-columns> and
C<-from> can be omitted, in which case they will be copied from the
main select(). Several levels of set operators can be nested.

=item C<< -group_by => "string" >>  or C<< -group_by => \@array >> 

adds a C<GROUP BY> clause in the SQL statement. Grouping columns are
specified either by a plain string or by an array of strings.

=item C<< -having => "string" >>  or C<< -having => \%criteria >> 

adds a C<HAVING> clause in the SQL statement. In most cases this is used
together with a C<GROUP BY> clause.
This is like a C<-where> clause, except that the criteria
are applied after grouping has occurred.


=item C<< -order_by => \@order >>

C<< \@order >> is a reference to a list 
of columns for sorting. Columns can 
be prefixed by '+' or '-' for indicating sorting directions,
so for example C<< -orderBy => [qw/-col1 +col2 -col3/] >>
will generate the SQL clause
C<< ORDER BY col1 DESC, col2 ASC, col3 DESC >>.

Column names C<asc> and C<desc> are treated as exceptions to this
rule, in order to preserve compatibility with L<SQL::Abstract>.
So C<< -orderBy => [-desc => 'colA'] >> yields
C<< ORDER BY colA DESC >> and not C<< ORDER BY desc DEC, colA >>.
Any other syntax supported by L<SQL::Abstract> is also
supported here; see L<SQL::Abstract/"ORDER BY CLAUSES"> for examples.

The whole C<< -order_by >> parameter can also be a plain SQL string
like C<< "col1 DESC, col3, col2 DESC" >>.

=item C<< -page_size => $page_size >>

specifies how many rows will be retrieved per "page" of data.
Default is unlimited (or more precisely the maximum 
value of a short integer on your system).
When specified, this parameter automatically implies C<< -limit >>.

=item C<< -page_index => $page_index >>

specifies the page number (starting at 1). Default is 1.
When specified, this parameter automatically implies C<< -offset >>.

=item C<< -limit => $limit >>

limit to the number of rows that will be retrieved.
Automatically implied by C<< -page_size >>.

=item C<< -offset => $offset >>

Automatically implied by C<< -page_index >>.
Defaults to 0.

=item C<< -for => $clause >> 

specifies an additional clause to be added at the end of the SQL statement,
like C<< -for => 'READ ONLY' >> or C<< -for => 'UPDATE' >>.

=item C<< -want_details => 1 >>

If true, the return value will be a hashref instead of the usual
C<< ($sql, @bind) >>. The hashref contains the following keys :

=over

=item sql

generated SQL

=item bind

bind values

=item aliased_tables

a hashref of  C<< {table_alias => table_name} >> encountered while
parsing the C<-from> parameter.

=item aliased_columns

a hashref of  C<< {column_alias => column_name} >> encountered while
parsing the C<-columns> parameter.

=back


=back



=head2 insert

  # positional parameters, directly passed to the parent class
  ($sql, @bind) = $sqla->insert($table, \@values || \%fieldvals, \%options);

  # named parameters, handled in this class
  ($sql, @bind) = $sqla->insert(
    -into      => $table,
    -values    => {col => $val, ...},
    -returning => $return_structure,
    -add_sql   => $keyword,
  );

  # insert from a subquery
  ($sql, @bind) = $sqla->insert(
    -into    => $destination_table,
    -columns => \@columns_into
    -select  => {-from => $source_table, -columns => \@columns_from, -where => ...},
  );

Like for L</select>, values assigned to columns can have associated
SQL types; see L</"BIND VALUES WITH TYPES">.

Parameters C<-into> and C<-values> are passed verbatim to the parent method.

Parameters C<-select> and C<-columns> are used for selecting from
subqueries -- this is incompatible with the C<-values> parameter.

Parameter C<-returning> is optional and only
supported by some database vendors (see L<SQL::Abstract/insert>);
if the C<$return_structure> is 

=over

=item *

a scalar or an arrayref, it is passed directly to the parent method

=item *

a hashref, it is interpreted as a SQL clause "RETURNING .. INTO ..",
as required in particular by Oracle. Hash keys are field names, and
hash values are references to variables that will receive the
results. Then it is the client code's responsibility
to use L<DBD::Oracle/bind_param_inout> for binding the variables
and retrieving the results, but the L</bind_params> method in the
present module is there for help. Example:

  ($sql, @bind) = $sqla->insert(
    -into      => $table,
    -values    => {col => $val, ...},
    -returning => {key_col => \my $generated_key},
  );

  my $sth = $dbh->prepare($sql);
  $sqla->bind_params($sth, @bind);
  $sth->execute;
  print "The new key is $generated_key";

=back

Optional parameter C<-add_sql> is used with some specific SQL dialects, for
injecting additional SQL keywords after the C<INSERT> keyword. Examples :

  $sqla->insert(..., -add_sql => 'IGNORE')     # produces "INSERT IGNORE ..."    -- MySQL
  $sqla->insert(..., -add_sql => 'OR IGNORE')  # produces "INSERT OR IGNORE ..." -- SQLite



=head2 update

  # positional parameters, directly passed to the parent class
  ($sql, @bind) = $sqla->update($table, \%fieldvals, \%where);

  # named parameters, handled in this class
  ($sql, @bind) = $sqla->update(
    -table     => $table,
    -set       => {col => $val, ...},
    -where     => \%conditions,
    -order_by  => \@order,
    -limit     => $limit,
    -returning => $return_structure,
    -add_sql   => $keyword,
  );

This works in the same spirit as the L</insert> method above.
Positional parameters are supported for backwards compatibility
with the old API; but named parameters should be preferred because
they improve the readability of the client's code.

Few DBMS would support parameters C<-order_by> and C<-limit>, but
MySQL does -- see L<http://dev.mysql.com/doc/refman/5.6/en/update.html>.

Optional parameter C<-returning> works like for the L</insert> method.

Optional parameter C<-add_sql> is used with some specific SQL dialects, for
injecting additional SQL keywords after the C<UPDATE> keyword. Examples :

  $sqla->update(..., -add_sql => 'IGNORE')     # produces "UPDATE IGNORE ..."    -- MySQL
  $sqla->update(..., -add_sql => 'OR IGNORE')  # produces "UPDATE OR IGNORE ..." -- SQLite

=head2 delete

  # positional parameters, directly passed to the parent class
  ($sql, @bind) = $sqla->delete($table, \%where);

  # named parameters, handled in this class 
  ($sql, @bind) = $sqla->delete (
    -from     => $table
    -where    => \%conditions,
    -order_by => \@order,
    -limit    => $limit,
    -add_sql  => $keyword,
  );

Positional parameters are supported for backwards compatibility
with the old API; but named parameters should be preferred because
they improve the readability of the client's code.

Few DBMS would support parameters C<-order_by> and C<-limit>, but
MySQL does -- see L<http://dev.mysql.com/doc/refman/5.6/en/update.html>.

Optional parameter C<-add_sql> is used with some specific SQL dialects, for
injecting additional SQL keywords after the C<DELETE> keyword. Examples :

  $sqla->delete(..., -add_sql => 'IGNORE')     # produces "DELETE IGNORE ..."    -- MySQL
  $sqla->delete(..., -add_sql => 'OR IGNORE')  # produces "DELETE OR IGNORE ..." -- SQLite


=head2 with_recursive, with

  my $new_sqla = $sqla->with_recursive( # or: $sqla->with(

    [ -table     => $CTE_table_name,
      -columns   => \@CTE_columns,
      -as_select => \%select_args ],

    [ -table     => $CTE_table_name2,
      -columns   => \@CTE_columns2,
      -as_select => \%select_args2 ],
    ...

   );
   ($sql, @bind) = $new_sqla->insert(...);
  
  # or, if there is only one table expression
  my $new_sqla = $sqla->with_recursive(
      -table     => $CTE_table_name,
      -columns   => \@CTE_columns,
      -as_select => \%select_args,
     );


Returns a new instance with an encapsulated I<common table expression (CTE)>, i.e. a
kind of local view that can be used as a table name for the rest of the SQL statement
-- see L<https://en.wikipedia.org/wiki/Hierarchical_and_recursive_queries_in_SQL> for
an explanation of such expressions, or, if you are using Oracle, see the documentation
for so-called I<subquery factoring clauses> in SELECT statements.

Further calls to C<select>, C<insert>, C<update> and C<delete> on that new instance
will automatically prepend a C<WITH> or C<WITH RECURSIVE> clause before the usual
SQL statement.

Arguments to C<with_recursive()> are expressed as a list of arrayrefs; each arrayref
corresponds to one table expression, with the following named parameters :

=over

=item C<-table>

The name to be assigned to the table expression

=item C<-columns>

An optional list of column aliases to be assigned to the
columns resulting from the internal select

=item C<-as_select>

The implementation of the table expression, given as a hashref
of arguments following the same syntax as the L</select> method.

=item C<-final_clause>

An optional SQL clause that will be added after the table expression.
This may be needed for example for an Oracle I<cycle clause>, like

  ($sql, @bind) = $sqla->with_recursive(
    -table        => ...,
    -as_select    => ...,
    -final_clause => "CYCLE x SET is_cycle TO '1' DEFAULT '0'",
   )->select(...);


=back

If there is only one table expression, its arguments can be passed directly
as an array instead of a single arrayref.


=head2 table_alias


  my $sql = $sqla->table_alias($table_name, $alias);

Returns the SQL fragment for aliasing a table.
If C<$alias> is empty, just returns C<$table_name>.

=head2 column_alias

Like C<table_alias>, but for column aliasing.

=head2 limit_offset

  ($sql, @bind) = $sqla->limit_offset($limit, $offset);

Generates C<($sql, @bind)> for a LIMIT-OFFSET clause.

=head2 join

  my $join_info = $sqla->join(
    <table0> <join_1> <table_1> ... <join_n> <table_n>
  );
  my $sth = $dbh->prepare($join_info->{sql});
  $sth->execute(@{$join_info->{bind}})
  while (my ($alias, $aliased) = each %{$join_info->{aliased_tables}}) {
    say "$alias is an alias for table $aliased";
  }

Generates join information for a JOIN clause, taking as input
a collection of joined tables with their join conditions.
The following example gives an idea of the available syntax :

  ($sql, @bind) = $sqla->join(qw[
     Table1|t1       ab=cd                     Table2|t2
                 <=>{ef>gh,ij<kl,mn='foobar'}  Table3
                  =>{t1.op=qr}                 Table4
     ]);

This will generate

  Table1 AS t1 INNER JOIN Table2 AS t2 ON t1.ab=t2.cd
               INNER JOIN Table3       ON t2.ef>Table3.gh
                                      AND t2.ij<Table3.kl
                                      AND t2.mn=?
                LEFT JOIN Table4       ON t1.op=Table4.qr

with one bind value C<foobar>.

More precisely, the arguments to C<join()> should be a list
containing an odd number of elements, where the odd positions
are I<table specifications> and the even positions are
I<join specifications>.

=head3 Table specifications

A table specification for join is a string containing
the table name, possibly followed by a vertical bar
and an alias name. For example C<Table1> or C<Table1|t1>
are valid table specifications.

These are converted into internal hashrefs with keys
C<sql>, C<bind>, C<name>, C<aliased_tables>, like this :

  {
    sql            => "Table1 AS t1"
    bind           => [],
    name           => "t1"
    aliased_tables => {"t1" => "Table1"}
  }

Such hashrefs can be passed directly as arguments,
instead of the simple string representation.

=head3 Join specifications

A join specification is a string containing
an optional I<join operator>, possibly followed
by a pair of curly braces or square brackets
containing the I<join conditions>.

Default builtin join operators are
C<< <=> >>, C<< => >>, C<< <= >>, C<< == >>,
corresponding to the following
SQL JOIN clauses :

  '<=>' => '%s INNER JOIN %s ON %s',
   '=>' => '%s LEFT OUTER JOIN %s ON %s',
  '<='  => '%s RIGHT JOIN %s ON %s',
  '=='  => '%s NATURAL JOIN %s',
  '>=<' => '%s FULL OUTER JOIN %s ON %s',

This operator table can be overridden through
the C<join_syntax> parameter of the L</new> method.

The join conditions are a comma-separated list
of binary column comparisons, like for example

  {ab=cd,Table1.ef<Table2.gh}

Table names may be explicitly given using dot notation,
or may be implicit, in which case they will be filled
automatically from the names of operands on the
left-hand side and right-hand side of the join.

Strings within quotes will be treated as bind values instead
of column names; pairs of quotes within such values become
single quotes. Ex.

  {ab=cd,ef='foo''bar',gh<ij}

becomes

  ON Table1.ab=Table2.cd AND Table1.ef=? AND Table1.gh<Table2.ij
  # bind value: "foo'bar"

In accordance with L<SQL::Abstract> common conventions,
if the list of comparisons is within curly braces, it will
become an C<AND>; if it is within square brackets, it will
become an C<OR>.

Join specifications expressed as strings
are converted into internal hashrefs with keys
C<operator> and C<condition>, like this :

  {
    operator  => '<=>',
    condition => { '%1$s.ab' => {'=' => {-ident => '%2$s.cd'}},
                   '%1$s.ef' => {'=' => {-ident => 'Table2.gh'}}},
  }

The C<operator> is a key into the C<join_syntax> table; the associated
value is a C<sprintf> format string, with placeholders for the left and
right operands, and the join condition.  The C<condition> is a
structure suitable for being passed as argument to
L<SQL::Abstract/where>.  Places where the names of left/right tables
(or their aliases) are expected should be expressed as C<sprintf>
placeholders, i.e.  respectively C<%1$s> and C<%2$s>. Usually the
right-hand side of the condition refers to a column of the right
table; in such case it should B<not> belong to the C<@bind> list, so
this is why we need to use the C<-ident> operator from
L<SQL::Abstract>. Only when the right-hand side is a string constant
(string within quotes) does it become a bind value : for example

  ->join(qw/Table1 {ab=cd,ef='foobar'}) Table2/)

is parsed into

  [ 'Table1',
    { operator  => '<=>',
      condition => { '%1$s.ab' => {'=' => {-ident => '%2$s.cd'}},
                     '%1$s.ef' => {'=' => 'foobar'} },
    },
    'Table2',
  ]

Hashrefs for join specifications as shown above can be passed directly
as arguments, instead of the simple string representation.
For example the L<DBIx::DataModel> ORM uses hashrefs for communicating
with C<SQL::Abstract::More>.

=head3 joins with USING clause instead of ON

In most DBMS, when column names on both sides of a join are identical, the join
can be expressed as

  SELECT * FROM T1 INNER JOIN T2 USING (A, B)

instead of

  SELECT * FROM T1 INNER JOIN T2 ON T1.A=T2.A AND T1.B=T2.B

The advantage of this syntax with a USING clause is that the joined
columns will appear only once in the results, and they do not need to
be prefixed by a table name if they are needed in the select list or
in the WHERE part of the SQL.

To express joins with the USING syntax in C<SQL::Abstract::More>, just
mention the column names within curly braces, without any equality
operator. For example

  ->join(qw/Table1 {a,b} Table2 {c} Table3/)

will generate

  SELECT * FROM Table1 INNER JOIN Table2 USING (a,b)
                       INNER JOIN Table3 USING (c)

In this case the internal hashref representation has the following shape :

  {
    operator  => '<=>',
    using     => [ 'a', 'b'],
  }

When they are generated directy by the client code, internal hashrefs
must have I<either> a C<condition> field I<or> a C<using> field; it is
an error to have both.


=head3 Return value

The structure returned by C<join()> is a hashref with 
the following keys :

=over

=item sql

a string containing the generated SQL

=item bind

an arrayref of bind values

=item aliased_tables

a hashref where keys are alias names and values are names of aliased tables.

=back


=head2 merge_conditions

  my $conditions = $sqla->merge_conditions($cond_A, $cond_B, ...);

This utility method takes a list of "C<where>" conditions and
merges all of them in a single hashref. For example merging

  ( {a => 12, b => {">" => 34}}, 
    {b => {"<" => 56}, c => 78} )

produces 

  {a => 12, b => [-and => {">" => 34}, {"<" => 56}], c => 78});


=head2 bind_params

  $sqla->bind_params($sth, @bind);

For each C<$value> in C<@bind>:

=over 

=item *

if the value is a scalarref, call

  $sth->bind_param_inout($index, $value, $INOUT_MAX_LEN)

(see L<DBI/bind_param_inout>). C<$INOUT_MAX_LEN> defaults to
99, which should be good enough for most uses; should you need another value, 
you can change it by setting

  local $SQL::Abstract::More::INOUT_MAX_LEN = $other_value;

=item *

if the value is an arrayref that matches L</is_bind_value_with_type>,
then call the method and arguments returned by L</is_bind_value_with_type>.

=item *

for all other cases, call

  $sth->bind_param($index, $value);

=back

This method is useful either as a convenience for Oracle
statements of shape C<"INSERT ... RETURNING ... INTO ...">
(see L</insert> method above), or as a way to indicate specific
datatypes to the database driver.

=head2 is_bind_value_with_type

  my ($method, @args) = $sqla->is_bind_value_with_type($value);


If C<$value> is a ref to a pair C<< [\%args, $orig_value] >> :


=over 

=item *

if  C<%args> is of shape C<< {dbd_attrs => \%sql_type} >>,
then return C<< ('bind_param', $orig_value, \%sql_type) >>.

=item *

if  C<%args> is of shape C<< {sqlt_size => $num} >>,
then return C<< ('bind_param_inout', $orig_value, $num) >>.

=back

Otherwise, return C<()>.



=head1 BIND VALUES WITH TYPES

At places where L<SQL::Abstract> would expect a plain value,
C<SQL::Abstract::More> also accepts a pair, i.e. an arrayref of 2
elements, where the first element is a type specification, and the
second element is the value. This is convenient when the DBD driver needs
additional information about the values used in the statement.

The usual type specification is a hashref C<< {dbd_attrs => \%type} >>,
where C<\%type> is passed directly as third argument to
L<DBI/bind_param>, and therefore is specific to the DBD driver.

Another form of type specification is C<< {sqlt_size => $num} >>,
where C<$num> will be passed as buffer size to L<DBI/bind_param_inout>.

Here are some examples

  ($sql, @bind) = $sqla->insert(
   -into   => 'Foo',
   -values => {bar => [{dbd_attrs => {ora_type => ORA_XMLTYPE}}]},
  );
  ($sql, @bind) = $sqla->select(
   -from  => 'Foo',
   -where => {d_begin => {">" => [{dbd_attrs => {ora_type => ORA_DATE}}, 
                                  $some_date]}},
  );


When using this feature, the C<@bind> array will contain references
that cannot be passed directly to L<DBI> methods; so you should use
L</bind_params> from the present module to perform the appropriate
bindings before executing the statement.


=head1 UTILITY FUNCTIONS

=head2 shallow_clone

  my $clone = SQL::Abstract::More::shallow_clone($some_object, %override);

Returns a shallow copy of the object passed as argument. A new hash is created
with copies of the top-level keys and values, and it is blessed into the same
class as the original object. Not to be confused with the full recursive copy
performed by L<Clone/clone>.

The optional C<%override> hash is also copied into C<$clone>; it can be used
to add other attributes or to override existing attributes in C<$some_object>.

=head2 does()

  if (SQL::Abstract::More::does $ref, 'ARRAY') {...}

Very cheap version of a C<does()> method, that
checks whether a given reference can act as an ARRAY, HASH, SCALAR or
CODE. This was designed for the limited internal needs of this module
and of L<DBIx::DataModel>; for more complete implementations of a
C<does()> method, see L<Scalar::Does>, L<UNIVERSAL::DOES> or
L<Class::DOES>.


=head1 AUTHOR

Laurent Dami, C<< <laurent dot dami at cpan dot org> >>

=head1 ACKNOWLEDGEMENTS

=over

=item L<https://github.com/rouzier> : support for C<-having> without C<-order_by>

=back


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SQL::Abstract::More


The same documentation is also available at
L<https://metacpan.org/module/SQL::Abstract::More>


=head1 LICENSE AND COPYRIGHT

Copyright 2011-2022 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


