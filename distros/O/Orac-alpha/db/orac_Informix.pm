use strict;

#use pretty_print; # for serious debugging

package orac_Informix;
require orac_Base;
@orac_Informix::ISA = qw{orac_Base};

#0 = CHAR
#1 = SMALLINT
#2 = INTEGER
#3 = FLOAT
#4 = SMALLFLOAT
#5 = DECIMAL
#6 = SERIAL
#7 = DATE
#8 = MONEY
#9 = n/a
#10 = DATETIME
#11 = BYTE
#12 = TEXT
#13 = VARCHAR
#14 = INTERVAL
#15 = NCHAR
#16 = NVARCHAR
my @type_names = qw( CHAR SMALLINT INTEGER FLOAT SMALLFLOAT DECIMAL SERIAL
                     DATE MONEY not_used DATETIME BYTE TEXT VARCHAR INTERVAL
                     NCHAR NVARCHAR); 
#YEAR 0
#MONTH 2
#DAY 4
#HOUR 6
#MINUTE 8
#SECOND 10
#FRACTION(1) 11
#FRACTION(2) 12
#FRACTION(3) 13
#FRACTION(4) 14
#FRACTION(5) 15
my @date_names = qw/ YEAR not_used MONTH not_used DAY not_used HOUR not_used
                     MINUTE not_used SECOND FRACTION(1) FRACTION(2)
                     FRACTION(3) FRACTION(4) FRACTION(5) /;

=head1 NAME

orac_Informix.pm - the Informix module to the Orac tool

=head1 DESCRIPTION

This code is a database object that can be created by the Orac tool.
It inherits from orac_Base, which has all the basic data and methods.
Some of those are called from here, some are overridden, most are
inherited and used as is.

=head1 PUBLIC METHODS

=pod   # please keep this sorted

 &new()
 &init1()
 &init2()

=cut

=head2 new

This method overrides orac_Base's; well, actually we call it to set
ourselves up, but then we do set Informix specific variables.
We return the new object instance, just like we're supose to do.

=cut

sub new
{
    print STDERR "creating orac_Informix!\n" if ($main::debug > 0);

    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = orac_Base->new("Informix", @_);

    bless($self, $class);
    # can add own instance vars:  $self->{field}
    $self->{dont_need_sys} = 1;
    $self->{dont_need_ps} = 1;
    return $self;
}

=head2 init1

This methode overrides the "do nothing" version in orac_Base.
It's job is to do whatever we need to do just before trying to connect.
We return nothing.

=cut

sub init1
{
    print STDERR "init1_orac_Informix()\n" if ($main::debug > 0);
    my $self = shift;

    # Place here whatever environmental variables are needed
    # for dbi:Informix, eg (for oracle):
    # $ENV{TWO_TASK} = $v_db;
    #
    # the user needs to have:
    #   INFORMIXDIR
    #   INFORMIXSERVER
    #   ONCONFIG
    # hmm, don't know what to do if we don't have these, can we croak to a 
    # dialog?
    # i have no way to guess values...

    # also useful, but optional
    #   DBTERM
    #   DBDATE
    $ENV{DBTERM} = "vt100" if (!exists($ENV{DBTERM}));
    $ENV{DBDATE} = "y4md0" if (!exists($ENV{DBDATE}));
}

=head2 init1

This methode overrides the "do nothing" version in orac_Base.
It's job is to do whatever we need to do just after successfully
connecting to the database.  In our case, we always ChopBlanks.
We return nothing.

=cut

sub init2
{
    my $self = shift;
    print STDERR "init2_orac_Informix()\n" if ($main::debug > 0);

    # Remove trailing blanks.  Doesn't everyone want to do this?
    $self->{Database_conn}->{ChopBlanks}=1;
}

############# Database dependent code functions below here #####################

=head1 SEMI-PUBLIC METHODS

These should only be called by main:: functions, like the menu functions,
or by ourselves, obviously. :-)

=cut

=head2 onstat_databases

Show the list of the databases, and info about them.
No args, no return value.

=cut

sub onstat_databases
{
    my $self = shift;
    $self->f_clr();
    $self->show_sql("Databases", "1");
}

=head2 onstat_dbspaces

Show the list of DBSpaces, and info about them.
No args, no return value.

=cut

sub onstat_dbspaces
{
    my $self = shift;
    $self->f_clr();
    $self->show_sql("DBSpaces", "1");
}

=head2 onstat_chunks

Show the list of DB chunks, and info about them.
No args, no return value.

=cut

sub onstat_chunks
{
    my $self = shift;
    $self->f_clr();
    $self->show_sql("Chunks", "1");
}

=head2 onstat_onconfig_params

Show the current $ONCONFIG file.
No args, no return value.

=cut

sub onstat_onconfig_params
{
    my $self = shift;
    $self->f_clr();
    $self->{Text_var}->insert('end', $self->gf_str("$ENV{INFORMIXDIR}/etc/$ENV{ONCONFIG}"));
}

# show the extents being used & check for errors
#sub oncheck_extents
#{
#    # Do your stuff
#    $self->show_sql("Extents", "1");
#    # IT MAY not BE POSSIBLE TO DO THIS VIA THE SMI TABLES!!!
#    execute_and_display("$ENV{INFORMIXDIR}/bin/oncheck -pe ", 1);
#}
# show physical & logical log status
#sub onstat_log_rep
#{
#    my $self = shift;
#    # Do your stuff
#    $self->show_sql("LogRpt", "1");
#    # IT MAY not BE POSSIBLE TO DO THIS VIA THE SMI TABLES!!!
#    execute_and_display("$ENV{INFORMIXDIR}/bin/oninit -l ", 0);
#}
# display a logical log [postponed]
#sub onlog_log
#{
#    # Do your stuff
#    $self->show_sql("ShowLog", "1");
#}
#sub dbschema_procs
#{
#    # Do your stuff
#    $self->show_sql("Procedures", "1");
#}
#sub dbschema_proc_list
#{
#    # Do your stuff
#    $self->show_sql("ProcedureBody", "1");
#}

=head2 dbschema_syns

Show the synonums for all tables.
No args, no return value.

=cut

sub dbschema_syns
{
    my $self = shift;
    $self->f_clr();
    $self->show_sql("Synonyms", "1");
}

=head2 dbschema_grants

Show the grants on this database.
No args, no return value.

=cut

# (kevin: restart here for getting sql to work)
sub dbschema_grants
{
    my $self = shift;
    $self->f_clr();
    $self->show_sql("Grants", "1");
}

#kevin restart here
=head2 dbschema_indices

Show the list of the indicies for all tables, and info about them.
No args, no return value.

NOT IMPLEMENTED YET!

=cut

sub dbschema_indices
{
    my $self = shift;
    $self->f_clr();
    $self->show_sql("Indicies", "1");
}

=head2 dbschema_schema

Show the schema for the databases.
No args, no return value.

NOT IMPLEMENTED YET!

=cut

sub dbschema_schema
{
    my $self = shift;
    $self->f_clr();
    $self->show_sql("Schema", "1");

    # IN THEORY, IT SHOULD BE POSSIBLE TO DO THIS VIA THE SMI TABLES, BUT HOW?!!!
    #execute_and_display("$ENV{INFORMIXDIR}/bin/dbschema -d ", 1);
}

=head2 onstat_threads

Show the application threads running in the database.
No args, no return value.

NOT IMPLEMENTED YET!

=cut

sub onstat_threads
{
    my $self = shift;
    $self->f_clr();
    $self->show_sql("Threads", "1");
}

=head2 onstat_curr_sql

Show the current SQL statements running in the database.
No args, no return value.

NOT IMPLEMENTED YET!

=cut

sub onstat_curr_sql
{
    # Do your stuff
    #$self->show_sql("CurrSQL", "1");
    # IN THEORY, IT SHOULD BE POSSIBLE TO DO THIS VIA THE SMI TABLES, BUT HOW?!!!
    #execute_and_display("$ENV{INFORMIXDIR}/bin/onstat -u ", 0);
}

=head2 onstat_blobs

Show the list of blob fields, and info about them.
No args, no return value.

=cut

sub onstat_blobs
{
    my $self = shift;
    $self->f_clr();
    $self->show_sql("Blobs", "1");
}

#sub finderr_num
#{
#    # Do your stuff
#    # IT IS not POSSIBLE TO DO THIS VIA THE SMI TABLES!!!
#    execute_and_display("$ENV{INFORMIXDIR}/bin/dbschema -d ", 1);
#}

=head2 onstat_io_profile

Show the I/O going on in the database.
No args, no return value.

=cut

sub onstat_io_profile
{
    my $self = shift;
    $self->f_clr();
    $self->live_update("IOProfile", 1, $main::lg{oi_io_profile_title});
}

=head2 onstat_locks_held

Show the list of locks being held, and info about them, by:
database, owner, table.
It calls live_update() until the user hits STOP.
No args, no return value.

=cut

sub onstat_locks_held
{
    my $self = shift;
    $self->f_clr();
    $self->live_update("Locks", 1, $main::lg{locks_held});
}

=head2 onstat_tblspace_info

Show what's going on in the table space arena.
It calls live_update() until the user hits STOP.
No args, no return value.

=cut

sub onstat_tblspace_info
{
    my $self = shift;
    $self->f_clr();
    $self->live_update("TblSpace", 1, $main::lg{oi_tblspace_info});
}

=head2 onstat_sessions

Show who's connected?
It calls live_update() until the user hits STOP.
No args, no return value.

=cut

sub onstat_sessions
{
    my $self = shift;
    $self->f_clr();
    $self->live_update("Sessions", 1, $main::lg{oi_sessions});
}

###############################################################################
# Generic support functions
###############################################################################

=head1 PRIVATE METHODS

These should only be called ourself, they are support functions.
There are currently none, or at least none that care to tell anyone about. :-)

=cut

=head2 post_process_sql

This subroutine is called with the results from show_sql() (or live_update)
to allow DB modules to "post process" the output, if required,
before it is analyzed to be shown.
This is useful for turning numeric flags into words, and other such DB
dependent things.

=cut

sub post_process_sql
{
    my ($self, $sql_name, $sql_num, $tar, $r_bindees) = @_;
#print STDERR "post_process_sql: $sql_name $sql_num\n";
    my $key = "$sql_name$sql_num";
    my %care = ( "Sessions1" => 1,
                 "Grants1" => 1,
                 "Tables3" => 1,
                 "TableInfo2" => 1,
                 "Blobs1" => 1,
               );
    if ($care{$key})
    {
        my $j;
        for ($j=0 ; $j < @{$tar} ; $j++)
        {
            if ($key eq "Sessions1")
            {
                # I may not want all of these later, but show them all for now.
                # Put the the important ones in a cap.
                my $state = $tar->[$j]->[7];
                $tar->[$j]->[7] =
                    ($state & 0x00000001 ? "u" : "-") . # user structure in use
                    ($state & 0x00000002 ? "l" : "-") . # waiting for a latch
                    ($state & 0x00000004 ? "c" : "-") . # waiting for a clock 
                    ($state & 0x00000008 ? "B" : "-") . # waiting for a buffer
                    ($state & 0x00000010 ? "C" : "-") . # waiting for a checkpoint
                    ($state & 0x00000020 ? "r" : "-") . # in a read RSAM call
                    ($state & 0x00000040 ? "l" : "-") . # writing logical-log file to backup tape
                    ($state & 0x00000080 ? "o" : "-") . # ON-Monitor (UNIX-only)
                    ($state & 0x00000100 ? "c" : "-") . # in a critical section
                    ($state & 0x00000200 ? "d" : "-") . # special daemon
                    ($state & 0x00000400 ? "a" : "-") . # archiving
                    ($state & 0x00000800 ? "c" : "-") . # clean up dead processes
                    ($state & 0x00001000 ? "w" : "-") . # waiting for write of log buffer
                    ($state & 0x00002000 ? "f" : "-") . # special buffer-flushing thread
                    ($state & 0x00004000 ? "r" : "-") . # remote database server
                    ($state & 0x00008000 ? "D" : "-") . # deadlock timeout used to set RS_timeout
                    ($state & 0x00010000 ? "L" : "-") . # regular lock timeout
                    ($state & 0x00040000 ? "W" : "-") . # waiting for a transaction
                    ($state & 0x00080000 ? "p" : "-") . # primary thread for a session
                    ($state & 0x00100000 ? "i" : "-") . # thread for building indexes
                    ($state & 0x00200000 ? "b" : "-")   # btree cleaner thread
            }
            elsif ($key eq "Grants1")
            {
                my $val = $tar->[$j]->[1];
                if    ($val eq "D") { $val = "dba"; }
                elsif ($val eq "C") { $val = "connect"; }
                elsif ($val eq "R") { $val = "resource"; }
                elsif ($val eq "G") { $val = "role"; }
                $tar->[$j]->[1] = $val;
            }
            elsif ($key eq "Tables3")
            {
                my $val = $tar->[0]->[3] % 256;
                # fix col_type
                $tar->[0]->[3] = col_type($tar->[0]->[3]);
                # fix DECIMAL fields
                if ($type_names[$val] eq "DECIMAL")
                {
                    $val = $tar->[0]->[4];
                    $tar->[0]->[4] = sprintf("prec:%d  scale:%d", int($val/256), ($val%256)); 
                }
                # fix TIME fields
                elsif (($type_names[$val] eq "DATETIME") ||
                       ($type_names[$val] eq "INTERVAL"))
                {
                    $val = $tar->[0]->[4];
                    my $len = int($val/256);
                    $val -= $len*256;
                    my $lqv = int($val/16);
                    my $sqv = int($val%16);
                    $tar->[0]->[4] = "length:$len  largest:$date_names[$lqv]  smallest:$date_names[$sqv]";
                }
            }
            elsif ($key eq "TableInfo2")
            {
                my $val = $tar->[$j]->[7];
                my $count = 0;
                ($count) = $self->do_query_fetch1("select count(*) from $r_bindees->[0]");
                $tar->[$j]->[7] = $count;
                $tar->[$j]->[6] = col_type($tar->[$j]->[6]);
            }
            elsif ($key eq "Blobs1")
            {
                $tar->[$j]->[6] = col_type($tar->[$j]->[6]);
            }
        }
    }
    return;
}

sub col_type
{
    my $val = $_[0];
    my $nullable = "";
    if ($val > 255)
    {
        $nullable = "  (not null)";
        $val %= 256;
    }
    return "$type_names[$val]$nullable";
}

###############################################################################
# Experimental functions
###############################################################################

=head1 EXPERIMENTAL METHODS

These functions are ones that I'm developing and should not be called
by anyone else, unless you like living dangerously. :-)  It is hoped that
one day, they'll be good enough to move into orac_Base.

 None for now...they've been moved!

# Andy, you can move this if you want. (i.e. feel brave :-)

=cut

###############################################################################
1;
# vi: set sw=4 ts=4 et:
