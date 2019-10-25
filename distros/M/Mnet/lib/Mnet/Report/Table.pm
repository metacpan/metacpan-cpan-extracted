package Mnet::Report::Table;

=head1 NAME

Mnet::Report::Table - Output rows of report data

=head1 SYNOPSIS

    my $table = Mnet::Report::Table->new({
        table   => "example",
        output  => "csv:file.csv",
        columns => [ device => "string", error => "error" ],
    });

    $table->row({ device => $device });

=head1 DESCRIPTION

Mnet::Report::table can be used to create new report table objects, add rows
to those tables, with output of those rows at script exit in various formats.

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

# set autoflush and sig handlers to capture first error
#   autoflush is set so multi-process syswrite lines don't clobber each other
#   die and warn sig handlers here are used only if Mnet::Log is not loaded
#   row_on_error array has objects that will be processed in END block
BEGIN {
    $| = 1;
    my $error = undef;
    my @row_on_error = ();
    if (not $INC{'Mnet/Log.pm'}) {
        $SIG{__DIE__} = sub {
            if (not defined $Mnet::Report::Table::error) {
                $Mnet::Report::Table::error = "@_";
            }
            die @_;
        };
        $SIG{__WARN__} = sub {
            if (not defined $Mnet::Report::Table::error) {
                $Mnet::Report::Table::error = "@_";
            }
            warn @_
        };
    }
}



sub new {

=head2 new

    $table = Mnet::Report::Table->new(\%opts)

A new Mnet::Report::Table object can be created for each required table, as
in the following example:

    my $table = Mnet::Report::Table->new({
        columns => [                # ordered column names and types
            device  => "string",    #   eol chars stripped for csv output
            count   => "integer",   #   +/- integer numbers
            error   => "error",     #   first error, refer to row_on_error
            time    => "time",      #   row time as yyyy/mm/dd hh:mm:ss
        ],
        log_id  => $optional,       # refer to perldoc Mnet::Log new method
        output  => "csv:$file",     # refer to this module's OUTPUT section
    });

Errors are issued if invalid options are specified.

Refer to the documentation for specific output options below for more info.

=cut

    # read input class and options hash ref merged with cli options
    my $class = shift // croak("missing class arg");
    my $opts = Mnet::Opts::Cli::Cache::get(shift // {});

    # bless new object created from input opts hash
    #   this allows log_id and other Mnet::Log options to be in effect
    #   the following keys start with underscore and are used internally:
    #       _column_order => array ref listing column names in sort order
    #       _column_types => hash ref keyed by column names with value as type
    #       _row_on_error => row sets "row output" for row_on_error method
    #   in addition refer to perldoc for input opts and Mnet::Log0->new opts
    my $self = $opts;
    bless $self, $class;
    $self->debug("new starting");

    # abort if we were called before batch fork if Mnet::Batch was loaded
    #   avoids problems with first row methdod call from new sub to init output
    #   for example: _output_csv batch parent must create file and heading row
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
        if ($type !~ /^(error|integer|string|time)$/) {
            croak("column type $type is invalid");
        }
    }

    # debug calls to display output option set for this object
    $self->debug("new output = ".Mnet::Dump::line($self->{output}));

    # call _output method with no row arg to init output
    #   this allows parent or non-batch proc to output heading row, etc.
    $self->debug("new init _output call");
    $self->_output;

    # finished new method, return Mnet::Report::Table object
    $self->debug("new finished, returning $self");
    return $self;
}



sub row_on_error {

=head2 row_on_error

    $table->row_on_error(\%data)

This method can be used to ensure that an Mnet::Report::Table object with an
error column outputs an error row when the script exits if no normal row was
output for that object, as in the example below:

    # declare report object as a global
    use Mnet::Report::Table;
    my $table = Mnet::Report::Table->new({
        table   => "example",
        output  => "json:file.json",
        columns => [
            input => "text",
            error => "error",
            ttl   => "integer"
        ],
    });

    # we'll output one row per input line
    $line = Mnet::Batch::fork({ batch => "/dev/stdin" });

    # outputs error row at exit if no normal row methods were output
    $table->row_on_error({ input => $input });

    # lots of code could go here, with possibility of errors...
    my $ttl = int(rand*100);
    die if $ttl > 50;

    # output normal row, assuming no errors
    $table->row({ input => $input, ttl = $ttl });

This ensures that a script does not die after the row_on_error call without
any indication in the report output.

Multiple row_on_error calls can be used to output multiple rows at script exit
if there were any errors.

=cut

    # read inputs and add object and row data to row_on_error global array
    my $self = shift // croak("missing self arg");
    my $data = shift // croak("missing self arg");
    my $row_on_error = { self => $self, data => $data };
    push @Mnet::Report::Table::row_on_error, $row_on_error;
    return;
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

Note that an error is issued if any input columns are not defined for the
current table object or invalid column data is specified.

=cut

    # read input object
    my $self = shift // croak("missing self arg");
    my $data = shift // croak("missing data arg");
    $self->debug("row starting");

    # init hash ref to hold output row data
    my $row = {};

    # loop through all columns in the current object
    foreach my $column (sort keys %{$self->{_column_types}}) {
        my $type = $self->{_column_types}->{$column};
        my $value = $data->{$column};

        # set error column type to current Mnet::Log::Error value
        #   use Mnet::Log::error if that module is loaded
        if ($type eq "error") {
            $row->{$column} = $Mnet::Report::Table::error;
            $row->{$column} = Mnet::Log::error() if $INC{'Mnet/Log.pm'};
            chomp($row->{$column}) if defined $row->{$column};
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

    # output row data
    $self->debug("row calling _outout method");
    $self->_output($row);

    # set _row_on_error to indicate that we output a row
    $self->{_row_on_error} = "row output";

    # finished row method
    $self->debug("row finished");
    return;
}



=head1 OUTPUT OPTIONS

When a new Mnet::Report::Table object is created the output option can be set
to any of the output format types listed in the documentation sections below,
or left undefined.

If the L<Mnet::Log> module is loaded report rows are always logged with the
info method.

Note that the L<Mnet::Test> module --test command line option silently
overrides all other report output options, outputting report data using
the L<Mnet::Log> module if loaded or sending report output to stdout in
L<Data::Dumper> format.

Output options below can use /dev/stdout as the output file, which works nicely
with the L<Mnet::Log> --silent option used with the L<Mnet::Batch> --batch
option, allowing report output from all concurrently exeecuting batch children
to be easily piped or redirected in aggregate as necessary.

Note that /dev/stdout report output is not captured by the Mnet::Tee module,
and might be missed if the L<Mnet::Log> module is not being used. In this case
you should output report data to stdout yourself.

=cut

sub _output {

# $self->_output($row)
# purpose: call the correct output subroutine
# \%row: row data, or undef for init call from new method w/Mnet::Batch loaded

    # read inputs
    my $self = shift // die "missing self arg";
    my $row = shift;
    $self->debug("_output starting");

    # handle --test output
    my $cli = Mnet::Opts::Cli::Cache::get({});
    if ($cli->{test}) {
        $self->debug("_output calling _output_test");
        $self->_output_test($row);

    # handle non-test output
    } else {

        # always log report row output
        $self->debug("_output calling _output_log");
        $self->_output_log($row);

        # note that no output option was set
        if (not defined $self->{output}) {
            $self->debug("_output skipped, output option not set");

        # handle csv output
        } elsif ($self->{output} =~ /^csv:/) {
            $self->debug("_output calling _output_csv");
            $self->_output_csv($row);

        # handle dump output
        } elsif ($self->{output} =~ /^dump:/) {
            $self->debug("_output calling _output_dump");
            $self->_output_dump($row);

        # handle json output
        } elsif ($self->{output} =~ /^json:/) {
            $self->debug("_output calling _output_json");
            $self->_output_json($row);

        # handle sql output
        } elsif ($self->{output} =~ /^sql:/) {
            $self->debug("_output calling _output_sql");
            $self->_output_sql($row);

        # error on invalid output option
        } else {
            $self->fatal("invalid output option $self->{output}");
        }

    # finished handling non-test output
    }

    # finished _output method
    $self->debug("_output finished");
    return;
}



sub _output_csv {

=head2 output csv

    csv:$file

The csv output option can be used to create csv files.

Note that eol characters are replaced with spaces in csv output.

Scripts that create multiple Mnet::Report::Table objects with output options
set to csv need to ensure that the csv filenames are different, otherwise the
single csv file created will possibly have different columns mixed together and
be missing rows.

All csv output fields are double quoted, and double quotes in column output
data are escaped with an extra double quote.

=cut

    # read input object
    my $self = shift // die "missing self arg";
    my $row = shift;
    $self->debug("_output_csv starting");

    # note output csv filename
    $self->fatal("unable to parse output option $self->{output}")
        if $self->{output} !~ /^csv:(.+)/;
    my $file = $1;

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
    my $headings_needed = 0;
    if (not $INC{"Mnet/Batch.pm"} or not $MNet::Batch::fork_called) {
        $headings_needed = 1 if not defined $row;
    }

    # attempt to open csv file for output
    #   open to create anew if headings are needed, perhaps batch parent
    #   otherwise open to append, perhaps batch children outputting rows
    my $fh = undef;
    if ($headings_needed) {
        open($fh, ">", $file) or $self->fatal("unable to open $file, $!");
    } else {
        open($fh, ">>", $file) or $self->fatal("unable to open $file, $!");
    }

    # output heading row, if needed
    if ($headings_needed) {
        my @headings = ();
        foreach my $column (@{$self->{_column_order}}) {
            push @headings, _output_csv_escaped($column);
        }
        syswrite $fh, join(",", @headings) . "\n";
    }

    # output data row, if defined
    #   this will be undefined when called from new method
    if (defined $row) {
        my @data = ();
        foreach my $column (@{$self->{_column_order}}) {
            push @data, _output_csv_escaped($row->{$column});
        }
        syswrite $fh, join(",", @data) . "\n";
    }

    # close output csv file
    close $fh;

    # finished _output_csv method
    $self->debug("_output_csv finished");
    return;
}



sub _output_dump {

=head2 output dump

    dump:$var:$file

The dump output option writes one row per line in L<Data::Dumper> format
prefixed by the specified variable name.

This dump output can be read back into a perl script as follows:

    use Data::Dumper;
    while (<STDIN>) {
        my ($line, $var) = ($_, undef);
        my $table = $1 if $line =~ s/^\$(\S+)/\$var/ or die;
        eval "$line";
        print Dumper($var);
    }

Note that dump output is appended to the specified file, so the perl unlink
command can be used to remove these files prior to each Mnet::Report::Table
new call, if desired. This means it can be ok for multiple Mnet::Report::Table
objects to write data to the same file, Use 'dump:$var:/dev/stdout' for output
to the user's terminal.

=cut

    # read input object
    my $self = shift // die "missing self arg";
    my $row = shift // return;
    $self->debug("_output_dump starting");

    # note output dump variable and file names
    $self->fatal("unable to parse output option $self->{output}")
        if $self->{output} !~ /^dump:([a-zA-Z]\w*):(.+)/;
    my ($var, $file) = ($1, $2);

    # attempt to open dump file for appending
    open(my $fh, ">>", $file) or $self->fatal("unable to open $file, $!");

    # output data row
    #   this will be undefined if called from new method
    if (defined $row) {
        my $dump = Mnet::Dump::line($row);
        syswrite $fh, "\$$var = $dump;\n";
    }

    # finished _output_dump method
    $self->debug("_output_dump finished");
    return;
}



sub _output_json {

=head2 output json

    json:$var:$file

The dump output option writes one row per line in json format prefixed by the
table name as the variable name. This requires that the L<JSON> module is
available.

This json output can be read back into a perl script as follows:

    use JSON;
    use Data::Dumper;
    while (<STDIN>) {
        my ($line, $var) = ($_, undef);
        my $table = $1 if $line =~ s/^(\S+) = // or die;
        $var = decode_json($line);
        print Dumper($var);
    }

Note that json output is appended to the specified file, so the perl unlink
command can be used to remove these files prior to each Mnet::Report::Table
new call, if desired. This means it can be ok for multiple Mnet::Report::Table
objects to write data to the same file. Use 'dump:/dev/stdout' for terminal
output.

=cut

    # read input object
    my $self = shift // die "missing self arg";
    my $row = shift // return;
    $self->debug("_output_json starting");

    # abort with an error if JSON module is not available
    croak("Mnet::Report::Table json requires perl JSON module is installed")
        if not $INC{'JSON.pm'} and not eval("require JSON; 1");

    # note output json variable and file names
    $self->fatal("unable to parse output option $self->{output}")
        if $self->{output} !~ /^json:([a-zA-Z]\w*):(.+)/;
    my ($var, $file) = ($1, $2);

    # attempt to open dump file for appending
    open(my $fh, ">>", $file) or $self->fatal("unable to open $file, $!");

    # output data row
    #   json is sorted so that test output doesn't vary
    #   this will be undefined if called from new method
    if (defined $row) {
        my $json = JSON->new->canonical->encode($row);
        syswrite $fh, "$var = $json;\n";
    }

    # finished _output_json method
    $self->debug("_output_json finished");
    return;
}



sub _output_log {

# $self->_output_log
# purpose: output report row as info log entries

    # read input object
    my $self = shift // die "missing self arg";
    my $row = shift;
    $self->debug("_output_log starting");

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

=head2 output sql

    sql:$table:$file
    or sql:"$table":$file

The dump output option writes one row perl line as sql insert statements in
the following format:

    INSERT INTO <table> (<column>, ...) VALUES (<value>, ...);

Column names are double quotes, and values are single quoted. Single quotes in
values are escaped with an extra single quote character, LF and CR characters
are escaped as '+CHAR(10)+' and '+CHAR(13)+' respectively.

Note that sql output is appended to the specified file, so the perl unlink
command can be used to remove this file prior to the Mnet::Report::Table new
call, if desired. This means it can be ok for multiple Mnet::Report::Table
objects to write data to the same file. Use 'dump:/dev/stdout' for terminal
output.

=cut

    # read input object
    my $self = shift // die "missing self arg";
    my $row = shift // return;
    $self->debug("_output_sql starting");

    # note output sql table and file names
    $self->fatal("unable to parse output option $self->{output}")
        if $self->{output} !~ /^sql:"?([^"]+)"?:(.+)/;
    my ($table, $file) = ($1, $2);

    # attempt to open sql file for appending
    open(my $fh, ">>", $file) or $self->fatal("unable to open $file, $!");

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
        my $sql = "INSERT INTO \"$table\" ";
        $sql .= "(" . join(",", @sql_columns) . ") ";
        $sql .= "VALUES (" . join(",", @sql_values) . ");";
        syswrite $fh, "$sql\n";
    }

    # finished _output_sql method
    $self->debug("_output_sql finished");
    return;
}



sub _output_test {

=head2 output test

Normal Mnet::Report::Table output is overriden when the L<Mnet::Test> module is
loaded and the --test cli option is present. Normal file output is suppressed
and instead test report output is sent to stdout.

The test output option may also be set maually.

=cut

    # read input object
    my $self = shift // die "missing self arg";
    my $row = shift;
    $self->debug("_output_test starting");

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



# output row_on_error data if errors for those objects not already output
END {
    if ($INC{'Mnet/Log.pm'} and Mnet::Log::error()
        or $Mnet::Report::Table::error) {
        foreach my $row_on_error (@Mnet::Report::Table::row_on_error) {
            DEBUG("END row_on_error");
            my $self = $row_on_error->{self};
            my $data = $row_on_error->{data};
            $self->row($data) if not $self->{_row_on_error};
        }
    }
}



=head1 TESTING

Mnet::Report::Table supports the L<Mnet::Test> module test, record, and replay
functionality, tracking report data so it can be included in test results.

=head1 SEE ALSO

L<JSON>

L<Mnet>

L<Mnet::Test>

=cut

# normal package return
1;

