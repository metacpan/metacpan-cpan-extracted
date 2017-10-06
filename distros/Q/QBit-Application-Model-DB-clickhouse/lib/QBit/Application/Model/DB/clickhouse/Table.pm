package QBit::Application::Model::DB::clickhouse::Table;
$QBit::Application::Model::DB::clickhouse::Table::VERSION = '0.005';
use qbit;

use base qw(QBit::Application::Model::DB::Table);

use QBit::Application::Model::DB::clickhouse::Field;

our $ADD_CHUNK = 1000;

BEGIN {
    no strict 'refs';

    foreach my $method (qw(edit delete replace)) {
        *{__PACKAGE__ . "::$method"} = sub {throw gettext('Method "%s" not supported', $method)}
    }
}

sub init {
    my ($self) = @_;

    $self->QBit::Application::Model::DB::Class::init();

    throw gettext('Required opt "fields"')
      unless $self->{'fields'};

    foreach my $field (@{$self->{'fields'}}) {
        $field = $self->_get_field_object(%$field, db => $self->db, table => $self);
        $self->{'__FIELDS_HS__'}{$field->{'name'}} = $field;
    }
}

sub add {
    my ($self, $data, %opts) = @_;

    return $self->add_multi([$data], %opts);
}

sub add_multi {
    my ($self, $data, %opts) = @_;

    my $fields = $self->_fields_hs();

    my $field_names;
    if ($opts{'fields'}) {
        my @unknown_fields = grep {!exists($fields->{$_})} @{$opts{'fields'}};

        throw gettext('In table %s not found follows fields: %s', $self->name(), join(', ', @unknown_fields))
          if @unknown_fields;

        $field_names = $opts{'fields'};
    } elsif (blessed($data->[0]) && $data->[0]->isa('QBit::Application::Model::DB::Query')) {
        $field_names = [sort map {$fields->{$_}->name} keys %$fields];
    } else {
        my $data_fields;
        if ($opts{'identical_rows'}) {
            $data_fields = [keys(%{$data->[0] // {}})];
        } else {
            $data_fields = array_uniq(map {keys(%$_)} @$data);
        }

        if ($opts{'ignore_extra_fields'}) {
            $field_names = arrays_intersection([map {$fields->{$_}->name} keys %$fields], $data_fields);
        } else {
            my @unknown_fields = grep {!exists($fields->{$_})} @$data_fields;

            throw gettext('In table %s not found follows fields: %s', $self->name(), join(', ', @unknown_fields))
              if @unknown_fields;

            $field_names = $data_fields;
        }

        $field_names = [sort @$field_names];
    }

    throw Exception::BadArguments gettext('Expected fields') unless $field_names;

    my @locales = sort keys(%{$self->db->get_option('locales', {})});
    @locales = (undef) unless @locales;

    my $add_rows = 0;

    my $sql_header = 'INSERT INTO ' . $self->quote_identifier($self->name) . ' (';

    my @real_field_names;
    foreach my $name (@$field_names) {
        if ($fields->{$name}{'i18n'}) {
            push(@real_field_names, defined($_) ? "${name}_${_}" : $name) foreach @locales;
        } else {
            push(@real_field_names, $name);
        }
    }
    $sql_header .= join(', ', map {$self->quote_identifier($_)} @real_field_names) . ") ";

    my $db = $self->db();

    if (blessed($data->[0]) && $data->[0]->isa('QBit::Application::Model::DB::Query')) {
        my ($sql, @params) = $data->[0]->get_sql_with_data();

        return $db->_do($sql_header . $sql, @params);
    }

    $sql_header .= "VALUES\n";

    while (my @add_data = splice(@$data, 0, $ADD_CHUNK)) {
        my ($delimiter, $values) = ('', '');

        foreach my $row (@add_data) {
            my @params;
            foreach my $name (@$field_names) {
                if ($fields->{$name}{'i18n'}) {
                    if (ref($row->{$name}) eq 'HASH') {
                        my @missed_langs = grep {!exists($row->{$name}{$_})} @locales;
                        throw Exception::BadArguments gettext('Undefined languages "%s" for field "%s"',
                            join(', ', @missed_langs), $name)
                          if @missed_langs;
                        push(@params, $fields->{$name}->quote($row->{$name}{$_})) foreach @locales;
                    } elsif (!ref($row->{$name})) {
                        push(@params, $fields->{$name}->quote($row->{$name})) foreach @locales;
                    } else {
                        throw Exception::BadArguments gettext('Invalid value in table->add');
                    }
                } else {
                    push(@params, $fields->{$name}->quote($row->{$name}));
                }
            }

            $values .= "$delimiter(" . join(', ', @params) . ')';

            $delimiter ||= ",\n";
        }

        $db->_do($sql_header . $values);

        $add_rows += @add_data;
    }

    return $add_rows;
}

sub create_sql {
    my ($self) = @_;

    throw gettext('Inherites does not realize') if $self->inherits;

    my $engine = $self->engine() or throw gettext('Expected "engine" for table "%s"', $self->name);

    my ($engine_to_sql) =
      $self->db->query(without_table_alias => TRUE)->_field_to_sql(undef, $engine, {table => $self});

    return
        'CREATE TABLE '
      . $self->quote_identifier($self->name)
      . " (\n    "
      . join(",\n    ", (map {$_->create_sql()} @{$self->fields}),) . "\n"
      . ") ENGINE = $engine_to_sql;\n";
}

sub _get_field_object {
    my ($self, %opts) = @_;

    throw gettext('Required option "name"') unless defined($opts{'name'});
    throw gettext('Required option "type" for field "%s"', $opts{'name'}) unless defined($opts{'type'});

    return QBit::Application::Model::DB::clickhouse::Field->new(%opts);
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Application::Model::DB::clickhouse::Table - Class for ClickHouse tables.

=head1 Description

Implements methods for ClickHouse tables.

=head1 Package methods

=head2 add

B<Arguments:>

=over

=item *

B<$data> - reference to hash or object(QBit::Application::Model::DB::Query)

=item *

B<%opts> - additional options

=over

=item *

B<fields> - array ref (order for fields)

=back

=back

B<Return values:>

=over

=item

B<$count> - number of new records

=back

B<Example:>

  my $count = $app->db->stat->add({date => '2017-09-03', hits => 10}); # $count = 1, insert all fields

  $count = $app->db->stat->add({date => '2017-09-03', hits => 10, not_exists => 'something'}, fields => [qw(date hits)]);
  # $count = 1, insert only date and hits in this order

  $app->db->stat->add(
      $app->db->query->select(
          table  => $app->db->today_stat,
          fields => [qw(date hits)],
          filter => {date => '2017-09-17 19:19:23'}
      ),
      fields => [qw(date hits)]
  );

  # clickhouse
  INSERT INTO `stat` (`date`, `hits`) SELECT
    `today_stat`.`date` AS `date`,
    `today_stat`.`hits` AS `hits`
  FROM `today_stat`
  WHERE (
    `today_stat`.`date` = '2017-09-17 19:19:23'
  );

=head2 add_multi

ADD_CHUNK (records number in one statement; default: 1000)

  $QBit::Application::Model::DB::clickhouse::ADD_CHUNK = 500;

B<Arguments:>

=over

=item *

B<$data> - reference to array

=item *

B<%opts> - additional options

=over

=item *

B<fields> - array ref (order for fields)

=item *

B<identical_rows> - boolean (true: get field names from first row, false: Unites all fields from all rows; default: false)

=item *

B<ignore_extra_fields> - boolean (true: ignore field names that not exists in table, false: throw exception; default: false)

=back

=back

B<Return values:>

=over

=item

B<$count> - records number

=back

B<Example:>

  my $count = $app->db->stat->add_multi([{date => '2017-09-02', hits => 5}, {date => '2017-09-03', hits => 10}]); # $count = 2

  $count = $app->db->stat->add_multi([
      {date => '2017-09-02', hits => 5, not_exists => 'something'},
      {date => '2017-09-03', hits => 10, not_exists => 'something'}
    ],
    fields => [qw(date hits)]
  );
  # $count = 2, insert only date and hits in this order

=head2 create_sql

returns sql for create table.

B<No arguments.>

B<Return values:>

=over

=item

B<$sql> - string

=back

B<Example:>

  my $sql = $app->db->stat->create_sql();

=cut
