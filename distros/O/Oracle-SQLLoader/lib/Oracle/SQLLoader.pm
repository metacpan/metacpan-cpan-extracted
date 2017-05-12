# -*- mode: cperl -*-
# $Id: SQLLoader.pm,v 1.43 2005-07-28 03:10:23 ezra Exp $

=head1 NAME

Oracle::SQLLoader - object interface to Oracle's sqlldr

=head1 DESCRIPTION

B<Oracle::SQLLoader> provides an object wrapper to the most commonly used
functionality of Oracle's SQL*Loader bulk loader utility. It tries to dwim
as best as possible by using defaults to all of the various sqlldr options.

The module currently supports the loading of a single table from a single file.
The file can be either fixed length or delimited. For a delimited file load, just
add the names of the destination columns in the order the fields appears in the
data file and optionally supply a data type. For a fixed length load, supply the
destination column name; the combination of the field starting offset and field
length, or the field start and end offsets in the data file; and an optional
data type.

Besides letting you skip the Oracle docs, the module provides a lot of useful
stats and return codes by parsing the sqlldr output.


=head1 SYNOPSIS

  use Oracle::SQLLoader qw/$CHAR $INT $DECIMAL $DATE/;

  ### load a simple comma-delimited file to a single table
  $ldr = new Oracle::SQLLoader(
 				infile => '/tmp/test.dat',
 				terminated_by => ',',
 				username => $user,
 				password => $pass,
                                sid => $sid
 			       );

  $ldr->addTable(table_name => 'test_table');
  $ldr->addColumn(column_name => 'first_col');
  $ldr->addColumn(column_name => 'second_col');
  $ldr->addColumn(column_name => 'third_col');
  $ldr->executeLoader() || warn "Problem executing sqlldr: $@\n";

  # stats
  $skipped = $ldr->getNumberSkipped();

  $read = $ldr->getNumberRead();

  $rejects = $ldr->getNumberRejected();

  $discards = $ldr->getNumberDiscarded();

  $loads = $ldr->getNumberLoaded();

  $beginTS = $ldr->getLoadBegin();

  $endTS = $ldr->getLoadEnd();

  $runtimeSecs = $ldr->getElapsedSeconds();

  $secsOnCpu = $ldr->getCpuSeconds();




  #### a fixed length example
  $flldr = new Oracle::SQLLoader(
				 infile => '/tmp/test.fixed',
				 username => $user,
				 password => $pass,
				 );
  $flldr->addTable(table_name => 'test_table');

  $flldr->addColumn(column_name => 'first_col',
	            field_offset => 0,
		    field_length => 4,
		    column_type => $INT);

  $flldr->addColumn(column_name => 'second_col',
	            field_offset => 4,
		    field_end => 9);

  $flldr->addColumn(column_name => 'third_col',
	            field_offset => 9,
		    field_end => 14,
		    column_type => $CHAR);

  $flldr->addColumn(column_name => 'timestamp',
	            field_offset => 9,
		    field_length => 13,
                    column_type => $DATE,
		    date_format => "YYYYMMDD HH24:MI");

  $flldr->executeLoader() || warn "Problem executing sqlldr: $@\n";

  # stats
  $skipped = $ldr->getNumberSkipped();

  $read = $ldr->getNumberRead();

  $rejects = $ldr->getNumberRejected();

  $discards = $ldr->getNumberDiscarded();

  $loads = $ldr->getNumberLoaded();

  $beginTS = $ldr->getLoadBegin();

  $endTS = $ldr->getLoadEnd();

  $runtimeSecs = $ldr->getElapsedSeconds();

  $secsOnCpu = $ldr->getCpuSeconds();


=head1 AUTHOR

Ezra Pagel <ezra@cpan.org>

=head1 CONTRIBUTIONS

John Huckelba - fix for single record files scenario

Craig Pearlman <cpearlman@healthmarketscience.com> - added various fixes, most
importantly initializing and generating the options clause correctly.

=head1 COPYRIGHT

The Oracle::SQLLoader module is Copyright (c) 2006 Ezra Pagel.

The Oracle::SQLLoader module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

Modifications to Oracle::SQLLoader are Copyright (c) 2006 Health Market Science,
though this code remains free under the terms of the original license.

SQL*Loader is Copyright (c) 1982, 2002, Oracle Corporation.  All rights reserved.

=cut

package Oracle::SQLLoader;

use IO::File;
use Carp;
use Config;
use Cwd;
use strict;
use Exporter;
use Time::Local;

use vars qw/@ISA
            @EXPORT_OK
            $VERSION
            $CHAR
            $INT
            $DECIMAL
            $DATE
            $APPEND
            $TRUNCATE
            $REPLACE
            $INSERT/;


$VERSION = '0.9';
@ISA = qw/Exporter/;
@EXPORT_OK = qw/$CHAR $INT $DECIMAL $DATE $APPEND $TRUNCATE $REPLACE $INSERT/;

our %OPTS = map { $_, 1 } qw/bindsize columnarrayrows direct discardmax
                             errors load readsize resumable rows silent
                             skip streamsize/;

our %BOOL_OPTS = map { $_, 1 } qw/direct multithreading parallel
                                  skip_index_maintenance skip_unusable_indexes/;

our %OPT_DEFAULTS;

#initDefaults();

################################################################################

=head1 API

=cut

################################################################################


################################################################################

=head2 IMPORTABLE VARIABLES

=over 2

=item Column Data Types

=over 2

=item $CHAR - data to be interpreted as character. empty data is treated as null

=item $INT - data to be interpreted as integer. empty data is treated as 0

=item $DECIMAL - data to be interpreted as floating point. empty data is treated
as null

=item $DATE - date fields. these want a valid format, but will default to DD-MON-YY

=back

=item Table Load Modes

=over 2

=item $APPEND - add new rows into the table

=item $INSERT - adds rows into an empty table, or error out if the table has data

=item $REPLACE - delete all existing rows from the table and then load

=item $TRUNCATE - truncate the table (no rollback!) and then load

=back

=back

=cut

################################################################################

$CHAR = 'CHAR';
$INT = 'INTEGER EXTERNAL';
$DECIMAL = 'DECIMAL EXTERNAL';
$DATE = 'DATE';
$APPEND = 'APPEND';
$TRUNCATE = 'TRUNCATE';
$REPLACE = 'REPLACE';
$INSERT = 'INSERT';


# what's the name of the sqlldr executable?
my $SQLLDRBIN = $^O =~ /win32/i ? 'sqlldr.exe' : 'sqlldr';


# trial+error result codes
my %ERRORCODES = $^O =~ /win32/i ? (SUCCESS => 0,
				    ERROR => 3,
				    WARN => 2,
				    FATAL => 4) :
                                   (SUCCESS => 0,
				    ERROR => 1,
				    WARN => 2,
				    FATAL => 3);

# used to determine start/end epochs from logs
my %MONTHS = (Jan => 0, Feb => 1, Mar => 2, Apr => 3, May => 4, Jun => 5,
	      Jul => 6, Aug => 7, Sep => 8, Oct => 9, Nov => 10, Dec=> 11);
my $DEBUG = 0;


################################################################################

=head2 PUBLIC METHODS

=cut

################################################################################




################################################################################

=head3 B<new()>

create a new Oracle::SQLLoader object

=over 2

=item mandatory arguments

=over 2

=item I<infile> - the name and full filesystem path to the input file

=item I<username> - the oracle username for this load

=item I<password> - the password for this username

=back

=item common arguments

=over 2

=item I<control_file> - supply an explicit file name to use when
generating the control file; useful when I<cleanup> is set to false.

=item I<terminated_by> - if you're planning on loading a delimited file,
just provide the character used as a delimiter and Oracle::SQLLoader will
presume that it's a delimited load from here on out. if this option is not
supplied, a fixed length file format will be used.

=item I<direct> - bypass parsing sql and write directly to the tablespace on
the filesystem. this is considerably faster than conventional loads, but can
only be performed on a local instance. if this argument is not supplied,
conventional load will be used.

=item I<loadmode> - one of the above Load Modes: $APPEND, $INSERT, $REPLACE,
$TRUNCATE (default $APPEND)

=back

=item other optional arguments - you can ususally accept the defaults and
pretend that these don't exist.

=over 2

=item I<bindsize> - byte size of conventional load buffer; also sets
I<readsize> (default 256000)

=item I<columnarrayrows> - number of rows to buffer for direct loads
(default 5000)

=item I<errors> - the maximum number of errors to accept before failing
the load (default 50)

=item I<load> - the maximum number of records to load (default ALL)

=item I<rows> - the number of rows to load before committing (default 64)

=item I<skip> - the number of records to allow to be skipped (default 0)

=item I<skip_index_maintenance> - for direct loads, don't rebuild indexes (default false)

=item I<skip_unusable_indexes> - skips rebuilding unusable indexes (default false)

=item I<streamsize> - (direct) the byte size of the load stream (default 256000)

=item I<badfile> -

=item I<discardfile> -

=item I<eol> -

=item I<offset_from> - do your offsets start at position 0 or 1

=item I<enclosed_by> - are there some sort of enclosing characters, double-quotes perhaps?

=item I<cleanup> - want to leave the load files on disk, maybe for
testing/auditing?

=back

=back

=cut

################################################################################
sub new {
  my ($class, %args) = @_;

  croak __PACKAGE__."::new: missing mandatory argument 'infile'"
    unless exists $args{'infile'};

  my $self = {};
  bless ($self, $class);

  if ($^O =~ /win32/i) {
    $self->{'_OSTYPE'} = 'WIN';
  }

  $self->_initDefaults(%args);

  return $self;
} # sub new





###############################################################################

=head3 B<addTable()>

identify a table to be loaded. multiple adds with the same table name clobbers
any old definition.

=over 2

=item mandatory arguments

=over 2

=item I<table name> - the name of the table to load

=back

=item optional arguments

=over 2

=item I<when_clauses>

=item I<continue_clauses>

=item I<terminated_clauses>

=item I<enclosed_clauses>

=item I<nullcols>

=back

=back

=cut

###############################################################################
sub addTable {
  my $self = shift;

  croak __PACKAGE__."::addTable(): need name/value pairs" unless $#_ % 2;

  my %args = @_;
  croak __PACKAGE__."::addTable: missing table name"
    unless $args{'table_name'};
  $self->{'_cfg_tables'}{$args{'table_name'}} = \%args;
  $self->{'_last_table'} = $args{'table_name'};
} # sub addTable





###############################################################################

=head3 B<addColumn()>

add a column to be loaded

=over 2

=item mandatory arguments for all load types

=over 2

=item I<column_name> - the name of the column to be loaded

=back

=item mandatory arguments for fixed length load types

=over 2

=item I<field_offset> - starting position of the data in the input file

=item and one of:

=over 2

=item I<field_end> - the ending position of the data in the input file

=item I<field_length> - the length of the field, measured from field_offset

=back

=back

=item optional arguments for all load types

=over 2

=item I<table_name> -
the name of the table that this column belongs to. if no table name is
specified, default is the last known table name. if no previous table name
exists, croak.

=item I<column_type> -
$CHAR, $INT, $DECIMAL, or $DATE; defaults to $CHAR

=item I<date_format> -
the TO_DATE format for a $DATE column; defaults to "DD-MON-YY"

=item I<column_length> -
on occassion, it's useful to specify the length of the field; for some reason,
this is required when loading large strings (e.g. CHAR(3000))

=back

=back

=cut

###############################################################################
sub addColumn {
  my $self = shift;
  my %args = @_;
  my $table = $args{'table_name'} || $self->{'_last_table'};
  croak __PACKAGE__."::addColumn: missing table name"
    unless $table;
  croak __PACKAGE__."::addColumn: missing column name"
    unless $args{'column_name'};

  # if this isn't a delimited file, then we'll need offsets and lengths for
  # each column to parse
  if (not $self->{'_cfg_global'}{'terminated_by'}) {
    croak __PACKAGE__."::addColumn: fixed length file fields require offset ".
      "and length or end" unless (exists $args{'field_offset'} &&
				  (exists $args{'field_length'} ||
				   exists $args{'field_end'})
				 );
    # sqlldr offsets start 1
    if ($self->{_cfg_global}{'offset_from'} == 0) {
      $args{'field_offset'} += 1;
      $args{'field_end'} += 1 if exists $args{'field_end'};
    }


    if (exists $args{'field_length'}) {
      $args{'field_end'} = $args{'field_offset'} + $args{'field_length'};
    }


    $args{'position_spec'} = "POSITION(".
      "$args{'field_offset'}-$args{'field_end'}) ";


    # may as well clean up
    delete $args{'field_length'};
    delete $args{'field_offset'};
    delete $args{'field_end'};
  }


  # control files default to character;
  # so the external numeric types mean that there are strings, but that
  # they should be treated as numbers, including defaulting to 0, not null
  $args{'column_type'} = $args{'column_type'} || $CHAR;

  $args{'column_length'} = $args{'column_length'} ?
    "($args{'column_length'})" : '';
  $args{'column_type'} .= $args{'column_length'};

  # and should we just warn and use the default format? probably not; i'd hade
  # to load a bunch of bad date w/out knowing about it.
  if ($args{'column_type'} eq $DATE) {
    $args{'date_format'} = $args{'date_format'} || "DD-MON-YY";
    $args{'column_type'} =
      "\"TO_DATE(:$args{'column_name'},'$args{'date_format'}')\"";
  }

  push @{$self->{'_cfg_tables'}{$table}{'columns'}}, \%args;

} # sub addColumn




################################################################################

=head3 B<executeLoader()>

generate a control file and execute an sqlldr job. this is a blocking call. if
you don't care about load statistics, you can always fork it off. returns 1 if
sqlldr ran successfully, 0 if there were errors or warnings

=cut

################################################################################
sub executeLoader {
  my $self = shift;

  $self->generateControlfile();
#  if ($self->{'_OSTYPE'} ne 'WIN') {
  my $exe = $ENV{'ORACLE_HOME'}."/bin/$SQLLDRBIN";
  my $cmd = "$exe control=$self->{'_control_file'} ".
            "userid=$self->{'_cfg_global'}{'userid'} ".
            "log=$self->{'_cfg_global'}{'logfile'} 2>&1";

  my $output = `$cmd`;
  my $exitval = $? / 256;

  $self->checkLogfile();

#--   if ($exitval == $ERRORCODES{'SUCCESS'} ||
#--       $exitval == $ERRORCODES{'WARN'}) {
#--     $self->checkLogfile();
#--
  if ($self->{'_cleanup'}) {
    my $ctlFile = $self->{'_cfg_global'}{'control_file'} ||
      $self->{'_cfg_global'}{'infile'} . ".ctl";
    unlink $ctlFile;
    unlink $self->{'_cfg_global'}{'badfile'};
    unlink $self->{'_cfg_global'}{'discardfile'};
    unlink $self->{'_cfg_global'}{'logfile'};
  }

  return !$exitval;
} # sub executeLoader





################################################################################

=head3 B<checkLogfile()>

parse an sqlldr logfile and be store results in object status

=over 2

=item optional arguments

=over 2

=item $logfile - the file to parse; defaults to the object's current logfile

=back

=back

=cut

################################################################################
sub checkLogfile {
  my $self = shift;
  my $logfile = shift || $self->{'_cfg_global'}{'logfile'};

  my $log = new IO::File "< $logfile";
  if (! defined $log) {
    carp "checkLogfile(): failed to open file $logfile : $!\n" if $DEBUG;
    $self->{'_stats'}{'skipped'} = undef;
    $self->{'_stats'}{'read'} = undef;
    $self->{'_stats'}{'rejected'} = undef;
    $self->{'_stats'}{'discarded'} = undef;
    $self->{'_stats'}{'loaded'} = undef;
    return undef;
  }

  # skip the first line, check the second for the SQL*Loader declaration
  my $line = <$log>;
  $line = <$log>;

  unless ($line =~ /^SQL\*Loader/) {
    carp __PACKAGE__."::checkLoadLogfile: $logfile does not appear to be a ".
      "valid sqlldr log file. returning";
    return undef;
  }

  while (<$log>) {
    chomp;
    if (/Total logical records skipped:\s+(\d+)/) {
      $self->{'_stats'}{'skipped'} = $1;
    }

    # presume that additional lines have error messages
    elsif (/^SQL\*Loader/) {
      push (@{$self->{'_stats'}->{'errors'}},$_);
    }
    elsif (/Total logical records read:\s+(\d+)/) {
      $self->{'_stats'}{'read'} = $1;
    }
    elsif (/Total logical records rejected:\s+(\d+)/) {
      $self->{'_stats'}{'rejected'} = $1;
    }
    elsif (/Total logical records discarded:\s+(\d+)/) {
      $self->{'_stats'}{'discarded'} = $1;
    }
    elsif (/(\d+) Rows? successfully loaded\./) {
      $self->{'_stats'}{'loaded'} = $1;
    }
    elsif (/Record\s\d+:\s+Rejected\s+\-\s+/) {
      # grab the next line and add it to the last known rejection
      my $errMsg = <$log>;
      chomp $errMsg;
      $errMsg =~ s/\s+$//g;
      $self->{'_stats'}{'last_reject_message'} = $errMsg;
    }
    elsif(/Run began on (\w+)\s(\w+)\s(\d\d)\s(\d\d):(\d\d):(\d\d)\s+(\d{4})/) {
      my ($dow,$mon,$dom,$hr,$min,$sec,$yr) = ($1,$2,$3,$4,$5,$6,$7);
      $yr -= 1900;
      $mon = $MONTHS{$mon};
      $self->{'_stats'}{'run_begin'} = timelocal($sec,$min,$hr,$dom,$mon,$yr);
    }
    elsif(/Run ended on (\w+)\s(\w+)\s(\d\d)\s(\d\d):(\d\d):(\d\d)\s+(\d{4})/) {
      my ($dow,$mon,$dom,$hr,$min,$sec,$yr) = ($1,$2,$3,$4,$5,$6,$7);
      $yr -= 1900;
      $mon = $MONTHS{$mon};
      $self->{'_stats'}{'run_end'} = timelocal($sec,$min,$hr,$dom,$mon,$yr);
    }
    elsif(/Elapsed time was:\s+(\d+):(\d{2}):(\d{2})\.\d{2}/) {
      # i'm assuming that this is hh::mm::ss.ms
      $self->{'_stats'}{'elapsed_seconds'} = (3600 * $1) + (60 * $2) + $3;
    }
    elsif(/CPU time was:\s+(\d+):(\d{2}):(\d{2})\.\d{2}/) {
      $self->{'_stats'}{'cpu_seconds'} = (3600 * $1) + (60 * $2) + $3;
    }
    # what to do w/ trashed indexes, force rebuild?
    elsif (/index\s(\w+\.\w+)\swas made unusable/) {
    }
  }

  $self->{'_stats'}{'skipped'} ||= 0;
  $self->{'_stats'}{'read'} ||= 0;
  $self->{'_stats'}{'rejected'} ||= 0;
  $self->{'_stats'}{'discarded'} ||= 0;
  $self->{'_stats'}{'loaded'} ||= 0;
  $self->{'_stats'}{'run_begin'} ||= 0;
  $self->{'_stats'}{'run_end'} ||= time;
  $self->{'_stats'}{'elapsed_seconds'} ||= 0;
  $self->{'_stats'}{'cpu_seconds'} ||= 0;

  $log->close;
} # sub checkLoadLogfile



###############################################################################

=head2 STATUS METHODS

=cut

###############################################################################




###############################################################################

=head3 B<getNumberSkipped()>

returns the number of records skipped , or undef if no stats are known

=cut

###############################################################################
sub getNumberSkipped {
  $_[0]->{'_stats'}{'skipped'};
}



###############################################################################

=head3 B<getNumberRead()>

returns the number of read from all input files, or undef if no stats are known

=cut

###############################################################################
sub getNumberRead {
  $_[0]->{'_stats'}{'read'};
}



###############################################################################

=head3 B<getNumberRejected()>

returns the number of records rejected, or undef if no stats are known

=cut

###############################################################################
sub getNumberRejected {
  $_[0]->{'_stats'}{'rejected'};
}



###############################################################################

=head3 B<getNumberDiscarded()>

returns the number of records discarded, or undef if no stats are known

=cut

###############################################################################
sub getNumberDiscarded {
  $_[0]->{'_stats'}{'discarded'};
}



###############################################################################

=head3 B<getNumberLoaded()>

returns the number of records successfully loaded, or undef if no stats are
known

=cut

###############################################################################
sub getNumberLoaded {
  $_[0]->{'_stats'}{'loaded'};
}



###############################################################################

=head3 B<getLastRejectMessage()>

returns the last known rejection message, if any

=cut

###############################################################################
sub getLastRejectMessage {
  $_[0]->{'_stats'}{'last_reject_message'};
}


###############################################################################

=head3 B<getLoadBegin()>

the time that the job began represented as epoch timestamp

=cut

###############################################################################
sub getLoadBegin {
  $_[0]->{'_stats'}{'run_begin'};
}

###############################################################################

=head3 B<getLoadEnd()>

the time that the job finished represented as epoch timestamp

=cut

###############################################################################
sub getLoadEnd {
  $_[0]->{'_stats'}{'run_end'};
}


###############################################################################

=head3 B<getElapsedSeconds()>

returns the number if seconds elapsed during load

=cut

###############################################################################
sub getElapsedSeconds {
  $_[0]->{'_stats'}{'elapsed_seconds'};
}



###############################################################################

=head3 B<getCpuSeconds()>

returns the number if seconds on cpu during load

=cut

###############################################################################
sub getCpuSeconds {
  $_[0]->{'_stats'}{'cpu_seconds'};
}


###############################################################################

=head3 B<getErrors()>

returns a listref of any SQL*Loader-specific error codes and messages that were
reported in the load logs, e.g the instance is down (SQL*Loader-128),
the table does not exist (SQL*Loader-941), or the username/password was wrong
(SQL*Loader-101). see the 'SQL*Loader Messages' section of your Oracle docs

=cut

###############################################################################
sub getErrors {
  my $self = shift;
  return $self->{'_stats'}{'errors'};
} # getErrors



###############################################################################

=head3 B<getLastError()>

returns the last known SQL*Loader error code and message, or an empty string

=cut

###############################################################################
sub getLastError {
  my $self = shift;
  if (scalar @{$self->{'_stats'}{'errors'}}) {
    return $self->{'_stats'}{'errors'}->[$#{$self->{'_stats'}{'errors'}}];
  }
  return '';
} # getErrors









###############################################################################

=head2 B<CONTENT GENERATION METHODS>

=cut

###############################################################################




###############################################################################

=head3 B<generateControlfile()>

based on the current configuration options, generate a control file

=cut

###############################################################################
sub generateControlfile {
  my $self = shift;

  my $ctlFile = $self->{'_cfg_global'}{'control_file'} ||
             $self->{'_cfg_global'}{'infile'} . ".ctl";

  my $fh = new IO::File;
  carp __PACKAGE__."::generateControlfile: file $ctlFile already exists\n"
    if -e $ctlFile && $DEBUG;

  if (! $fh->open("> $ctlFile")) {
    croak __PACKAGE__."::generateControlfile: failed to opern file $ctlFile: $!\n";
  }

  # the SQL*Loader reference says that control files are basically three
  # sections:
  # * Session-wide information
  #   - Global options such as bindsize, rows, records to skip, and so on
  #   - INFILE clauses to specify where the input data is located
  #   - Data to be loaded

  # * Table and field-list information
  # * Input data (optional section)



  $self->{'_control_text'} =
    $self->_generateSessionClause().
    $self->_generateTablesClause().
    $self->_generateDataClause();

  print $fh $self->{'_control_text'};
  $fh->close;

  $self->{'_control_file'} = $ctlFile;

  return 1;
} # sub generateControlFile





################################################################################

=head2 UTILITY METHODS

=cut

################################################################################


################################################################################

=head3 B<findProgram()>

searches ORACLE_HOME and PATH environment variables for an executable program.
returns the full path and file name of the first match, or undef if not found.
can be invoked as a class or instance method.

Oracle::SQLLoader->findProgram('sqlldr')
or
$ldr->findProgram('sqlldr.exe')

=over 2

=item mandatory arguments

=over 2

=item $executable - the name of the program to search for

=back

=back

=cut

################################################################################
sub findProgram {
  my $argclass = shift;
  my $exe = shift;
  my $class = ref($argclass) || $argclass;

  if (exists $ENV{'ORACLE_HOME'}) {
    return "$ENV{'ORACLE_HOME'}/bin/$exe"
      if -x "$ENV{'ORACLE_HOME'}/bin/$exe";
  }

  foreach (split($Config{'path_sep'}, $ENV{'PATH'})){
    return "$_/$exe" if -x "$_/$exe";
  }
  return undef;
} # sub findProgram



################################################################################

=head3 B<checkEnvironment()>

ensure that ORACLE_HOME is set and that the sqlldr binary is present and
executable. can be invoked as a class or instance method.

Oracle::SQLLoader->findProgram('sqlldr')
or
$ldr->findProgram('sqlldr.exe')

=cut

################################################################################
sub checkEnvironment {
  my $argclass = shift;
  my $class = ref($argclass) || $argclass;

  carp __PACKAGE__."::checkEnvironment: no ORACLE_HOME environment variable set"
    unless $ENV{'ORACLE_HOME'};
  carp __PACKAGE__."::checkEnvironment: no ORACLE_SID environment variable set"
    unless $ENV{'ORACLE_SID'};
  carp __PACKAGE__."::checkEnvironment: sqlldr doesn't exist or isn't executable"
    unless ($class->findProgram($SQLLDRBIN));
} # sub checkEnvironment




################################################################################

=head2 PRIVATE METHODS

=cut

################################################################################


################################################################################
# setup sane defaults
################################################################################
sub _initDefaults {
  my $self = shift;
  my %args = @_;


  # _cfg_global
  if ($args{'infile'} eq '*') {
    # so we're loading inline data; that means that we don't have a sane
    # default for any of the other file options.
    $args{'badfile'} ? $self->{'_cfg_global'} = $args{'badfile'} :
      croak __PACKAGE__,"::_initDefaults: can't guess badfile with inline data";

    $args{'discardfile'} ? $self->{'_cfg_global'} = $args{'discardfile'} :
      croak __PACKAGE__,"::_initDefaults: can't guess discardfile with inline data";

    $args{'logfile'} ? $self->{'_cfg_global'} = $args{'logfile'} :
      croak __PACKAGE__,"::_initDefaults: can't guess logfile with inline data";

  }
  else {
    $self->{'_cfg_global'}{'badfile'} = $args{'badfile'} ||
      $args{'infile'} . '.bad';
    $self->{'_cfg_global'}{'discardfile'} = $args{'discardfile'} ||
      $args{'infile'} . '.discard';
    $self->{'_cfg_global'}{'logfile'} = $args{'logfile'} ||
      $args{'infile'} . '.log';
  }

  $self->{'_cfg_global'}{'infile'} = $args{'infile'};


  # only accept legal keys as config values
  foreach my $key (keys %OPTS) {
    $self->{'_cfg_global'}{$key} = $args{$key} if exists $args{$key};
  }

  foreach my $key (keys %BOOL_OPTS) {
    if (exists $args{$key}) {
      if ($args{$key} =~ /0|false/i) {
        $self->{'_cfg_global'}{$key} = 'false';
      }
      elsif ($args{$key} =~ /1|true/i) {
        $self->{'_cfg_global'}{$key} = 'true';
      }
      else {
        carp __PACKAGE__,"::_initDefaults: invalid value \"$args{$key}\"".
          " for option \"$key\"";
      }
    }
  }



  # fix $recordLength, var $bytes
  $self->{'_cfg_global'}{'recfmt'} = $args{'recfmt'} || '';

  # end of stream terminator. don't bother with defaulting to \n
  $self->{'_cfg_global'}{'eol'} = $args{'eol'} || '';

  # delimiter?
  $self->{'_cfg_global'}{'terminated_by'} = $args{'terminated_by'};

  # if not, it's fixed length; do offsets start at position 0 or 1?
  $self->{_cfg_global}{'offset_from'} = exists $args{'offset_from'} ?
    $args{'offset_from'} : 0;

  # are there some sort of enclosing characters, double-quotes perhaps?
  $self->{'_cfg_global'}{'enclosed_by'} = $args{'enclosed_by'};


  # handle 0 or 'false', 1 or 'true'
  if (exists $args{'direct'}) {
    if (!$args{'direct'} || $args{'direct'} =~ /false/i) {
      $self->{'_cfg_global'}{'direct'} = 'false';
    }
    else {
      $self->{'_cfg_global'}{'direct'} = 'true';
    }
  }
  else {
    $self->{'_cfg_global'}{'direct'} = $OPT_DEFAULTS{'direct'};
  }

  # default to 'all'
  $self->{'_cfg_global'}{'nullcols'} = $args{'nullcols'} ? 'trailing nullcols' : '';

  # default to shutup
  $self->{'_cfg_global'}{'silent'} = $args{'silent'} ? $args{'silent'} : 'header,feedback';
#    'silent=header,feedback,errors,discards,partitions';


  # figure out if we've got username and password arguments. if not, check
  # ORACLE_USERID for it and see if it's a 'scott/tiger@sid' format
  if ($args{'username'}) {
    if (exists $args{'password'}) {

      my $sid;
      if (exists $args{'sid'}) {
	$sid = $args{'sid'};
      }
      elsif(exists $ENV{'ORACLE_SID'}) {
	$sid = $ENV{'ORACLE_SID'};
      }
      else {
	croak __PACKAGE__,"::_initDefaults(): must include sid argument if no ".
	  "ORACLE_SID environment variable is set";
      }
      $self->{'_cfg_global'}{'userid'} =
	$args{'username'} . "/" .
	$args{'password'} . "\@$sid";
    }
    else {
      croak __PACKAGE__,"::_initDefaults(): must include password with ".
	"username option";
    }
  }
  # missing auth info. let's see if ORACLE_USERID holds anything useful
  elsif ($ENV{'ORACLE_USERID'}) {
    if (($self->{'_cfg_global'}{'username'},
	 $self->{'_cfg_global'}{'password'},
	 $self->{'_cfg_global'}{'sid'}) =
	($ENV{'ORACLE_USERID'} =~ (/(\w+)\/(\w+)[\@(\w+)]?/))) {
      # great, got a match
    }
    else {
      croak __PACKAGE__,"::_initDefaults: no username argument supplied and ".
	"ORACLE_USERID environment variable does not contain valid account info";
    }
  }
  else {
    croak __PACKAGE__,"::_initDefaults: no username argument supplied and ".
      "ORACLE_USERID environment variable does not contain valid account info";
  }

  # default the load mode to append
  $self->{'_cfg_global'}{'loadmode'} = $args{'loadmode'} || $APPEND;

  # cache the last table
  undef $self->{'_last_table'};

  # do we want to cleanup after ourselves, or leave the files around for
  # testing or auditing?
  $self->{'_cleanup'} = exists $args{'cleanup'} ? $args{'cleanup'} : 1;



  # finally, initialize any stats we're interested in
  $self->{'_stats'}{'skipped'} = undef;
  $self->{'_stats'}{'read'} = undef;
  $self->{'_stats'}{'rejected'} = undef;
  $self->{'_stats'}{'discarded'} = undef;
  $self->{'_stats'}{'loaded'} = undef;
  $self->{'_stats'}{'errors'} = [];

} # sub _initDefaults



###############################################################################

=head3 B<_generateSessionClause()>

generate the session-wide information for a control file

=cut

###############################################################################
sub _generateSessionClause {
  my $self = shift;
  my $cfg = $self->{'_cfg_global'};
  $cfg->{'fixed'} ||= '';


  # TBD
  #-- RESUMABLE = {TRUE | FALSE}
  #-- RESUMABLE_NAME = 'text string'
  #-- RESUMABLE_TIMEOUT = n
  #-- SKIP_INDEX_MAINTENANCE = {TRUE | FALSE}
  #-- SKIP_UNUSABLE_INDEXES = {TRUE | FALSE}


  my $text = <<EndText;
OPTIONS (
    SILENT=(\U$cfg->{'silent'}\E)

)
LOAD DATA
    INFILE '$cfg->{'infile'}' $cfg->{'fixed'}
    BADFILE '$cfg->{'badfile'}'
    DISCARDFILE '$cfg->{'discardfile'}'
$cfg->{'loadmode'}
EndText

  chomp $text; # remove extra \n

  return $text;
} # sub _generateSessionClause


###############################################################################

=head3 B<_generateTablesClause()>

generate table and column information for a control file

=cut

###############################################################################
sub _generateTablesClause {
  my $self = shift;
  my $tableClause;
  if (not $self->{'_cfg_tables'}) {
   croak  __PACKAGE__."::_generateTablesClause: no tables defined";
  }

  foreach my $table (keys %{$self->{'_cfg_tables'}}) {

    my $cfg = $self->{'_cfg_tables'}{$table};
    $cfg->{'when_clauses'} ||= '';


    $tableClause = "\nINTO TABLE $table $cfg->{'when_clauses'} ";
    if ($self->{'_cfg_global'}{'terminated_by'}) {
      $tableClause .= "\nfields terminated by '".
	$self->{'_cfg_global'}{'terminated_by'} ."'";
    }

    if ($self->{'_cfg_global'}{'enclosed_by'}) {
      $tableClause .= "\noptionally enclosed by '".
	$self->{'_cfg_global'}{'enclosed_by'}. "'";
    }

    if ($self->{'_cfg_global'}{'nullcols'}) {
      $tableClause .= "\ntrailing nullcols ";
    }
    $tableClause .= " (\n";


#      "$cfg->{'continue_clauses'}  ".

    my @colDefs;
    foreach my $def (@{$self->{'_cfg_tables'}{$table}{'columns'}}) {
      my $colClause;

      $colClause .= $def->{'column_name'} . " ";
      $colClause .= $def->{'position_spec'} . " " if $def->{'position_spec'};
      $colClause .= $def->{'column_type'}. " ";
      $colClause .= $def->{'nullif_clause'}. " " if $def->{'nullif_clause'};
      $colClause .= $def->{'terminated_clause'}. " " if $def->{'terminated_clause'};
      $colClause .= $def->{'transform_clause'}. " " if $def->{'transform_clause'};
      $colClause =~ s/\s+$//g;
      push @colDefs, "\t$colClause";
    }

    $tableClause .= join(",\n", @colDefs);
    $tableClause .= "\n)";
  }


  # after the table clause, we can include optional delimiter or enclosure specs

  return $tableClause;
} # sub _generateTablesClause




###############################################################################

=head3 B<_generateDataClause()>

generate any input data for a control file

=cut

###############################################################################
sub _generateDataClause {
  my $self = shift;
  return '';
} # sub _generateDataClause



###############################################################################

=head3 B<initDefaults()>

the loader defaults are almost directly from the sqlldr usage dumps

=cut

###############################################################################
sub unused_initDefaults {

  %OPT_DEFAULTS = (
                   bindsize => 256000,
                   columnarrayrows => 5000,
                   direct => 'false',
#                   discardmax => 'all',
                   errors => 50,
#                   load => 'all',
                   multithreading => 'false',
                   parallel => 'false',
                   parfile => '',
                   readsize => 0,
                   resumable => 'false',
                   resumable_name => 'text string',
                   resumable_timeout => 0,
                   rows_direct => 'all',
                   rows_conventional => 64,
                   rows => 64,
                   skip => 0,
                   skip_index_maintenance => 'false',
                   skip_unusable_indexes => 'false',
                   streamsize => 256000,
                   silent => '',
                   file => '',
                  );


  my %optDescrip = (
		    bad => 'Bad file name',
		    data => 'Data file name',
		    discard => 'Discard file name',
		    discardmax => 'Number of discards to allow',
		    skip => 'Number of logical records to skip',
		    load => 'Number of logical records to load',
		    errors => 'Number of errors to allow',
		    rows => 'Number of rows in conventional path bind array '.
                            'or between direct path data saves',
		    bindsize => 'Size of conventional path bind array in bytes',
		    silent => 'Suppress messages during run (header,feedback,'.
		              'errors,discards,partitions)',
		    direct => 'use direct path',
		    parfile => 'parameter file: name of file that contains '.
                               'parameter specifications',
		    parallel => 'do parallel load',
		    file => 'File to allocate extents from',
		   );
} # sub initDescriptions





1;
