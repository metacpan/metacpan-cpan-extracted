package Exception::DB::NoFieldsAvailable;
$Exception::DB::NoFieldsAvailable::VERSION = '0.016';
use base qw(Exception::DB);

=head1 Name
 
QBit::Application::Model::DB::Query
 
=head1 Description
 
Base class for DB queries.

=cut

package QBit::Application::Model::DB::Query;
$QBit::Application::Model::DB::Query::VERSION = '0.016';
use qbit;

use base qw(QBit::Application::Model::DB::Class);

use QBit::Application::Model::DB::VirtualTable;

=head1 Abstract methods

=over

=item

B<_found_rows>

=back

=cut

__PACKAGE__->abstract_methods(qw(_found_rows));

=head1 Package methods

=head2 init

B<No arguments.>

Method called from L</new> before return object.
 
=cut

sub init {
    my ($self) = @_;

    $self->SUPER::init();

    delete($self->{$_}) foreach grep {/__.+__/} keys(%$self);
}

=head2 select

B<Arguments:>

=over

=item *

B<%opts> - options with keys

=over

=item *

B<table> - object

=item *

B<fields> (optional, default: all fields)

=item *

B<filter> (optional)

=back

=back

B<Return values:>

=over

=item *

B<$query> - object

=back

B<Example:>

  my $query = $app->db->query->select(
      table  => $app->db->users,
      fields => [qw(id login)],
      filter => {id => 3},
  );
  
=cut

sub select {
    my ($self, %opts) = @_;

    $self->{'__TABLES__'} = [];

    return $self->_add_table(%opts);
}

=head2 join

B<Arguments:>

=over

=item *

B<%opts> - options with keys

=over

=item *

B<table> - object

=item *

B<alias> (optional)

=item *

B<fields> (optional, default: all fields)

=item *

B<filter> (optional)

=item *

B<join_type> (optional, default: 'INNER JOIN')

=item *

B<join_on> (optional, default: use foreign keys)

=back

=back

B<Return values:>

=over

=item *

B<$query> - object

=back

B<Example:>

  my $join_query = $query->join(
      table     => $app->db->fio,
      fields    => [qw(name surname)],
      filter    => ['name' => 'LIKE' => \'Max'],
      join_type => 'INNER JOIN',
      join_on   => ['user_id' => '=' => {'id' => $app->db->users}],
  );
 
=cut

sub join {
    my ($self, %opts) = @_;

    $opts{'join_type'} = $opts{'join_type'} ? uc($opts{'join_type'}) : 'INNER JOIN';

    my $dont_check_join_on;

    # Проверяем, что в query есть таблица из FK
    unless (exists($opts{'join_on'})) {
        foreach (@{$opts{'table'}->{'foreign_keys'} || []}) {
            my $table = $_->[1];
            my $foreign_table;
            try {
                $foreign_table = $self->_get_table($self->db->$table);
            }
            catch {
                undef($foreign_table);
            };
            if (defined($foreign_table)) {
                my $fkey = $_;
                $dont_check_join_on = $opts{'join_on'} = [];
                push(@{$opts{'join_on'}}, [$fkey->[0][$_] => '=' => {$fkey->[2][$_] => $foreign_table->{'table'}}])
                  for 0 .. @{$fkey->[0]} - 1;
                last;
            }
        }
        $opts{'join_on'} = [AND => $opts{'join_on'}] if exists($opts{'join_on'});
    }

    # Проверяем, что в query есть таблица, в FK которой есть текущая таблица
    unless (exists($opts{'join_on'})) {
        foreach my $qtable (map {$_->{'table'}} @{$self->{'__TABLES__'} || []}) {
            foreach (@{$qtable->{'foreign_keys'} || []}) {
                if ($opts{'table'}->name eq $_->[1]) {
                    my $fkey = $_;
                    $dont_check_join_on = $opts{'join_on'} = [];
                    push(@{$opts{'join_on'}}, [$fkey->[2][$_] => '=' => {$fkey->[0][$_] => $qtable}])
                      for 0 .. @{$fkey->[0]} - 1;
                    last;
                }
            }
        }
        $opts{'join_on'} = [AND => $opts{'join_on'}] if exists($opts{'join_on'});
    }

    unless ($dont_check_join_on) {
        throw gettext('join_on is required')
          unless exists($opts{'join_on'});

    }

    return $self->_add_table(%opts);
}

=head2 left_join

join_type => 'LEFT JOIN'
 
=cut

sub left_join {
    my ($self, %opts) = @_;

    return $self->join(%opts, join_type => 'LEFT JOIN');
}

=head2 right_join

join_type => 'RIGHT JOIN'
 
=cut

sub right_join {
    my ($self, %opts) = @_;

    return $self->join(%opts, join_type => 'RIGHT JOIN');
}

=head2 group_by

B<Arguments:>

=over

=item *

B<@fields>

=back

B<Return values:>

=over

=item *

B<$query> - object

=back

B<Example:>

  my $group_query = $query->group_by(qw(name surname));
 
=cut

sub group_by {
    my ($self, @group_by) = @_;

    my %group_by = map {$_ => TRUE} @group_by;
    my %fields = map {%{$_->{'fields'}}} @{$self->{'__TABLES__'}};
    my @not_grouping_fields = grep {!$fields{$_} && !$group_by{$_}} keys(%fields);

    throw Exception::BadArguments gettext("You've forgotten grouping function for query field(s) '%s'.",
        CORE::join(', ', @not_grouping_fields))
      if @not_grouping_fields;

    $self->{'__GROUP_BY__'} = \@group_by;

    return $self;
}

=head2 order_by

B<Arguments:>

=over

=item *

B<@fields> - fields or reference to array

=back

B<Return values:>

=over

=item *

B<$query> - object

=back

B<Example:>

  my $order_query = $query->order_by('id', ['login', 1]);
 
=cut

sub order_by {
    my ($self, @order_by) = @_;

    $self->{'__ORDER_BY__'} = [map {ref($_) eq 'ARRAY' ? $_ : [$_]} @order_by];

    return $self;
}

=head2 limit

B<Arguments:>

=over

=item *

B<@limit>

=back

B<Return values:>

=over

=item *

B<$query> - object

=back

B<Example:>

  my $limit_query = $query->limit(100, 200);
 
=cut

sub limit {
    my ($self, @params) = @_;

    $self->{'__LIMIT__'} = [splice(@params, 0, 2)];

    return $self;
}

=head2 distinct

B<No arguments.>

B<Return values:>

=over

=item *

B<$query> - object

=back

B<Example:>

  my $distinct_query = $query->distinct();
 
=cut

sub distinct {
    my ($self) = @_;

    $self->{'__DISTINCT__'} = TRUE;

    return $self;
}

=head2 union

B<Arguments:>

=over

=item *

B<$query> - object

=item *

B<%opts> - options with keys

=over

=item *

B<all> - boolean (optional, default: FALSE)

=back

=back

B<Return values:>

=over

=item *

B<$query> - object

=back

B<Example:>

  my $union_query = $query->union(
      $app->db->query->select(
          table => $app->db->people,
          fields => [qw(id login name surname)]
      ),
      all => FALSE,
  );
 
=cut

sub union {
    my ($self, $query, %opts) = @_;

    throw Exception::BadArguments gettext('"query" must be QBit::Application::Model::DB::Query descendant')
      unless defined($query) && blessed($query) && $query->isa('QBit::Application::Model::DB::Query');

    $self->{'__UNION__'} ||= [];
    push(@{$self->{'__UNION__'}}, {query => $query, %opts});

    return $self;
}

=head2 union_all

all => TRUE
 
=cut

sub union_all {
    my ($self, @params) = @_;

    return $self->union(@params, all => TRUE);
}

=head2 calc_rows

B<Arguments:>

=over

=item *

B<$flag> - boolean

=back

B<Return values:>

=over

=item *

B<$query> - object

=back

B<Example:>

  my $calc_rows_query = $query->calc_rows(TRUE);
 
=cut

sub calc_rows {
    my ($self, $flag) = @_;

    $self->{'__CALC_ROWS__'} = !!$flag;

    return $self;
}

=head2 all_langs

B<Arguments:>

=over

=item *

B<$flag> - boolean

=back

B<Return values:>

=over

=item *

B<$query> - object

=back

B<Example:>

  my $all_langs_query = $query->all_langs(TRUE);
 
=cut

sub all_langs {
    my ($self, $flag) = @_;

    $self->{'__ALL_LANGS__'} = !!$flag;

    return $self;
}

=head2 for_update

B<No arguments.>

B<Return values:>

=over

=item *

B<$query> - object

=back

B<Example:>

  my $for_update_query = $query->for_update();
 
=cut

sub for_update {
    my ($self) = @_;

    $self->{'__FOR_UPDATE__'} = 1;

    return $self;
}

=head2 filter
 
=cut

sub filter {shift->db->filter(@_)}

=head2 get_sql_with_data

B<Arguments:>

=over

=item *

B<%opts> - options with keys

=over

=item *

B<offset> - number (optional, default: 0)

=back

=back

B<Return values:>

=over

=item *

B<$sql> - string

=back

B<Example:>

  my $sql = $query->get_sql_with_data();
 
=cut

sub get_sql_with_data {
    my ($self, %opts) = @_;

    my @sql_data = ();
    my $sql      = '';

    $opts{'offset'} ||= 0;
    my ($orig_offset, $offset);
    $orig_offset = $offset = ' ' x $opts{'offset'};

    if (@{$self->{'__UNION__'} || []}) {
        $opts{'offset'} += 4;
        $offset .= '    ';
        $sql    .= "(\n$offset";
    }

    $sql .= 'SELECT';

    $sql .= ' DISTINCT' if $self->{'__DISTINCT__'};

    $sql .= $self->_after_select(\@sql_data);

    my %all_fields = ();
    foreach my $table (@{$self->{'__TABLES__'}}) {
        throw Exception::BadArguments gettext('Fields must be hash ref') if ref($table->{'fields'}) ne 'HASH';
        foreach my $field (keys(%{$table->{'fields'}})) {
            throw Exception::BadArguments gettext('Duplicate field name "%s", table "%s"', $field,
                $table->{'table'}->name)
              if exists($all_fields{$field});
            $all_fields{$field} = [$self->_field_to_sql($field, $table->{'fields'}{$field}, $table)];
        }
    }

    unless (%all_fields) {
        throw Exception::DB::NoFieldsAvailable;
    }

    $sql .= "\n$offset    " . CORE::join(",\n$offset    ", map {@{$all_fields{$_}}} sort keys(%all_fields));
    my ($select_query_table, @join_query_tables) = @{$self->{'__TABLES__'}};
    $sql .= "\n${offset}FROM";

    if ($select_query_table->{'table'}->isa('QBit::Application::Model::DB::VirtualTable')) {
        my ($vt_sql, @vt_data) = $select_query_table->{'table'}->get_sql_with_data(offset => $opts{'offset'} + 4);

        $sql .= " (\n${offset}    $vt_sql\n${offset}) " . $self->quote_identifier($select_query_table->{'table'}->name);
        push(@sql_data, @vt_data);
    } else {
        $sql .=
            ' ' 
          . $self->quote_identifier($select_query_table->{'table'}->name)
          . (
            exists($select_query_table->{'alias'})
            ? ' AS ' . $self->quote_identifier($select_query_table->{'alias'})
            : ''
          );
    }

    foreach my $table (@join_query_tables) {
        $sql .= "\n${offset}" . $table->{'join_type'};

        if ($table->{'table'}->isa('QBit::Application::Model::DB::VirtualTable')) {
            my ($vt_sql, @vt_data) = $table->{'table'}->get_sql_with_data(offset => $opts{'offset'} + 4);

            $sql .= " (\n${offset}    $vt_sql\n${offset}) " . $self->quote_identifier($table->{'table'}->name);
            push(@sql_data, @vt_data);
        } else {
            $sql .=
                ' ' 
              . $self->quote_identifier($table->{'table'}->name)
              . (
                exists($table->{'alias'})
                ? ' AS ' . $self->quote_identifier($table->{'alias'})
                : ''
              );
        }

        next unless exists($table->{'join_on'});
        my $filter_expr = $self->filter($table->{'join_on'})->expression();
        next unless defined($filter_expr);
        my ($filter_sql) = $self->_field_to_sql(undef, $filter_expr, $table, offset => $opts{'offset'});
        $sql .= " ON " . $filter_sql if $filter_sql;
    }

    my $where_sql = '';
    foreach my $table (@{$self->{'__TABLES__'}}) {
        next unless defined($table->{'filter'});
        my $filter_expr = $self->filter($table->{'filter'})->expression();
        next unless defined($filter_expr);
        my ($filter_sql) = $self->_field_to_sql(undef, $filter_expr, $table, offset => $opts{'offset'});
        $where_sql .= "\n${offset}" . ($where_sql ? 'AND ' : 'WHERE ') . $filter_sql if $filter_sql;
    }
    $sql .= $where_sql;

    $sql .= "\n${offset}GROUP BY " . CORE::join(', ', map {$self->quote_identifier($_)} @{$self->{'__GROUP_BY__'}})
      if exists($self->{'__GROUP_BY__'});

    $sql .= $self->_after_group_by();

    $sql .=
      "\n${offset}ORDER BY "
      . CORE::join(', ', map {$self->quote_identifier($_->[0]) . ($_->[1] ? ' DESC' : '')} @{$self->{'__ORDER_BY__'}})
      if exists($self->{'__ORDER_BY__'});

    $sql .= "\n${offset}LIMIT " . CORE::join(', ', map {int($_ || 0)} @{$self->{'__LIMIT__'}})
      if exists($self->{'__LIMIT__'});

    $sql .= "\n${offset}FOR UPDATE" if $self->{'__FOR_UPDATE__'};

    $sql .= "\n$orig_offset)" if @{$self->{'__UNION__'} || []};
    foreach my $union_query (@{$self->{'__UNION__'} || []}) {
        $sql .= "\n${orig_offset}UNION";
        $sql .= ' ALL' if $union_query->{'all'};
        $sql .= "\n${orig_offset}(\n$offset";

        my ($usql, @udata) = $union_query->{'query'}->get_sql_with_data(offset => $opts{'offset'});
        $sql .= $usql;
        push(@sql_data, @udata);
        $sql .= "\n${orig_offset})";
    }

    return ($sql, @sql_data);
}

=head2 get_all

B<No arguments.>

B<Return values:>

=over

=item *

B<$data> - reference to array

=back

B<Example:>

  my $data = $query->get_all();
   
=cut

sub get_all {
    my ($self) = @_;

    return []
      unless exists($self->{'__TABLES__'}) && @{$self->{'__TABLES__'}};

    my $res = $self->db->_get_all($self->get_sql_with_data());

    $self->{'__FOUND_ROWS__'} = $self->{'__CALC_ROWS__'} ? $self->_found_rows() : undef;

    return $res;
}

=head2 found_rows

B<No arguments.>

B<Return values:>

=over

=item *

B<$bool>

=back

B<Example:>

  my $bool = $query->found_rows();
 
=cut

sub found_rows {
    my ($self) = @_;

    return $self->{'__FOUND_ROWS__'};
}

sub _add_table {
    my ($self, %opts) = @_;

    throw '"table" is not defined' unless defined $opts{'table'};

    throw '"table" must be QBit::Application::Model::DB::Table or QBit::Application::Model::DB::Query descendant'
      unless $opts{'table'}
          && $opts{'table'}
          && (   $opts{'table'}->isa('QBit::Application::Model::DB::Table')
              || $opts{'table'}->isa('QBit::Application::Model::DB::Query'));

    $opts{'table'} = QBit::Application::Model::DB::VirtualTable->new(
        db    => $self->db,
        query => $opts{'table'},
        name  => $opts{'alias'}
    ) if $opts{'table'}->isa('QBit::Application::Model::DB::Query');

    my %table_info =
      map {exists($opts{$_}) ? ($_ => $opts{$_}) : ()} qw(table alias fields join_type join_on filter);
    $table_info{'fields'} = [keys(%{$opts{'table'}->_fields_hs()})] unless exists($opts{'fields'});

    $table_info{'fields'} = {map {$_ => ''} @{$table_info{'fields'}}}
      if $table_info{'fields'} && ref($table_info{'fields'}) eq 'ARRAY';

    push(@{$self->{'__TABLES__'}}, \%table_info);

    return $self;
}

sub _get_table {
    my ($self, $tbl_or_alias) = @_;

    if (blessed($tbl_or_alias)
        && $tbl_or_alias->isa('QBit::Application::Model::DB::Table'))
    {    # Передали указатель на объект-таблицу
        foreach (@{$self->{'__TABLES__'}}) {
            return $_ if $_->{'table'}->name eq $tbl_or_alias->name;
        }
        throw gettext('Cannot find table "%s" in query', $tbl_or_alias->name);
    } elsif (!ref($tbl_or_alias)) {    # Передали alias таблицы
        foreach (@{$self->{'__TABLES__'}}) {
            return $_ if ($_->{'alias'} || '') eq $tbl_or_alias;
        }
        throw gettext('Cannot find table alias "%s" in query', $tbl_or_alias);
    } else {                           # Передали что-то непонятное
        throw Exception::BadArguments gettext('Bad arguments');
    }
}

sub _table_alias {
    my ($self, $query_table) = @_;

    return exists($query_table->{'alias'}) ? $query_table->{'alias'} : $query_table->{'table'}->name;
}

sub _get_locale_suffixes {
    my ($self) = @_;

    my @locales =
      $self->{'__ALL_LANGS__'}
      ? (sort keys(%{$self->db->get_option('locales', {})}))
      : ($self->db->get_option('locale'));
    @locales = (undef) unless @locales;

    return (map {defined($_) ? "_$_" : ''} @locales);
}

sub _after_select {''}

sub _after_group_by {''}

sub _field_to_sql {
    my ($self, $alias, $expr, $cur_query_table, %opts) = @_;

    throw Exception::BadArguments gettext('Table field aliase must be SCALAR') if ref($alias);

    $opts{'offset'} ||= 0;

    if (!defined($expr)) {
        return ('NULL');

    } elsif (ref($expr) eq 'SCALAR') {
        # {name => \'string or number'}
        return ($self->quote($$expr) . (defined($alias) ? ' AS ' . $self->quote_identifier($alias) : ''));

    } elsif (!ref($expr) && $expr eq '') {
        # {field_name => ''}
        my $field = $cur_query_table->{'table'}->_fields_hs()->{$alias}
          || throw Exception::BadArguments gettext('Table "%s" has not field "%s"', $cur_query_table->{'table'}->name,
            $alias);

        return (
            map {
                    $self->quote_identifier($self->_table_alias($cur_query_table)) . '.'
                  . $self->quote_identifier($alias . $_) . ' AS '
                  . $self->quote_identifier($alias . ($field->{'i18n'} && $self->{'__ALL_LANGS__'} ? $_ : ''))
              } $field->{'i18n'} ? $self->_get_locale_suffixes() : ('')
        );

    } elsif (!ref($expr)) {
        # {new_field_name => 'field_name'}
        my $field = $cur_query_table->{'table'}->_fields_hs()->{$expr}
          || throw Exception::BadArguments gettext('Table "%s" has not field "%s"', $cur_query_table->{'table'}->name,
            $expr);

        return (
            map {
                    $self->quote_identifier($self->_table_alias($cur_query_table)) . '.'
                  . $self->quote_identifier($expr . $_)
                  . (
                    defined($alias)
                    ? ' AS '
                      . $self->quote_identifier($alias . ($field->{'i18n'} && $self->{'__ALL_LANGS__'} ? $_ : ''))
                    : ''
                  )
              } $field->{'i18n'} ? $self->_get_locale_suffixes() : ('')
        );

    } elsif (
        ref($expr) eq 'HASH'
        && (!ref([%$expr]->[1])
            || (blessed([%$expr]->[1]) && [%$expr]->[1]->isa('QBit::Application::Model::DB::Table')))
      )
    {
        # {alias => {field_name => 'tbl_alias'}} {alias => {field_name => $...db->tbl}}
        my $query_table = $self->_get_table([%$expr]->[1]);
        my $field       = $query_table->{'table'}->_fields_hs()->{[%$expr]->[0]}
          || throw Exception::BadArguments gettext('Table "%s" has not field "%s"', $query_table->{'table'}->name,
            [%$expr]->[0]);

        return (
            map {
                    $self->quote_identifier($self->_table_alias($query_table)) . '.'
                  . $self->quote_identifier([%$expr]->[0] . $_)
                  . (
                    defined($alias)
                    ? ' AS '
                      . $self->quote_identifier($alias . ($field->{'i18n'} && $self->{'__ALL_LANGS__'} ? $_ : ''))
                    : ''
                  )
              } $field->{'i18n'} ? $self->_get_locale_suffixes() : ('')
        );

    } elsif (ref($expr) eq 'HASH' && ref([%$expr]->[1]) eq 'ARRAY') {
        # Function: {field => [SUM => ['f1', \5, ['-' => ['f2', 'f3']]]]}
        my @res       = ();
        my $func_name = [%$expr]->[0];
        $func_name =~ s/^\s+|\s+$//g;
        my @arg_sets =
          map {[$self->_field_to_sql(undef, $_, $cur_query_table, %opts, offset => $opts{'offset'} + 4)]}
          @{[%$expr]->[1]};
        my @locale_suffixes =
          $self->{'__ALL_LANGS__'} && (grep {@$_ > 1} @arg_sets) ? $self->_get_locale_suffixes() : ('');

        for my $i (0 .. @locale_suffixes - 1) {
            my @args = map {@$_ > 1 ? $_->[$i] : $_->[0]} @arg_sets;
            push(@res,
                    "$func_name("
                  . CORE::join(', ', @args) . ')'
                  . (defined($alias) ? ' AS ' . $self->quote_identifier($alias . $locale_suffixes[$i]) : ''));
        }
        return @res;

    } elsif (ref($expr) eq 'ARRAY' && @$expr == 2 && ref($expr->[1]) eq 'ARRAY') {
        # Expression: {field => ['+' => ['f1', 'f2', [f3 => '/' => \5]]]}
        my $offset   = ' ' x $opts{'offset'};
        my @res      = ();
        my $operator = $expr->[0];
        $operator =~ s/^\s+|\s+$//g;
        my @operand_sets =
          map {[$self->_field_to_sql(undef, $_, $cur_query_table, %opts, offset => $opts{'offset'} + 4)]} @{$expr->[1]};

        my @locale_suffixes =
          $self->{'__ALL_LANGS__'} && (grep {@$_ > 1} @operand_sets) ? $self->_get_locale_suffixes() : ('');

        for my $i (0 .. @locale_suffixes - 1) {
            my @operands = map {@$_ > 1 ? $_->[$i] : $_->[0]} @operand_sets;
            if (in_array($operator, [qw(AND OR)])) {
                push(@res,
                        "(\n$offset    "
                      . CORE::join("\n$offset    $operator ", @operands)
                      . "\n$offset)"
                      . (defined($alias) ? ' AS ' . $self->quote_identifier($alias . $locale_suffixes[$i]) : ''));
            } else {
                push(@res,
                        '('
                      . CORE::join(" $operator ", @operands) . ')'
                      . (defined($alias) ? ' AS ' . $self->quote_identifier($alias . $locale_suffixes[$i]) : ''));
            }
        }

        return @res;

    } elsif (ref($expr) eq 'ARRAY' && @$expr == 3) {
        # Comparison: [field => '=' => \5], [field => '=' => \[5, 10, 15]]
        my $offset = ' ' x $opts{'offset'};
        my @res    = ();
        my ($cmp1, $operator, $cmp2) = @$expr;

        if (ref($cmp2) eq 'REF' && ref($$cmp2) eq 'ARRAY' && !@{$$cmp2}) {
            return $offset . 'NULL';
        }

        $expr->[1] =~ s/^\s+|\s+$//g;
        # Fix operator
        $operator = uc($operator);
        $operator =~ s/!=/<>/;
        $operator =~ s/==/=/;
        $operator = 'IS'     if $operator eq '='  && !defined($expr->[2]);
        $operator = 'IS NOT' if $operator eq '<>' && !defined($expr->[2]);
        $operator = 'IN'     if $operator eq '='  && ref($expr->[2]) eq 'REF' && ref(${$expr->[2]}) eq 'ARRAY';
        $operator = 'NOT IN' if $operator eq '<>' && ref($expr->[2]) eq 'REF' && ref(${$expr->[2]}) eq 'ARRAY';

        $cmp1 = [$self->_field_to_sql(undef, $cmp1, $cur_query_table, %opts, offset => $opts{'offset'} + 4)];

        if (ref($cmp2) eq 'REF' && ref($$cmp2) eq 'ARRAY') {
            $cmp2 = ['(' . CORE::join(', ', map {$self->quote($_)} @{$$cmp2}) . ')'];
        } elsif ($operator =~ /ANY|ALL/ && blessed($cmp2) && $cmp2->isa(__PACKAGE__)) {
            ($cmp2) = $cmp2->get_sql_with_data(offset => $opts{'offset'} + 4);
            $cmp2 = ["(\n$offset    $cmp2\n$offset)"];
        } else {
            $cmp2 = [$self->_field_to_sql(undef, $cmp2, $cur_query_table, %opts, offset => $opts{'offset'} + 4)];
        }

        my @locale_suffixes = $self->{'__ALL_LANGS__'} && @$cmp1 + @$cmp2 > 2 ? $self->_get_locale_suffixes() : ('');

        for my $i (0 .. @locale_suffixes - 1) {
            push(@res,
                    (exists($cmp1->[$i]) ? $cmp1->[$i] : $cmp1->[0])
                  . " $operator "
                  . (exists($cmp2->[$i]) ? $cmp2->[$i] : $cmp2->[0]));
        }

        return (
            (@res > 1 ? '(' . CORE::join(' OR ', @res) . ')' : $res[0])
            . (
                defined($alias)
                ? ' AS ' . $self->quote_identifier($alias)
                : ''
              )
        );
    } else {
        throw Exception::BadArguments gettext('Bad field expression:\n%s', Dumper($expr));
    }
}

TRUE;

=pod

For more information see code and test.

=cut
