package Oracle::Sqlldr;

=head1 NAME

Oracle::Sqlldr - Perl wrapper around Oracle's sqlldr utility.

=head1 SYNOPSIS

  use Oracle::Sqlldr;
  my $sqlldr = Oracle::Sqlldr->new(); # get new sqlldr object

=head1 DESCRIPTION

Oracle::Sqlldr is an object-oriented class that provides a convenient
Perl wrapper around Oracle's sqlldr utility.

SQL*Loader (I<sqlldr>) is the utility to use for high performance 
data loading from a text file into a an Oracle database.

=head1 LIMITATIONS

=over

=item No WIN32 support

=item No fixed format record support

=item Assumes table owner and user to load data as are the same

=item No support for parameter file

=head1 CAUTION

Whilst you are calling the method C<execute()>, Oracle::Sqlldr is calling C<sqlldr> and displaying your user/pass to the world, or at least readable within C<`ps -deaf`>.

=head1 PERFORMANCE

=over

=item Bulk uploads will be faster if indexes are disabled and built after loading.

=item Disable Archiving, only do this if the DBA is at lunch.

=item Use fixed width data - unsupported.

=head1 EXAMPLE

use strict;
use warnings;
use Oracle::Sqlldr;

my $sqlldr = Oracle::Sqlldr->new(-db=>'thedb');

$sqlldr->warnings(-status=>'on');
$sqlldr->table(-name=>'animals');
$sqlldr->user(-name=>'scott');
$sqlldr->pass(-word=>'tiger');
$sqlldr->fieldsterminatedby(-symbol=>',');
$sqlldr->datafile(-file=>'animals.dat');
$sqlldr->controlfile(-file=>'animals.ctr');
$sqlldr->logfile(-file=>'animals.log');
$sqlldr->badfile(-file=>'animals.bad');
$sqlldr->discardfile(-file=>'animals.dis');

$sqlldr->create_controlfile() or die "cannot create the controlfile";
$sqlldr->write_controlfile() or die "cannot write controlfile";

my $r = $sqlldr->execute() or die "cannot execute sqlldr";

print "output from Oracle::Sqlldr: $r\n";

=head1 AUTHOR

Andrew McGregor, E<lt>mcgregor@cpan.orgE<gt>

=head1 SEE ALSO

C<Oracle::SQLLoader>

=head1 METHODS

=cut



require 5.006;
use strict;
use warnings;
use Carp qw/carp croak/;
use DBI;
use vars qw /$VERSION $bin/;

#require Exporter;

#our @ISA = qw(Exporter);

# This allows declaration       use Oracle::Sqlldr ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
#our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
#our @EXPORT = qw( );

$VERSION = '0.13';

$bin = 'sqlldr';


=item new

constructor to create a new instance of the Sqlldr.

C<my $sqlldr = Oracle->Sqlldr;>

C<my $sqlldr = Oracle->Sqlldr(-warnings=>'on');>

C<my $sqlldr = Oracle->Sqlldr(-warnings           => 'off',>
C<                            -parameterfile      => 'parameterfile.par',>
C<                            -datafile           => 'datafile.csv',>
C<                            -controlfile        => 'controlfile.ctr',>
C<                            -logfile            => 'logfile.log',>
C<                            -discardfile        => 'discardfile.dis',>
C<                            -badfile            => 'badfile.bad',>
C<                            -table              => 'table_name',>
C<                            -fieldsterminatedby => ',',>
C<                            -user               => 'scott',>
C<                            -pass               => 'tiger',>
C<                            -db                 => 'foo',>
C<                           );>

=cut

sub new {
    my ($pkg, %params) = @_;
    my $self = {};

    # check for any critical errors before instantiation

    ## TODO
    ## perhaps this should be in the Makefile.PL to stop
    ## MS users installing it only to find out they are
    ## unsupported.
    if ($^O =~ /win32/i) {
        croak __PACKAGE__."::new: WIN32 is unsupported.";
    }

    $self->{CSTR} = 'DBI:Oracle:';

    # instantiate the object
    bless($self, $pkg);

    # check for any none critical warnings

    # enable or disable warnings depending on signature
    ## TODO
    ## warnings should be in a more generic package 
    ## which can he inherited by us.
    ## TODO
    ## when I call an external facing method
    ## that expects its first parameter to be $self
    ## how do I call it from within the object without
    ## explicitly typing $self every time?
    warnings($self, -status=>$params{-warnings}) if $params{-warnings};

    # check for $ORACLE_HOME, if warnings are enabled
    carp "env \$ORACLE_HOME is not defined"
        if not $ENV{ORACLE_HOME} and $self->warnings();

    # check for $ORACLE_BASE, if warnings are enabled
    carp "env \$ORACLE_BASE is not defined"
        if not $ENV{ORACLE_BASE} and $self->warnings();

    parameterfile($self, -file=>$params{-parameterfile});

    datafile($self, -file=>$params{-datafile});

    controlfile($self, -file=>$params{-controlfile});

    logfile($self, -file=>$params{-logfile});

    discardfile($self, -file=>$params{-discardfile});

    badfile($self, -file=>$params{-badfile});

    user($self, -name=>$params{-user});

    pass($self, -word=>$params{-pass});

    table($self, -name=>$params{-table});

    db($self, -name=>$params{-db});

    if ($params{-fieldsterminatedby}) {
        fieldsterminatedby($self, -symbol=>$params{-fieldsterminatedby});
    }
    else {
        carp "fixed format records are unsupported, specify a field terminator."
            if $self->warnings();
    }

    return $self;
}




=item warnings

turn warnings on or or off
return status, 1 = on, 0 = off

C<my $status = $sqlldr->warnings(-status=>'on');>
C<my $status = $sqlldr->warnings(-status=>'off');>
C<             $sqlldr->warnings(-status=>1);>
C<my $status = $sqlldr->warnings(-status=>0);>
C<my $status = $sqlldr->warnings();>

=cut

sub warnings {
    my ($self, %params) = @_;

    if (defined $params{-status}) {

        no warnings;

        if ($params{-status} > 0 or $params{-status} =~ /on/i) {
            warnings_on($self);
        }
        elsif ($params{-status} == 0 or $params{-status} =~ /off/i) {
            warnings_off($self);
        }

    }

    return $self->{WARNINGS};
}




=item warnings_on

turn warnings on

C<$sqlldr->warnings_on();>

=cut

sub warnings_on {
    my ($self) = @_;
    $self->{WARNINGS} = 1;
}




=item warnings_off

turn warnings off

C<$sqlldr->warnings_off();>

=cut

sub warnings_off {
    my ($self) = @_;
    $self->{WARNINGS} = 0;
}




=item logfile

set the logfile to load.

C<$sqlldr->logfile(-file=>'load.log');>

SQL*Loader writes messages to this log file during loading.

=cut

sub logfile {
    my ($self, %params) = @_;

    if ($params{-file}) {
        $self->{LOGFILE} = $params{-file};
    }

    return $self->{LOGFILE};
}




=item discardfile

set the discardfile to load.

C<$sqlldr->discardfile(-file=>'load.dis');>

SQL*Loader writes discarded rows to this discard file during loading.

=cut

sub discardfile {
    my ($self, %params) = @_;

    if ($params{-file}) {
        $self->{DISCARDFILE} = $params{-file};
    }

    return $self->{DISCARDFILE};
}




=item badfile

set the badfile to load.

C<$sqlldr->badfile(-file=>'load.bad');>

SQL*Loader writes bad rows to this bad file during loading.

=cut

sub badfile {
    my ($self, %params) = @_;

    if ($params{-file}) {
        $self->{BADFILE} = $params{-file};
    }

    return $self->{BADFILE};
}




=item controlfile

set the controlfile to load.

C<$sqlldr->controlfile(-file=>'controlfile.ctr');>

=cut

sub controlfile {
    my ($self, %params) = @_;

    if ($params{-file}) {
        $self->{CONTROLFILE} = $params{-file};
    }

    return $self->{CONTROLFILE};
}




=item datafile

set the datafile to load.

C<$sqlldr->datafile(-file=>'datafile.ctr');>

=cut

sub datafile {
    my ($self, %params) = @_;

    if ($params{-file}) {
        $self->{DATAFILE} = $params{-file};

        unless (-f $self->{DATAFILE}) {
            carp "datafile ", $self->{DATAFILE}, " does not exist therefore cannot be loaded"
                if $self->warnings;
        }

    }

    return $self->{DATAFILE};
}




=item parameterfile

set the parameterfile to load.

C<$sqlldr->parameterfile(-file=>'parameterfile.dat');>

=cut

sub parameterfile {
    my ($self, %params) = @_;

    ## TODO support this method!

    carp __PACKAGE__."::parameterfile: this method is not yet supported";
    return 0;


    if ($params{-file}) {
        $self->{PARAMETERFILE} = $params{-file};
    }

    return $self->{PARAMETERFILE};
}




=item table

set the table to load into.

C<$sqlldr->table(-name=>'table_name');>

=cut

sub table {
    my ($self, %params) = @_;

    if ($params{-name}) {
        $self->{TABLE} = $params{-name};
    }

    return $self->{TABLE};
}




=item fieldsterminatedby

set the field to terminate the datafile.

C<$sqlldr->fieldsterminatedby(-symbol=>',');>
C<my $t = $sqlldr->fieldsterminatedby;>

if you don't set this or pass null assumes 
records are fixed format .. unsupported :(

=cut

sub fieldsterminatedby {
    my ($self, %params) = @_;

    if ($params{-symbol}) {
        $self->{FIELDSTERMINATEDBY} = $params{-symbol};
    }

    return $self->{FIELDSTERMINATEDBY};
}




=item pass

set or get the password

C<$sqlldr->pass(-word=>'tiger');>
C<my $pass = $sqlldr->pass;>

=cut

sub pass {
    my ($self, %params) = @_;

    if ($params{-word}) {
        $self->{PASS} = $params{-word};
    }

    return $self->{PASS};
}




=item user

set or get the username

C<$sqlldr->user(-name=>'scott');>
C<my $user = $sqlldr->user;>

=cut

sub user {
    my ($self, %params) = @_;

    if ($params{-name}) {
        $self->{USER} = $params{-name};
    }

    return $self->{USER};
}




=item cstr

get or set the connection string used

C<my $user = $sqlldr->cstr;>

=cut

sub cstr {
    my ($self, %params) = @_;

    if ($params{-name}) {
        $self->{USER} = $params{-name};
    }

    return $self->{CSTR};
}




=item db

set or get the db

C<$sqlldr->db(-name=>'foo:');>
C<my $user = $sqlldr->db;>

=cut

sub db {
    my ($self, %params) = @_;

    if ($params{-name}) {
        $self->{DB} = $params{-name};
    }

    return $self->{DB};
}



=item create_controlfile

creates the controlfile from DB

=cut

sub create_controlfile {
    my ($self, %params, $controlfile) = @_;

    eval {

        my $datafile = $self->datafile
            or die "datafile is not defined";
        my $table = $self->table 
            or die "table name is not defined";
        my $user = $self->user 
            or die "user is not defined";
        my $pass = $self->pass 
            or die "pass is not defined";
        my $cstr = $self->cstr 
            or die "cstr is not defined";
        my $db = $self->db 
            or die "db is not defined";
        my $fieldsterminatedby = $self->fieldsterminatedby 
            or die "fields terminated by is not defined";
    
        my $dbh = DBI->connect($self->cstr . $db, $user, $pass)
            or die "cannot connect to DB";
    
## TODO handle fields terminated

## TODO get some SQL guru to explain this code

## TODO give credit to SQL author
## http://www.oracleutilities.com/OSUtil/sqlldr.html

        my $SQL1 = <<__SQL1__;
select 'LOAD DATA' || chr(10) ||
       'INFILE ''$datafile''' || chr(10) ||
       'INTO TABLE '|| table_name || chr(10) ||
       'FIELDS TERMINATED BY '','''||chr(10) ||
       'TRAILING NULLCOLS' || chr(10) || '('
from   user_tables
where  table_name = upper ('$table')
__SQL1__

        my $SQL2 = <<__SQL2__;
select decode (rownum, 1, '   ', ' , ') ||
       rpad (column_name, 33, ' ')      ||
       decode (data_type,
           'VARCHAR2', 'CHAR NULLIF ('||column_name||'=BLANKS)', 
           'FLOAT',    'DECIMAL EXTERNAL NULLIF('||column_name||'=BLANKS)',
           'NUMBER',   decode (data_precision, 0, 
                       'INTEGER EXTERNAL NULLIF ('||column_name||
                       '=BLANKS)', decode (data_scale, 0, 
                       'INTEGER EXTERNAL NULLIF ('||
                       column_name||'=BLANKS)', 
                       'DECIMAL EXTERNAL NULLIF ('||
                       column_name||'=BLANKS)')), 
           'DATE',     'DATE "DD/MM/YYYY" NULLIF ('||column_name||'=BLANKS)', null) 
from   user_tab_columns 
where  table_name = upper ('$table') 
order  by column_id
__SQL2__

        my $SQL3 = <<__SQL3__;
select ')'
from dual
__SQL3__

        ## TODO
        ## The table must exist!!

        my $sth1 = $dbh->prepare($SQL1) or die "cannot prepare sql1: $!\n$SQL1";
        my $sth2 = $dbh->prepare($SQL2) or die "cannot prepare sql2: $!\n$SQL2";
        my $sth3 = $dbh->prepare($SQL3) or die "cannot prepare sql3: $!\n$SQL3";

        $sth1->execute() or die "cannot execute sth1: $!\n$SQL1";
        $sth2->execute() or die "cannot execute sth2: $!\n$SQL2";
        $sth3->execute() or die "cannot execute sth3: $!\n$SQL3";

        $controlfile .= $sth1->fetchrow();

        while (my $col = $sth2->fetchrow()) {
            $controlfile .= $col;
        }

        $controlfile .= $sth3->fetchrow();

        $self->{CONTROL} = "$controlfile\n";

        $sth1->finish();
        $sth2->finish();
        $sth3->finish();

        $dbh->disconnect();

    }; if ($@) {
        carp $@;
        return undef;
    } else { return $self->{CONTROL} }

}




=item write_controlfile

writes the control file to disk

=cut

sub write_controlfile {
    my ($self, %params) = @_;

    eval {
        my $controlfile = $self->controlfile
            or die "controlfile is not defined";

        open (my $fh, ">$self->{CONTROLFILE}")
            or die "cannot open " . $self->{CONTROLFILE} . ": $!";

        print $fh $self->{CONTROL};

        close $fh 
            or die "cannot close " . $self->{CONTROLFILE} . ": $!";

    }; if($@) {
        carp $@;
        return undef;
    } else { return $self->{CONTROL} }

}




=item execute

call and execute the sqlldr utility.

=cut

sub execute {
    my ($self, %params, $return) = @_;

    eval {

        ## TODO could this be an internal method?

        my $user = $self->user 
            or die "user is not defined";			# -- ORACLE username
        my $table = $self->table 
            or die "table is not defined";			# -- table name
        my $fieldsterminatedby = $self->fieldsterminatedby 
            or die "fields terminated by is not defined";	# -- FIELDSTERMINATEDBY
        my $controlfile = $self->controlfile 
            or die "control file by is not defined";		# -- Control file name
        my $logfile = $self->logfile
            or die "log file is not defined";			# -- Log file name
        my $badfile = $self->badfile 
            or die "bad file is not defined";			# -- Bad file name
        my $datafile = $self->datafile
            or die "datafile does not exist";			# -- Data file name
        my $discardfile = $self->discardfile 
            or die "discard file is not defined";		# -- Discard file name
## TODO
## see sub param
#        my $parameterfile = $self->parameterfile 
#            or die "parameter file name is not defined";	# -- parameter specifications file name

        ## TODO WARNING
        ## The user's password can be snooped on with `ps`
        ## give the user an option to key their password on demand
        my $pass = $self->pass 
            or die "user is not defined";			# -- ORACLE password

=for TODO support these..

discardmax -- Number of discards to allow          (Default all)
      skip -- Number of logical records to skip    (Default 0)
      load -- Number of logical records to load    (Default all)
    errors -- Number of errors to allow            (Default 50)
      rows -- Number of rows in conventional path bind array or between direct path data saves
               (Default: Conventional path 64, Direct path all)
  bindsize -- Size of conventional path bind array in bytes  (Default 65536)
    silent -- Suppress messages during run (header,feedback,errors,discards,partitions)
    direct -- use direct path                      (Default FALSE)
  parallel -- do parallel load                     (Default FALSE)
      file -- File to allocate extents from
skip_unusable_indexes -- disallow/allow unusable indexes or index partitions  (Default FALSE)
skip_index_maintenance -- do not maintain indexes, mark affected indexes as unusable  (Default FALSE)
commit_discontinued -- commit loaded rows when load is discontinued  (Default FALSE)
  readsize -- Size of Read buffer                  (Default 1048576)

=cut

        # Usage: SQLLOAD keyword=value [,keyword=value,...]
        my $cmd = "$ENV{ORACLE_HOME}/bin/$bin userid=$user/$pass control=$controlfile log=$logfile bad=$badfile"
                . " data=$datafile discard=$discardfile";

## TODO
#        my $cmd = "$ENV{ORACLE_HOME}/bin/$bin userid=$user control=$controlfile log=$logfile bad=$badfile"
#                . " data=$datafile discard=$discardfile parfile=$parameterfile";

        $return = `$cmd`;

    }; if ($@) {
        croak __PACKAGE__."::execute: $@.";
    } else {
        return $return;
    }

}




=item cleanup

delete parameter, control, bad, discard and log files.

=cut

sub cleanup {
    my $self = shift;

    ## TODO

    unlink $self->{CONTROLFILE} if $self->{CONTROLFILE};

}




=item DESTROY

cleanup this instance

=cut

# TODO
# DESTROY is currently called once per instance
# but do I want it called once after the final instance
# is destroyed?

sub DESTROY {
    my $self = shift;
}




=head1 SQL*Loader Options

SQL*Loader provides the following options, which can be specified either on the command line or within a parameter file:   

 

·     bad . A file that is created when at least one record from the input file is rejected.  The rejected data records are placed in this file.  A record could be rejected for many reasons, including a non-unique key or a required column being null.  

·     bindsize .  [256000] The size of the bind array in bytes.  

·     columnarrayrows . [5000] Specifies the number of rows to allocate for direct path column arrays.

·     control . The name of the control file.  This file specifies the format of the data to be loaded.  

·     data . The name of the file that contains the data to load.  

·     direct . [FALSE] Specifies whether or not to use a direct path load or conventional.   

·     discard . The name of the file that contains the discarded rows.  Discarded rows are those that fail the WHEN clause condition when selectively loading records. 

·     discardmax . [ALL] The maximum number of discards to allow. 

·     errors . [50] The number of errors to allow on the load.  

·     external_table . [NOT_USED] Determines whether or not any data will be loaded using external tables.  The other valid options include GENERATE_ONLY and EXECUTE.     

·     file . Used only with parallel loads, this parameter specifies the file to allocate extents from.

·     load . [ALL] The number of logical records to load.   

·     log . The name of the file used by SQL*Loader to log results.  

·     multithreading . The default is TRUE on multiple CPU systems and FALSE on single CPU systems.  

·     parfile . [Y] The name of the file that contains the parameter options for SQL*Loader.  

·     parallel . [FALSE] Specifies a filename that contains index creation statements. 

·     readsize . The size of the buffer used by SQL*Loader when reading data from the input file.  This value should match that of bindsize.  

·     resumable . [N] Enables and disables resumable space allocation.  When .Y., the parameters resumable_name and resumable_timeout are utilized.  

·     resumable_name . User defined string that helps identify a resumable statement that has been suspended.  This parameter is ignored unless resumable = Y. 

·     resumable_timeout . [7200 seconds] The time period in which an error must be fixed.  This parameter is ignored unless resumable = Y. 

·     rows . [64] The number of rows to load before a commit is issued (conventional path only).  For direct path loads, rows are the number of rows to read from the data file before saving the data in the datafiles.  

·     silent . Suppress errors during data load.  A value of ALL will suppress all load messages.  Other options include DISCARDS, ERRORS, FEEDBACK, HEADER, and PARTITIONS. 

·     skip . [0] Allows the skipping of the specified number of logical records.  

·     skip_unusable_indexes . [FALSE] Determines whether SQL*Loader skips the building of indexes that are in an unusable state. 

·     skip_index_maintenance . [FALSE] Stops index maintenance for direct path loads only.  

·     streamsize . [256000] Specifies the size of direct path streams in bytes.   

·     userid . The Oracle username and password.



=cut




1;
__END__
