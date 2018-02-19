package ChoboTest::FakeStatement;

use Mouse;

use Clone qw(clone);
use Carp qw(confess);
use List::Util qw(first);
use Text::CSV;
use Text::CSV::Encoded;

has statement => (is => 'rw', required => 1);
has storage => (is => 'rw', required => 1, isa => 'HashRef');
has query_table_name => (is => 'rw');
has query_order_by => (is => 'rw');
has query_column_names => (is => 'rw', isa => 'ArrayRef');
has rows => (is => 'rw', isa => 'ArrayRef');

sub BUILD
{
  my $self = shift;

  my $statement = $self->statement();

  if ($statement =~ /select\s+(.*?)\s+from\s+(\S+)(?:\s+order by\s+(.*))?/i) {
    my $table_name = $2;
    $self->query_table_name($table_name);
    if (defined $3) {
      $self->query_order_by($3);
    } else {
      $self->query_order_by($table_name . '_id');
    }

    my @column_names = split /,\s*/, $1;

    $self->query_column_names(\@column_names);
  } else {
    if ($statement =~ /copy\s+(.*?)\s*\((.+)\) (FROM STDIN|TO STDOUT) CSV/i) {
      my $table_name = $1;

      $self->query_table_name($table_name);

      $self->query_order_by($table_name . '_id');

      my @column_names = split /,\s*/, $2;

      $self->query_column_names(\@column_names);
    } else {
      die "can't parse statement in BUILD: ", $statement;
    }
  }

  my $table_data = $self->storage()->{$self->query_table_name()};

  my $query_order_by_index =
    $table_data->{column_info}->{$self->query_order_by()}->{index};

  my @rows = sort {
    if ($self->query_order_by() =~ /_id$/) {
      $a->[$query_order_by_index] <=> $b->[$query_order_by_index];
    } else {
      $a->[$query_order_by_index] cmp $b->[$query_order_by_index];
    }
  } @{clone $self->storage()->{$self->query_table_name()}->{rows}};

  $self->rows(\@rows);
}

sub first_index
{
  my $val = shift;
  my @array = @_;

  return first { $array[$_] eq $val } 0..$#array;
}

sub check_unique
{
  my @rows = @_;

  my %counts = ();

  for my $row (@rows) {
    if ($counts{$row}) {
      return $row;
    }

    $counts{$row} = 1;
  }

  return undef;
}

sub execute
{
  return 1;
}

sub _as_hashref
{
  my $self = shift;
  my $row = shift;

  if (!$row) {
    return undef;
  }

  my %ret = ();

  my $table_storage = $self->storage()->{$self->query_table_name};

  for my $query_col_name (@{$self->query_column_names()}) {
    my $index = $table_storage->{column_info}->{$query_col_name}->{index};

    if (!defined $index) {
      die "no such column: $query_col_name\n";
    }

    $ret{$query_col_name} = $row->[$index];
  }

  return \%ret;
}

sub fetchrow_hashref
{
  my $self = shift;
  return $self->_as_hashref(shift @{$self->rows()});
}

sub _check_constraints
{
  my $self = shift;

  my $store_table_name = $self->query_table_name();
  my $table_storage = $self->storage()->{$store_table_name};

  my $unique_columns = $table_storage->{unique_columns};

  if ($unique_columns) {
    my $column_names = $table_storage->{column_names};
    my $rows = $table_storage->{rows};

    my @column_indexes = map {
      first_index($_, @$column_names);
    } @$unique_columns;

    my $col_values = sub {
      my $row = shift;

      return map {
        $row->[$_];
      } @column_indexes;
    };

    my $check_return =
      check_unique(map { join '-', $col_values->($_); } @$rows);

    if ($check_return) {
      return "unique constraint failed for $store_table_name: $check_return\n";
    }
  }

  return undef;
}

sub pg_putcopydata
{
  my $self = shift;

  my $storage = $self->storage();
  my $table_data = $storage->{$self->query_table_name()};
  my $query_table_name = $self->query_table_name();

  my $row_data = shift;
  chomp $row_data;

  my @parsed_row_data;

  my $csv = Text::CSV->new({sep_char => ","});

  if ($csv->parse($row_data)) {
    @parsed_row_data = $csv->fields();
  } else {
    die "couldn't parse this line: $row_data";
  }

  my @insert_row = ();

  my $id_index = $table_data->{column_info}->{$query_table_name . '_id'}->{index};

  for (my $i = 0; $i < @{$self->query_column_names()}; $i++) {
    my $query_column_name = $self->query_column_names()->[$i];
    my $query_column_index = $table_data->{column_info}->{$query_column_name}->{index};

    if (!defined $query_column_index) {
      die "no such column: $query_column_name\n";
    }

    $insert_row[$query_column_index] = $parsed_row_data[$i];
  }

  $insert_row[$id_index] = $table_data->{'id_counter'}++;

  push @{$table_data->{rows}}, \@insert_row;

  my $check_res = $self->_check_constraints();

  if ($check_res) {
    use Data::Dumper;
    confess $check_res . ' while adding ' . Dumper([$row_data]) . ' to ' . $query_table_name;
  }

  return 1;
}

sub pg_getcopydata
{
  my $self = shift;
  my $line_ref = shift;

  my $storage = $self->storage();
  my $table_data = $storage->{$self->query_table_name()};
  my $query_table_name = $self->query_table_name();

  my $row_data = $self->fetchrow_hashref();

  if (!$row_data) {
    return -1;
  }

  my @ret_col_values = ();

  for my $ret_col_name (@{$self->query_column_names()}) {
    push @ret_col_values, $row_data->{$ret_col_name};
  }

  my $csv = Text::CSV::Encoded->new({ encoding  => "utf8" });
  $csv->combine(@ret_col_values);

  $$line_ref = $csv->string();

  return length $$line_ref;
}

sub finish
{
}

1;
