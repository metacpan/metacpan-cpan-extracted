package SQL::Wizard::Renderer;

use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed);

sub new {
  my ($class, %args) = @_;
  bless \%args, $class;
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
  return ($thing, ());
}

# table|alias => table alias
sub _expand_table {
  my ($self, $thing) = @_;
  if (blessed($thing) && $thing->isa('SQL::Wizard::Expr')) {
    return $self->render($thing);
  }
  my ($table, $alias) = split /\|/, $thing, 2;
  return $alias ? ("$table $alias", ()) : ($table, ());
}

## Leaf renderers

sub _render_column {
  my ($self, $node) = @_;
  return ($node->{name}, ());
}

sub _render_value {
  my ($self, $node) = @_;
  return ('?', $node->{value});
}

sub _render_raw {
  my ($self, $node) = @_;

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
    my ($es, @eb) = $self->render($node->{_cast}{expr});
    return ("CAST($es AS $node->{_cast}{type})", @eb);
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
  return ("$sql AS $node->{alias}", @bind);
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
  push @parts, "SELECT " . join(', ', @col_sqls);

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
    push @parts, "WHERE $wsql";
    push @bind, @wbind;
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
    push @parts, "HAVING $hsql";
    push @bind, @hbind;
  }

  # WINDOW
  if ($node->{window}) {
    my @wdefs;
    for my $name (sort keys %{$node->{window}}) {
      my $spec = $node->{window}{$name};
      my ($s, @b) = $self->_render_window_spec($spec);
      push @wdefs, "$name AS ($s)";
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
        my ($s, @b) = $self->_render_expr($col);
        push @osqls, "$s $dir";
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
  push @parts, "LIMIT $node->{limit}"   if defined $node->{limit};
  push @parts, "OFFSET $node->{offset}" if defined $node->{offset};

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
    return ("$expr_sql OVER $spec->{name}", @bind);
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
        my ($s, @b) = $self->_render_expr($col);
        push @sqls, "$s $dir";
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
      my ($s, @b) = $self->_render_expr($o);
      push @osqls, $s;
      push @bind, @b;
    }
    push @parts, "ORDER BY " . join(', ', @osqls);
  }
  push @parts, "LIMIT $node->{limit}"   if defined $node->{limit};
  push @parts, "OFFSET $node->{offset}" if defined $node->{offset};

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
    my $query = $cte->{query};

    # Recursive CTE with -initial and -recurse
    if (ref $query eq 'HASH' && $query->{'-initial'}) {
      my ($is, @ib) = $self->render($query->{'-initial'});
      my ($rs, @rb) = $self->render($query->{'-recurse'});
      push @cte_sqls, "$name AS ($is UNION ALL $rs)";
      push @bind, @ib, @rb;
    } else {
      my ($s, @b) = $self->render($query);
      push @cte_sqls, "$name AS ($s)";
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

  push @parts, "INSERT INTO $node->{into}";

  if ($node->{select}) {
    # INSERT ... SELECT
    if ($node->{columns}) {
      push @parts, "(" . join(', ', @{$node->{columns}}) . ")";
    }
    my ($s, @b) = $self->render($node->{select});
    push @parts, $s;
    push @bind, @b;
  } elsif (ref $node->{values} eq 'HASH') {
    # Single row insert from hash
    my @cols = sort keys %{$node->{values}};
    my @vals;
    for my $col (@cols) {
      my $v = $node->{values}{$col};
      my ($s, @b) = $self->_render_expr($v);
      push @vals, $s;
      push @bind, @b;
    }
    push @parts, "(" . join(', ', @cols) . ")";
    push @parts, "VALUES (" . join(', ', @vals) . ")";
  } elsif (ref $node->{values} eq 'ARRAY') {
    # Multi-row insert
    push @parts, "(" . join(', ', @{$node->{columns}}) . ")" if $node->{columns};
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
    my $update = $oc->{'-update'};
    my @set_parts;
    for my $col (sort keys %$update) {
      my ($s, @b) = $self->_render_expr($update->{$col});
      push @set_parts, "$col = $s";
      push @bind, @b;
    }
    push @parts, "ON CONFLICT ($target) DO UPDATE SET " . join(', ', @set_parts);
  }

  # ON DUPLICATE KEY (MySQL)
  if ($node->{on_duplicate}) {
    my @set_parts;
    for my $col (sort keys %{$node->{on_duplicate}}) {
      my ($s, @b) = $self->_render_expr($node->{on_duplicate}{$col});
      push @set_parts, "$col = $s";
      push @bind, @b;
    }
    push @parts, "ON DUPLICATE KEY UPDATE " . join(', ', @set_parts);
  }

  # RETURNING
  if ($node->{returning}) {
    push @parts, "RETURNING " . join(', ', @{$node->{returning}});
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
    my ($s, @b) = $self->_render_expr($node->{set}{$col});
    push @set_parts, "$col = $s";
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
    push @parts, "WHERE $ws";
    push @bind, @wb;
  }

  # LIMIT (MySQL UPDATE ... LIMIT n)
  push @parts, "LIMIT $node->{limit}" if defined $node->{limit};

  # RETURNING
  if ($node->{returning}) {
    push @parts, "RETURNING " . join(', ', @{$node->{returning}});
  }

  return (join(' ', @parts), @bind);
}

## DELETE

sub _render_delete {
  my ($self, $node) = @_;
  my @parts;
  my @bind;

  push @parts, "DELETE FROM $node->{from}";

  # USING (PostgreSQL)
  if ($node->{using}) {
    push @parts, "USING $node->{using}";
  }

  # WHERE
  if ($node->{where}) {
    my ($ws, @wb) = $self->_render_where($node->{where});
    push @parts, "WHERE $ws";
    push @bind, @wb;
  }

  # RETURNING
  if ($node->{returning}) {
    push @parts, "RETURNING " . join(', ', @{$node->{returning}});
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

      if (!defined $val) {
        push @parts, "$key IS NULL";
      } elsif (blessed($val) && $val->isa('SQL::Wizard::Expr')) {
        my ($vs, @vb) = $self->render($val);
        push @parts, "$key = $vs";
        push @bind, @vb;
      } elsif (ref $val eq 'HASH') {
        my ($s, @b) = $self->_render_where_value($key, $val);
        push @parts, $s;
        push @bind, @b;
      } elsif (ref $val eq 'ARRAY') {
        # { col => [1,2,3] } => col IN (?,?,?)
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
        push @parts, "$key IN (" . join(', ', @placeholders) . ")";
      } else {
        push @parts, "$key = ?";
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

      # -in / -not_in
      if ($sql_op eq '-IN' || $sql_op eq '-NOT_IN') {
        my $neg = $sql_op eq '-NOT_IN' ? 'NOT ' : '';
        if (blessed($rhs) && $rhs->isa('SQL::Wizard::Expr')) {
          my ($s, @b) = $self->render($rhs);
          push @parts, "$col ${neg}IN ($s)";
          push @bind, @b;
        } elsif (ref $rhs eq 'ARRAY') {
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
      } elsif (blessed($rhs) && $rhs->isa('SQL::Wizard::Expr')) {
        my ($s, @b) = $self->render($rhs);
        $s = "($s)" if $rhs->isa('SQL::Wizard::Expr::Select');
        push @parts, "$col $op $s";
        push @bind, @b;
      } else {
        push @parts, "$col $op ?";
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
