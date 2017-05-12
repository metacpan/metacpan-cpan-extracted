package orac_Base;
use Exporter;
use Tk::Balloon;
use File::Basename;

=head1 NAME

orac_Base.pm - the base class for all database modules of the Orac tool

=head1 DESCRIPTION

This code is the base database object that can be created by the Orac tool.
It has all the basic data and methods.
Many of those are empty (do nothing) methods to be overridden, some are
inherited and used as is.

=head1 PUBLIC METHODS

=pod   # please keep this sorted

 &Dump()
 &about_orac()
 &add_contents()
 &balloon_bar()
 &create_button_bar()
 &create_balloon_bars()
 &do_a_generic()
 &db_check_error()
 &do_query()
 &do_query_fetch1()
 &do_query_fetch_all()
 &double_click_message()
 &f_clr()
 &f_str()
 &generic_hlist()
 &get_frm()
 &get_img()
 &get_lines()
 &gf_str()
 &init1()
 &init2()
 &live_update()
 &must_f_clr()
 &need_ps()
 &need_sys()
 &new()
 &orac_image_label()
 &post_process_sql()
 &print_lines()
 &print_stack()
 &see_gif()
 &see_plsql()
 &see_sql()
 &see_sql_but()
 &show_or_hide()
 &show_sql()
 &stop_live_update()
 &top_left_message()
 &top_right_ball_message()
 &window_exit_button()

=cut

@ISA = ('Exporter');
@EXPORT = qw( new Dump init1 init2 show_sql get_lines print_lines do_query
              do_query_fetch_all db_check_error print_stack live_update
              stop_live_update f_str get_frm f_clr must_f_clr see_plsql
              see_sql see_gif about_orac gf_str need_sys need_ps generic_hlist
              show_or_hide add_contents post_process_sql do_a_generic
              do_query_fetch1 create_button_bar window_exit_button
              double_click_message create_balloon_bars top_left_message
              balloon_bar orac_image_label see_sql_but get_img
            );
use strict;

my $g_typ;
my $v_yes_no_txt;
my %all_the_owners;

=head2 new

Start documenting here next time...

=cut

sub new
{
   #print STDERR "orac_Base::new\n" if ( $main::debug > 0 );
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $self  = {};

   bless($self, $class);

   # save off args...
   # or other encapsulated values, these do NOT inherit!

   $self->{Database_type} = $_[0];
   $self->{Main_window} = $_[1];
   $self->{Text_var} = $_[2];
   $self->{Version} = $_[3];
   $self->{dont_need_sys} = 0;
   $self->{dont_need_ps} = 0;

   return $self;
}

sub Dump
{
   # for debugging!

   my $self = shift;
   my $f;
   my $t = ref($self);

   if ( $main::debug > 0 ) {

      #print STDERR "Dump()\n";

      foreach $f (keys(%{$self}))
      {
         #print STDERR ("\t $f \t $self->{$f} \n");
      }
   }
}

sub init1 {
   my $self = shift;
}

sub init2 {
   my $self = shift;
}

sub set_db_handle
{
   my $self = shift;
   $self->{Database_conn} = $_[0];
}

###############################################################################
# Generic execute query & auto-format results & print...
###############################################################################

=head2 show_sql

Take some SQL, execute it, format the results in a matrix-like style,
and show it in the Text_var widget.

 ARG1 = the SQL file name (main part, e.g. "Threads")
 ARG2 = the SQL level number (e.g. 1)
 ARG3 = a title (optional, if not sent, the first 40 chars of the SQL is used)
 ARG4 = optional bind parameters array (note: array not ref to array)

There is no return value.

=cut

sub show_sql
{
   my $self = shift;

   my ($sql_name, $sql_num, $title, @bindees) = @_;
   my (@row, $id);

   # some sanity checking :-)
   unless ($sql_name) { return; }
   unless ($sql_num) { return; }
   my $sql = $self->f_str($sql_name, $sql_num);
   unless ($sql) { return; }

   # get patient id
   my ($r_lines, $r_format, $r_tlen, $r_names, $header) =
      $self->get_lines($sql_name, $sql_num, $sql, @bindees);
   my @lines = @{$r_lines};

   #@list = $tar->[0]; $list[0][0] $list[0][1] $list[0][2]
   #@names = @{$sth->{NAME}}
   #@prec = @{$sth->{PRECISION}}
   #@scal = @{$sth->{SCALE}}

   $title = substr($sql, 0, 40) if (!$title);
   $self->report_title($title);
   if ($#lines == -1)
   {
      $self->{Text_var}->insert('end', $main::lg{no_rows_found} . "\n");
   }
   else
   {
      if ( $sql_name eq 'steps' )
      {
        my $obj = DDL::Oracle->new(
                                   type => 'components',
                                   list => [[undef]],
                                 );
       my $text= $obj->create ;
  
       $self->{Text_var}->insert('end', "\n$text\n");
      }
      else
      {
        $self->print_lines($header, $r_lines, $r_tlen, $r_format);
        $self->see_plsql($sql);
      }
   }
}

# support func for show_sql

sub report_title
{
   my $self = shift;

   my($title) = @_;
   $self->{Text_var}->insert('end', "$main::lg{report} $title ($main::v_db " .
                                     $self->get_time(1) .
                                     "):\n"
                            );
}

sub get_time
{
   my $self = shift;

   my($time_type) = @_;

   # Pick up the system time

   my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

   # As everything has come out of the ctime 'struct', a few
   # of them go from zero upwards, so let's turn them into
   # more sensible real world values

   $mon = $mon + 1;
   $year = $year + 1900;
   $wday = $wday + 1;
   $yday = $yday + 1;

   my $time;
   if($time_type == 1){
      $time = sprintf("%02d:%02d:%02d %02d/%02d/%04d", $hour, $min, $sec,
                                                       $mday, $mon, $year);
   } else {
      $time = sprintf("%02d:%02d:%02d %02d/%02d/%04d", $hour, $min, $sec,
                                                       $mday, $mon, $year);
   }
   return $time;
}
sub get_lines
{
   my $self = shift;

   my ($sql_name, $sql_num, $param1, @bindees) = @_;

   my $sth;
   my $tar = $self->do_query_fetch_all( $param1, \$sth , @bindees);
   my @tlen;
   my @names = @{$sth->{NAME}};

   $self->post_process_sql($sql_name, $sql_num, $tar, \@bindees);

   # as this is new, how do I know if the user's version has
   # this before I use it?

   my @types;
   @types = @{$sth->{TYPE}} if (exists($sth->{TYPE}));

   my ($j, $i, $len, $just);
   my (@format, $header);

   for ($i=0 ; $i <= $#names ; $i++)
   {

      # default justify to the left and hope for the best!
      $just = '-';

      # as this is new, how do I know if the user's version
      # has this before I use it?

      if (exists($sth->{TYPE}) && defined(DBI::SQL_INTEGER))
      {
         # find the type to set the justification; get these from DBI.pm
         SWITCH: {
            $_ = $types[$i];
            #($_ == DBI::SQL_CHAR) && do { $just = '-'; last SWITCH; };
            #($_ == DBI::SQL_VARCHAR) && do { $just = '-'; last SWITCH; };
            #($_ == DBI::SQL_DATE) && do { $just = '-'; last SWITCH; };
            #($_ == DBI::SQL_TIME) && do { $just = '-'; last SWITCH; };
            #($_ == DBI::SQL_TIMESTAMP) && do { $just = '-'; last SWITCH; };
            #($_ == DBI::SQL_LONGVARCHAR) && do { $just = '-'; last SWITCH; };
            #($_ == DBI::SQL_BINARY) && do { $just = '-'; last SWITCH; };
            #($_ == DBI::SQL_VARBINARY) && do { $just = '-'; last SWITCH; };
            #($_ == DBI::SQL_LONGVARBINARY) && do { $just = '-'; last SWITCH; };
            ($_ == DBI::SQL_NUMERIC) && do { $just = ''; last SWITCH; };
            ($_ == DBI::SQL_DECIMAL) && do { $just = ''; last SWITCH; };
            ($_ == DBI::SQL_INTEGER) && do { $just = ''; last SWITCH; };
            ($_ == DBI::SQL_SMALLINT) && do { $just = ''; last SWITCH; };
            ($_ == DBI::SQL_BIGINT) && do { $just = ''; last SWITCH; };
            ($_ == DBI::SQL_TINYINT) && do { $just = ''; last SWITCH; };
            ($_ == DBI::SQL_FLOAT) && do { $just = ''; last SWITCH; };
            ($_ == DBI::SQL_REAL) && do { $just = ''; last SWITCH; };
            ($_ == DBI::SQL_DOUBLE) && do { $just = ''; last SWITCH; };
         } # SWITCH
      }

      # get the column name length
      $len = length($names[$i]);
      $tlen[$i] = $len; # comment this out if we do A. below

      # Option A is use the width of the column definition
      # Option B is find the widest value & use that!  (current)
      # A. is the length of the column definition bigger?
      #$tlen[$i] = $len if ($len > $tlen[$i]);
      # B. instead check find the longest value!
      for ($j=0 ; $j < @{$tar} ; $j++)
      {
        # NOTE: unless you turned on ChopBlanks, you may not be totally happy
        $len = defined($tar->[$j]->[$i]) ? length($tar->[$j]->[$i]) : 0;
        $tlen[$i] = $len if ($len > $tlen[$i]);
      }

      # now build the format & header
      # if I was really good, I'd try to line up decimal points on
      #   floating point numbers, :-) maybe later...
      $format[$i] = "%$just$tlen[$i]s ";
      $header .= sprintf($format[$i], $names[$i]);
   }
   return ($tar, \@format, \@tlen, \@names, $header);
}

# a support func for show_sql
sub print_lines
{
   my $self = shift;

   my ($header, $tar, $r_tlen, $r_format) = @_;
   my ($i, $j, @row);
   my @lines = @{$tar};
   my @format = @{$r_format};
   my @tlen = @{$r_tlen};
   my $ubar = '---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------';

   # print the column header
   $self->{Text_var}->insert('end', "\n$header\n");

   # print the underbars to show column width
   for ($i=0 ; $i <= $#tlen ; $i++)
   {
      $self->{Text_var}->insert('end', substr($ubar, 0, $tlen[$i]) . ' ');
   }
   $self->{Text_var}->insert('end', "\n");

   # print the data!
   for ($j=0 ; $j <= $#lines ; $j++)
   {
      @row = @{$lines[$j]};
      for ($i=0 ; $i <= $#tlen ; $i++)
      {
        $row[$i] = "" if (!defined($row[$i]));
        $self->{Text_var}->insert('end', sprintf($format[$i], $row[$i]));
      }
      $self->{Text_var}->insert('end', "\n");
   }
}
###############################################################################
# some DBI/DBD wrappers...
###############################################################################
# do a standard query, call $sth->fetch() to retrieve.
sub do_query
{
   my $self = shift;

   my ($stmt, @bindees) = @_;
   my $sth;

   #print STDERR "do_query: " . $stmt, "\n" if ( $main::debug > 0 );
   #print STDERR "do_query: self_dbconn" . $self->{Database_conn} . "\n" if ( $main::debug > 0 );

   $sth = $self->{Database_conn}->prepare( $stmt );
   db_check_error($stmt, "Prepare");

   my $num_bind = @bindees;

   if ($num_bind > 0){
      my $i;
      for ($i = 1;$i <= $num_bind;$i++){
         $sth->bind_param($i,$bindees[($i - 1)]);
      }
   }

   $sth->execute();
   db_check_error($stmt, "Execute");

   return $sth;
}

# do a query, and fetch all rows into an array of arrays
# be careful, this could consume a LOT of memory if called with a bad statement!

sub do_query_fetch_all
{
   my $self = shift;

   my($stmt, $asth, @bindees) = @_;
   my $tbl_ary_ref = undef;
   my $sth;

   # to do them all:
   $sth = $self->do_query($stmt, @bindees);
   $tbl_ary_ref = $sth->fetchall_arrayref();
   db_check_error($stmt, "Fetch");
   $$asth = $sth if (defined($asth));
   $sth->finish();

   return $tbl_ary_ref;
}

=head2 array do_query_fetch1(statement)

This subroutine takes an SQL statement (a select) as ARG 1, executes it,
fetches the 1 row as the answer, and returns that row as an
array for the answer.  If it fails, it dies.

This is useful for those times you KNOW you're getting back a single row,
or even a single value; e.g. a count.

Example:
   ($count) = do_query_fetch1("select count(*) from table");

=cut

sub do_query_fetch1
{
   my ($self, $stmt) = @_;
   my @row_ary;
   my $sth;

   $sth = $self->do_query($stmt);
   @row_ary  = $sth->fetchrow_array();
   $self->db_check_error($stmt, "Fetch");
   $sth->finish();

   return @row_ary;
}

# generic check for errors while interacting with the DB
sub db_check_error
{
   my $self = shift;

   my ($stmt, $action) = @_;
   if (defined($DBI::err) && $DBI::err  < 0)
   {
      #print STDERR "-->>$action error for $stmt\n";
      #print STDERR "$DBI::errstr\n";
      #print_stack();
      die "SQL Error";
   }
}
# we're about to die, so print a stack dump to see how we got in trouble
sub print_stack
{
   my $self = shift;

   my($package, $filename, $line, $i);
   $package="";
   $i=0;
   while (($package, $filename, $line) = caller($i++))
   {
      #print STDERR "Package: $package   File: $filename   Line: $line\n";
   }
}
###############################################################################

=head2 live_update

Take some SQL, execute it, format the results in a matrix-like style,
and show it in the Text_var widget (just like show_sql :-) AND do it
once a second until the user presses the Stop button.

 ARG1 = the SQL file name (main part, e.g. "Threads")
 ARG2 = the SQL level number (e.g. 1)
 ARG3 = a title (optional, if not sent, the first 40 chars of the SQL is used)

There is no return value.

Note:  it may take 1 or 2 seconds for the process to register the stop
after the user presses Stop.  Not sure how to fix this; probably can't as
the GUI will most likely be sleeping when the button is actually pressed,
so it'll take a second or so for the button press to be found.:w

=cut

my $live_update_flag; # our control flag
sub live_update
{
   my $self = shift;

   my ($sql_name, $sql_num, $title, $sleeptime) = @_;

   if(!defined($sleeptime)){
      $sleeptime = 1;
   }

   # some sanity checking :-)
   unless ($sql_name) { return; }
   unless ($sql_num) { return; }

   # give us a clean slate
   $self->must_f_clr();

   # create the stop button and put it at the top

   my $b = $self->{Text_var}->Button(  -text=>$main::lg{stop},
                                       -command=>sub{ stop_live_update() });

   $self->{Text_var}->window('create','end',-window=>$b);
   $self->{Text_var}->insert('end', "\n\n");

   # set this to be true so we loop for awhile
   $live_update_flag = 1;

   # while we're live, keep updating
   while ($live_update_flag)
   {
      # delete from after the stop button to EOS

      $self->{Text_var}->delete('1.1', 'end');

      # put the new values on the screen

      $self->show_sql($sql_name, $sql_num, $title);

      # cause the screen to show the new values

      $self->{Text_var}->update();

      sleep($sleeptime);
   }

   # the user hit stop, so remove the stop button

   $self->{Text_var}->delete('1.0', '1.1');

}
sub stop_live_update
{
   my $self = shift;

   # the user hit stop, so change the control flag
   $live_update_flag = 0;
}

sub f_str {

   my $self = shift;

   my $l_db_type = $self->{Database_type};

   # Takes a SQL module name, and sequence number,
   # and then returns the SQL code stored in the
   # appropriate file, as a Perl string variable

   my($sub,$number) = @_;
   my $rt = "";

   if(defined($sub) && defined($number)){
      my $file = ($self->{Database_type} eq "tools" ? $main::orac_home : $FindBin::RealBin) .
		         '/sql/' .
                 $self->{Database_type} .
                 '/' .
                 sprintf("%s.%s.sql",$sub,$number);

      my $dirname = File::Basename::dirname($file);
      my $basename = File::Basename::basename($file);
      $file = File::Spec->catfile($dirname, $basename);

      #print STDERR "f_str: file >$file<\n" if ($main::debug > 0);

	  local ($/) = (undef); # make the line delimiter empty to read in file in one call
      open(SQL,$file);
      $rt = <SQL>; # read in file in one fell swoop
      close(SQL);
   }
   return $rt;
}

sub get_frm {

   my $self = shift;

   # We may occasionally wish to generate formats on-the-fly.
   # If this is required, this is where we do it...

   my($l_dbh,$cm,$min_len) = @_;
   #print STDERR "get_frm:prepare($cm)\n" if ($main::debug > 0);

   my $sth = $l_dbh->prepare($cm) || die $l_dbh->errstr;
   $sth->execute;
   my $ret;
   my @res;
   if (@res = $sth->fetchrow) {
      my $i = 0;
      my $str = "";
      for($i = 0;$i < $sth->{NUM_OF_FIELDS};$i++){
         $str = $sth->{NAME}->[$i];
         my $l = length($str);
         if ($l < $min_len){
            $l = $min_len;
         }
         if($i == 0){
            $ret = 'r:' . $l;
         } else {
            $ret = $ret . ',r:' . $l;
         }
      }
   }
   $sth->finish;
   return $ret;
}

# Various sub-functions to clear screen, exit program
# cleanly etc

sub f_clr {
   my $self = shift;

   my($l_clr) = @_;

   # Check out what clearing option has
   # been chosen, and then clear the
   # screen if appropriate

   if($l_clr eq 'Y'){
      $self->must_f_clr();
   }
}
sub must_f_clr {

   my $self = shift;

   # Clear out all the text on the main screen,
   # and anything else that may be lurking like
   # 'See SQL' buttons.

   $self->{Text_var}->delete('1.0','end');
}
sub see_plsql {

   my $self = shift;

   # Helps put up a button on the page, so that the generative
   # SQL code can be viewed for validation purposes

   my ($res,$dum) = @_;

   my $img;
   $self->get_img( \$self->{Main_window}, \$img, 'sql' );

   my $b = $self->{Text_var}->Button(
                        -image=>$img,
                        -cursor=>'hand2',
                        -command=>
                           sub{ $self->see_sql( $self->{Main_window},
                                                $res) }
                                  );

   $main::balloon->attach( $b, -msg => $main::ssq, );

   # Now slap up the button

   $self->{Text_var}->insert('end', "\n\n  ");
   $self->{Text_var}->window('create','end', -window=>$b);
   $self->{Text_var}->insert('end', "\n\n");

   return;
}

sub see_gif {

   my $self = shift;

   my ($file, ) = @_;

   # Produce the box that contains the viewable SQL

   my $window = $self->{Main_window}->Toplevel();
   $window->title( $file );

   my $loc_menu;
   my $balloon;
   $self->create_balloon_bars(\$loc_menu, \$balloon, \$window );
   $self->window_exit_button(\$loc_menu, \$window, 1, \$balloon, );

   my $image = $window->Photo( -file => $file );

   my $l = $window->Label(
                        -relief=>'flat',
                        -image => $image,
                         )->pack(-expand=>1,-fill=>'both');

   main::iconize( $window );

}
sub see_sql {

   my $self = shift;

   my ($ins_window, $ins_text, $title) = @_;

   if (!defined($title) || (length($title) < 1) )
   {
      $title = $main::ssq;
   }
   # Produce the box that contains the viewable SQL

   my $window = $self->{Main_window}->Toplevel();

   $window->title( $title );

   my $loc_menu;
   my $balloon;
   $self->create_balloon_bars(\$loc_menu, \$balloon, \$window, );
   $self->window_exit_button(\$loc_menu, \$window, 1, \$balloon, );

   $window->{text} = $window->Scrolled(   'Text',
                                          -height=>16,
                                          -width=>60,
                                          -wrap=>'none',
                                          -setgrid=>1,
                                          -font=>$main::font{name},
                                          -foreground=>$main::fc,
                                          -background=>$main::bc
                                      );

   $window->{text}->insert('end', $ins_text, );
   $window->{text}->pack(-expand=>1,-fill=>'both');

   main::iconize( $window );

   # Just in case people want to do further manipulation

   return (\$loc_menu, \$balloon, \$window, );
}
sub about_orac {

   my $self = shift;

   # Slap up the various files onto the
   # main TEXT widget

   my $print_out = $self->gf_str( $_[0] );
   $self->{Text_var}->insert('end', $print_out);
}

# generic file into a string

sub gf_str
{

   my $self = shift;

   my $file = $_[0];
   my $rt = "";

   if (-r $file)
   {
	  local ($/) = (undef);  # unset so the file will be read in all at once
      open(SQL, "<$file") or return "ERROR:  can not open $file\n";
      $rt = <SQL>;  # read entire file at once
      close(SQL);
   }
   return $rt;
}
sub need_sys
{
   my $self = shift;
   return $self->{dont_need_sys};
}

sub need_ps
{
   my $self = shift;
   return $self->{dont_need_ps};
}

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

my ($g_hlst, $g_hlvl, $gen_sep, );
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

   my $window = $self->{Main_window}->Toplevel();
   $window->title("$g_hlst");

   my $loc_menu;
   my $balloon;
   $self->create_balloon_bars(\$loc_menu, \$balloon, \$window, );
   $self->window_exit_button(\$loc_menu, \$window, 1, \$balloon, );

   $window->{text} =
      $window->Scrolled('HList',
                      -drawbranch=> 1,
                      -separator=> $gen_sep,
                      -indent=> 50,
                      -width=> 80,
                      -height=> 20,
                      -font=>$main::font{name},
                      -foreground=> $main::fc,
                      -background=> $main::bc,
                      -command=> sub {

                            $self->show_or_hide( $_[0],
                                                 $window,
                                                 $window->{text},
                                               );

                                               },

                     )->pack(-fill=>'both',
                             -expand=>'both'
                            );

   $self->get_img( \$window, \$open_folder_bitmap, 'folder.open' );
   $self->get_img( \$window, \$closed_folder_bitmap, 'folder' );
   $self->get_img( \$window, \$file_bitmap, 'text' );

   my $cm = $self->f_str( $g_hlst ,'1');
   #print STDERR "prepare1: $cm\n" if ($main::debug > 0);
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
      $window->{text}->add(  $owner,
                             -itemtype=>'imagetext',
                             -image=>$bitmap,
                             -text=>$owner
                          );
   }
   $sth->finish;

   main::iconize( $window );

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

   my (  $path,
         $win,
         $text,

      ) = @_;

   my $next_entry = $text->info('next', $path);
   #print STDERR "path=>$path<   next_entry=$next_entry\n" if ($main::debug > 0);

   # Is there another level?
   my $x = $path;

   #print STDERR "before x=>$x<\n" if ($main::debug > 0);
   #$x =~ s/[^.$gen_sep]//g;
   $x =~ s/[^$gen_sep]//g;
   #print STDERR "after  x=>$x<\n" if ($main::debug > 0);

   $g_hlvl = length($x) + 1;
   my $another_level = sql_file_exists($self->{Database_type},$g_hlst, $g_hlvl + 1);
   if (!$another_level)
   {
      #print STDERR "no more levels!\n";
      # change this next line if we desire
      $self->do_a_generic($win, $gen_sep, $g_hlst, $path);
      return;
   }

   # decide what to do
   if (!$next_entry || (index ($next_entry, "$path$gen_sep") == -1))
   {
      # No. open it
      #print "NO!\n";

      $text->entryconfigure( $path,
                                         '-image' => $open_folder_bitmap
                                       );

      #print STDERR "show_or_hid:  path>$path<\n" if ($main::debug > 0);

      $self->add_contents( $path,
                           $text,
                         );
   }
   else
   {
      # Yes. Close it by changing the icon, and deleting its subnode.
      #print "YES!\n";

      $text->entryconfigure( $path,
                                         '-image' => $closed_folder_bitmap
                                       );

      $text->delete('offsprings', $path);
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

   my ( $path,
        $text,

      ) = @_;

   #print STDERR "path=$path\n" if ($main::debug > 0);

   # is there another level down?
   my $x = $path;
   #$x =~ s/[^.$gen_sep]//g;
   $x =~ s/[^$gen_sep]//g;
   $g_hlvl = length($x) + 2;
   my $bitmap = (sql_file_exists($self->{Database_type}, $g_hlst, $g_hlvl + 1)
                ? $closed_folder_bitmap
                : $file_bitmap);

   # get the SQL & execute!
   my $s = $self->f_str( $g_hlst, $g_hlvl);
   #print STDERR "prepare2: SQL>\n$s\n<\n ($path)\n" if ($main::debug > 0);
   my $sth = $self->{Database_conn}->prepare( $s )
      or die $self->{Database_conn}->errstr;

   # in theory this should work, COOL! I didn't know you could
   # give split a variable for the RE pattern. :-)

   my @params = split("\\$gen_sep", $path);

   #print STDERR "add_contents: gen_sep >$gen_sep<\n" if ($main::debug > 0);
   #print STDERR "add_contents: params0 >$params[0]<\n" if ($main::debug > 0);
   #print STDERR "add_contents: params1 >$params[1]<\n" if ($main::debug > 0);

   # should we search $s for number of placeholders,
   # and restrict @params to that number?

   if ($self->{Database_type} ne 'Sybase') {
       $sth->execute(@params);
   } else {
       $self->{Database_conn}->do("use @params");
       $sth ->execute;
   }

   # fetch the values
   my @res;
   while (@res = $sth->fetchrow)
   {
      $self->post_process_sql( $g_hlst, $g_hlvl, [ \@res ], \@params );
      # if the result has multiple columns, assume there will only be 1 row,
      # but we should display the columns as rows; but if there is only
      # 1 column, assume we'll get multiple rows/fetchs
      if ($#res > 0)
      {
         for (0 .. $#res)
         {
            my $gen_thing = "$path.$sth->{NAME}->[$_] = $res[$_]";

            $text->add(  $gen_thing,
                                     -itemtype => 'imagetext',
                                     -image    => $bitmap,
                                     -text     => $gen_thing,
                                  );
         }
         last;
      }
      else
      {
         my $gen_thing = "$path" . $gen_sep . "$res[0]";

         $text->add(  $gen_thing,
                                  -itemtype => 'imagetext',
                                  -image    => $bitmap,
                                  -text     => $gen_thing
                               );
      }
   }
   $sth->finish;
}

=head2 do_a_generic

A support function of generic_hlist, DO NOT CALL DIRECTLY!!!

show_or_hide calls this when it needs to add new items.
The base, no nothing, version.

=cut

sub do_a_generic
{
   return;
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

   # FindBin::RealBin patch below supplied by Bruce Albrecht,
   # 9/9/99

   my $file =
      sprintf("$FindBin::RealBin/sql/%s/%s.%d.sql",$type,$sub,$number);

   #print STDERR "sql_file_exists: $file\n" if ($main::debug > 0);
   return (-r $file);
}

###############################################################################

=head2 post_process_sql

This subroutine is called with the results from show_sql() to allow DB
modules to "post process" the output, if required, before it is analyzed
to be shown.
This is useful for turning numeric flags into words, and other such DB
dependent things.
This generic one does NOTHING!

=cut

sub post_process_sql
{
   my $self = shift;
   return;
}

=head2 create_button_bar

This creates a generic bar for placing active screen buttons upon.

=cut

sub create_button_bar {

   my $self = shift;

   my ($button_bar_ref,
       $win_ref,

      ) = @_;

   my(@lay) = qw/-side bottom -expand no -fill both/;
   $$button_bar_ref = $$win_ref->Frame(-relief=>'ridge',
                                       -bd=>2,
                                      )->pack(@lay);

   return;
}

=head2 create_balloon_bars

This creates the necessary basic requirements for setting up
message balloons within a status bar.

=cut

sub create_balloon_bars {

   my $self = shift;

   my ($button_bar_ref,
       $balloon_ref,
       $win_ref,

      ) = @_;

   $self->balloon_bar($balloon_ref, $win_ref, undef, );

   $$button_bar_ref = $$win_ref->Frame(-relief=>'ridge',
                                       -bd=>2,
                                      )->pack( -side => 'bottom',
                                               -fill => 'both',
                                               -expand => 'no',
                                             );

   return;
}

=head2 see_sql_but

This creates a basic 'See SQL' button for viewing executed SQL.

=cut

sub see_sql_but {

   my $self = shift;

   my ($menu_ref, $win_ref, $cm_ref, $use_img, $balloon_ref, ) = @_;

   if (!defined($use_img))
   {
      $use_img = 0;
   }

   my $b = $$menu_ref->Button(

                          -command=> sub{

                             $$win_ref->Busy(-recurse=>1);
                             $self->see_sql($$win_ref,$$cm_ref);
                             $$win_ref->Unbusy;

                                        }

                             )->pack(-side=>'left');

   if ($use_img)
   {
      my $img;
      $self->get_img( $win_ref, \$img, 'sql' );

      $b->configure(-image=>$img);

      if (defined($balloon_ref))
      {
         $$balloon_ref->attach(

            $b,
            -msg => $main::ssq,

                              );
      }
   }
   else
   {
      $b->configure(-text=>$main::ssq);
   }

   return \$b;

}

=head2 window_exit_button

This creates a basic 'Exit' button for leaving a window.
It destroys the window it is set upon.

=cut

sub window_exit_button {

   my $self = shift;

   my ($button_bar_ref,
       $win_ref,
       $use_image,
       $balloon_ref,

      ) = @_;

   if (!defined($use_image))
   {
      $use_image = 0;
   }

   my $b = $$button_bar_ref->Button(
                          -command=>
                             sub{
                                $$win_ref->destroy();
                                },

                                   )->pack(-side=>'right');

   if ($use_image)
   {
      my $img;
      $self->get_img( $win_ref, \$img, 'exit' );
      $b->configure(-image=>$img);

      if (defined($balloon_ref))
      {
         $$balloon_ref->attach(

            $b,
            -msg => $main::lg{exit},

                              );
      }
   }
   else
   {
      $b->configure(-text=>$main::lg{exit});
   }

   return \$b;

}

=head2 double_click_message

For helpful "Double-click" messages, at the tops of screens,
use this function.

=cut

sub double_click_message {

   my $self = shift;

   my ($win_ref) = @_;

   my $doub_frame = $$win_ref->Frame(-relief=>'ridge',
                                     -bd=>2,
                                    )->pack(-side=>'top',
                                            -expand=>'no',
                                            -fill=>'both'
                                           );

   $doub_frame->Label(  -text=>$main::lg{doub_click},
                        -relief=>'flat'
                     )->pack();

   return;

}

=head2 top_left_message

For 'top of the screen' left hand basic messages, this function
is used.

=cut

sub top_left_message {

   my $self = shift;

   my ($frame_r, $message) = @_;

   $$frame_r->Label(-text=>$message,
                    -anchor=>'w',
                    -relief=>'flat',
                    -justify=>'left',
                   )->pack(-expand=>'no',
                           -side=>'left',
                          );
   return;
}

=head2 top_right_ball_message

For 'top of the screen' right hand 'green-ball' type messages,
use this basic function.

=cut

sub top_right_ball_message {

   my $self = shift;

   my ($frame_r, $message_r, $win_ref , $gif_file) = @_;

   if (!defined($gif_file) || (length($gif_file) < 1) )
   {
      $gif_file = 'grn_ball.gif';
   }
   my $ball =
      $$win_ref->Photo(-file=>"$FindBin::RealBin/img/${gif_file}");

   $$frame_r->Label(-textvariable => $message_r,  # Remember, use the Ref.
                    -padx=>2,
                    -pady=>2,
                   )->pack(-side=>'right',
                           -anchor=>'e');

   $$frame_r->Label( -image => $ball,
                     -padx=>2,
                     -pady=>2,
                   )->pack(-side=>'right',
                           -anchor=>'e');
   return;

}

=head2 balloon_bar

Create the basic balloon bar for attaching balloon messages to.

=cut

sub balloon_bar {

   my $self = shift;

   my ($balloon_r, $win_r, $width, ) = @_;

   my $status_bar = $$win_r->Frame( -relief => 'groove',
                                    -bd => 2
                                  )->pack( -side => 'bottom',
                                           -fill => 'both',
                                           -expand => 'no',
                                         );

   my $balloon_status = $status_bar->Label(-relief => 'flat',
                                           -justify => 'left',
                                           -anchor=>'w',
                                          )->pack(-side=>'left',
                                                 );

   if (defined($width) && (length($width) > 0))
   {
      $balloon_status->configure(-width=>$width);
   }

   $$balloon_r = $$win_r->Balloon(-statusbar => $balloon_status,
                                  -state => 'status',
                                 );

   return;

}

=head2 orac_image_label

Create a label with the basic Orac image on it, and packs it
to the right of a frame.

=cut

sub orac_image_label {

   my $self = shift;

   my ( $frame_r, $win_r, ) = @_;

   my $orac_li;
   $self->get_img( $win_r, \$orac_li, 'orac' );

   $$frame_r->Label(-image=>$orac_li,
                    -borderwidth=>2,
                    -relief=>'flat'
                   )->pack(-side=>'right',-anchor=>'e');
   return;
}

=head2 get_img

Gets a window and image reference, and a file name, and fills the
image variable with the desired image.

=cut

sub get_img {

   my $self = shift;

   my ( $win_r, $img_r, $file_n, ) = @_;

   $$img_r =
      $$win_r->Photo( -file => "$FindBin::RealBin/img/${file_n}.gif" );

   return;
}
################################################
1;
# vi: set sw=3 ts=3 et:
