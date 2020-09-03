package Mnet::Report::Table;

=head1 NAME

Mnet::Report::Table - Output rows of report data

=head1 SYNOPSIS

    # create an example new table object, with csv file output
    my $table = Mnet::Report::Table->new({
        output  => "csv:file.csv",
        columns => [
            device  => "string",
            time    => "time",
            data    => "Integer",
            error   => "error"
        ],
    });

    # output error row if script aborts with unreported errors
    $table->row_on_error({ device => $device });

    # output a normal report row, call again to output more
    $table->row({ device => $device, data => $data });

=head1 DESCRIPTION

Mnet::Report::Table can be used to create new report table objects, with a row
method call to add data, a row_on_error method to ensure errors always appear,
with various output options including csv, json, sql, and perl L<Data::Dumper>
formats.

=head1 METHODS

Mnet::Report::Table implements the methods listed below.

=cut

# required modules
use warnings;
use strict;
use parent qw( Mnet::Log::Conditional );
use Carp;
use Mnet::Dump;
use Mnet::Log::Conditional qw( DEBUG INFO WARN FATAL NOTICE );
use Mnet::Opts::Cli::Cache;

# init autoflush, global variables, and sig handlers
#   autoflush is set so multi-process syswrite lines don't clobber each other
#   @selves tracks report objects until deferred/row_on_error output end block
#   $error and sig handlers used to track first error, if Mnet::Log not loaded
BEGIN {
    $| = 1;
    my @selves = ();
    my $error = undef;
    if (not $INC{'Mnet/Log.pm'}) {
        $SIG{__DIE__} = sub {
            if (not defined $Mnet::Report::Table::error) {
                chomp($Mnet::Report::Table::error = "@_");
            }
            die @_;
        };
        $SIG{__WARN__} = sub {
            if (not defined $Mnet::Report::Table::error) {
                chomp($Mnet::Report::Table::error = "@_");
            }
            warn @_
        };
    }
}



sub new {

=head2 new

    $table = Mnet::Report::Table->new(\%opts)

A new Mnet::Report::Table object can be created with the options showm in
the example below:

    my $table = Mnet::Report::Table->new({
        columns => [                # ordered column names and types
            device  => "string",    #   strips eol chars in csv output
            count   => "integer",   #   +/- integer numbers
            error   => "error",     #   first error, see row_on_error()
            time    => "time",      #   time as yyyy/mm/dd hh:mm:ss
            unix    => "epoch",     #   unix time, see perldoc -f time
        ],
        output  => "csv:$file",     # see this module's OUTPUT section
        append  => $boolean,        # set to append output to file
        log_id  => $string,         # see perldoc Mnet::Log new method
        nodefer => $boolean,        # set to output rows immediately
    });

The columns option is required, and is an array reference containing an ordered
list of hashed column names of type string, integer, error, time, or epoch.

Columns of type string and integer are set by the user for new rows using the
row method in this module. Columns of type error, time, and epoch are set
automatically for each row of output.

The output option should be used to specify an output format and filename, as
in the example above. Refer to the OUTPUT section below for more information.

The append option opens the output file for appending and doesn't write a
heading row, Otherwise the default is to overwrite the output file when the
new table object is created.

The nodefer option can be used so that report data rows are output immediately
when the row method is called. Otherwise row data is output when the script
exits. This can affect the reporting of errors, refer to the row_on_error
method below for more information.

Note that new Mnet::Report::Table objects should be created before forking
batch children if the L<Mnet::Batch> module is being used.

Errors are issued for invalid options.

=cut

    # read input class and options hash ref merged with cli options
    my $class = shift // croak("missing class arg");
    my $opts = Mnet::Opts::Cli::Cache::get(shift // {});

    # bless new object created from input opts hash
    #   this allows log_id and other Mnet::Log options to be in effect
    #   the following keys start with underscore and are used internally:
    #       _column_error => set if error column is present, for _row_on_error
    #       _column_order => array ref listing column names in sort order
    #       _column_types => hash ref keyed by column names with value as type
    #       _output_rows  => list of row hashes, output t end unless nodefer
    #       _output_fh    => filehandle for row outputs, opened from new method
    #       _row_on_error => set with row hash to ensure output if any errors
    #   in addition refer to perldoc for input opts and Mnet::Log0->new opts
    my $self = $opts;
    bless $self, $class;
    push @{$Mnet::Report::Table::selves}, $self;
    $self->debug("new starting");

    # abort if we were called before batch fork if Mnet::Batch was loaded
    #   avoids problems with first row method call from new sub to init output
    #   for example: _output_csv batch parent must create file and heading row
    #       we don't want every batch child creating duplicate heading rows
    croak("new Mnet::Report::Table must be created before Mnet::Batch::fork")
        if $INC{"Mnet/Batch.pm"} and Mnet::Batch::fork_called();

    # abort if opts columns array ref is not set
    #   create _column_types hash ref and _column_order array ref in new object
    #   croak for invalid column types and error type if Mnet::Log not loaded
    croak("missing opts input columns key") if not $opts->{columns};
    croak("invalid opts input columns key") if ref $opts->{columns} ne "ARRAY";
    croak("missing opts input column data") if not scalar(@{$opts->{columns}});
    $self->{_column_types} = {};
    $self->{_column_order} = [];
    while (@{$opts->{columns}}) {
        my $column = shift @{$opts->{columns}} // croak("missing column name");
        my $type = shift @{$opts->{columns}} // croak("missing column type");
        croak("invalid column name $column") if $column =~ /["\r\n]/;
        $self->debug("new column = $column ($type)");
        $self->{_column_types}->{$column} = $type;
        push @{$self->{_column_order}}, $column;
        $self->{_column_error} = 1 if $type eq "error";
        if ($type !~ /^(epoch|error|integer|string|time)$/) {
            croak("column type $type is invalid");
        }
    }

    # debug calls to display output option set for this object
    $self->debug("new output = ".Mnet::Dump::line($self->{output}));

    # call _output method with no row arg to init output
    #   allows batch parent or non-batch proc to open file and output headings
    $self->debug("new init _output call");
    $self->_output;

    # finished new method, return Mnet::Report::Table object
    $self->debug("new finished, returning $self");
    return $self;
}



sub row {

=head2 row

    $table->row(\%data)

This method will add a row of specified data to the current report table
object, as in the following example:

    $table->row({
        device  => $string,
        sample  => $integer,
    })

Note that an error is issued if any keys in the data were not defined as string
or integer columns when the new method was used to create the current object.

=cut

    # read input object
    my $self = shift // croak("missing self arg");
    my $data = shift // croak("missing data arg");

    # init hash ref to hold output row data
    my $row = $self->_row_data($data);

    # output or store row data
    if ($self->{nodefer}) {
        $self->_output($row);
    } else {
        push @{$self->{_output_rows}}, $row;
    }

    # finished row method
    return;
}



sub _row_data {

# \%row = $self->_row_data(\%data)
# purpose: set keys in output row hash form input data hash, with error refs

    # read input object
    my $self = shift // die "missing self arg";
    my $data = shift // die "missing data arg";
    $self->debug("_row_data starting");

    # init hash ref to hold output row data
    my $row = {};

    # loop through all columns in the current object
    foreach my $column (sort keys %{$self->{_column_types}}) {
        my $type = $self->{_column_types}->{$column};
        my $value = $data->{$column};

        # set epoch column to unix time, refer to perldoc -f time
        #   on most systems is non-leap seconds since 00:00:00 jan 1, 1970 utc
        #   this is simplest way to agnostically store time for various uses
        if ($type eq "epoch") {
            $row->{$column} = time;
            $row->{$column} = Mnet::Test::time() if $INC{'Mnet/Test.pm'};
            croak("invalid time column $column") if exists $data->{$column};

        # set error column type as reference to global first error variable
        #   update global error ref, so all rows show errors from end block
        #   croak if the user supplied data for an error column
        } elsif ($type eq "error") {
            $row->{$column} = \$Mnet::Report::Table::error;
            croak("invalid error column $column") if exists $data->{$column};

        # set integer column type, croak on bad integer
        } elsif ($type eq "integer") {
            if (defined $value) {
                $value =~ s/(^\s+|\s+$)//;
                if ($value =~ /^(\+|\-)?\d+$/) {
                    $row->{$column} = $value;
                } else {
                    $value = Mnet::Dump::line($value);
                    croak("invalid integer column $column value $value");
                }
            }

        # set string column type
        } elsif ($type eq "string") {
            $row->{$column} = $value;

        # set time column types to yyyy/mm/dd hh:mm:ss
        } elsif ($type eq "time") {
            my $time = time;
            $time = Mnet::Test::time() if $INC{'Mnet/Test.pm'};
            my ($sec, $min, $hour, $date, $month, $year) = localtime($time);
            $month++; $year += 1900;
            my @fields = ($year, $month, $date, $hour, $min, $sec);
            $row->{$column} = sprintf("%04s/%02s/%02s %02s:%02s:%02s", @fields);
            croak("invalid time column $column") if exists $data->{$column};

        # abort on unknown column type
        } else {
            die "invalid column type $type";
        }

    # continue loop through columns in the currect object
    }

    # croak if any input data columns were not declared for current object
    foreach my $column (sort keys %$data) {
        next if exists $self->{_column_types}->{$column};
        croak("column $column was not defined for $self->{output}");
    }

    # finished row method, return row hash ref
    $self->debug("_row_data finished");
    return $row;
}



sub row_on_error {

=head2 row_on_error

    $table->row_on_error(\%data)

This method can be used to ensure that an Mnet::Report::Table object with an
error column outputs an error row when the script exits if no prior output row
reflected that there was an error, as in the example below:

    # declare report object as a global
    use Mnet::Report::Table;
    my $table = Mnet::Report::Table->new({
        output  => "json:file.json",
        columns => [
            input => "text",
            error => "error",
            ttl   => "integer"
        ],
    });

    # call Mnet::Batch::fork here, if using Mnet::Batch module

    # output error row at exit if there was an unreported error
    $table->row_on_error({ input => "error" });

    # output first row, no error, always present in output
    $table->row({ input => "first" });

    # lots of code could go here, with possibility of errors...
    die if int(rand) > .5;

    # output second row, no error, present if die did not occur
    $table->row({ input => "second" });

    # row_on_error output at exit for unpreported errors
    exit;

This ensures that a script does not die after the row_on_error call without
any indication of an error in the report output.

The default is to output all report data rows when the script exits. At this
time all error columns for all rows will be set with the first of any prior
script errors. In this case row_on_error will output an error row if there
was an error and the row method was never called.

If the nodefer option was set when a new Mnet::Report::Table object was created
then row data is output immediately each time the row method is called, with
the error column set only if there was an error before the row method call. Any
errors afterward could go unreported. In this case row_on_error will output an
extra row at script exit if there was an error after the last row method call,
or the row method was never called.

=cut

    # read inputs, store row_on_error row data as object _row_on_error
    #   this is output from module end block if there were unreported errors
    my $self = shift // croak("missing self arg");
    my $data = shift // croak("missing data arg");
    croak("row_on_error requires error column") if not $self->{_column_error};
    $self->{_row_on_error} = $self->_row_data($data);
    return;
}



=head1 OUTPUT OPTIONS

When a new Mnet::Report::Table object is created the output option can be set
to any of the output format types listed in the documentation sections below.

If the L<Mnet::Log> module is loaded report rows are always logged with the
info method.

Note the L<Mnet::Test> module --test command line option silently overrides all
other report output options, outputting report data using the L<Mnet::Log>
module if loaded or sending report output to stdout in L<Data::Dumper> format,
for consistant test results.

Output files are opened when an Mnet::Report object is created, with a heading
row if necessary. Refer to the new method in this documentation for information
on the append and nodefer options that control how the output file is opened
and when row data is written.

Output options below can use /dev/stdout as the output file, which works nicely
with the L<Mnet::Log> --silent option used with the L<Mnet::Batch> --batch
option, allowing report output from all concurrently executing batch children
to be easily piped or redirected in aggregate as necessary. However be aware
thet /dev/stdout report output is not captured by the L<Mnet::Tee> module.

Note the L<Mnet::Test> module --test command line option silently overrides
all other report output options, outputting report data using the L<Mnet::Log>
module if loaded or sending report output to stdout in L<Data::Dumper> format,
for consistant test results.

=cut

sub _output {

# $self->_output(\$row)
# purpose: called from new to open file and output headings, called from row
# \%row: row data, or undef for init call from new method w/Mnet::Batch loaded
# $self->{output} object property is parsed to determin output type
# $self->{append} clear by default, output overwrites file, heading rows output
# $self->{append} set will append to output file, headng rows are suppressed

    # read input object and row data hash reference
    my $self = shift // die "missing self arg";
    my $row = shift;
    $self->debug("_output starting");

    # init file parsed from output option and row output line
    my ($file, $output) = (undef, undef);

    # handle --test output, skipped for undef heading row
    my $cli = Mnet::Opts::Cli::Cache::get({});
    if ($cli->{test}) {
        if (defined $row) {
            $self->debug("_output calling _output_test");
            $output = $self->_output_test($row);
        }

    # handle non-test output
    } else {

        # log report row output, skipped for undef heading row
        if (defined $row) {
            $self->debug("_output calling _output_log");
            $output = $self->_output_log($row);
        }

        # note that no output option was set
        if (not defined $self->{output}) {
            $self->debug("_output skipped, output option not set");

        # handle csv output, refer to sub _output_csv
        } elsif ($self->{output} =~ /^csv(:(.+))?$/) {
            $self->debug("_output calling _output_csv");
            $output = $self->_output_csv($row);
            $file = $2 // "/dev/stdout";

        # handle dump output, call with var name arg, refer to sub _output_dump
        } elsif ($self->{output} =~ /^dump(:([a-zA-Z]\w*)(:(.+))?)?$/) {
            $self->debug("_output calling _output_dump");
            $output = $self->_output_dump($row, $2 // "dump");
            $file = $4 // "/dev/stdout";

        # handle json output, call with var name arg, refer to sub _output_json
        } elsif ($self->{output} =~ /^json(:([a-zA-Z]\w*)(:(.+))?)?$/) {
            $self->debug("_output calling _output_json");
            $output = $self->_output_json($row, $2 // "json");
            $file = $4 // "/dev/stdout";

        # handle sql output, call with table name arg, refer to sub _output_sql
        } elsif ($self->{output} =~ /^sql(:("([^"]+)"|(\w+))(:(.+))?)?$/) {
            $self->debug("_output calling _output_sql");
            $output = $self->_output_sql($row, $3 // $4 // "table");
            $file = $6 // "/dev/stdout";

        # error on invalid output option
        } else {
            $self->fatal("invalid output option $self->{output}");
        }

    # finished handling non-test output
    }

    # open output filehandle, honor object append option
    #   open output file for first heading row call so we know we can open it
    #       so we don't continue running script when report file won't work
    if ($file and not $self->{_output_fh}) {
        my $mode = ">";
        $mode = ">>" if $self->{append};
        $self->debug("_output opening ${mode}$file");
        open($self->{_output_fh}, $mode, $file)
            or $self->fatal("unable to open ${mode}$file, $!");
    }

    # output row
    #   note that for heading row the input row value is undefined
    #   normal rows are always output, heading row output only if append not set
    if ($output) {
        if ($row or not $self->{append}) {
            syswrite $self->{_output_fh}, "$output\n";
        }
    }

    # finished _output method
    $self->debug("_output finished");
    return;
}



sub _output_csv {

# $output = $self->_output_csv($row)
# purpose: return output row data in csv format, or heading row
# \%row: row data, undef for heading row which returns heading row
# $output: single line of row output, or heading row if input row was undef

=head2 output csv

    csv
    csv:$file

The csv output option can be used to output a csv file, /dev/stdout by default.

All csv outputs are doule quoted. Double quotes in the outut data are escaped
with an extra double quote.

All end of line carraige return and linefeed characters are replaced with
spaces in the csv output. Multiline csv output data is not supported.

The output csv file will be created with a heading row when the new method is
called unless the append option was set when the new method was called.

Refer to the OUTPUT OPTIONS section of this module for more info.

=cut

    # read input object and row data hash reference
    my $self = shift // die "missing self arg";
    my $row = shift;
    $self->debug("_output_csv starting");

    # init csv row output sting, will be heading row if input row is undef
    my $output = undef;

    # declare sub to quote and escape csv value
    #   eol chars removed so concurrent batch outputs klines don't intermix
    #   double quotes are escaped with an extra double quote
    #   value is prefixed and suffixed with double quotes
    sub _output_csv_escaped {
        my $value = shift // "";
        $value =~ s/(\r|\n)/ /g;
        $value =~ s/"/""/g;
        $value = '"'.$value.'"';
        return $value;
    }

    # determine if headings row is needed
    #   headings are needed if current script is not a batch script
    #   headings are needed for parent process of batch executions
    #   headings are not needed if the append option is set for table
    my $headings_needed = 0;
    if (not $INC{"Mnet/Batch.pm"} or not $MNet::Batch::fork_called) {
        if (not $self->{append}) {
            $headings_needed = 1 if not defined $row;
        }
    }

    # output heading row, if needed
    if ($headings_needed) {
        $self->debug("_output_csv generating heading row");
        my @headings = ();
        foreach my $column (@{$self->{_column_order}}) {
            push @headings, _output_csv_escaped($column);
        }
        $output = join(",", @headings);
    }

    # output data row, if defined
    if (defined $row) {
        my @data = ();
        foreach my $column (@{$self->{_column_order}}) {
            my $column_data = $row->{$column};
            $column_data = ${$row->{$column}} if ref $row->{$column};
            push @data, _output_csv_escaped($column_data);
        }
        $output = join(",", @data);
    }

    # finished _output_csv method, return output line
    $self->debug("_output_csv finished");
    return $output;
}



sub _output_dump {

# $output = $self->_output_dump($row, $var)
# purpose: return output row data in perl Data::Dumper format
# \%row: row data, undef for heading row which returns undef (no heading row)
# $var: var name parsed from object output option used in Data::Dumper output
# $output: single line of row output, or undef if input row was undef

=head2 output dump

    dump
    dump $var
    dump:$var:$file

The dump output option writes one row per line in L<Data::Dumper> format
prefixed by the specified var name, defaulting to 'dump' and /dev/stdout.

This dump output can be read back into a perl script as follows:

    use Data::Dumper;
    while (<STDIN>) {
        my ($line, $var) = ($_, undef);
        my $table = $1 if $line =~ s/^\$(\S+)/\$var/ or die;
        eval "$line";
        print Dumper($var);
    }

Refer to the OUTPUT OPTIONS section of this module for more info.

=cut

    # read input object and row data hash reference
    my $self = shift // die "missing self arg";
    my $row = shift // return;
    my $var = shift // die "missing var arg";
    $self->debug("_output_dump starting");

    # dereference error columns
    foreach my $column (keys %$row) {
        $row->{$column} = ${$row->{$column}} if ref $row->{$column};
    }

    # create output row string, singl line dump
    my $output = "\$$var = ".Mnet::Dump::line($row).";";

    # finished _output_dump method, return output line
    $self->debug("_output_dump finished");
    return $output;
}



sub _output_json {

# $output = $self->_output_json($row, $var)
# purpose: return output row data in json format
# \%row: row data, undef for heading row which returns undef (no heading row)
# $var: var name parsed from object output option used in json output
# $output: single line of row output, or undef if input row was undef

=head2 output json

    json
    json:$var
    json:$var:$file

The json output option writes one row per line in json format prefixed by the
specified var name, defaulting to 'json' and /dev/stdout. This requires that
the L<JSON> module is available.

The output json looks something like the example below:

    var = {"device":"test","error":null};

This json output can be read back into a perl script as follows:

    use JSON;
    use Data::Dumper;
    while (<STDIN>) {
        my ($line, $var) = ($_, undef);
        my $table = $1 if $line =~ s/^(\S+) = // or die;
        $var = decode_json($line);
        print Dumper($var);
    }

Refer to the OUTPUT OPTIONS section of this module for more info.

=cut

    # read input object and row data hash reference
    my $self = shift // die "missing self arg";
    my $row = shift // return;
    my $var = shift // die "missing var arg";
    $self->debug("_output_json starting");

    # abort with an error if JSON module is not available
    croak("Mnet::Report::Table json requires perl JSON module is installed")
        if not $INC{'JSON.pm'} and not eval("require JSON; 1");

    # dereference error columns
    foreach my $column (keys %$row) {
        $row->{$column} = ${$row->{$column}} if ref $row->{$column};
    }

    # create output data row
    #   json is sorted so that test output doesn't vary
    #   this will be undefined if called from new method
    my $output = "$var = ".JSON->new->canonical->encode($row).";";

    # finished _output_json method, return output line
    $self->debug("_output_json finished");
    return $output;
}



sub _output_log {

# $self->_output_log
# purpose: output report row as info log entries

    # read input object and row data hash reference
    my $self = shift // die "missing self arg";
    my $row = shift;
    $self->debug("_output_log starting");

    # dereference error columns
    foreach my $column (keys %$row) {
        $row->{$column} = ${$row->{$column}} if ref $row->{$column};
    }

    # determine width of widest column, for formatting
    my $width = 0;
    foreach my $column (@{$self->{_column_order}}) {
        $width = length($column) if length($column) > $width;
    }

    # output data row to Mnet::Log
    #   row will be undefined if called from new method
    if (defined $row) {
        my $prefix = "row";
        $self->info("$prefix {");
        foreach my $column (@{$self->{_column_order}}) {
            my $value = Mnet::Dump::line($row->{$column});
            $self->info(sprintf("$prefix    %-${width}s => $value", $column));
        }
        $self->info("$prefix }");
    }

    # finished _output_log method
    $self->debug("_output_log finished");
    return;
}



sub _output_sql {

# $output = $self->_output_sql($row, $var)
# purpose: return output row data in sql format, as an insert statement
# \%row: row data, undef for heading row which returns undef (no heading row)
# $table: table name parsed from object output option used in sql output
# $output: single line of row output, or undef if input row was undef

=head2 output sql

    sql
    sql:$table
    sql:"$table"
    sql:$table:$file
    sql:"$table":$file

The sql output option writes one row per line as sql insert statements using
the specified table name, double-quoting non-word table names, defaulting to
"table" and /dev/stdout, in the following format:

    INSERT INTO <table> (<column>, ...) VALUES (<value>, ...);

Table and column names are double quoted, and values are single quoted. Single
quotes in values are escaped with an extra single quote character, LF and CR
characters are escaped as '+CHAR(10)+' and '+CHAR(13)+' respectively.

Refer to the OUTPUT OPTIONS section of this module for more info.

=cut

    # read input object and row data hash reference
    my $self = shift // die "missing self arg";
    my $row = shift // return;
    my $table = shift // die "missing table arg";
    $self->debug("_output_sql starting");

    # init sql row output sting, will be heading row if input row is undef
    my $output = undef;

    # dereference error columns
    foreach my $column (keys %$row) {
        $row->{$column} = ${$row->{$column}} if ref $row->{$column};
    }

    # output data row
    #   this will be undefined if called from new method
    #   double quote column names to handle unusual column names
    #   escape multiline outputs which concurrent batch procs can clobber
    if (defined $row) {
        my @sql_columns = ();
        my @sql_values = ();
        foreach my $column (@{$self->{_column_order}}) {
            push @sql_columns, '"' . $column . '"';
            my $value = $row->{$column} // "";
            $value =~ s/'/''/g;
            $value =~ s/\r/'+CHAR(10)+'/g;
            $value =~ s/\n/'+CHAR(13)+'/g;
            push @sql_values, "'" . $value . "'";
        }
        $output = "INSERT INTO \"$table\" ";
        $output .= "(" . join(",", @sql_columns) . ") ";
        $output .= "VALUES (" . join(",", @sql_values) . ");";
    }

    # finished _output_sql method, return output line
    $self->debug("_output_sql finished");
    return $output;
}



sub _output_test {

# $self->_output_test(\%row)
# purpose: output test row data to stdout in Data::Dumper for when --test set
# \%row: row data, or undef for init call from new method w/Mnet::Batch loaded

    # read input object and row data hash reference
    my $self = shift // die "missing self arg";
    my $row = shift;
    $self->debug("_output_test starting");

    # dereference error columns
    foreach my $column (keys %$row) {
        $row->{$column} = ${$row->{$column}} if ref $row->{$column};
    }

    # determine width of widest column, for formatting
    my $width = 0;
    foreach my $column (@{$self->{_column_order}}) {
        $width = length($column) if length($column) > $width;
    }

    # output data row to Mnet::Log
    #   row will be undefined if called from new method
    if (defined $row and $INC{"Mnet/Log.pm"}) {
        $self->debug("_output_test calling _output_log");
        $self->_output_log($row);

    # otherwise output data row to standard output
    #   row will be undefined if called from new method
    } elsif (defined $row) {
        syswrite STDOUT, "\nMnet::Report::Table row = {\n";
        foreach my $column (@{$self->{_column_order}}) {
            my $value = Mnet::Dump::line($row->{$column});
            syswrite STDOUT, sprintf("  %-${width}s => $value\n", $column);
        }
        syswrite STDOUT, "}\n";
    }

    # finished _output_test method
    $self->debug("_output_test finished");
    return;
}



# ensure that row data and error for all report objects has been output
#   update global error var if Mnet::Log is loaded, ref used for error columns
#   output rows for report objects that stored rows for end (nodefer not set)
#   output row_on_error if there were unreported errors or nodefer was set
sub END {
    $Mnet::Report::Table::error = Mnet::Log::error() if $INC{'Mnet/Log.pm'};
    foreach my $self (@{$Mnet::Report::Table::selves}) {
        $self->_output($_) foreach @{$self->{_output_rows}};
        if ($self->{_row_on_error} and $Mnet::Report::Table::error) {
            if (not $self->{_row_on_error} or $self->{nodefer}) {
                $self->_output($self->{_row_on_error});
            }
        }
    }
}



=head1 TESTING

Mnet::Report::Table supports the L<Mnet::Test> module test, record, and replay
functionality, tracking report data so it can be included in test results.

=head1 SEE ALSO

L<Data::Dumper>

L<JSON>

L<Mnet>

L<Mnet::Batch>

L<Mnet::Log>

L<Mnet::Test>

=cut

# normal package return
1;

