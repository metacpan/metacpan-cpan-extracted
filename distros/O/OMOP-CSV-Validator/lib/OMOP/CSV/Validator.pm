package OMOP::CSV::Validator;

use strict;
use warnings;
use utf8;
use JSON::Validator;
use Text::CSV_XS;
use Scalar::Util qw(looks_like_number refaddr);
use Path::Tiny;

our $VERSION = '0.05';
our @DETECTABLE_SEPARATORS = ( ',', "\t", ';', '|' );

=head1 NAME

OMOP::CSV::Validator - Validates OMOP CDM CSV files against their expected data types

=head1 SYNOPSIS

    use OMOP::CSV::Validator;

    my $validator = OMOP::CSV::Validator->new();

    # Load schemas from DDL
    my $schemas = $validator->load_schemas_from_ddl($ddl_text);

    # Retrieve specific table schema for a CSV file
    my $schema = $validator->get_schema_from_csv_filename($csv_file, $schemas);

    # Validate CSV file
    my $errors  = $validator->validate_csv_file($csv_file, $schema);
    if (@$errors) {
        print "Validation errors found:\n";
        for my $err_info (@$errors) {
            print "Row $err_info->{row}:\n";
            for my $e (@{ $err_info->{errors} }) {
                print "  $e\n";
            }
        }
    } else {
        print "CSV is valid.\n";
    }

=head1 DESCRIPTION

OMOP::CSV::Validator is a CLI tool and Perl module designed to validate OMOP Common Data Model (CDM) CSV files. It auto-generates JSON schemas from PostgreSQL DDL files and then validates CSV rows against those schemas.

=head1 METHODS

=cut

##########################################################################
# Constructor: new()
##########################################################################
sub new {
    my ( $class, %args ) = @_;
    my $self = bless { _runtime_plan_cache => {} }, $class;
    return $self;
}

##########################################################################
# load_schemas_from_ddl($ddl_text)
#
# Parses all CREATE TABLE definitions from a PostgreSQL OMOP DDL
# and returns a hashref of JSON schemas keyed by table name (lowercase).
##########################################################################
sub load_schemas_from_ddl {
    my ( $self, $ddl_text ) = @_;
    return $self->_ddl_to_json_schemas($ddl_text);
}

##########################################################################
# load_column_order_from_ddl($ddl_text, $table_name)
#
# Parses the ordered column names for one PostgreSQL CREATE TABLE block.
##########################################################################
sub load_column_order_from_ddl {
    my ( $self, $ddl_text, $table_name ) = @_;
    my $tables = $self->_ddl_to_table_blocks($ddl_text);
    my $cols_block = $tables->{ lc $table_name };
    die "Could not find columns for table '$table_name' in the DDL file\n"
      unless defined $cols_block;
    return $self->_extract_column_order($cols_block);
}

##########################################################################
# _ddl_to_json_schemas($ddl_text) - private
#
# Internal subroutine that iterates over all CREATE TABLE blocks.
##########################################################################
sub _ddl_to_json_schemas {
    my ( $self, $ddl_text ) = @_;
    my %schemas;
    my $tables = $self->_ddl_to_table_blocks($ddl_text);
    while ( my ( $table, $cols_block ) = each %{$tables} ) {
        $schemas{$table} = $self->_build_schema( $table, $cols_block );
    }
    return \%schemas;
}

##########################################################################
# _ddl_to_table_blocks($ddl_text) - private
#
# Returns a hashref of table_name => raw column-definition block.
##########################################################################
sub _ddl_to_table_blocks {
    my ( $self, $ddl_text ) = @_;
    my %tables;
    while (
        $ddl_text =~ /
        CREATE\s+TABLE\s+
        (?:
            [^\s(]+?\.
        )?
        "?(\w+)"?\s*\(
        (.*?)
        \)\s*;
    /gisx
      )
    {
        $tables{ lc $1 } = $2;
    }
    return \%tables;
}

##########################################################################
# _build_schema($table_name, $cols_block) - private
#
# Builds a JSON schema for one table from the column definitions.
##########################################################################
sub _build_schema {
    my ( $self, $table_name, $cols_block ) = @_;
    my $schema = {
        '$schema'            => 'http://json-schema.org/draft-07/schema#',
        title                => $table_name,
        type                 => 'object',
        properties           => {},
        required             => [],
        additionalProperties => 0,
    };

    for my $col_def ( @{ $self->_extract_column_definitions($cols_block) } ) {
        my ( $col, $type, $length, $notnull ) =
          @{$col_def}{qw(col type length notnull)};
            my $prop = {};

            if ( $type =~ /int/ ) {
                $prop->{type}    = 'integer';
                $prop->{_coerce} = 1;
            }
            elsif ( $type =~ /numeric|real|double/ ) {
                $prop->{type}    = 'number';
                $prop->{_coerce} = 1;

            }
            elsif ( $type eq 'date' ) {
                $prop->{type}   = 'string';
                $prop->{format} = 'date';
            }
            elsif ( $type =~ /timestamp/ ) {
                $prop->{type}   = 'string';
                $prop->{format} = 'date-time';
            }
            elsif ( $type eq 'varchar' ) {
                $prop->{type} = 'string';
                if ( defined $length ) {

                    # Capture only the first number if a comma is present (e.g., varchar(10,2))
                    if ( $length =~ /^(\d+)/ ) {
                        $prop->{maxLength} = int($1);
                    }
                }
            }
            else {
                $prop->{type} = 'string';
            }

            # If the column is not marked as NOT NULL, allow null values
            unless ($notnull) {
                $prop->{type} = [ $prop->{type}, 'null' ];
            }

            $schema->{properties}{$col} = $prop;
            push @{ $schema->{required} }, $col if $notnull;
    }
    return $schema;
}

##########################################################################
# _extract_column_definitions($cols_block) - private
#
# Returns parsed column definitions in DDL order.
##########################################################################
sub _extract_column_definitions {
    my ( $self, $cols_block ) = @_;
    my @defs;

    for my $line ( grep /\S/, split /\n/, $cols_block ) {
        $line =~ s/^\s+|\s+$//g;
        $line =~ s/,$//;
        next if $line =~ /^--/;
        next if $line =~ /^(?:primary|foreign|unique|constraint)\b/i;

        if ( $line =~
            /^"?(\w+)"?\s+([A-Za-z]+)(?:\((\d+(?:,\d+)?)\))?(?:\s+(NOT NULL))?/i )
        {
            push @defs,
              {
                col     => lc $1,
                type    => lc $2,
                length  => $3,
                notnull => defined $4 ? 1 : 0,
              };
        }
    }

    return \@defs;
}

##########################################################################
# _extract_column_order($cols_block) - private
#
# Returns ordered column names for one CREATE TABLE block.
##########################################################################
sub _extract_column_order {
    my ( $self, $cols_block ) = @_;
    return [ map { $_->{col} } @{ $self->_extract_column_definitions($cols_block) } ];
}

##########################################################################
# get_schema_from_csv_filename($csv_filename, $schemas)
#
# Derives the table name from the CSV file's basename (e.g. PERSON.csv → person)
# and returns the corresponding schema from the provided hashref.
##########################################################################
sub get_schema_from_csv_filename {
    my ( $self, $csv_filename, $schemas ) = @_;
    my $table = $self->_table_name_from_csv_filename($csv_filename);
    return $schemas->{$table};
}

##########################################################################
# validate_csv_file($csv_file, $schema, $sep)
#
# Reads the CSV file, coerces numeric fields, and validates each row against
# the provided JSON schema. Returns an arrayref of error info (each entry is a
# hashref with keys 'row' and 'errors').
##########################################################################
sub validate_csv_file {
    my ( $self, $csv_file, $schema, $sep, @rest ) = @_;
    my %options =
      @rest == 1 && ref( $rest[0] ) eq 'HASH' ? %{ $rest[0] } : @rest;
    my @errors;
    $self->_stream_csv_rows(
        $csv_file,
        $schema,
        $sep,
        validation_mode => $options{validation_mode},
        on_row => sub {
            my ($row_result) = @_;
            push @errors,
              {
                row    => $row_result->{row},
                errors => $row_result->{errors},
              }
              if @{ $row_result->{errors} };
        },
    );
    return \@errors;
}

##########################################################################
# normalize_csv_value($val)
#
# Normalizes CSV null markers to undef.
##########################################################################
sub _table_name_from_csv_filename {
    my ( $self, $csv_filename ) = @_;
    ( my $table = lc $csv_filename ) =~ s{^.*/}{};      # remove any path
    $table =~ s/\.csv$//i;                              # remove .csv extension
    return $table;
}

##########################################################################
# _build_json_validator($schema)
#
# Returns a JSON::Validator instance for a pre-built schema.
##########################################################################
sub _build_json_validator {
    my ( $self, $schema ) = @_;
    my $validator = JSON::Validator->new;
    $validator->schema($schema);
    return $validator;
}

##########################################################################
# _build_runtime_plan($schema, $validation_mode)
#
# Compiles per-schema normalization metadata and a validation backend.
##########################################################################
sub _build_runtime_plan {
    my ( $self, $schema, $validation_mode ) = @_;
    $validation_mode ||= 'json';
    die "Unsupported validation mode '$validation_mode'\n"
      unless $validation_mode eq 'json' || $validation_mode eq 'turbo';

    my $schema_id = refaddr($schema);
    if ($schema_id) {
        my $cached = $self->{_runtime_plan_cache}{$validation_mode}{$schema_id};
        return $cached if $cached;
    }

    my @required = @{ $schema->{required} || [] };
    my %required = map { $_ => 1 } @required;
    my %seen;
    my @ordered_columns = grep { !$seen{$_}++ }
      ( @required, sort keys %{ $schema->{properties} || {} } );

    my @columns = map {
        my $name = $_;
        my $prop = $schema->{properties}{$name} || {};
        my @types =
          ref( $prop->{type} ) eq 'ARRAY' ? @{ $prop->{type} } : ( $prop->{type} );
        my ($base_type) = grep { defined $_ && $_ ne 'null' } @types;
        $base_type ||= 'string';

        {
            name       => $name,
            type       => $base_type,
            nullable   => scalar( grep { defined $_ && $_ eq 'null' } @types ) ? 1 : 0,
            required   => $required{$name} ? 1 : 0,
            coerce     => $prop->{_coerce} ? 1 : 0,
            max_length => $prop->{maxLength},
            format     => $prop->{format},
        };
    } @ordered_columns;

    my $plan = {
        mode          => $validation_mode,
        columns       => \@columns,
        required      => \@required,
        allowed       => { map { $_->{name} => 1 } @columns },
        validator_sub => undef,
    };

    if ( $validation_mode eq 'turbo' ) {
        $plan->{validator_sub} = $self->_build_turbo_validator_sub($plan);
    }
    else {
        my $validator = $self->_build_json_validator($schema);
        $plan->{validator_sub} = sub {
            my ($record) = @_;
            return [ map { "$_" } $validator->validate($record) ];
        };
    }

    $self->{_runtime_plan_cache}{$validation_mode}{$schema_id} = $plan
      if $schema_id;
    return $plan;
}

##########################################################################
# _csv_parser_for_sep($sep)
#
# Returns a Text::CSV_XS parser configured for a separator.
##########################################################################
sub _csv_parser_for_sep {
    my ( $self, $sep, %args ) = @_;
    my $csv = Text::CSV_XS->new(
        {
            binary         => 1,
            sep_char       => $sep,
            auto_diag      => $args{auto_diag} // 1,
            blank_is_undef => 1,
        }
    );
    die "Cannot use CSV: " . Text::CSV_XS->error_diag() unless $csv;
    return $csv;
}

##########################################################################
# _sample_csv_lines($csv_file, $max_lines)
#
# Returns up to $max_lines non-empty lines for separator detection.
##########################################################################
sub _sample_csv_lines {
    my ( $self, $csv_file, $max_lines ) = @_;
    $max_lines //= 6;

    my $handle = path($csv_file)->openr_utf8;
    my @lines;
    while ( defined( my $line = <$handle> ) ) {
        next if $line =~ /^\s*$/;
        chomp $line;
        push @lines, $line;
        last if @lines >= $max_lines;
    }
    $handle->close;
    return \@lines;
}

##########################################################################
# _candidate_score_for_sep($lines, $sep)
#
# Scores a separator candidate based on consistent parsed column counts.
##########################################################################
sub _candidate_score_for_sep {
    my ( $self, $lines, $sep ) = @_;
    my $parser = eval { $self->_csv_parser_for_sep( $sep, auto_diag => 0 ) };
    return undef if !$parser;

    my @counts;
    for my $line ( @{$lines} ) {
        my $ok = $parser->parse($line);
        return undef if !$ok;
        my @fields = $parser->fields();
        return undef if !@fields;
        push @counts, scalar(@fields);
    }

    my $header_count = $counts[0];
    return undef if !defined $header_count || $header_count < 2;

    for my $count (@counts) {
        return undef if $count != $header_count;
    }

    return {
        sep         => $sep,
        column_count => $header_count,
        sample_rows  => scalar(@counts),
    };
}

##########################################################################
# detect_csv_separator($csv_file)
#
# Attempts to infer the separator from a small file sample.
##########################################################################
sub detect_csv_separator {
    my ( $self, $csv_file ) = @_;
    my $lines = $self->_sample_csv_lines($csv_file);
    die "Input CSV has no header row\n" unless @{$lines};

    my @candidates =
      grep { defined $_ }
      map { $self->_candidate_score_for_sep( $lines, $_ ) } @DETECTABLE_SEPARATORS;

    die "Could not infer a field separator for '$csv_file'. Please pass --sep explicitly.\n"
      unless @candidates;

    @candidates = sort {
             $b->{column_count} <=> $a->{column_count}
          || $b->{sample_rows}  <=> $a->{sample_rows}
    } @candidates;

    my $best = $candidates[0];
    my @tied = grep {
           $_->{column_count} == $best->{column_count}
        && $_->{sample_rows}  == $best->{sample_rows}
    } @candidates;

    die "Ambiguous field separator for '$csv_file'. Please pass --sep explicitly.\n"
      if @tied > 1;

    return $best->{sep};
}

##########################################################################
##########################################################################
# _open_csv_stream($csv_file, $sep)
#
# Opens a CSV file for row-by-row processing and returns parser state.
##########################################################################
sub _open_csv_stream {
    my ( $self, $csv_file, $sep ) = @_;
    $sep = defined $sep ? $sep : $self->detect_csv_separator($csv_file);
    my $csv_handle = path($csv_file)->openr_utf8;
    my $csv        = $self->_csv_parser_for_sep($sep);

    my $header = $csv->getline($csv_handle)
      or die "Input CSV has no header row\n";
    $csv->column_names(@$header);

    return {
        csv    => $csv,
        handle => $csv_handle,
        header => $header,
        sep    => $sep,
    };
}

##########################################################################
# _stream_csv_rows($csv_file, $schema, $sep, %callbacks)
#
# Reads a CSV file row by row and emits header/row callbacks.
##########################################################################
sub _stream_csv_rows {
    my ( $self, $csv_file, $schema, $sep, %options ) = @_;
    die "Schema is required for CSV validation\n"
      unless defined $schema && ref($schema) eq 'HASH';

    my $validation_mode = delete $options{validation_mode} || 'json';
    my $on_header       = delete $options{on_header};
    my $on_row          = delete $options{on_row};
    my $stream          = $self->_open_csv_stream( $csv_file, $sep );
    my $plan            = $self->_build_runtime_plan( $schema, $validation_mode );
    my $row_count       = 0;

    $on_header->( $stream->{header} ) if $on_header;

    while ( my $record = $stream->{csv}->getline_hr( $stream->{handle} ) ) {
        $row_count++;
        my $raw_record = { %{$record} };
        my $normalized = $self->_normalize_record_for_plan( $record, $plan );
        my $errs       = $self->_validation_messages_for_record( $plan, $normalized );

        my $row_result = {
            row    => $row_count,
            ok     => @$errs ? 0 : 1,
            raw    => $raw_record,
            errors => $errs,
        };

        $on_row->($row_result) if $on_row;
    }

    $stream->{handle}->close;
    return {
        header   => $stream->{header},
        row_count => $row_count,
    };
}

##########################################################################
# _analyze_csv_file($csv_file, $schema, $sep)
#
# Reads a CSV file and returns header + per-row validation results.
##########################################################################
sub _analyze_csv_file {
    my ( $self, $csv_file, $schema, $sep, @rest ) = @_;
    my %options =
      @rest == 1 && ref( $rest[0] ) eq 'HASH' ? %{ $rest[0] } : @rest;
    my @row_results;
    my $header;

    $self->_stream_csv_rows(
        $csv_file,
        $schema,
        $sep,
        validation_mode => $options{validation_mode},
        on_header => sub {
            my ($stream_header) = @_;
            $header = $stream_header;
        },
        on_row => sub {
            my ($row_result) = @_;
            push @row_results, $row_result;
        },
    );

    return {
        header => $header,
        rows   => \@row_results,
    };
}

##########################################################################
# _normalize_record_for_plan($record, $plan)
#
# Applies null normalization and numeric coercion according to the schema.
##########################################################################
sub _normalize_record_for_plan {
    my ( $self, $record, $plan ) = @_;
    my %normalized = %{$record};

    for my $col_plan ( @{ $plan->{columns} } ) {
        my $col = $col_plan->{name};
        next unless exists $normalized{$col};
        $normalized{$col} = $self->normalize_csv_value( $normalized{$col} );
        if ( $col_plan->{coerce} ) {
            $normalized{$col} = $self->dotify_and_coerce_number( $normalized{$col} );
        }
    }

    return \%normalized;
}

##########################################################################
# _validation_messages_for_record($plan, $record)
#
# Returns stringified validation messages for a record.
##########################################################################
sub _validation_messages_for_record {
    my ( $self, $plan, $record ) = @_;
    return $plan->{validator_sub}->($record);
}

##########################################################################
# _build_turbo_validator_sub($plan)
#
# Builds a lightweight schema-driven validator without JSON::Validator.
##########################################################################
sub _build_turbo_validator_sub {
    my ( $self, $plan ) = @_;
    return sub {
        my ($record) = @_;
        my @errors;

        my @extra =
          sort grep { !$plan->{allowed}{$_} } keys %{$record};
        push @errors, '/: Properties not allowed: ' . join( ', ', @extra ) . '.'
          if @extra;

        for my $required_col ( @{ $plan->{required} } ) {
            push @errors, "/$required_col: Missing property."
              unless exists $record->{$required_col};
        }

        for my $col_plan ( @{ $plan->{columns} } ) {
            my $name = $col_plan->{name};
            next unless exists $record->{$name};
            my $value = $record->{$name};

            if ( !defined $value ) {
                push @errors,
                  "/$name: Expected $col_plan->{type} - got null."
                  unless $col_plan->{nullable};
                next;
            }

            my $type_error = $self->_turbo_type_error( $col_plan, $value );
            if ($type_error) {
                push @errors, "/$name: $type_error";
                next;
            }

            if ( defined $col_plan->{max_length}
                && length($value) > $col_plan->{max_length} )
            {
                push @errors,
                  "/$name: String is too long: "
                  . length($value) . "/$col_plan->{max_length}.";
            }

            if ( defined $col_plan->{format} ) {
                if (   $col_plan->{format} eq 'date'
                    && !$self->_is_valid_date($value) )
                {
                    push @errors, "/$name: Does not match date format.";
                }
                elsif (   $col_plan->{format} eq 'date-time'
                       && !$self->_is_valid_date_time($value) )
                {
                    push @errors, "/$name: Does not match date-time format.";
                }
            }
        }

        @errors = sort @errors;
        return \@errors;
    };
}

##########################################################################
# _turbo_type_error($col_plan, $value)
#
# Returns an error string if the value does not match the compiled type.
##########################################################################
sub _turbo_type_error {
    my ( $self, $col_plan, $value ) = @_;
    my $expected = $col_plan->{type};

    return undef
      if $expected eq 'integer' && $self->_is_integer_value($value);
    return undef
      if $expected eq 'number' && $self->_is_number_value($value);
    return undef
      if $expected eq 'string' && !ref($value);

    my $expected_label =
      $col_plan->{nullable} ? "$expected/null" : $expected;
    return "Expected $expected_label - got " . $self->_turbo_value_type($value) . '.';
}

##########################################################################
# _turbo_value_type($value)
#
# Returns a short human-readable type name for error messages.
##########################################################################
sub _turbo_value_type {
    my ( $self, $value ) = @_;
    return 'null' unless defined $value;
    return 'array'  if ref($value) eq 'ARRAY';
    return 'object' if ref($value) eq 'HASH';
    return 'reference' if ref($value);
    return 'string' unless looks_like_number($value);
    return $self->_is_integer_value($value) ? 'integer' : 'number';
}

##########################################################################
# _is_integer_value($value)
##########################################################################
sub _is_integer_value {
    my ( $self, $value ) = @_;
    return 0 unless defined $value && !ref($value) && looks_like_number($value);
    return int($value) == $value ? 1 : 0;
}

##########################################################################
# _is_number_value($value)
##########################################################################
sub _is_number_value {
    my ( $self, $value ) = @_;
    return defined $value && !ref($value) && looks_like_number($value) ? 1 : 0;
}

##########################################################################
# _is_valid_date($value)
##########################################################################
sub _is_valid_date {
    my ( $self, $value ) = @_;
    return 0 unless defined $value && $value =~ /^(\d{4})-(\d{2})-(\d{2})$/;
    return $self->_valid_ymd( $1, $2, $3 );
}

##########################################################################
# _is_valid_date_time($value)
##########################################################################
sub _is_valid_date_time {
    my ( $self, $value ) = @_;
    return 0
      unless defined $value
      && $value =~ /^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})?$/;

    my ( $year, $month, $day, $hour, $minute, $second ) =
      ( $1, $2, $3, $4, $5, $6 );

    return 0 unless $self->_valid_ymd( $year, $month, $day );
    return 0 if $hour > 23 || $minute > 59 || $second > 59;
    return 1;
}

##########################################################################
# _valid_ymd($year, $month, $day)
##########################################################################
sub _valid_ymd {
    my ( $self, $year, $month, $day ) = @_;
    return 0 if $month < 1 || $month > 12;

    my @days_in_month = ( 31, 28 + $self->_is_leap_year($year), 31, 30, 31, 30,
        31, 31, 30, 31, 30, 31 );
    return 0 if $day < 1 || $day > $days_in_month[ $month - 1 ];
    return 1;
}

##########################################################################
# _is_leap_year($year)
##########################################################################
sub _is_leap_year {
    my ( $self, $year ) = @_;
    return 1 if $year % 400 == 0;
    return 0 if $year % 100 == 0;
    return $year % 4 == 0 ? 1 : 0;
}

##########################################################################
# normalize_csv_value($val)
#
# Converts CSV null markers to undef.
##########################################################################
sub normalize_csv_value {
    my ( $self, $val ) = @_;
    return undef unless defined $val;
    return undef if $val eq '\\N';
    return $val;
}

##########################################################################
# dotify_and_coerce_number($val)
#
# Converts a CSV string value to a number if it looks numeric.
# Returns undef if the value is empty or "\N".
##########################################################################
sub dotify_and_coerce_number {
    my ( $self, $val ) = @_;
    return undef unless ( defined $val && $val ne '' && $val ne '\\N' );
    ( my $tr_val = $val ) =~ tr/,/./;
    return looks_like_number($tr_val) ? 0 + $tr_val : $val;
}

=head1 AUTHOR

Written by Manuel Rueda, PhD. Info about CNAG can be found at L<https://www.cnag.eu>.

=head1 LICENSE

This module is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
