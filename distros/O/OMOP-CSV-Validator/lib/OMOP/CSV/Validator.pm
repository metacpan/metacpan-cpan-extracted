package OMOP::CSV::Validator;

use strict;
use warnings;
use utf8;
use JSON::XS;
use JSON::Validator;
use Text::CSV_XS;
use Scalar::Util qw(looks_like_number);
use Path::Tiny;

our $VERSION = '0.01';

=head1 NAME

OMOP::CSV::Validator - Validates OMOP CDM CSV files against their expected data types

=head1 SYNOPSIS

    use OMOP::CSV::Validator;

    my $validator = OMOP::CSV::Validator->new();

    # Load schemas from DDL
    my $schemas = $validator->load_schemas_from_ddl($ddl_text);

    # Retrieve specific table schema for a CSV file
    my $schema  = $validator->get_schema_from_csv_filename($csv_file, $schemas);

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
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    return $self;
}

##########################################################################
# load_schemas_from_ddl($ddl_text)
#
# Parses all CREATE TABLE definitions from a PostgreSQL OMOP DDL
# and returns a hashref of JSON schemas keyed by table name (lowercase).
##########################################################################
sub load_schemas_from_ddl {
    my ($self, $ddl_text) = @_;
    return $self->_ddl_to_json_schemas($ddl_text);
}

##########################################################################
# _ddl_to_json_schemas($ddl_text) - private
#
# Internal subroutine that iterates over all CREATE TABLE blocks.
##########################################################################
sub _ddl_to_json_schemas {
    my ($self, $ddl_text) = @_;
    my %schemas;
    while (
        $ddl_text =~ /
        CREATE\s+TABLE\s+\S+\.(\w+)\s*\(   # capture table name (after schema qualifier)
        (.*?)                             # capture everything inside parentheses
        \)\s*;                           # until the closing parenthesis and semicolon
    /gisx
      )
    {
        my ( $table, $cols_block ) = ( lc $1, $2 );
        $schemas{$table} = $self->_build_schema( $table, $cols_block );
    }
    return \%schemas;
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
    for my $line ( grep /\S/, split /\n/, $cols_block ) {
        $line         =~ s/^\s+|\s+$//g;
        $line         =~ s/,$//;
        next if $line =~ /^--/;            # skip comment lines
                                           # Greedy match for the type
        if ( $line =~
            /^(\w+)\s+([A-Za-z]+)(?:\(\d+(?:,\d+)?\))?(?:\s+(NOT NULL))?/i )
        {
            my ( $col, $type, $notnull ) = ( lc $1, lc $2, defined $3 );
            my $prop = {};
            if ( $type =~ /int/ ) {
                $prop->{type} = 'integer';
            }
            elsif ( $type =~ /numeric|real|double/ ) {
                $prop->{type} = 'number';
            }
            elsif ( $type eq 'date' ) {
                $prop->{type}   = 'string';
                $prop->{format} = 'date';
            }
            elsif ( $type =~ /timestamp/ ) {
                $prop->{type}   = 'string';
                $prop->{format} = 'date-time';
            }
            else {
                $prop->{type} = 'string';
            }
            $schema->{properties}{$col} = $prop;
            push @{ $schema->{required} }, $col if $notnull;
        }
    }
    return $schema;
}

##########################################################################
# get_schema_from_csv_filename($csv_filename, $schemas)
#
# Derives the table name from the CSV file's basename (e.g. PERSON.csv → person)
# and returns the corresponding schema from the provided hashref.
##########################################################################
sub get_schema_from_csv_filename {
    my ( $self, $csv_filename, $schemas ) = @_;
    ( my $table = lc $csv_filename ) =~ s{^.*/}{};      # remove any path
    $table =~ s/\.csv$//i;                              # remove .csv extension
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
    my ( $self, $csv_file, $schema, $sep ) = @_;
    $sep //= ',';

    my $csv_handle = path($csv_file)->openr_utf8;
    my $csv =
      Text::CSV_XS->new( { binary => 1, sep_char => $sep, auto_diag => 1 } )
      or die "Cannot use CSV: " . Text::CSV_XS->error_diag();

    my $header  = $csv->getline($csv_handle);
    $csv->column_names(@$header);

    my $records = $csv->getline_hr_all($csv_handle);
    $csv_handle->close;

    my @errors;
    my $validator = JSON::Validator->new;
    $validator->schema($schema);

    for my $i ( 0 .. $#$records ) {
        my $record = $records->[$i];

        # Coerce numeric fields according to the schema.
        for my $col ( keys %{ $schema->{properties} } ) {
            if ( exists $record->{$col} ) {
                my $prop = $schema->{properties}->{$col};
                if ( $prop->{type} eq 'integer' or $prop->{type} eq 'number' ) {
                    $record->{$col} = $self->dotify_and_coerce_number( $record->{$col} );
                }
            }
        }

        # Validate
        my $errs = [ $validator->validate($record) ];
        if (@$errs) {
            # row number excludes header → row index + 1
            push @errors, { row => $i + 1, errors => $errs };
        }
    }
    return \@errors;
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
