package QBit::Application::Model::DB::mysql::Table;
$QBit::Application::Model::DB::mysql::Table::VERSION = '0.011';
use qbit;

use base qw(QBit::Application::Model::DB::Table);

use Exception::DB;
use Exception::DB::DuplicateEntry;

use QBit::Application::Model::DB::mysql::Field;

our $ADD_CHUNK = 1000;

sub create_sql {
    my ($self) = @_;

    throw gettext('Inherites does not realize') if $self->inherits;

    my $collate = defined($self->collate()) ? (" COLLATE '" . $self->collate() . "'") : '';
    my $engine = defined($self->engine()) ? $self->engine() : 'InnoDB';

    return
        'CREATE TABLE '
      . $self->quote_identifier($self->name)
      . " (\n    "
      . join(
        ",\n    ",
        (map {$_->create_sql()} @{$self->fields}),
        (
            $self->primary_key
            ? 'PRIMARY KEY (' . join(', ', map {$self->quote_identifier($_)} @{$self->primary_key}) . ')'
            : ()
        ),
        (map {$self->_create_sql_index($_)} @{$self->indexes            || []}),
        (map {$self->_create_sql_foreign_key($_)} @{$self->foreign_keys || []}),
      )
      . "\n"
      . ") ENGINE='$engine' DEFAULT CHARACTER SET 'UTF8'$collate;";
}

sub add_multi {
    my ($self, $data, %opts) = @_;

    my $fields = $self->_fields_hs();

    my $data_fields;
    if ($opts{'identical_rows'}) {
        $data_fields = [keys(%{$data->[0] // {}})];
    } else {
        $data_fields = array_uniq(map {keys(%$_)} @$data);
    }

    my $field_names;
    if ($opts{'ignore_extra_fields'}) {
        $field_names = arrays_intersection([map {$fields->{$_}->name} keys %$fields], $data_fields);
    } else {
        my @unknown_fields = grep {!exists($fields->{$_})} @$data_fields;

        throw gettext('In table %s not found follows fields: %s', $self->name(), join(', ', @unknown_fields))
          if @unknown_fields;

        $field_names = $data_fields;
    }

    throw Exception::BadArguments gettext('Expected fields') unless $field_names;

    my @locales = keys(%{$self->db->get_option('locales', {})});
    @locales = (undef) unless @locales;

    my $add_rows = 0;

    my $need_transact = @$data > $ADD_CHUNK;
    $self->db->begin() if $need_transact;

    my $sql_header =
        ($opts{'replace'} ? 'REPLACE'  : 'INSERT')
      . ($opts{'ignore'}  ? ' IGNORE ' : '')
      . ' INTO '
      . $self->quote_identifier($self->name) . ' (';
    my @real_field_names;
    foreach my $name (@$field_names) {
        if ($fields->{$name}{'i18n'}) {
            push(@real_field_names, defined($_) ? "${name}_${_}" : $name) foreach @locales;
        } else {
            push(@real_field_names, $name);
        }
    }
    $sql_header .= join(', ', map {$self->quote_identifier($_)} @real_field_names) . ") VALUES\n";

    try {
        $self->db->_sub_with_connected_dbh(
            sub {
                my ($db, @data) = @_;

                my ($sql, $values);
                my $sth;
                my $err_code;

                while (my @add_data = splice(@data, 0, $ADD_CHUNK)) {
                    if (@add_data != $ADD_CHUNK) {
                        $sql    = undef;
                        $values = undef;
                    }

                    my @params = ();
                    foreach my $row (@add_data) {
                        unless ($values) {
                            $values = '(?' . ', ?' x (@real_field_names - 1) . ')';
                            $values = $values . (",\n" . $values) x (@add_data - 1);
                        }

                        foreach my $name (@$field_names) {
                            if ($fields->{$name}{'i18n'}) {
                                if (ref($row->{$name}) eq 'HASH') {
                                    my @missed_langs = grep {!exists($row->{$name}{$_})} @locales;
                                    throw Exception::BadArguments gettext('Undefined languages "%s" for field "%s"',
                                        join(', ', @missed_langs), $name)
                                      if @missed_langs;
                                    push(@params, $row->{$name}{$_}) foreach @locales;
                                } elsif (!ref($row->{$name})) {
                                    push(@params, $row->{$name}) foreach @locales;
                                } else {
                                    throw Exception::BadArguments gettext('Invalid value in table->add');
                                }
                            } else {
                                push(@params, $row->{$name});
                            }
                        }
                    }

                    unless ($sql) {
                        $sql = $sql_header . $values;

                        $sth = $db->get_dbh()->prepare($sql)
                          || ($err_code = $db->get_dbh()->err())
                          && throw Exception::DB $db->get_dbh()->errstr()
                          . " ($err_code)\n"
                          . $db->_log_sql($sql, \@params),
                          errorcode => $err_code;
                    }

                    $add_rows += $sth->execute(@params)
                      || ($err_code = $db->get_dbh()->err())
                      && throw Exception::DB $sth->errstr() . " ($err_code)\n" . $db->_log_sql($sql, \@params),
                      errorcode => $err_code;
                }
            },
            [$self->db, @$data]
        );
    }
    catch Exception::DB with {
        my $e = shift;
        $e->{'text'} =~ /^Duplicate entry/
          ? throw Exception::DB::DuplicateEntry $e
          : throw $e;
    };

    $self->db->commit() if $need_transact;

    return $add_rows;
}

sub add {
    my ($self, $data, %opts) = @_;

    $data = {$self->primary_key->[0] => $data} if !ref($data) && @{$self->primary_key || []} == 1;

    $self->add_multi([$data], %opts);

    my $fields_hs = $self->_fields_hs();
    my @res       = map {
        !defined($data->{$_})
          && $fields_hs->{$_}{'autoincrement'}
          ? $self->db->_get_all('SELECT LAST_INSERT_ID() AS `id`')->[0]{'id'}
          : $data->{$_}
    } @{$self->primary_key || []};

    return @res == 1 ? $res[0] : \@res;
}

sub edit {
    my ($self, $pkeys_or_filter, $data, %opts) = @_;

    my @fields = keys(%$data);

    my $sql = 'UPDATE ' . $self->quote_identifier($self->name) . "\n" . 'SET ';

    my $fields = $self->_fields_hs();

    my @locales = keys(%{$self->db->get_option('locales', {})});

    my $ssql             = '';
    my @real_field_names = ();
    my @field_data       = ();
    foreach my $name (@fields) {
        $ssql .= ",\n    " unless $ssql;
        if ($fields->{$name}{'i18n'} && @locales) {
            foreach my $locale (@locales) {
                push(@real_field_names, "${name}_${locale}");
                push(@field_data, ref($data->{$name}) eq 'HASH' ? $data->{$name}{$locale} : $data->{$name});
            }
        } else {
            push(@real_field_names, $name);
            push(@field_data,       $data->{$name});
        }
    }
    $sql .= join(",\n    ", map {$self->quote_identifier($_) . ' = ?'} @real_field_names) . "\n";

    my $query = $self->db->query()->select(table => $self, fields => {});
    my $filter_expr = $query->filter($self->_pkeys_or_filter_to_filter($pkeys_or_filter))->expression();
    my ($filter_sql, @filter_data) = $query->_field_to_sql(undef, $filter_expr, $query->_get_table($self));
    $sql .= 'WHERE ' . $filter_sql;

    return $self->db->_do($sql, @field_data, @filter_data);
}

sub delete {
    my ($self, $pkeys_or_filter, %opts) = @_;

    my $query = $self->db->query()->select(table => $self, fields => {});
    my $filter_expr = $query->filter($self->_pkeys_or_filter_to_filter($pkeys_or_filter))->expression();
    my ($filter_sql, @filter_data) = $query->_field_to_sql(undef, $filter_expr, $query->_get_table($self));

    $self->db->_do('DELETE FROM ' . $self->quote_identifier($self->name) . "\nWHERE $filter_sql", @filter_data);
}

sub replace {
    my ($self, $data, %opts) = @_;

    $self->add($data, %opts, replace => 1);
}

sub _get_field_object {
    my ($self, %opts) = @_;

    return QBit::Application::Model::DB::mysql::Field->new(%opts);
}

sub _convert_fk_auto_type {
    my ($self, $field, $fk_field) = @_;

    $field->{$_} = $fk_field->{$_}
      foreach grep {exists($fk_field->{$_}) && !exists($field->{$_})} qw(type unsigned not_null length);
}

sub _create_sql_index {
    my ($self, $index) = @_;

    my @fields = map {ref($_) ? $_ : {name => $_}} @{$index->{'fields'}};

    if ($index->{'unique'}) {
        throw gettext('Class "%s" conflict with option "unique"', $index->{'class'})
          if defined($index->{'class'}) && $index->{'class'} ne 'UNIQUE';

        $index->{'class'} = 'UNIQUE';
    }

    return
        ($index->{'class'} ? "$index->{'class'} " : '')
      . 'INDEX '
      . $self->quote_identifier(
        substr(join('_', ($index->{'unique'} ? 'uniq' : ()), $self->name, '', map {$_->{'name'}} @fields), 0, 64))
      . ' ('
      . join(', ', map {$self->quote_identifier($_->{'name'}) . ($_->{'length'} ? "($_->{'length'})" : '')} @fields)
      . ')';
}

sub _create_sql_foreign_key {
    my ($self, $key) = @_;

    return 'FOREIGN KEY '
      . $self->quote_identifier(
        substr(join('_', 'fk', $self->name, '', @{$key->[0]}, '_', $key->[1], '', @{$key->[2]}), 0, 64))
      . ' ('
      . join(', ', map {$self->quote_identifier($_)} @{$key->[0]}) . ")\n"
      . '        REFERENCES '
      . $self->quote_identifier($key->[1]) . ' ('
      . join(', ', map {$self->quote_identifier($_)} @{$key->[2]}) . ")\n"
      . "            ON UPDATE RESTRICT\n"
      . "            ON DELETE RESTRICT";
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Application::Model::DB::mysql::Table - Class for MySQL tables.

=head1 Description

Implements methods for MySQL tables.

=head1 Package methods

=head2 add

B<Arguments:>

=over

=item *

B<$data> - reference to hash

=item *

B<%opts> - additional options

=over

=item *

B<replace> - boolean (uses 'REPLACE' instead 'INSERT')

=back

=back

B<Return values:>

=over

=item

B<$id> - ID new record (returns array if primary key has more than one columns)

=back

B<Example:>

  my $id = $app->db->users->add({login => 'Login'});

=head2 add_multi

ADD_CHUNK (records number in one statement; default: 1000)

  $QBit::Application::Model::DB::mysql::ADD_CHUNK = 500;

B<Arguments:>

=over

=item *

B<$data> - reference to array

=item *

B<%opts> - additional options

=over

=item *

B<replace> - boolean

=item *

B<identical_rows> - boolean (true: get field names from first row, false: Unites all fields from all rows; default: false)

=item *

B<ignore_extra_fields> - boolean (true: ignore field names that not exists in table, false: throw exception; default: false)

=item *

B<ignore> - boolean (true: adds 'IGNORE' after 'INSERT/REPLACE', false: without 'IGNORE'; default: false)

=back

=back

B<Return values:>

=over

=item

B<$count> - records number

=back

B<Example:>

  my $count = $app->db->users->add_multi([{login => 'Login 1'}, {login => 'Login 2'}]); # $count = 2

=head2 create_sql

returns sql for create table.

B<No arguments.>

B<Return values:>

=over

=item

B<$sql> - string

=back

B<Example:>

  my $sql = $app->db->users->create_sql();

=head2 delete

B<Arguments:>

=over

=item *

B<$pkeys_or_filter> - perl variables or object (QBit::Application::Model::DB::filter)

=back

B<Example:>

  $app->db->users->delete(1);
  $app->db->users->delete([1]);
  $app->db->users->delete({id => 1});
  $app->db->users->delete($app->db->filter({login => 'Login'}));

=head2 edit

B<Arguments:>

=over

=item *

B<$pkeys_or_filter> - perl variables or object (QBit::Application::Model::DB::filter)

=item *

B<$data> - reference to hash

=back

B<Example:>

  $app->db->users->edit(1, {login => 'LoginNew'});
  $app->db->users->edit([1], {login => 'LoginNew'});
  $app->db->users->edit({id => 1}, {login => 'LoginNew'});
  $app->db->users->edit($app->db->filter({login => 'Login'}), {login => 'LoginNew'});

=head2 replace

Same as

  $app->db->users->add($data, replace => TRUE);

=cut
