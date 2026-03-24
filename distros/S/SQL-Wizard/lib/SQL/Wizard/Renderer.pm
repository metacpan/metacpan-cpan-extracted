package SQL::Wizard::Renderer;

use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed);

my $INJECTION_GUARD = qr/
    \;
      |
    ^ \s* go \s
/xmi;

my %VALID_OPS = map { $_ => 1 }
  '=', '!=', '<>', '<', '>', '<=', '>=',
  'LIKE', 'NOT LIKE', 'ILIKE', 'NOT ILIKE',
  '-IN', '-NOT_IN';

sub new {
  my ($class, %args) = @_;
  bless \%args, $class;
}

# Combined reserved words (PostgreSQL + MySQL + ANSI SQL)
my %RESERVED = map { $_ => 1 } qw(
  ACCESSIBLE ADD ALL ALTER ANALYZE AND ANY ARRAY AS ASC ASENSITIVE ASYMMETRIC
  BEFORE BETWEEN BIGINT BINARY BLOB BOTH BY
  CALL CASCADE CASE CAST CHANGE CHAR CHARACTER CHECK COLLATE COLUMN CONCURRENTLY
  CONDITION CONSTRAINT CONTINUE CONVERT CREATE CROSS CUBE CUME_DIST CURRENT_DATE
  CURRENT_TIME CURRENT_TIMESTAMP CURRENT_USER CURSOR
  DATABASE DATABASES DAY_HOUR DAY_MICROSECOND DAY_MINUTE DAY_SECOND DEC DECIMAL
  DECLARE DEFAULT DEFERRABLE DELAYED DELETE DENSE_RANK DESC DESCRIBE DETERMINISTIC
  DISTINCT DISTINCTROW DIV DO DOUBLE DROP DUAL
  EACH ELSE ELSEIF EMPTY ENCLOSED END ESCAPED EXCEPT EXISTS EXIT EXPLAIN
  FALSE FETCH FIRST_VALUE FLOAT FLOAT4 FLOAT8 FOR FORCE FOREIGN FREEZE FROM
  FULL FULLTEXT FUNCTION
  GENERATED GET GRANT GROUP GROUPING GROUPS
  HAVING HIGH_PRIORITY HOUR_MICROSECOND HOUR_MINUTE HOUR_SECOND
  IF IGNORE IN INDEX INFILE INITIALLY INNER INOUT INSENSITIVE INSERT INT INT1
  INT2 INT3 INT4 INT8 INTEGER INTERSECT INTERVAL INTO IO_AFTER_GTIDS
  IO_BEFORE_GTIDS IS ISNULL ITERATE
  JOIN JSON_TABLE
  KEY KEYS KILL
  LAG LAST_VALUE LATERAL LEAD LEADING LEAVE LEFT LIKE LIMIT LINEAR LINES LOAD
  LOCALTIME LOCALTIMESTAMP LOCK LONG LONGBLOB LONGTEXT LOOP LOW_PRIORITY
  MASTER_BIND MASTER_SSL_VERIFY_SERVER_CERT MATCH MAXVALUE MEDIUMBLOB MEDIUMINT
  MEDIUMTEXT MIDDLEINT MOD MODIFIES
  NATURAL NOT NOTNULL NO_WRITE_TO_BINLOG NTH_VALUE NTILE NULL NUMERIC
  OF ON ONLY OPTIMIZE OPTIMIZER_COSTS OPTION OPTIONALLY OR ORDER OUT OUTER
  OUTFILE OVER OVERLAPS
  PARTITION PRECISION PRIMARY PROCEDURE PURGE
  RANGE READ READS READ_WRITE REAL RECURSIVE REFERENCES REGEXP RELEASE RENAME
  REPEAT REPLACE REQUIRE RESIGNAL RESTRICT RETURN REVOKE RIGHT RLIKE ROW ROWS
  ROW_NUMBER
  SCHEMA SCHEMAS SELECT SENSITIVE SEPARATOR SET SHOW SIGNAL SIMILAR SOME SPATIAL
  SPECIFIC SQL SQLEXCEPTION SQLSTATE SQLWARNING SQL_BIG_RESULT SQL_CALC_FOUND_ROWS
  SQL_SMALL_RESULT SSL STARTING STORED STRAIGHT_JOIN SYMMETRIC SYSTEM
  TABLE TABLESAMPLE TERMINATED THEN TINYBLOB TINYINT TINYTEXT TO TRAILING
  TRIGGER TRUE
  UNDO UNION UNIQUE UNLOCK UNSIGNED UPDATE USAGE USE USING UTC_DATE UTC_TIME
  UTC_TIMESTAMP
  VALUES VARBINARY VARCHAR VARCHARACTER VARIADIC VARYING VERBOSE VIRTUAL
  WHEN WHERE WHILE WINDOW WITH WRITE
  XOR YEAR_MONTH ZEROFILL
);

sub _needs_quoting {
  my ($self, $part) = @_;
  return 0 if $part eq '*';
  return 1 if $RESERVED{uc $part};
  return 1 if $part =~ /[A-Z]/;
  return 1 if $part =~ /[^a-z0-9_]/;
  return 0;
}

sub _quote_ident {
  my ($self, $name) = @_;
  my $q = ($self->{dialect} || 'ansi') eq 'mysql' ? '`' : '"';
  return join('.', map {
    $_ eq '*' ? $_ : $q . (s/\Q$q\E/$q$q/gr) . $q
  } split /\./, $name, -1);
}

sub _quote_ident_if_needed {
  my ($self, $name) = @_;
  my @parts = split /\./, $name, -1;
  return $name unless grep { $self->_needs_quoting($_) } @parts;
  return $self->_quote_ident($name);
}

sub _injection_guard {
  my ($self, $string) = @_;
  if ($string =~ $INJECTION_GUARD) {
    confess "Possible SQL injection attempt '$string'. "
      . "If this is indeed a part of the desired SQL, use raw()";
  }
}

sub _assert_column {
  my ($self, $col) = @_;
  confess "Invalid column name '$col'"
    unless $col =~ /^(\w+\.)*(\w+|\*)$/;
}

sub _assert_order_column {
  my ($self, $col) = @_;
  confess "Invalid order_by column '$col'"
    unless $col =~ /^(\w+\.)*\w+$/;
}

sub _assert_integer {
  my ($self, $name, $value) = @_;
  confess "$name must be an integer, got '$value'"
    unless $value =~ /^\d+$/;
}

# Main dispatch
sub render {
  my ($self, $node) = @_;
  my $type = ref $node;

  my %dispatch = (
    'SQL::Wizard::Expr::Column'   => \&_render_column,
    'SQL::Wizard::Expr::Value'    => \&_render_value,
    'SQL::Wizard::Expr::Raw'      => \&_render_raw,
    'SQL::Wizard::Expr::Alias'    => \&_render_alias,
    'SQL::Wizard::Expr::Order'    => \&_render_order,
    'SQL::Wizard::Expr::Func'     => \&_render_func,
    'SQL::Wizard::Expr::BinaryOp' => \&_render_binop,
    'SQL::Wizard::Expr::Select'   => \&_render_select,
    'SQL::Wizard::Expr::Join'     => \&_render_join,
    'SQL::Wizard::Expr::Case'     => \&_render_case,
    'SQL::Wizard::Expr::Window'   => \&_render_window,
    'SQL::Wizard::Expr::Compound' => \&_render_compound,
    'SQL::Wizard::Expr::CTE'      => \&_render_cte,
    'SQL::Wizard::Expr::Insert'   => \&_render_insert,
    'SQL::Wizard::Expr::Update'   => \&_render_update,
    'SQL::Wizard::Expr::Delete'   => \&_render_delete,
  );

  my $handler = $dispatch{$type}
    or croak "No renderer for node type: $type";
  $handler->($self, $node);
}

# Render any expression or plain string (column name)
sub _render_expr {
  my ($self, $thing) = @_;
  return ('', ()) unless defined $thing;
  if (blessed($thing) && $thing->isa('SQL::Wizard::Expr')) {
    return $self->render($thing);
  }
  # Plain string = column name
  $self->_injection_guard($thing);
  return ($self->_quote_ident_if_needed($thing), ());
}

# table|alias => table alias
sub _expand_table {
  my ($self, $thing) = @_;
  if (blessed($thing) && $thing->isa('SQL::Wizard::Expr')) {
    return $self->render($thing);
  }
  confess "Invalid table name '$thing'"
    unless $thing =~ /^(\w+\.)*\w+(\|\w+)?$/;
  my ($table, $alias) = split /\|/, $thing, 2;
  my $qt = $self->_quote_ident_if_needed($table);
  return $alias ? ("$qt " . $self->_quote_ident_if_needed($alias), ()) : ($qt, ());
}

## Leaf renderers

sub _render_column {
  my ($self, $node) = @_;
  return ($self->_quote_ident_if_needed($node->{name}), ());
}

sub _render_value {
  my ($self, $node) = @_;
  return ('?', $node->{value});
}

sub _render_raw {
  my ($self, $node) = @_;

  # COMPARE
  if ($node->{_compare}) {
    my $c = $node->{_compare};
    my $sql_op = uc($c->{op});
    confess "Unknown operator '$c->{op}' in compare()"
      unless $VALID_OPS{$sql_op};
    my ($ls, @lb) = $self->render($c->{left});
    my ($rs, @rb) = $self->render($c->{right});
    $ls = "($ls)" if $c->{left}->isa('SQL::Wizard::Expr::Select');
    $rs = "($rs)" if $c->{right}->isa('SQL::Wizard::Expr::Select');
    return ("$ls $sql_op $rs", @lb, @rb);
  }

  # TRUNCATE
  if ($node->{_truncate}) {
    my $table = $node->{_truncate};
    confess "Invalid table name '$table'"
      unless $table =~ /^(\w+\.)*\w+$/;
    return ("TRUNCATE TABLE " . $self->_quote_ident_if_needed($table), ());
  }

  # EXISTS / NOT EXISTS
  if ($node->{_subquery}) {
    my ($s, @b) = $self->render($node->{_subquery});
    return ("$node->{sql}($s)", @b);
  }

  # BETWEEN / NOT BETWEEN
  if ($node->{_between} || $node->{_not_between}) {
    my $spec = $node->{_between} || $node->{_not_between};
    my $op   = $node->{_between} ? 'BETWEEN' : 'NOT BETWEEN';
    my ($cs, @cb) = $self->render($spec->{col});
    my ($ls, @lb) = $self->render($spec->{lo});
    my ($hs, @hb) = $self->render($spec->{hi});
    return ("$cs $op $ls AND $hs", @cb, @lb, @hb);
  }

  # CAST
  if ($node->{_cast}) {
    my $type = $node->{_cast}{type};
    confess "Invalid CAST type '$type'"
      unless $type =~ /^\w[\w\s(),]*$/;
    my ($es, @eb) = $self->render($node->{_cast}{expr});
    return ("CAST($es AS $type)", @eb);
  }

  # AND / OR
  if ($node->{_logic}) {
    my $op    = $node->{_logic}{op};
    my @conds = @{$node->{_logic}{conds}};
    my @parts;
    my @bind;
    for my $c (@conds) {
      my ($s, @b) = $self->_render_where($c);
      push @parts, $s;
      push @bind, @b;
    }
    my $joined = join(" $op ", @parts);
    $joined = "($joined)" if @parts > 1;
    return ($joined, @bind);
  }

  # NOT
  if ($node->{_not}) {
    my ($s, @b) = $self->_render_where($node->{_not});
    return ("NOT ($s)", @b);
  }

  return ($node->{sql}, @{$node->{bind}});
}

sub _render_alias {
  my ($self, $node) = @_;
  my ($sql, @bind) = $self->render($node->{expr});
  # Wrap subselects in parens
  if ($node->{expr}->isa('SQL::Wizard::Expr::Select')) {
    $sql = "($sql)";
  }
  return ("$sql AS " . $self->_quote_ident_if_needed($node->{alias}), @bind);
}

sub _render_order {
  my ($self, $node) = @_;
  my ($sql, @bind) = $self->_render_expr($node->{expr});
  $sql .= " $node->{direction}";
  $sql .= " NULLS $node->{nulls}" if $node->{nulls};
  return ($sql, @bind);
}

sub _render_func {
  my ($self, $node) = @_;
  my @arg_sqls;
  my @bind;
  for my $arg (@{$node->{args}}) {
    my ($s, @b) = $self->_render_expr($arg);
    push @arg_sqls, $s;
    push @bind, @b;
  }
  my $args_str = join(', ', @arg_sqls);
  return ("$node->{name}($args_str)", @bind);
}

sub _render_binop {
  my ($self, $node) = @_;
  my ($lsql, @lbind) = $self->render($node->{left});
  my ($rsql, @rbind) = $self->render($node->{right});
  return ("$lsql $node->{op} $rsql", @lbind, @rbind);
}

## SELECT

sub _render_select {
  my ($self, $node) = @_;
  my @parts;
  my @bind;

  # CTE
  if ($node->{_cte}) {
    my ($cte_sql, @cte_bind) = $self->render($node->{_cte});
    push @parts, $cte_sql;
    push @bind, @cte_bind;
  }

  # SELECT columns
  my @col_sqls;
  for my $col (@{$node->{columns} || ['*']}) {
    my ($s, @b) = $self->_render_expr($col);
    push @col_sqls, $s;
    push @bind, @b;
  }
  my $select_keyword = $node->{distinct} ? "SELECT DISTINCT" : "SELECT";
  push @parts, "$select_keyword " . join(', ', @col_sqls);

  # FROM
  if ($node->{from}) {
    my @from_sqls;
    my @from_items = ref $node->{from} eq 'ARRAY' ? @{$node->{from}} : ($node->{from});
    for my $i (0 .. $#from_items) {
      my $item = $from_items[$i];
      if (blessed($item) && $item->isa('SQL::Wizard::Expr::Join')) {
        my ($s, @b) = $self->render($item);
        push @from_sqls, $s;
        push @bind, @b;
      } else {
        my ($s, @b) = $self->_expand_table($item);
        # First item or non-join items
        if ($i == 0) {
          push @from_sqls, $s;
        } else {
          push @from_sqls, $s;
        }
        push @bind, @b;
      }
    }
    push @parts, "FROM " . join(' ', @from_sqls);
  }

  # WHERE
  if ($node->{where}) {
    my ($wsql, @wbind) = $self->_render_where($node->{where});
    if (defined $wsql && $wsql ne '') {
      push @parts, "WHERE $wsql";
      push @bind, @wbind;
    }
  }

  # GROUP BY
  if ($node->{group_by}) {
    my @items = ref $node->{group_by} eq 'ARRAY' ? @{$node->{group_by}} : ($node->{group_by});
    my @gsqls;
    for my $g (@items) {
      my ($s, @b) = $self->_render_expr($g);
      push @gsqls, $s;
      push @bind, @b;
    }
    push @parts, "GROUP BY " . join(', ', @gsqls);
  }

  # HAVING
  if ($node->{having}) {
    my ($hsql, @hbind) = $self->_render_where($node->{having});
    if (defined $hsql && $hsql ne '') {
      push @parts, "HAVING $hsql";
      push @bind, @hbind;
    }
  }

  # WINDOW
  if ($node->{window}) {
    my @wdefs;
    for my $name (sort keys %{$node->{window}}) {
      confess "Invalid window name '$name'" unless $name =~ /^\w+$/;
      my $spec = $node->{window}{$name};
      my ($s, @b) = $self->_render_window_spec($spec);
      push @wdefs, $self->_quote_ident_if_needed($name) . " AS ($s)";
      push @bind, @b;
    }
    push @parts, "WINDOW " . join(', ', @wdefs);
  }

  # ORDER BY
  if ($node->{order_by}) {
    my @items = ref $node->{order_by} eq 'ARRAY' ? @{$node->{order_by}} : ($node->{order_by});
    my @osqls;
    for my $o (@items) {
      if (ref $o eq 'HASH') {
        # { -desc => 'col' } or { -asc => 'col' }
        my ($dir, $col) = each %$o;
        $dir = uc($dir);
        $dir =~ s/^-//;
        $self->_assert_order_column($col) unless ref $col;
        my ($s, @b) = $self->_render_expr($col);
        push @osqls, "$s $dir";
        push @bind, @b;
      } elsif (!ref $o && $o =~ /^-(.+)/) {
        # '-col' shorthand for col DESC
        $self->_assert_order_column($1);
        my ($s, @b) = $self->_render_expr($1);
        push @osqls, "$s DESC";
        push @bind, @b;
      } elsif (!ref $o) {
        $self->_assert_order_column($o);
        my ($s, @b) = $self->_render_expr($o);
        push @osqls, $s;
        push @bind, @b;
      } else {
        my ($s, @b) = $self->_render_expr($o);
        push @osqls, $s;
        push @bind, @b;
      }
    }
    push @parts, "ORDER BY " . join(', ', @osqls);
  }

  # LIMIT / OFFSET
  if (defined $node->{limit}) {
    $self->_assert_integer('-limit', $node->{limit});
    push @parts, "LIMIT ?";
    push @bind, $node->{limit};
  }
  if (defined $node->{offset}) {
    $self->_assert_integer('-offset', $node->{offset});
    push @parts, "OFFSET ?";
    push @bind, $node->{offset};
  }

  return (join(' ', @parts), @bind);
}

## JOIN

sub _render_join {
  my ($self, $node) = @_;
  my @bind;

  my ($table_sql, @tb) = $self->_expand_table($node->{table});
  push @bind, @tb;

  my $sql = "$node->{type} $table_sql";

  if (defined $node->{on}) {
    if (ref $node->{on} eq 'HASH') {
      my ($on_sql, @ob) = $self->_render_where($node->{on});
      $sql .= " ON $on_sql";
      push @bind, @ob;
    } else {
      # String ON condition
      $self->_injection_guard($node->{on});
      $sql .= " ON $node->{on}";
    }
  }

  return ($sql, @bind);
}

## CASE

sub _render_case {
  my ($self, $node) = @_;
  my @parts;
  my @bind;

  push @parts, 'CASE';

  # CASE ON (simple case with operand)
  if ($node->{operand}) {
    my ($os, @ob) = $self->_render_expr($node->{operand});
    $parts[0] .= " $os";
    push @bind, @ob;
  }

  for my $when (@{$node->{whens}}) {
    if ($node->{operand}) {
      # Simple CASE: WHEN value THEN result
      my ($ws, @wb) = $self->_render_expr($when->{condition});
      my ($ts, @tb) = $self->_render_expr($when->{then});
      push @parts, "WHEN $ws THEN $ts";
      push @bind, @wb, @tb;
    } else {
      # Searched CASE: WHEN condition THEN result
      my ($ws, @wb) = $self->_render_where($when->{condition});
      my ($ts, @tb) = $self->_render_expr($when->{then});
      push @parts, "WHEN $ws THEN $ts";
      push @bind, @wb, @tb;
    }
  }

  if (defined $node->{else}) {
    my ($es, @eb) = $self->_render_expr($node->{else});
    push @parts, "ELSE $es";
    push @bind, @eb;
  }

  push @parts, 'END';
  return (join(' ', @parts), @bind);
}

## Window

sub _render_window {
  my ($self, $node) = @_;
  my ($expr_sql, @bind) = $self->render($node->{expr});

  my $spec = $node->{spec};
  if ($spec->{name}) {
    confess "Invalid window name '$spec->{name}'" unless $spec->{name} =~ /^\w+$/;
    return ("$expr_sql OVER " . $self->_quote_ident_if_needed($spec->{name}), @bind);
  }

  my ($spec_sql, @sb) = $self->_render_window_spec($spec);
  push @bind, @sb;
  return ("$expr_sql OVER ($spec_sql)", @bind);
}

sub _render_window_spec {
  my ($self, $spec) = @_;
  my @parts;
  my @bind;

  if ($spec->{'-partition_by'}) {
    my @items = ref $spec->{'-partition_by'} eq 'ARRAY'
      ? @{$spec->{'-partition_by'}} : ($spec->{'-partition_by'});
    my @sqls;
    for my $p (@items) {
      my ($s, @b) = $self->_render_expr($p);
      push @sqls, $s;
      push @bind, @b;
    }
    push @parts, "PARTITION BY " . join(', ', @sqls);
  }

  if ($spec->{'-order_by'}) {
    my @items = ref $spec->{'-order_by'} eq 'ARRAY'
      ? @{$spec->{'-order_by'}} : ($spec->{'-order_by'});
    my @sqls;
    for my $o (@items) {
      if (ref $o eq 'HASH') {
        my ($dir, $col) = each %$o;
        $dir = uc($dir);
        $dir =~ s/^-//;
        $self->_assert_order_column($col) unless ref $col;
        my ($s, @b) = $self->_render_expr($col);
        push @sqls, "$s $dir";
        push @bind, @b;
      } elsif (!ref $o && $o =~ /^-(.+)/) {
        $self->_assert_order_column($1);
        my ($s, @b) = $self->_render_expr($1);
        push @sqls, "$s DESC";
        push @bind, @b;
      } elsif (!ref $o) {
        $self->_assert_order_column($o);
        my ($s, @b) = $self->_render_expr($o);
        push @sqls, $s;
        push @bind, @b;
      } else {
        my ($s, @b) = $self->_render_expr($o);
        push @sqls, $s;
        push @bind, @b;
      }
    }
    push @parts, "ORDER BY " . join(', ', @sqls);
  }

  if ($spec->{'-frame'}) {
    $self->_injection_guard($spec->{'-frame'});
    push @parts, $spec->{'-frame'};
  }

  return (join(' ', @parts), @bind);
}

## Compound (UNION/INTERSECT/EXCEPT)

sub _render_compound {
  my ($self, $node) = @_;
  my @parts;
  my @bind;

  for my $entry (@{$node->{queries}}) {
    my ($s, @b) = $self->render($entry->{query});
    if ($entry->{type}) {
      push @parts, $entry->{type};
    }
    push @parts, "($s)";
    push @bind, @b;
  }

  # ORDER BY / LIMIT / OFFSET on the compound
  if ($node->{order_by}) {
    my @items = ref $node->{order_by} eq 'ARRAY' ? @{$node->{order_by}} : ($node->{order_by});
    my @osqls;
    for my $o (@items) {
      if (ref $o eq 'HASH') {
        my ($dir, $col) = each %$o;
        $dir = uc($dir);
        $dir =~ s/^-//;
        $self->_assert_order_column($col) unless ref $col;
        my ($s, @b) = $self->_render_expr($col);
        push @osqls, "$s $dir";
        push @bind, @b;
      } elsif (!ref $o && $o =~ /^-(.+)/) {
        $self->_assert_order_column($1);
        my ($s, @b) = $self->_render_expr($1);
        push @osqls, "$s DESC";
        push @bind, @b;
      } elsif (!ref $o) {
        $self->_assert_order_column($o);
        my ($s, @b) = $self->_render_expr($o);
        push @osqls, $s;
        push @bind, @b;
      } else {
        my ($s, @b) = $self->_render_expr($o);
        push @osqls, $s;
        push @bind, @b;
      }
    }
    push @parts, "ORDER BY " . join(', ', @osqls);
  }
  if (defined $node->{limit}) {
    $self->_assert_integer('-limit', $node->{limit});
    push @parts, "LIMIT ?";
    push @bind, $node->{limit};
  }
  if (defined $node->{offset}) {
    $self->_assert_integer('-offset', $node->{offset});
    push @parts, "OFFSET ?";
    push @bind, $node->{offset};
  }

  return (join(' ', @parts), @bind);
}

## CTE

sub _render_cte {
  my ($self, $node) = @_;
  my @parts;
  my @bind;

  my $keyword = $node->{recursive} ? 'WITH RECURSIVE' : 'WITH';

  my @cte_sqls;
  for my $cte (@{$node->{ctes}}) {
    my $name = $cte->{name};
    $self->_injection_guard($name);
    my $query = $cte->{query};

    # Recursive CTE with -initial and -recurse
    if (ref $query eq 'HASH' && $query->{'-initial'}) {
      my ($is, @ib) = $self->render($query->{'-initial'});
      my ($rs, @rb) = $self->render($query->{'-recurse'});
      push @cte_sqls, $self->_quote_ident_if_needed($name) . " AS ($is UNION ALL $rs)";
      push @bind, @ib, @rb;
    } else {
      my ($s, @b) = $self->render($query);
      push @cte_sqls, $self->_quote_ident_if_needed($name) . " AS ($s)";
      push @bind, @b;
    }
  }

  return ("$keyword " . join(', ', @cte_sqls), @bind);
}

## INSERT

sub _render_insert {
  my ($self, $node) = @_;
  my @parts;
  my @bind;

  $self->_injection_guard($node->{into});
  push @parts, "INSERT INTO " . $self->_quote_ident_if_needed($node->{into});

  if ($node->{select}) {
    # INSERT ... SELECT
    if ($node->{columns}) {
      $self->_assert_column($_) for @{$node->{columns}};
      push @parts, "(" . join(', ', map { $self->_quote_ident_if_needed($_) } @{$node->{columns}}) . ")";
    }
    my ($s, @b) = $self->render($node->{select});
    push @parts, $s;
    push @bind, @b;
  } elsif (ref $node->{values} eq 'HASH') {
    # Single row insert from hash
    my @cols = sort keys %{$node->{values}};
    $self->_assert_column($_) for @cols;
    my @vals;
    for my $col (@cols) {
      my $v = $node->{values}{$col};
      my ($s, @b) = $self->_render_expr($v);
      push @vals, $s;
      push @bind, @b;
    }
    push @parts, "(" . join(', ', map { $self->_quote_ident_if_needed($_) } @cols) . ")";
    push @parts, "VALUES (" . join(', ', @vals) . ")";
  } elsif (ref $node->{values} eq 'ARRAY') {
    # Multi-row insert
    if ($node->{columns}) {
      $self->_assert_column($_) for @{$node->{columns}};
      push @parts, "(" . join(', ', map { $self->_quote_ident_if_needed($_) } @{$node->{columns}}) . ")";
    }
    my @row_sqls;
    for my $row (@{$node->{values}}) {
      my @vals;
      for my $v (@$row) {
        my ($s, @b) = $self->_render_expr($v);
        push @vals, $s;
        push @bind, @b;
      }
      push @row_sqls, "(" . join(', ', @vals) . ")";
    }
    push @parts, "VALUES " . join(', ', @row_sqls);
  }

  # ON CONFLICT (PostgreSQL)
  if ($node->{on_conflict}) {
    my $oc = $node->{on_conflict};
    my $target = $oc->{'-target'};
    $self->_injection_guard($target);
    my $update = $oc->{'-update'};
    my @set_parts;
    for my $col (sort keys %$update) {
      $self->_assert_column($col);
      my ($s, @b) = $self->_render_expr($update->{$col});
      push @set_parts, $self->_quote_ident_if_needed($col) . " = $s";
      push @bind, @b;
    }
    my $quoted_target = join(', ', map { $self->_quote_ident_if_needed(s/^\s+|\s+$//gr) } split /,/, $target);
    push @parts, "ON CONFLICT ($quoted_target) DO UPDATE SET " . join(', ', @set_parts);
  }

  # ON DUPLICATE KEY (MySQL)
  if ($node->{on_duplicate}) {
    my @set_parts;
    for my $col (sort keys %{$node->{on_duplicate}}) {
      $self->_assert_column($col);
      my ($s, @b) = $self->_render_expr($node->{on_duplicate}{$col});
      push @set_parts, $self->_quote_ident_if_needed($col) . " = $s";
      push @bind, @b;
    }
    push @parts, "ON DUPLICATE KEY UPDATE " . join(', ', @set_parts);
  }

  # RETURNING
  if ($node->{returning}) {
    $self->_assert_column($_) for @{$node->{returning}};
    push @parts, "RETURNING " . join(', ', map { $self->_quote_ident_if_needed($_) } @{$node->{returning}});
  }

  return (join(' ', @parts), @bind);
}

## UPDATE

sub _render_update {
  my ($self, $node) = @_;
  my @parts;
  my @bind;

  # Table (possibly with joins)
  if (ref $node->{table} eq 'ARRAY') {
    my @table_parts;
    for my $item (@{$node->{table}}) {
      if (blessed($item) && $item->isa('SQL::Wizard::Expr::Join')) {
        my ($s, @b) = $self->render($item);
        push @table_parts, $s;
        push @bind, @b;
      } else {
        my ($s, @b) = $self->_expand_table($item);
        push @table_parts, $s;
        push @bind, @b;
      }
    }
    push @parts, "UPDATE " . join(' ', @table_parts);
  } else {
    my ($ts, @tb) = $self->_expand_table($node->{table});
    push @parts, "UPDATE $ts";
    push @bind, @tb;
  }

  # SET
  my @set_parts;
  for my $col (sort keys %{$node->{set}}) {
    $self->_assert_column($col);
    my ($s, @b) = $self->_render_expr($node->{set}{$col});
    push @set_parts, $self->_quote_ident_if_needed($col) . " = $s";
    push @bind, @b;
  }
  push @parts, "SET " . join(', ', @set_parts);

  # FROM (PostgreSQL)
  if ($node->{from}) {
    my @from_items = ref $node->{from} eq 'ARRAY' ? @{$node->{from}} : ($node->{from});
    my @from_sqls;
    for my $item (@from_items) {
      my ($s, @b) = $self->_expand_table($item);
      push @from_sqls, $s;
      push @bind, @b;
    }
    push @parts, "FROM " . join(', ', @from_sqls);
  }

  # WHERE
  if ($node->{where}) {
    my ($ws, @wb) = $self->_render_where($node->{where});
    if (defined $ws && $ws ne '') {
      push @parts, "WHERE $ws";
      push @bind, @wb;
    }
  }

  # LIMIT (MySQL UPDATE ... LIMIT n)
  if (defined $node->{limit}) {
    $self->_assert_integer('-limit', $node->{limit});
    push @parts, "LIMIT ?";
    push @bind, $node->{limit};
  }

  # RETURNING
  if ($node->{returning}) {
    $self->_assert_column($_) for @{$node->{returning}};
    push @parts, "RETURNING " . join(', ', map { $self->_quote_ident_if_needed($_) } @{$node->{returning}});
  }

  return (join(' ', @parts), @bind);
}

## DELETE

sub _render_delete {
  my ($self, $node) = @_;
  my @parts;
  my @bind;

  $self->_injection_guard($node->{from});
  push @parts, "DELETE FROM " . $self->_quote_ident_if_needed($node->{from});

  # USING (PostgreSQL)
  if ($node->{using}) {
    $self->_injection_guard($node->{using});
    push @parts, "USING " . $self->_quote_ident_if_needed($node->{using});
  }

  # WHERE
  if ($node->{where}) {
    my ($ws, @wb) = $self->_render_where($node->{where});
    if (defined $ws && $ws ne '') {
      push @parts, "WHERE $ws";
      push @bind, @wb;
    }
  }

  # RETURNING
  if ($node->{returning}) {
    $self->_assert_column($_) for @{$node->{returning}};
    push @parts, "RETURNING " . join(', ', map { $self->_quote_ident_if_needed($_) } @{$node->{returning}});
  }

  return (join(' ', @parts), @bind);
}

## WHERE clause rendering (self-contained, SQL::Abstract-compatible syntax)

sub _render_where {
  my ($self, $where) = @_;

  # Expression object
  if (blessed($where) && $where->isa('SQL::Wizard::Expr')) {
    return $self->render($where);
  }

  # Hashref: { col => val, col2 => { '>' => 3 } }
  if (ref $where eq 'HASH') {
    my @parts;
    my @bind;
    for my $key (sort keys %$where) {
      my $val = $where->{$key};

      # Expression object as key (e.g. $q->func(...) => { '>' => 5 })
      if (blessed($key) && $key->isa('SQL::Wizard::Expr')) {
        my ($ks, @kb) = $self->render($key);
        my ($vs, @vb) = $self->_render_where_value($ks, $val);
        push @parts, $vs;
        push @bind, @kb, @vb;
        next;
      }

      $self->_injection_guard($key);
      my $qkey = $self->_quote_ident_if_needed($key);

      if (!defined $val) {
        push @parts, "$qkey IS NULL";
      } elsif (blessed($val) && $val->isa('SQL::Wizard::Expr')) {
        my ($vs, @vb) = $self->render($val);
        push @parts, "$qkey = $vs";
        push @bind, @vb;
      } elsif (ref $val eq 'HASH') {
        my ($s, @b) = $self->_render_where_value($qkey, $val);
        push @parts, $s;
        push @bind, @b;
      } elsif (ref $val eq 'ARRAY') {
        # { col => [1,2,3] } => col IN (?,?,?)
        if (!@$val) {
          push @parts, '1 = 0';
        } else {
          my @placeholders;
          for my $v (@$val) {
            if (blessed($v) && $v->isa('SQL::Wizard::Expr')) {
              my ($s, @b) = $self->render($v);
              push @placeholders, $s;
              push @bind, @b;
            } else {
              push @placeholders, '?';
              push @bind, $v;
            }
          }
          push @parts, "$qkey IN (" . join(', ', @placeholders) . ")";
        }
      } else {
        push @parts, "$qkey = ?";
        push @bind, $val;
      }
    }
    return (join(' AND ', @parts), @bind);
  }

  # Arrayref: [-and => ..., -or => ...]
  if (ref $where eq 'ARRAY') {
    return $self->_render_where_array($where);
  }

  # Plain string
  $self->_injection_guard($where);
  return ($where, ());
}

sub _render_where_value {
  my ($self, $col, $val) = @_;

  if (ref $val eq 'HASH') {
    my @parts;
    my @bind;
    for my $op (sort keys %$val) {
      my $rhs = $val->{$op};
      my $sql_op = uc($op);

      confess "Unknown operator '$op' in WHERE clause"
        unless $VALID_OPS{$sql_op};

      # -in / -not_in
      if ($sql_op eq '-IN' || $sql_op eq '-NOT_IN') {
        my $neg = $sql_op eq '-NOT_IN' ? 'NOT ' : '';
        if (blessed($rhs) && $rhs->isa('SQL::Wizard::Expr')) {
          my ($s, @b) = $self->render($rhs);
          push @parts, "$col ${neg}IN ($s)";
          push @bind, @b;
        } elsif (ref $rhs eq 'ARRAY') {
          if (!@$rhs) {
            # Empty list: -in => always false, -not_in => always true
            push @parts, $neg ? '1 = 1' : '1 = 0';
          } else {
            my @ph;
            for my $v (@$rhs) {
              if (blessed($v) && $v->isa('SQL::Wizard::Expr')) {
                my ($s, @b) = $self->render($v);
                push @ph, $s;
                push @bind, @b;
              } else {
                push @ph, '?';
                push @bind, $v;
              }
            }
            push @parts, "$col ${neg}IN (" . join(', ', @ph) . ")";
          }
        }
      } elsif (!defined $rhs) {
        if ($sql_op eq '!=' || $sql_op eq '<>') {
          push @parts, "$col IS NOT NULL";
        } else {
          push @parts, "$col IS NULL";
        }
      } elsif (blessed($rhs) && $rhs->isa('SQL::Wizard::Expr')) {
        my ($s, @b) = $self->render($rhs);
        $s = "($s)" if $rhs->isa('SQL::Wizard::Expr::Select');
        push @parts, "$col $sql_op $s";
        push @bind, @b;
      } else {
        push @parts, "$col $sql_op ?";
        push @bind, $rhs;
      }
    }
    return (join(' AND ', @parts), @bind);
  }

  return ("$col = ?", $val);
}

sub _render_where_array {
  my ($self, $arr, $default_logic) = @_;
  my @items = @$arr;
  my @parts;
  my @bind;

  my $logic = $default_logic || 'AND';

  my $i = 0;
  while ($i <= $#items) {
    my $item = $items[$i];

    if (!ref $item && $item =~ /^-(and|or)$/i) {
      $logic = uc($1);
      $i++;
      # Next item could be arrayref of conditions
      if ($i <= $#items && ref $items[$i] eq 'ARRAY') {
        my ($s, @b) = $self->_render_where_array($items[$i], $logic);
        push @parts, $s;
        push @bind, @b;
        $i++;
      }
      next;
    }

    if (ref $item eq 'HASH') {
      my ($s, @b) = $self->_render_where($item);
      push @parts, $s;
      push @bind, @b;
    } elsif (ref $item eq 'ARRAY') {
      my ($s, @b) = $self->_render_where_array($item);
      push @parts, "($s)";
      push @bind, @b;
    } elsif (blessed($item) && $item->isa('SQL::Wizard::Expr')) {
      my ($s, @b) = $self->render($item);
      push @parts, $s;
      push @bind, @b;
    }

    $i++;
  }

  my $joined = join(" $logic ", @parts);
  $joined = "($joined)" if @parts > 1;
  return ($joined, @bind);
}

1;
