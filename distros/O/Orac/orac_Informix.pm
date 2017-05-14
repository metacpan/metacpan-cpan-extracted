use strict;

#use pretty_print; # for serious debugging

package orac_Informix;
require orac_Base;
@orac_Informix::ISA = qw{orac_Base};


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
    # Do your stuff
    $self->show_sql($self->f_str("Databases", "1"));
}

=head2 onstat_dbspaces

Show the list of DBSpaces, and info about them.
No args, no return value.

=cut

sub onstat_dbspaces
{
    my $self = shift;
    # Do your stuff
    $self->show_sql($self->f_str("DBSpaces", "1"));
}

=head2 onstat_chunks

Show the list of DB chunks, and info about them.
No args, no return value.

=cut

sub onstat_chunks
{
    my $self = shift;
    # Do your stuff
    $self->show_sql($self->f_str("Chunks", "1"));
}

=head2 onstat_onconfig_params

Show the current $ONCONFIG file.
No args, no return value.

=cut

sub onstat_onconfig_params
{
    my $self = shift;
    # Do your stuff
    $self->{Text_var}->insert('end', $self->gf_str("$ENV{INFORMIXDIR}/etc/$ENV{ONCONFIG}"));
}

# show the extents being used & check for errors
#sub oncheck_extents
#{
#    # Do your stuff
#    $self->show_sql($self->f_str("Extents", "1"));
#    # IT MAY not BE POSSIBLE TO DO THIS VIA THE SMI TABLES!!!
#    execute_and_display("$ENV{INFORMIXDIR}/bin/oncheck -pe ", 1);
#}
# show physical & logical log status
#sub onstat_log_rep
#{
#    my $self = shift;
#    # Do your stuff
#    $self->show_sql($self->f_str("LogRpt", "1"));
#    # IT MAY not BE POSSIBLE TO DO THIS VIA THE SMI TABLES!!!
#    execute_and_display("$ENV{INFORMIXDIR}/bin/oninit -l ", 0);
#}
# display a logical log [postponed]
#sub onlog_log
#{
#    # Do your stuff
#    $self->show_sql($self->f_str("ShowLog", "1"));
#}
#sub dbschema_procs
#{
#    # Do your stuff
#    $self->show_sql($self->f_str("Procedures", "1"));
#}
#sub dbschema_proc_list
#{
#    # Do your stuff
#    $self->show_sql($self->f_str("ProcedureBody", "1"));
#}

=head2 dbschema_syns

Show the synonums for all tables.
No args, no return value.

=cut

sub dbschema_syns
{
    my $self = shift;
    # Do your stuff
    $self->show_sql($self->f_str("Synonyms", "1"));
}

=head2 dbschema_grants

Show the grants on this database.
No args, no return value.

NOT IMPLEMENTED YET!

=cut

# (kevin: restart here for getting sql to work)
sub dbschema_grants
{
    my $self = shift;
    # Do your stuff
    $self->show_sql($self->f_str("Grants", "1"));
}

=head2 dbschema_indices

Show the list of the indicies for all tables, and info about them.
No args, no return value.

NOT IMPLEMENTED YET!

=cut

sub dbschema_indices
{
    my $self = shift;
    # Do your stuff
    $self->show_sql($self->f_str("Indicies", "1"));
}

=head2 dbschema_schema

Show the schema for the databases.
No args, no return value.

NOT IMPLEMENTED YET!

=cut

sub dbschema_schema
{
    my $self = shift;
    # Do your stuff
    $self->show_sql($self->f_str("Schema", "1"));

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
    # Do your stuff
    $self->show_sql($self->f_str("Threads", "1"));
}

=head2 onstat_curr_sql

Show the current SQL statements running in the database.
No args, no return value.

NOT IMPLEMENTED YET!

=cut

sub onstat_curr_sql
{
    # Do your stuff
    #$self->show_sql($self->f_str("CurrSQL", "1"));
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
    # Do your stuff
    $self->show_sql($self->f_str("Blobs", "1"));
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
    # Do your stuff
    #$self->show_sql($self->f_str("IOProfile", "1"));
    $self->live_update($self->f_str("IOProfile", 1), $main::lg{oi_io_profile_title});
}

=head2 onstat_databases

Show the list of locks being held, and info about them.
No args, no return value.

NOT IMPLEMENTED YET!

=cut

sub onstat_locks_held
{
    my $self = shift;
    # Do your stuff
    $self->live_update($self->f_str("Locks", 1), $main::lg{locks_held});
}

###############################################################################
# Generic support functions
###############################################################################

=head1 PRIVATE METHODS

These should only be called ourself, they are support functions.
There are currently none, or at least none that care to tell anyone about. :-)

=cut

###############################################################################
# Experimental functions
###############################################################################

=head1 EXPERIMENTAL METHODS

These functions are ones that I'm developing and should not be called
by anyone else, unless you like living dangerously. :-)  It is hoped that
one day, they'll be good enough to move into orac_Base.

 &generic_hlist()
 &sql_file_exists()

Andy, you can move this if you want. (i.e. feel brave :-)

=cut

# variable to make generic_hlist() & friends work.
# they must be outside all functions!
my ($g_hlst, $g_hlvl, $gen_sep, $g_mw, $hlist);
my ($open_folder_bitmap,$closed_folder_bitmap,$file_bitmap);

=head2 generic_hlist

A function to produce a dialog screen, with HList widget
to show data--all generic.  It will go down as many levels as
there are SQL files, which must be numbered sequentially.

The function executes the SQL, and expects either a set of rows
with 1 column each, or 1 row with a set of columns.  It takes the
data, and makes each value an item in the HList widget.  If it
can find another level below this SQL script, it gives the item
a "folder" looking icon, else just a "file" looking icon.

Clicking on closed folders executes the next level of SQL, and
displays the results in the HList widget.  Icons on the new level
are assigned as above.  The value clicked on is parsed, split by
the separator char (ARG2) and those are the bind parameters to the SQL.
It is assumed the SQL will take those and do the right thing.  If
there is a mismatch on number of bind parameters, an error will
occurr. [Implementation question: should we search the SQL and
get the number of placeholders and send only that number of parameters?]

Clicking on a file, or bottom level item, currently does nothing.
[Implementation question: should we put a function to be called in
orac_Base here, and let the various modules override that if they
want to do more than just show items?]

 ARG1 = name of SQL, and title of dialog (e.g. Tables)
 ARG2 = separator character

There is no return value.

Note: this functoin calls orac_Show(), therefore, it does not really
return until the dialog is dismissed.

=cut

sub generic_hlist
{
   my $self = shift;
   ($g_hlst,$gen_sep) = @_;
   $g_hlvl = 1;

   my $save_cb = $self->{Database_conn}->{ChopBlanks};
   $g_mw = $self->{Main_window}->DialogBox(-title=>"$g_hlst", 
                                           -buttons => ["OK"]);
   $hlist = $g_mw->Scrolled('HList', 
                            '-drawbranch'     => 1, 
                            '-separator'      => $gen_sep,
                            '-indent'         => 50,
                            '-width'          => 80,
                            '-height'         => 20,
                            '-command'        => [ \&show_or_hide, $self ],
                           )->pack('-fill'   => 'both',
                                   '-expand' => 'both');

   $open_folder_bitmap = $g_mw->Bitmap(-file=>Tk->findINC('openfolder.xbm'));
   $closed_folder_bitmap = $g_mw->Bitmap(-file=>Tk->findINC('folder.xbm'));
   $file_bitmap = $g_mw->Bitmap(-file=>Tk->findINC('file.xbm'));

   my $cm = $self->f_str( $g_hlst ,'1');
   print STDERR "prepare1: $cm\n" if ($main::debug > 0);
   my $sth = $self->{Database_conn}->prepare( $cm )
             or die $self->{Database_conn}->errstr; 
   $sth->execute;
   
   my $bitmap = (sql_file_exists($self->{Database_type}, $g_hlst, 2)
                ? $closed_folder_bitmap
                : $file_bitmap);
   my @res;
   while (@res = $sth->fetchrow)
   {
      my $owner = $res[0];
      $hlist->add($owner,
                  -itemtype=>'imagetext',
                  -image=>$bitmap,
                  -text=>$owner);
   }
   $sth->finish;
   $g_mw->Show();
   $self->{Database_conn}->{ChopBlanks} = $save_cb;
}

=head2 show_or_hide

A support function of generic_hlist, DO NOT CALL DIRECTLY!!!

This is called when an entry is double-clicked.  It decides what to do.
Basically ripped off from the "Adv. Perl Prog." book. :-)

=cut

sub show_or_hide
{
   my $self = shift;
   my ($path) = @_;
   my $next_entry = $hlist->info('next', $path);
   #print STDERR "path=$path   next_entry=$next_entry\n" if ($main::debug > 0);

   # Is there another level?
   my $x = $path;
   $x =~ s/[^.$gen_sep]//ge;
   $g_hlvl = length($x) + 1;
   my $another_level = sql_file_exists($self->{Database_type},$g_hlst, $g_hlvl + 1);
   if (!$another_level)
   {
      #print STDERR "no more levels!\n";
      # change this next line if we desire
      # $self->bottom_level_in_generic_hlist_do_something_function();
      return;
   }

   # decide what to do
   if (!$next_entry || (index ($next_entry, "$path$gen_sep") == -1))
   {
      # No. open it
      #print "NO!\n";
      $hlist->entryconfigure($path, '-image' => $open_folder_bitmap);
      #add_contents($path, $parent);
      $self->add_contents($path);
   }
   else
   {
      # Yes. Close it by changing the icon, and deleting its subnode.
      #print "YES!\n";
      $hlist->entryconfigure($path, '-image' => $closed_folder_bitmap);
      $hlist->delete('offsprings', $path);
   }
}

=head2 add_contents

A support function of generic_hlist, DO NOT CALL DIRECTLY!!!

show_or_hide calls this when it needs to add new items.
Here is where the SQL is called.

=cut

sub add_contents
{
   my $self = shift;
   my ($path) = @_;

   #print STDERR "path=$path\n" if ($main::debug > 0);

   # is there another level down?
   my $x = $path;
   $x =~ s/[^.$gen_sep]//ge;
   $g_hlvl = length($x) + 2;
   my $bitmap = (sql_file_exists($self->{Database_type}, $g_hlst, $g_hlvl + 1)
                ? $closed_folder_bitmap
                : $file_bitmap);

   # get the SQL & execute!
   my $s = $self->f_str( $g_hlst, $g_hlvl);
   print STDERR "prepare2: $s ($path)\n" if ($main::debug > 0);
   my $sth = $self->{Database_conn}->prepare( $s ) or die $self->{Database_conn}->errstr; 

   # in theory this should work, COOL! I didn't know you could give split a variable
   # for the RE pattern. :-)
   my @params = split("\\$gen_sep", $path);

   # should we search $s for number of placeholders, and restrict @params to that number?
   $sth->execute(@params);

   # fetch the values
   my @res;
   while (@res = $sth->fetchrow)
   {
      # if the result has multiple columns, assume there will only be 1 row,
      # but we should display the columns as rows; but if there is only
      # 1 column, assume we'll get multiple rows/fetchs
      if ($#res > 0)
      {
         for (0 .. $#res)
         {
            my $gen_thing = "$path.$sth->{NAME}->[$_] = $res[$_]";
            $hlist->add($gen_thing,
                        -itemtype => 'imagetext',
                        -image    => $bitmap,
                        -text     => $gen_thing);
         }
         last;
      }
      else
      {
         my $gen_thing = "$path" . $gen_sep . "$res[0]";
         $hlist->add($gen_thing,
                     -itemtype => 'imagetext',
                     -image    => $bitmap,
                     -text     => $gen_thing);
      }
   }
   $sth->finish;
}

=head2 sql_file_exists

Does the SQL file exist?  This is normally used to find out if there is
another level down.

 ARG1 = database type
 ARG2 = SQL subroutine name (e.g. Tables, Views, ...)
 ARG3 = level number

It returns TRUE (non-zero) if the file exists and is readable, FALSE otherwise.

=cut

sub sql_file_exists
{
   my ($type, $sub, $number) = @_;
   my $file = sprintf("sql/%s/%s.%d.sql",$type,$sub,$number);

   #print STDERR "sql_file_exists: $file\n" if ($main::debug > 0);
   return (-r $file);
}
###############################################################################
1;
# vi: set sw=4 ts=4 et:
