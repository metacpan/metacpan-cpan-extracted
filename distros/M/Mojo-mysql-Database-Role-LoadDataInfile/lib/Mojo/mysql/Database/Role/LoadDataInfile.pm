package Mojo::mysql::Database::Role::LoadDataInfile;
use Mojo::Base -role;
use Mojo::File 'tempfile';
use Mojo::Util ();

our $VERSION = '0.01';

my $text_csv_package;
BEGIN {
    if (not $ENV{MOJO_MYSQL_DATABASE_ROLE_LOAD_DATA_INFILE_NO_XS} and eval { require Text::CSV_XS; 1 }) {
        Text::CSV_XS->import('csv');
        $text_csv_package = 'Text::CSV_XS';
    } else {
        require Text::CSV_PP;
        Text::CSV_PP->import('csv');
        $text_csv_package = 'Text::CSV_PP';
    }
}

sub import {
    my $class = shift;
    if (grep { $_ eq '-no_apply' } @_) {
        return if @_ == 1;
        Carp::croak 'no other options may be provided with -no_apply';
    }

    my %options = @_;
    my $database_class = delete $options{database_class} || 'Mojo::mysql::Database';

    Carp::croak 'unknown options provided to import: ' . Mojo::Util::dumper(\%options) if %options;

    require Role::Tiny;
    Role::Tiny->apply_roles_to_package($database_class, 'Mojo::mysql::Database::Role::LoadDataInfile');
}

sub load_data_infile {
    my $self = shift;
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

    my (
        $low_priority,
        $concurrent,
        $replace,
        $ignore,
        $table,
        $partition,
        $character_set,
        $tempfile_open_mode,
        $set,
        $rows,
        $columns,
        $headers) = _parse_options(@_);

    my $tempfile = _write_temp_file($tempfile_open_mode, $rows, $headers);

    my $query = _build_query($low_priority, $concurrent, $tempfile, $replace, $ignore, $table, $partition, $character_set, $columns, $set);

    if ($cb) {
        my $cb_wrapper = sub {
            no warnings 'void';
            $tempfile;
            $cb->(@_);
        };

        return $self->query($query, $cb_wrapper);
    } else {
        return $self->query($query);
    }
}

sub load_data_infile_p {
    my $promise = Mojo::Promise->new;

    shift->load_data_infile(@_ => sub { $_[1] ? $promise->reject($_[1]) : $promise->resolve($_[2]) });

    return $promise;
}

sub _write_temp_file {
    my ($tempfile_open_mode, $rows, $headers) = @_;

    my $tempfile = tempfile();
    my $temp_fh = $tempfile->open($tempfile_open_mode);
    csv(in => $rows, out => $temp_fh, sep_char => "\t", quote_char => q{"}, eol => "\n", headers => $headers) or Carp::croak $text_csv_package->error_diag;
    close $temp_fh;

    return $tempfile;
}

sub _parse_options {
    my %options = @_;

    my @parsed_options = (
        _parse_low_priority_and_concurrent(\%options),
        _parse_replace_and_ignore(\%options),
        _parse_table(\%options),
        _parse_partition(\%options),
        _parse_character_set_and_tempfile_open_mode(\%options),
        _parse_set(\%options),
        _parse_rows_and_columns_and_headers(\%options),
    );

    Carp::croak 'unknown options provided: ' . Mojo::Util::dumper(\%options) if %options;

    return @parsed_options;
}

sub _parse_low_priority_and_concurrent {
    my ($options) = @_;

    if ($options->{low_priority} and $options->{concurrent}) {
        Carp::croak 'cannot set both low_priority and concurrent';
    }

    my $low_priority = delete $options->{low_priority} ? 'LOW_PRIORITY' : '';
    my $concurrent = delete $options->{concurrent} ? 'CONCURRENT' : '';

    return $low_priority, $concurrent;
}

sub _parse_replace_and_ignore {
    my ($options) = @_;

    if ($options->{replace} and $options->{ignore}) {
        Carp::croak 'cannot set both replace and ignore';
    }
    my $replace = delete $options->{replace} ? 'REPLACE' : '';
    my $ignore = delete $options->{ignore} ? 'IGNORE' : '';

    return $replace, $ignore;
}

sub _parse_table {
    my $table = delete shift->{table};
    Carp::croak 'table required for load_data_infile' unless defined $table and $table ne '';

    return $table;

}

sub _parse_partition {
    my ($options) = @_;

    my $partition = delete $options->{partition};
    my $ref = ref $partition // '';
    Carp::croak 'partition must be an arrayref if provided' if $partition and $ref ne 'ARRAY';

    return $partition && @$partition ? 'PARTITION (' . join(',', map "`$_`", @$partition) . ')' : '';
}

sub _parse_character_set_and_tempfile_open_mode {
    my ($options) = @_;

    if ($options->{character_set} xor $options->{tempfile_open_mode}) {
        Carp::croak 'character_set and tempfile_open_mode must both be set when one is';
    }

    my $character_set = delete $options->{character_set} || 'utf8';
    my $tempfile_open_mode = delete $options->{tempfile_open_mode} || '>:encoding(UTF-8)';

    return $character_set, $tempfile_open_mode;
}

sub _parse_set {
    my ($options) = @_;

    my $set = delete $options->{set};
    my $ref = ref $set // '';
    Carp::croak 'set must be an arrayref if provided' if $set and $ref ne 'ARRAY';

    return
        $set && @$set
            ? 'SET ' . join ',', map {
                    Carp::croak 'hashrefs passed to set must have only exactly key and value' unless keys %$_ == 1;
                    my ($column, $expression) = %$_;
                    "`$column`=$expression"
                } @$set
            : '';
}

sub _parse_rows_and_columns_and_headers {
    my ($options) = @_;

    my $rows = delete $options->{rows} || Carp::croak 'rows required for load_data_infile';
    Carp::croak 'rows must be an arrayref' unless ref $rows eq 'ARRAY';
    Carp::croak 'rows cannot be empty' unless @$rows;

    my $hashes_in_columns_allowed;
    if (ref $rows->[0] eq 'ARRAY') {
        Carp::croak 'columns required when rows contains arrayrefs'
            unless $options->{columns} and @{$options->{columns}};
    } else {
        $hashes_in_columns_allowed = 1;
    }

    Carp::croak 'columns array cannot be empty' if $options->{columns} and not @{$options->{columns}};
    my $columns = delete $options->{columns} || [keys %{$rows->[0]}];
    my @headers = map {
        my $header;
        if (ref $_ and ref $_ eq 'HASH') {
            Carp::croak 'cannot provide hashes in columns when rows contains arrayrefs' unless $hashes_in_columns_allowed;
            Carp::croak 'hashrefs passed to columns must have only one key and value' unless keys %$_ == 1;
            ($header) = keys %$_;
        } else {
            $header = $_;
        }

        Carp::croak 'columns elements cannot be undef or an empty string' unless defined $header and $header ne '';

        $header;
    } @$columns;
    $columns = join ',', map {
        my $column;
        if (ref $_ and ref $_ eq 'HASH') {
            Carp::croak 'cannot provide hashes in columns when rows contains arrayrefs' unless $hashes_in_columns_allowed;
            Carp::croak 'hashrefs passed to columns must have only exactly key and value' unless keys %$_ == 1;
            ($column) = values %$_;
        } else {
            $column = $_;
        }

        Carp::croak 'columns elements cannot be undef or an empty string' unless defined $column and $column ne '';

        "`$column`";
    } @$columns;

    return $rows, $columns, \@headers;
}

sub _build_query {
    my ($low_priority, $concurrent, $tempfile, $replace, $ignore, $table, $partition, $character_set, $columns, $set) = @_;

    return qq{
        LOAD DATA $low_priority $concurrent LOCAL INFILE '$tempfile'
        $replace $ignore INTO TABLE `$table`
        $partition
        CHARACTER SET '$character_set'
        FIELDS TERMINATED BY '\\t' OPTIONALLY ENCLOSED BY '"'
        LINES TERMINATED BY '\\n'
        IGNORE 1 LINES
        ($columns)
        $set
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojo::mysql::Database::Role::LoadDataInfile - Easy load data infile support for Mojo::mysql

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojo-mysql-Database-Role-LoadDataInfile"><img src="https://travis-ci.org/srchulo/Mojo-mysql-Database-Role-LoadDataInfile.svg?branch=master"></a>

=head1 SYNOPSIS

  use Mojo::mysql;
  use Mojo::mysql::Database::Role::LoadDataInfile;

  my $mysql   = Mojo::mysql->new(...);
  my $results = $mysql->db->load_data_infile(
    table => 'people',
    rows => [
      {
        name => 'Bob',
        age  => 23,
      },
      {
        name => 'Alice',
        age  => 25,
      },
    ],
  );

  print $results->affected_rows . " affected rows\n";

  # use promises for non-blocking queries
  my $promise = $mysql->db->load_data_infile_p(
    table => 'people',
    rows => [
      {
        name => 'Bob',
        age  => 23,
      },
      {
        name => 'Alice',
        age  => 25,
      },
    ],
  );

  $promise->then(sub {
    my $results = shift;
    print $results->affected_rows . " affected rows\n";
  })->catch(sub {
    my $err = shift;
    warn "Something went wrong: $err";
  });


  # apply the LoadDataInfile role to your own database_class
  use Mojo::mysql::Database::Role::LoadDataInfile database_class => 'MyApp::Database';

  $mysql->database_class('MyApp::Database');
  my $results = $mysql->db->load_data_infile(...);


  # don't auto apply the role to Mojo::mysql::Database and do it yourself
  $mysql->db->with_roles('+LoadDataInfile')->load_data_infile(...);

  # or

  Role::Tiny->apply_roles_to_package('Mojo::mysql::Database', 'Mojo::mysql::Database::Role::LoadDataInfile');

=head1 DESCRIPTION

L<Mojo::mysql::Database::Role::LoadDataInfile> is a role that makes synchronous and asynchronous C<LOAD DATA INFILE> queries easy
with your L<Mojo::mysql/database_class>.

This module currently only supports C<LOAD DATA LOCAL INFILE>, meaning the file used for C<LOAD DATA INFILE> is on
the same computer where your code is running, not the database server. L<Mojo::mysql::Database::Role::LoadDataInfile>
generates a temporary file for you locally on the computer your code is running on.

=head1 IMPORT OPTIONS

=head2 database_class

  # apply the LoadDataInfile role to your own database_class
  use Mojo::mysql::Database::Role::LoadDataInfile database_class => 'MyApp::Database';

  $mysql->database_class('MyApp::Database');
  my $results = $mysql->db->load_data_infile(...);

L</database_class> allows you to apply L<Mojo::mysql::Database::Role::LoadDataInfile> to your own database class
instead of the default L<Mojo::mysql::Database>.

=head1 METHODS

=head2 load_data_infile

  my $results = $db->load_data_infile(table => 'people', rows => $rows);
  print $results->affected_rows . " affected rows\n";

Execute a blocking C<LOAD DATA INFILE> query and return a L<Mojo::mysql::Results> instance.
A temporary file is used to store the data in C<$rows> and then is sent to MySQL. The file is
deleted once the query is complete.
You can also append a callback to perform a non-blocking operation.

  my $results = $db->load_data_infile(table => 'people', rows => $rows, sub {
    my ($db, $err, $results) = @_;

    if ($err) {
        print "LOAD DATA INFILE failed: $err\n";
    } else {
      print $results->affected_rows . " affected rows\n";
    }
  });

=head2 load_data_infile_p

  my $promise = $db->load_data_infile_p(table => 'people', rows => $rows);

Same as L</load_data_infile>, but performs all operations non-blocking and returns a L<Mojo::Promise> object instead of accepting a callback.

  $db->load_data_infile_p(table => 'people', rows => $rows)->then(sub {
    my $results = shift;
    print $results->affected_rows . " affected rows\n";
    ...
  })->catch(sub {
    my $err = shift;
    ...
  })->wait;

=head2 options

These are the options that can be passed to both L</load_data_infile> and L</load_data_infile_p>. Unless
stated otherwise, options may be combined.

See L<LOAD DATA SYNTAX|https://dev.mysql.com/doc/refman/5.7/en/load-data.html> for more information
on the below options, and possibly more up-to-date information.

=head3 low_priority

  $db->load_data_infile(table => 'people', rows => $rows, low_priority => 1);

Adds the C<LOW_PRIORITY> modifier to the query, which means that the execution of the C<LOAD DATA> statement is delayed until
no other clients are reading from the table. This affects only storage engines that use only table-level locking (such as MyISAM, MEMORY, and MERGE).

This cannot be C<true> when L</concurrent> is C<true>.

=head3 concurrent

  $db->load_data_infile(table => 'people', rows => $rows, concurrent => 1);

Adds the C<CONCURRENT> modifier to the query, which means that for MyISAM tables that satisfy the condition for concurrent
inserts (that is, it contains no free blocks in the middle), other threads can retrieve data from the table while C<LOAD DATA> is executing.

This cannot be C<true> when L</low_priority> is C<true>.

=head3 replace

  $db->load_data_infile(table => 'people', rows => $rows, replace => 1);

Adds the C<REPLACE> modifier to the query, which means that rows that have the same value for a
primary key or unique index as an existing row will replace the existing row.

This cannot be C<true> when L</ignore> is C<true>.

If neither L</replace> nor L</ignore> is specified, the default is L</ignore> since this module
uses the C<LOCAL> modifier.

=head3 ignore

  $db->load_data_infile(table => 'people', rows => $rows, ignore => 1);

Adds the C<REPLACE> modifier to the query, which means that rows that duplicate an existing row on a unique key value
are discarded.

This cannot be C<true> when L</replace> is C<true>.

If neither L</ignore> nor L</replace> is specified, the default is L</ignore> since this module
uses the C<LOCAL> modifier.

=head3 partition

  $db->load_data_infile(table => 'people', rows => $rows, partition => ['p0', 'p1', 'p2']);

Adds the C<PARITION> clause along with the provided partitions to insert into.

See L<Partitioned Table Support|https://dev.mysql.com/doc/refman/5.7/en/load-data.html#load-data-partitioning-support> for more information.

=head3 character_set

  $db->load_data_infile(table => 'people', rows => $rows, character_set => 'utf8', tempfile_open_mode => '>:encoding(UTF-8)');

Adds the C<CHARACTER SET> clause, which specifies the encoding that MySQL will use to interpret the data.

The default is C<utf8>, which matches with the default of L</tempfile_open_mode>. If you provide L</character_set>,
you must also provide L</tempfile_open_mode>. The encodings should match between these two.

=head3 tempfile_open_mode

  $db->load_data_infile(table => 'people', rows => $rows, character_set => 'utf8', tempfile_open_mode => '>:encoding(UTF-8)');

Sets the mode when opening the temporary file.

The default is ">:encoding(UTF-8)", which matches with the default of L</character_set>. If you provide L</tempfile_open_mode>,
you must also provide L</character_set>. The encodings should match between these two.

=head3 set

  $db->load_data_infile(table => 'people', rows => $rows, set => [
      {insert_time => 'NOW()'},
      {update_time => 'NOW()'},
  ]);

The C<SET> clause can be used in several different ways, such as to supply values not derived from the input file. It accepts
an arrayref of hashes, where the key of each hash is the column to set and the value is the expression to set it to.

See L<Input Preprocessing|https://dev.mysql.com/doc/refman/5.7/en/load-data.html#load-data-input-preprocessing> for more examples
of how L</set> can be used.

=head3 rows

L</rows> correspond to the rows to be inserted. L</rows> can be passed either an arrayref of L</hashrefs>, or an arrayref of L</arrayrefs>.

=head4 hashrefs

  my $rows = [
    { name => 'Bob', age => 23 },
    { name => 'Alice', age => 27 },
  ];
  $db->load_data_infile(table => 'people', rows => $rows);

If the items are L</hashrefs> and L</columns> is not provided, the keys from the first hashref will be used for L</columns> and will
be used as both the MySQL column names, and the key names to get values from the hashrefs.

=head4 arrayrefs

  my $rows = [
    ['Bob', 23],
    ['Alice', 27],
  ];

  # columns required when using arrayrefs
  my $columns = ['name', 'age'];
  $db->load_data_infile(table => 'people', rows => $rows, columns => $columns);

If the items are L</arrayrefs>, L</columns> must be provided, and the order of the column names in columns must match with the order of the values in
each arrayref in L</rows>.

See L</columns> for more advance columns options.

=head3 columns

L</columns> specifies the names of the columns to set in the table. Different values may be provided
depending on whether L</rows> contains L</hashrefs> or L</arrayrefs>.

=head4 rows contains hashrefs

  # will use keys of first hashref in $rows for columns if columns is not provided
  $db->load_data_infile(table => 'people', rows => $rows);

  # strings in $columns will be used as keys to access values of the hashrefs
  # and also as the column names in MySQL
  my $columns = ['name', 'age'];
  $db->load_data_infile(table => 'people', rows => $rows, columns => $columns);

  # you can map hash keys to their correpsonding names in the table
  my $columns = [
    'name',
    { hash_age => 'column_age' },
  ];
  $db->load_data_infile(table => 'people', rows => $rows, columns => $columns);

If L</columns> is not provided, L</rows> must contain hashrefs,
and the keys of the first hashref will be used as the columns.

You may pass two types of values in L</columns> when L</hashrefs> are used in L</rows>:

=over 4

=item *
You may pass strings, which will be used as the keys to access the values of the hashrefs and the column names.

=item *

Or, you may also pass hashes with a single key value pair, where the key is the name of the key in the hash,
and the value is the name of the corresponding column in the table:

  { key_name => 'column_name' }

=back

=head4 rows contains arrayrefs

  # columns must be in the same order as their corresponding values in $rows
  my $columns = ['name', 'age'];
  $db->load_data_infile(table => 'people', rows => $rows, columns => $columns);

If L</rows> contains L</arrayrefs>, L</columns> is required and its values should be in the same order as
the corresponding values in the arrayrefs pasesed to L</rows>.

=head1 AUTHOR

Adam Hopkins E<lt>srchulo@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2019- Adam Hopkins

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over 4

=item * L<Mojolicious>

=item * L<Mojo::mysql>

=item * L<Mojo::mysql::Database>

=item * L<Text::CSV_XS>

=item * L<Text::CSV_PP>

=back

=cut
