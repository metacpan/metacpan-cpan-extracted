package orac_Oracle;
use strict;

@orac_Oracle::ISA = qw{orac_Base};

my $Block_Size;
my $Count_DBA_Tables;
my $Oracle_Version;

my $sql_slider;
my $sql_row_count;
my $sql_browse_arr;
my $w_orig_sql_string;
my $keep_tablespace;

my $expl_butt;

my @dsc_n;

my $ind_name;
my $t_n;

my $ary_ref;
my $w;

my @w_holders;
my @w_titles;
my @w_explain;

my $oracle_dba_user;
my $jpeg_user;   
my $view;

my %l_hlst_to_type =
(
  Comments         => 'comments',
  Constraints      => 'constraint',
  Functions        => 'function',
  Indexes          => 'index',
  Index_FreeSpace  => 'index',
  Links            => 'database link',
  PackageBods      => 'package body',
  PackageHeads     => 'package',
  Procedures       => 'procedure',
  Profiles         => 'profile',
  Roles            => 'role',
  RoleGrants       => 'role',
  Rollbacks        => 'rollback segment',
  Sequences        => 'sequence',
  SnapshotLogs     => 'snapshot log',
  Snapshots        => 'snapshot',
  Synonyms         => 'synonym',
  Tables           => 'table',
  Tablespaces      => 'tablespace',
  Tab_FreeSpace    => 'table',
  Users            => 'user',
  UserGrants       => 'user',
  Views            => 'view',
);

=head1 NAME

orac_Oracle.pm - the Oracle module to the Orac tool

=head1 DESCRIPTION

This code is a database object that can be created by the Orac tool.
It inherits from orac_Base, which has all the basic data and methods.
Some of those are called from here, some are overridden, most are
inherited and used as is.

=head1 PUBLIC METHODS

&new()
&init1()
&init2()
&dba_user()

=cut

=head2 new

This constructor method basically sucks up the orac_Base functions
to create the orac_Oracle object.

=cut

sub new
{
   my $proto = shift;
   my $class = ref($proto) || $proto;

   my ($l_window, $l_text) = @_;

   my $self  = orac_Base->new("Oracle", $l_window, $l_text);

   bless($self, $class);
   return $self;
}

=head2 init1

This sets some environmental variables that DBD::Oracle requires
to get to the right database.

=cut

sub init1 {
   my $self = shift;

   my($l_instance) = @_;

   # Set all environmental variable required for DBD::Oracle

   $main::ENV{TWO_TASK} = $l_instance;
   $main::ENV{ORACLE_SID} = $l_instance;

   # Fix idea by Sean Kamath, positioned by Bruce Albrecht :)
   # If Sean didn't set ORACLE_HOME under unix-u-like, then a core
   # dump occured at this point.  So we put the fix in.
   # However, Duncan Lawie found that the ActiveState
   # runs fine without ORACLE_HOME, and that this 'fix'
   # now dumped Orac out.  Therefore had to add the 'unless'
   # line to cope with both situations.  What fun! :-)

   unless ($^O =~ /MSWin/)
   {
      if ((!defined($main::ENV{ORACLE_HOME})) ||
          (length($main::ENV{ORACLE_HOME}) < 1))
      {
         die "You must make sure the environment variable ORACLE_HOME is set " .
             "properly\n";
      }
   }
}

=head2 init2

Picks up a few values used again and again by the rest
of the orac_Oracle object (eg: block size).

=cut

sub init2 {

   my $self = shift;

   $self->{Database_conn} = $_[0];
   $self->Dump;

   # Get the block size locally.

   my $cm = $self->f_str('get_user_db','1');

   my $sth = $self->{Database_conn}->prepare( $cm ); 
   $sth->execute;
   ($Block_Size) = $sth->fetchrow;
   $sth->finish;

   # Get the Version locally

   $cm = $self->f_str('get_version','1');

   $sth = $self->{Database_conn}->prepare( $cm ); 
   $sth->execute;
   ($Oracle_Version) = $sth->fetchrow;
   $sth->finish;

   # Figure out if the user is a DBA somehow.  I'll default to user
   # for now, until I can work out DBA status, later.

   $view = 'USER';
   $oracle_dba_user = 0;

   eval {
      $main::conn_comm_flag = 1;
      $cm = $self->f_str('check_dba','1');

      $sth = $self->{Database_conn}->prepare( $cm ); 
      $sth->execute;
      ($Count_DBA_Tables) = $sth->fetchrow;
      $sth->finish;
      $main::conn_comm_flag = 0;
   };
   if ($@) {
      $view = 'USER';
      $oracle_dba_user = 0;
   } else {
      $view = 'DBA';
      $oracle_dba_user = 1;
   }

   $jpeg_user = 0;                
   $main::conn_comm_flag = 1;    
   eval {                       
      require DBD::Chart;      
      require Tk::JPEG;        
   };                        
   if ($@) {                
      $jpeg_user = 0;      
   } else {               
      $jpeg_user = 1;    
   }                    
   $main::conn_comm_flag = 0; 

   eval {
      require DDL::Oracle;
   };
   if ($@) {
      warn $@;
      main::mes($main::mw,
                   "Oracle Development usage requires\n" .
                   "Richard Sutherland's DDL-Oracle module.\n" .
                   "You can get hold of this here:\n\n" .
                   "http://www.perl.com/CPAN-local/modules/" .
                   "by-authors/id/R/RV/RVSUTHERL/"
               );
   } else {
        DDL::Oracle->configure( 
                  dbh      => $self->{Database_conn},
                  resize   => 0,
                  view     => $view,
                  heading  => 0,
                  prompt   => 0,
                );
   }

   # Enable the PL/SQL memory area, for this
   # database connection
   
   $self->{Database_conn}->func(1000000,'dbms_output_enable');
}

sub dba_user {
   my $self = shift;
   return $oracle_dba_user;
}

sub jpeg_user {      
   my $self = shift; 
   return $jpeg_user;
}                   

################ Database dependent code functions below here ##################

=head2 tune_wait

Works out if anything is waiting in the database and then
produces the relevant report.

=cut

sub tune_wait {
   my $self = shift;

   # Works out if anything is waiting in the database

   $self->show_sql( 'tune_wait', '1' , $main::lg{sess_wt_stats} );
   $self->about_orac("$FindBin::RealBin/txt/Oracle/tune_wait.1.txt");

}

=head2 tune_pigs

This function gives you two differing reports which measure the
Shared Pool disk reads for various SQL statements in the library.

=cut

sub tune_pigs {
   my $self = shift;

   # This function gives you two differing reports
   # which measure the Shared Pool disk reads
   # for various SQL statements in the library

   my($type_flag)=@_;

   my $title;

   if($type_flag == 1){
      # If type 1, then we only want the highest
      # summarised readings
      $title = $main::lg{mem_hogs1};
   }
   elsif($type_flag == 2){
      # If type 1, then we only want the highest
      # summarised readings
      $title = $main::lg{mem_hogs2};
   }
   # Report for finding SQL monsters

   $self->show_sql( 'tune_pigs', $type_flag , $title );

}

=head2 who_what

Works out who is holding whom, so we can unblock needless locking.
Gives you various options for trying to view the blocking SQL.
Gives a schematic report to try and pinpoint the offending program.

=cut

sub who_what {

   my $self = shift;

   # Works out who is holding whom, so we can unblock
   # needless locking.

   my ($flag,$param1,$param2,$param3) = @_;

   my $title;

   if($flag == 1){
      $title = "$param1 $main::lg{investgn}";
   } elsif ($flag == 2){
      $title = "$param2";
   }

   if( $flag == 1 ){

      $self->show_sql(   'who_what',
                         '1',
                         $main::lg{hold_sql},
                         $param1,
                         $param2,
                         $param3
                     );

   } elsif ( $flag == 2 ){

      $self->show_sql(   'statter',
                         '1',
                         $title,
                         $param1
                        );

   }
}

=head2 all_stf

Takes particular PL/SQL statements, and generates DDL to recreate ALL of a
particular object in the database.

=cut

sub all_stf {
   my $self = shift;

   # Takes particular PL/SQL statements,
   # and generates DDL to recreate ALL of a
   # particular object in the database.

   my($module, $mod_number, $mod_binds) = @_;

   if ( 
           $module eq 'Views'
        or $module eq 'Synonyms'
        or $module eq 'UserGrants'
        or $module eq 'Constraints'
      )
   {
     my $stmt;

     if ( $module eq 'Constraints' )
     {
       $stmt =
        "
         SELECT
                owner
              , constraint_name
         FROM
                dba_constraints
         ORDER
            BY
                1, 2
        ";
     }
     elsif ( $module eq 'Views' )
     {
       $stmt =
        "
         SELECT
                owner
              , view_name
         FROM
                dba_views
         ORDER
            BY
                1, 2
        ";
     }
     elsif ( $module eq 'Synonyms' )
     {
       $stmt =
        "
         SELECT
                owner
              , synonym_name
         FROM
                dba_synonyms
         ORDER
            BY
                1, 2
        ";
     }
     elsif ( $module eq 'UserGrants' )
     {
       $stmt =
        "
         SELECT
                null
              , username
         FROM
                dba_users
         ORDER
            BY
                username
        ";
     }
  
     my $sth = $self->{Database_conn}->prepare( $stmt ) ||
                die $self->{Database_conn}->errstr;
     $sth->execute;
     my $aref = $sth->fetchall_arrayref;
     $sth->finish;
  
     my $obj = DDL::Oracle->new(
                                 type => $l_hlst_to_type{ $module },
                                 list => $aref,
                               );
     my $text= $obj->create ;
  
     $self->{Text_var}->delete('1.0', 'end');
     $self->{Text_var}->insert('end', "$text\n");
   }
   else   # Not sure we still need this ???
   {
     my $cm = $self->f_str($module, $mod_number);

     my $sth = $self->{Database_conn}->prepare($cm) ||
                die $self->{Database_conn}->errstr;
     my $i;
     for ( $i = 1 ; $i <= $mod_binds ; $i++ ){
        $sth->bind_param($i,'%');
     }
     $sth->execute;

     $i = 0;
     my $ls;
     while($i < 100000){
        $ls = scalar $self->{Database_conn}->func('dbms_output_get');
        if ((!defined($ls)) || (length($ls) == 0)){
           last;
        }
        $self->{Text_var}->insert('end', "$ls\n");
        $i++;
     }

     $self->see_plsql($cm);
   }
}

=head2 orac_create_db

Generates a script with which you can completely regenerate the skeleton
of your database (files, users, etc).

=cut

sub orac_create_db {
   my $self = shift;

   # Generates a script with which you can
   # completely regenerate the skeleton of your
   # database

   my ($oracle_sid,$dum) = split(/\./, $main::v_db);
   my $cm = $self->f_str('orac_create_db','1');
   my $sth = $self->{Database_conn}->prepare( $cm ) ||
                die $self->{Database_conn}->errstr;
   $sth->bind_param(1,$oracle_sid);
   $sth->execute;

   my $j = 0;
   my $full_list;

   while($j < 100000){
      $full_list = scalar $self->{Database_conn}->func('dbms_output_get');
      if ((!defined($full_list))|| (length($full_list) == 0)){
         last;
      }
      $self->{Text_var}->insert('end', "$full_list\n");
      $j++;
   }
   $self->see_plsql($cm);
}

=head2 selected_error

Pumps out information on a particular error.  This error comes from
the pick-list error screen, which detects invalid objects in
the database.

=cut

sub selected_error {

   my $self = shift;

   # Pumps out information on a particular error

   my ($err_bit) = @_;
   my ($owner,$object) = split(/\./, $err_bit);

   $self->f_clr( $main::v_clr );
   $self->show_sql( 'selected_error',
                    '1',
                    "$main::lg{comp_errs_for} $err_bit",
                    $owner,
                    $object
                  );
}

=head2 univ_form

A complex function for generating on-the-fly Forms for viewing database
information.  This examines DBA tables, and works out how to build the
form.  Then it asks the user to input SQL, and order the way it comes back.

Once this is done, Orac goes off and fills the on-the-fly data viewer
with the required information.

=cut

sub univ_form {

   my $self = shift;

   # A complex function for generating on-the-fly Forms
   # for viewing database information

   my ( $owner,
        $object,
        $screen_type,

     ) = @_;

   my $screen_title = "$main::lg{form_for} $object";

   my $univ_form_win = $self->{Main_window}->Toplevel();

   $univ_form_win->title( $screen_title );

   my $help_txt;

   if ($screen_type eq 'index'){

      $help_txt = "$owner.$object, $main::lg{sel_cols}";

   } else {

      $help_txt = "$main::lg{prov_sql} $main::lg{sel_info}";

   }

   $univ_form_win->Label( -text=>$help_txt,
                          -anchor=>'n',
                        )->pack();

   $univ_form_win->{text} =
      $univ_form_win->Scrolled( 'Text',
                                -height=>16,
                                -cursor=>undef,
                                -wrap=>'none',
                                -foreground=>$main::fc,
                                -background=>$main::bc,
                                -font=>$main::font{name},
                              );

   my $cm = $self->f_str('selected_dba','1');

   my $sth = $self->{Database_conn}->prepare( $cm ) ||
                die $self->{Database_conn}->errstr;

   $sth->bind_param(1,$owner);
   $sth->bind_param(2,$object);

   $sth->execute;

   my @entry_bubbles = (  $main::lg{i_col},
                          $main::lg{i_sel_sql},
                          $main::lg{i_dat_typ},
                          $main::lg{i_ord}
                       );

   my $i;
   my $w; # For small button window generation

   for $i (0..3){

      unless ( ($screen_type eq 'index') &&
               ($i == 2)
             )
      {

         $w = $univ_form_win->{text}->Entry(

                              -textvariable=>\$entry_bubbles[$i],
                                           );
         if ($i == 3)
         {
            $w->configure(-width=>3);
         }
         else
         {
            $w->configure(-width=>16);
         }

         $w->configure(  -background=>$main::fc,
                         -foreground=>$main::ec,
                      );

         $univ_form_win->{text}->windowCreate('end',-window=>$w);
      }
   }

   $univ_form_win->{text}->insert('end', "\n");

   my @column_tabs;
   my @title_tabs;
   my $index_win_cnt = 0;

   my @res;
   my @sql_entry;
   my @actual_entry;
   my @ordered_entry;

   my $counter = 0;
   my $need_focus = 0;
   my $focus_r;

   while (@res = $sth->fetchrow) {

      $counter++;

      $column_tabs[$index_win_cnt] = $res[0];

      $w = $univ_form_win->{text}->Entry(

                  -textvariable=>\$column_tabs[$index_win_cnt],
                  -width=>16,

                                        );

      $univ_form_win->{text}->windowCreate('end',-window=>$w);

      unless ($screen_type eq 'index'){

         $sql_entry[$index_win_cnt] = "";

         $w = $univ_form_win->{text}->Entry(

                             -textvariable=>\$sql_entry[$index_win_cnt],
                             -foreground=>$main::fc,
                             -background=>$main::ec,
                             -width=>16,

                                           );

         $univ_form_win->{text}->windowCreate('end',-window=>$w);

         if ($counter == 1)
         {
            $focus_r = \$w;
            $need_focus = 1;
         }

      }
      $title_tabs[$index_win_cnt] = "$res[1] $res[2]";

      $w = $univ_form_win->{text}->Entry(

                             -textvariable=>\$title_tabs[$index_win_cnt],
                             -width=>16,

                                        );

      $univ_form_win->{text}->windowCreate('end',-window=>$w);

      $actual_entry[$index_win_cnt] = "$res[0]";
      $ordered_entry[$index_win_cnt] = 0;

      $w = $univ_form_win->{text}->Checkbutton(

                   -cursor=>'hand2',
                   -variable=>\$ordered_entry[$index_win_cnt],
                   -relief=>'flat'

                                              );

      $univ_form_win->{text}->windowCreate('end',-window=>$w);

      $univ_form_win->{text}->insert('end', "\n");
      $index_win_cnt++;
   }
   $index_win_cnt--;
   $sth->finish;

   $univ_form_win->{text}->configure( -state=>'disabled' );

   $univ_form_win->{text}->pack( -expand =>1,
             -fill=>'both'
           );

   my $bb;
   my $balloon;
   $self->create_balloon_bars(\$bb, \$balloon, \$univ_form_win );

   if ($screen_type eq 'index'){

      $help_txt = $main::lg{build_index};

   } else {

      $help_txt = $main::lg{sel_info};

   }

   my $image;
   $self->get_img( \$univ_form_win, \$image, 'forward' );

   my $forward_b = $bb->Button( -image=>$image,
                                -command=>sub{
                               $univ_form_win->Busy(-recurse=>1);
                               $self->selector( \$univ_form_win,
                                                \$screen_type,,
                                                \$screen_title,
                                                \$index_win_cnt,
                                                \@actual_entry,
                                                \$owner,
                                                \$object,
                                                \@ordered_entry,
                                                \@sql_entry,
                                              );
                               $univ_form_win->Unbusy;
                                             }
                              )->pack (-side=>'left',
                                       -anchor=>'w');

   $balloon->attach($forward_b, -msg => $help_txt );

   $self->window_exit_button( \$bb, \$univ_form_win, 1, \$balloon, );
   main::iconize( $univ_form_win );

   if ($need_focus)
   {
      $$focus_r->focusForce;
   }
}

=head2 selector

User may wish to narrow search for info with universal form, down to a
particular set of rows, and order these rows.  This function helps
univ_form() and allows them to do that.

=cut

sub selector {

   my $self = shift;

   # User may wish to narrow search for info, down to
   # a particular set of rows, and order these rows.
   # This function allows them to do that.

   my( $win_ref,
       $screen_type_r,
       $screen_title_r,
       $index_cnt_r,
       $entries_r,
       $owner_r,
       $object_r,
       $ordered_entry_r,
       $sql_entry_r,

     ) = @_;

   my @actual_entries = @$entries_r;
   my @ordered_entry = @$ordered_entry_r;
   my @sql_entry = @$sql_entry_r;

   # Start building up the select string

   my $l_sel_str = ' select ';

   if ($$screen_type_r eq 'index'){

      $self->build_ord( $win_ref,
                        $screen_type_r,
                        $index_cnt_r,
                        $ordered_entry_r,
                        \$l_sel_str,
                        $owner_r,
                        $object_r,
                        $entries_r,
                        $screen_title_r,
                      );
      return;
   }

   my $i;

   for $i (0..$$index_cnt_r){

      if ($i != $$index_cnt_r){

         $l_sel_str = $l_sel_str . "$actual_entries[$i], ";

      } else {

         $l_sel_str = $l_sel_str . "$actual_entries[$i] ";

      }
   }

   $l_sel_str = $l_sel_str . "\nfrom " . $$owner_r . '.' . $$object_r . " ";

   my $flag = 0;
   my $last_one = 0;

   for $i (0..$$index_cnt_r){

      if ($ordered_entry[$i] == 1){

         $flag = 1;
         $last_one = $i;

      }
   }

   my $where_bit = "\nwhere ";

   for $i (0..$$index_cnt_r)
   {
      my $sql_bit = $sql_entry[$i];

      if (defined($sql_bit) && length($sql_bit))
      {

         $l_sel_str = $l_sel_str . $where_bit .
                      "$actual_entries[$i] $sql_bit ";

         $where_bit = "\nand ";

      }
   }

   $self->build_ord( $win_ref,
                     $screen_type_r,
                     $index_cnt_r,
                     $ordered_entry_r,
                     \$l_sel_str,
                     $owner_r,
                     $object_r,
                     $entries_r,
                     $screen_title_r,
                  );

   $self->and_finally( $win_ref,
                       \$l_sel_str,
                       $index_cnt_r,
                       $entries_r,
                       $screen_title_r,
                     );
   return;
}

=head2 and_finally

Now we've built up our full SQL statement for this table with
selector(), fill a Perl array with everything and display it in
the univ_form(), on-the-fly viewer.

=cut

sub and_finally {

   my $self = shift;

   my( $win_ref,
       $cm_ref,
       $count_r,
       $entries_r,
       $title_r,

     ) = @_;

   my @entries = @$entries_r;

   # Now we've built up our full SQL statement for this table,
   # fill a Perl array with everything and display it.

   my $ary_ref = $self->{Database_conn}->selectall_arrayref( $$cm_ref );

   my $min_row = 0;
   my $max_row = @$ary_ref;

   if ($max_row == 0){

      main::mes($$win_ref, $main::lg{no_rows});

   } else {

      my $out_screen = $main::mw->Toplevel(-title=>$$title_r);

      my(@lb) = qw/-anchor n -side top -expand 1 -fill both/;
      my $top_frame = $out_screen->Frame->pack(@lb);

      $out_screen->{text} =
            $top_frame->Scrolled('Text',
                                 -height=>16,
                                 -cursor=>undef,
                                 -width=>80,
                                 -wrap=>'none',
                                 -foreground=>$main::fc,
                                 -background=>$main::bc,
                                 -font=>$main::font{name},
                                );

      my @output;

      for my $i (0..$$count_r) {

         $output[$i] = "";

         $w = $out_screen->{text}->Entry(-textvariable=>\$entries[$i],
                                        );

         $out_screen->{text}->windowCreate('end',-window=>$w);

         $w = $out_screen->{text}->Entry(-textvariable=>\$output[$i],
                        -foreground=>$main::fc,
                        -background=>$main::ec,
                        -width=>30);

         $out_screen->{text}->windowCreate('end',-window=>$w);
         $out_screen->{text}->insert('end', "\n");
      }
      $out_screen->{text}->configure(-state=>'disabled');
      $out_screen->{text}->pack(@lb);

      my $loc_menu;
      my $balloon;
      $self->create_balloon_bars(\$loc_menu, \$balloon, \$out_screen, );
      $self->window_exit_button(\$loc_menu, \$out_screen, 1, \$balloon, );

      my $bot_f = $out_screen->Frame->pack( -fill=>'both',
                                            -side=>'bottom',
                                            -expand=>'no'
                                          );

      my $univ_scale;

      $univ_scale =
         $bot_f->Scale(
             -orient=>'horizontal',
             -label=>"$main::lg{rec_of} " . $max_row,
             -length=>400,
             -sliderrelief=>'raised',
             -from=>1,-to=>$max_row,
             -tickinterval=>($max_row/8),

             -command=>[
                sub {   $self->calc_scale_record(  \$univ_scale,
                                                   \@output,
                                                   $univ_scale->get(),
                                                   $ary_ref,
                                                   $count_r,
                                                )
                    }  ]

                     )->pack(side=>'left');

      $self->go_for_gold( \$univ_scale,
                          \@output,
                          $min_row,
                          $ary_ref,
                          $count_r,
                        );

      $self->see_sql_but(\$loc_menu, \$out_screen, $cm_ref, 1, \$balloon, );
      main::iconize( $out_screen );
   }
   return;
}

=head2 calc_scale_record

This whizzes backwards and forwards through the univ_form() records' array,
displaying up the required information.

=cut

sub calc_scale_record {
   my $self = shift;

   # Whizz backwards and forwards through the records

   my( $univ_scale_ref,
       $output_r,
       $normal_position,
       $ary_ref,
       $count_r,

     ) = @_;

   my $array_count_pos = $normal_position - 1;

   $self->go_for_gold( $univ_scale_ref,
                       $output_r,
                       $array_count_pos,
                       $ary_ref,
                       $count_r,
                     );

}

=head2 go_for_gold

Work out which row of information to display, and then display it.  The
name of this function comes from a very bad 80's TV show, hosted
by Henry Kelly :)

=cut

sub go_for_gold {

   my $self = shift;

   my ($univ_scale_ref,
       $output_r,
       $count,
       $ary_ref,
       $count_r,

      ) = @_;

   # Work out which row of information to display,
   # and then display it.

   my $curr_ref = $ary_ref->[$count];

   for my $i (0..$$count_r) {

      $output_r->[$i] = $curr_ref->[$i];
   }

   $$univ_scale_ref->set(($count + 1));

}

=head2 build_ord

It all gets a bit nasty here.  This works out the user's intentions on
how to order their required information for the univ_form() set of
functions.

=cut

sub build_ord {

   my $self = shift;

   # It all gets a bit nasty here.  This works out
   # the user's intentions on how to order their
   # required information.

   my( $win_ref,
       $screen_type_r,
       $index_count_r,
       $order_r,
       $select_string_r,
       $own_r,
       $obj_r,
       $entries_r,
       $title_r,

     ) = @_;

   my @orders = @$order_r;

   my $l_chk = 0;

   my $i;

   for $i (0..$$index_count_r){

      if ($orders[$i] == 1){

         $l_chk = 1;

      }
   }

   if ($l_chk == 1){

      my $total_indexed_count;
      my @index_array;
      my @index_head;
      my @index_open;

      $self->now_build_ord( $win_ref,
                            $screen_type_r,
                            \$total_indexed_count,
                            $index_count_r,
                            $entries_r,
                            $title_r,
                            \@index_array,
                            \@index_head,
                            \@index_open,
                            $order_r,
                          );

      if ($$screen_type_r eq 'index'){

         $self->really_build_index( $win_ref,
                                    $own_r,
                                    $obj_r,
                                    \$total_indexed_count,
                                    \@index_array,
                                    \@index_head,
                                    $title_r,
                                  );

      } else {

         $$select_string_r = $$select_string_r . "\norder by ";

         for my $cl (1..$total_indexed_count)
         {

            $$select_string_r = $$select_string_r .
                                "$index_array[$index_head[$cl]] ";

            if ($dsc_n[$index_head[$cl]] == 1)
            {
               $$select_string_r = $$select_string_r . "desc ";
            }

            if ($cl != $total_indexed_count)
            {
               $$select_string_r = $$select_string_r . ", ";
            }
         }
      }
   } else {

      if ($$screen_type_r eq 'index'){

         main::mes($$win_ref, $main::lg{no_cols_sel});

      }
   }
}

=head2 now_build_ord

This helps build up the ordering SQL string.

=cut

sub now_build_ord {

   my $self = shift;

   # This helps build up the ordering SQL string.

   my($win_ref,
      $screen_type_r,
      $total_r,
      $index_count_r,
      $entries_r,
      $title_r,
      $index_arr_r,
      $index_head_r,
      $index_open_r,
      $order_r,

     ) = @_;

   my @entries = @$entries_r;

   $$total_r = 0;

   my $i;

   for $i (0..$$index_count_r){

      if ($order_r->[$i] == 1){

         $$total_r++;
         $index_arr_r->[$$total_r] = $entries[$i];

      }
   }

   my $b_d = $$win_ref->DialogBox(-title=>$$title_r);

   $b_d->Label(  -text=>$main::lg{ind_ord_arrng},
                 -anchor=>'n'
              )->pack(-side=>'top');

   my $t = $b_d->Scrolled('Text',
                          -cursor=>undef,
                          -height=>16,
                          -wrap=>'none',
                          -foreground=>$main::fc,
                          -background=>$main::bc);

   if ($$screen_type_r eq 'index'){

      # User may be wanting to generate DDL to create new Index.
      # If so, this picks up the other information required.

      my $id_name = $main::lg{ind_name} . ':';

      $w = $t->Entry(-textvariable=>\$id_name,
                     -background=>$main::fc,
                     -foreground=>$main::ec);

      $t->windowCreate('end',-window=>$w);

      $ind_name = 'INDEX_NAME';
      $w = $t->Entry(-textvariable=>\$ind_name,
                     -foreground=>$main::fc,
                     -background=>$main::ec);
      $t->windowCreate('end',-window=>$w);
      $t->insert('end', "\n");

      my $tabp_name = $main::lg{tabsp} . ':';

      $w = $t->Entry(-textvariable=>\$tabp_name,
                     -background=>$main::fc,
                     -foreground=>$main::ec);

      $t->windowCreate('end',-window=>$w);

      $t_n = "TABSPACE_NAME";
      my $t_l = $t->BrowseEntry( -variable=>\$t_n,
                                 -foreground=>$main::fc,
                                 -background=>$main::ec,
                               );

      $t->windowCreate('end',-window=>$t_l);
      $t->insert('end', "\n");

      my $sth =
         $self->{Database_conn}->prepare($self->f_str('now_build_ord','1'))||
                die $self->{Database_conn}->errstr;
      $sth->execute;

      my $i = 0;
      my @tot_obj;

      my @res;

      while (@res = $sth->fetchrow) {
         $tot_obj[$i] = $res[0];
         $i++;
      }
      $sth->finish;

      my @h_ar = sort @tot_obj;
      foreach(@h_ar){
         $t_l->insert('end', $_);
      }
      $t->insert('end', "\n");
   }
   my @pos_txt;
   for $i (1..($$total_r + 2)){
      if ($i <= $$total_r){
         $pos_txt[$i] = "Pos $i";
         $w = $t->Entry(-textvariable=>\$pos_txt[$i],
                        -width=>7,
                        -background=>$main::fc,
                        -foreground=>$main::ec);
      } else {
         if ($i == ($$total_r + 1)){
            $pos_txt[$i] = $main::lg{i_col};
            $w = $t->Entry(-textvariable=>\$pos_txt[$i],
                           -background=>$main::fc,
                           -foreground=>$main::ec);
         } else {
            unless ($$screen_type_r eq 'index'){
               $pos_txt[$i] = $main::lg{i_desc};
               $w = $t->Entry(-textvariable=>\$pos_txt[$i],
                              -width=>8,
                              -background=>$main::fc,
                              -foreground=>$main::ec);
            }
         }
      }
      $t->windowCreate('end',-window=>$w);
   }
   $t->insert('end', "\n");

   # The following is all a bit horrible.  I'm afraid
   # you're going to have to work it out for yourself.
   # It's not nice, you may not want to bother.

   my $j_row;

   for $j_row (1..$$total_r){

      $index_head_r->[$j_row] = $j_row;
      $dsc_n[$j_row] = 0;
      $index_open_r->[$j_row] = $index_head_r->[$j_row];

      my $j_col;

      for $j_col (1..($$total_r + 2)){
         if ($j_col <= $$total_r){

            $w = $t->Radiobutton(
                        -cursor=>'hand2',
                        -relief=>'flat',
                        -value=>$j_row,
                        -variable=>\$index_head_r->[$j_col],
                        -width=>4,
                        -command=> sub {

            $self->j_inri($index_head_r,
                          $total_r,
                          $index_open_r,
                         )

                                       },
                                );

            $t->windowCreate('end',-window=>$w);
         } else {
            if ($j_col == ($$total_r + 1)){

               $w = $t->Entry( -textvariable=>\$index_arr_r->[$j_row],
                               -foreground=>$main::fc,
                               -background=>$main::ec
                             );

               $t->windowCreate('end',-window=>$w);
            } else {
               unless ($$screen_type_r eq 'index'){

                  $w = $t->Checkbutton( -variable=>\$dsc_n[$j_row],
                                        -cursor=>'hand2',
                                        -relief=>'flat',
                                        -width=>6);

                  $t->windowCreate('end',-window=>$w);
               }
            }
         }
      }
      $t->insert('end', "\n");
   }
   $t->configure(-state=>'disabled');
   $t->pack();
   $b_d->Show;
}

=head2 really_build_index

Picks up everything finally reqd. to build up the DDL for index creation.
It then works out the exact DDL, including INITIAL and NEXT sizes, to
create a particular index, on a particular database object.

=cut

sub really_build_index {

   my $self = shift;

   # Picks up everything finally reqd. to build
   # up the DDL for index creation

   my( $win_ref,
       $own_r,
       $obj_r,
       $total_r,
       $index_array_r,
       $index_head_r,
       $title_r,

     ) = @_;

   my $d = $main::mw->Toplevel(
              -title=>"$main::lg{ind_crt_for} " . $$own_r . '.' . $$obj_r
                              );

   $d->{text} = $d->Scrolled( 'Text',
                              -wrap=>'none',
                              -foreground=>$main::fc,
                              -background=>$main::bc,
                              -font=>$main::font{name},
                            );

   $d->{text}->pack(-expand=>1,-fil=>'both');

   tie (*L_TXT, 'Tk::Text', $d->{text});

   my $cm = $self->f_str('build_ind','1');

   for my $cl (1..$$total_r)
   {

      my $bs = " v_this_build($cl) := '" .
               $index_array_r->[$index_head_r->[$cl]] .
               "' ; ";
      $cm = $cm . $bs;

   }

   my $cm_part2 = $self->f_str('build_ind','2');
   $cm = $cm . "\n" . $cm_part2;

   $self->{Database_conn}->func(1000000, 'dbms_output_enable');

   my $sth = $self->{Database_conn}->prepare( $cm ) ||
                die $self->{Database_conn}->errstr;

   $sth->bind_param(1,$$own_r);
   $sth->bind_param(2,$$obj_r);
   $sth->bind_param(3,$$total_r);

   $sth->execute;

   my $full_list;
   $full_list = scalar $self->{Database_conn}->func('dbms_output_get');

   if (length($full_list) != 0){
      my $avg_entry_size = $full_list + 0.00;

      my($pct_free,$initrans) =
         $self->ind_prep($self->f_str('build_ind','3'),$$own_r,$$obj_r);

      my($n_rows) =
        $self->ind_prep($self->f_str('build_ind','4') .
                        ' ' . $$own_r . '.' . $$obj_r . ' ');

      my($avail_data_space) =
         $self->ind_prep($self->f_str('build_ind','5'),
             $Block_Size, $initrans, $pct_free);

      my($space) =
         $self->ind_prep($self->f_str('build_ind','6'),
                         $avail_data_space,$avg_entry_size,$avg_entry_size);

      my ($blocks_req) =
         $self->ind_prep($self->f_str('build_ind','7'),
                         $n_rows,$avg_entry_size,$space);

      my ($initial_extent) =
         $self->ind_prep($self->f_str('build_ind','8'),
                         $blocks_req,$Block_Size);

      my ($next_extent) =
          $self->ind_prep($self->f_str('build_ind','9'),$initial_extent);

      print L_TXT "\nrem  Index Script for new index ${ind_name} on " .
                  $$own_r . '.' . $$obj_r . "\n\n";

      print L_TXT "create index " . $$own_r . ".${ind_name} on\n";

      print L_TXT "   " . $$own_r . '.' . $$obj_r . " (\n";

      for my $cl (1..$$total_r){

         my $bs = "      $index_array_r->[$index_head_r->[$cl]]\n";

         if ($cl != $$total_r){
            $bs = $bs . ', ';
         }
         print L_TXT $bs;
      }

      print L_TXT "   ) tablespace ${t_n}\n";
      print L_TXT "   storage (initial ${initial_extent}K " .
                  "next ${next_extent}K pctincrease 0)\n";
      print L_TXT "   pctfree ${pct_free};\n\n";
      print L_TXT "\nrem Average Index Entry Size:  ${avg_entry_size}   ";

      my $calc_img;
      $self->get_img(\$d, \$calc_img, 'sql');
      my $b = $d->{text}->Button( -image=>$calc_img,
                                  -cursor=>'hand2',
                                  -command=>sub {$self->see_sql($d,$cm)}
                                );

      $d->{text}->window('create','end',-window=>$b);


      print L_TXT "\nrem Database Block Size:       ${Block_Size}\n";
      print L_TXT "rem Current Table Row Count:   ${n_rows}\n";
      print L_TXT "rem Available Space Per Block: ${avail_data_space}\n";
      print L_TXT "rem Space For Each Index:      ${space}\n";
      print L_TXT "rem Blocks Required:           ${blocks_req}\n\n";
   }

   my $loc_menu;
   my $balloon;
   $self->create_balloon_bars(\$loc_menu, \$balloon, \$d, );
   $self->window_exit_button(\$loc_menu, \$d, 1, \$balloon, );

   main::iconize( $d );
}

=head2 ind_prep

Small helper function for working out Index DDL.

=cut

sub ind_prep {

   my $self = shift;

   # Helper function for working out Index DDL

   my $cm = shift;
   my @bindees = @_;
   my $sth = $self->{Database_conn}->prepare($cm) ||
                die $self->{Database_conn}->errstr;
   my $num_bindees = @bindees;
   if ($num_bindees > 0){
      my $i;
      for ($i = 1;$i <= $num_bindees;$i++){
         $sth->bind_param($i,$bindees[($i - 1)]);
      }
   }
   $sth->execute;
   my @res = $sth->fetchrow;
   $sth->finish;
   return @res;
}

=head2 j_inri

Here lies the end of sanity.  Welcome!  This function drove me mad when
I first wrote it.  It basically takes several lines of radiobuttons,
and makes sure only one of the is set in each column.  This is
used to help the user select the correct ordering for their table
selections.  There must've been an easier way than this, but it worked
at the time, looked nice, and still works now, so I'm leaving it
alone.  I'll let you work out what j_inri stands for.

=cut

sub j_inri {

   my $self = shift;

   my ($index_head_r,
       $total_r,
       $index_open_r,

      ) = @_;

   # Here lies the end of sanity.  Welcome!

   my $i = 0;
   my $cl = 0;

   for $cl (1..$$total_r){

      if ($index_open_r->[$cl] != $index_head_r->[$cl])
      {
         $i = $cl;
         last;
      }
   }
   if ($i > 0){
      for $cl (1..$$total_r){
         unless ($cl == $i){
            if ($index_head_r->[$cl] == $index_head_r->[$i]){
                $index_head_r->[$cl] = $index_open_r->[$i];
                $index_open_r->[$cl] = $index_head_r->[$cl];
                last;
            }
         }
      }
      $index_open_r->[$i] = $index_head_r->[$i];
   }
}

=head2 work_out_why

Works out new Y-coordinate positions for various simple canvas graphs
called by Orac.

=cut

sub work_out_why {
   my $self = shift;

   return (0.8 + (1.2 * $_[0]));
}

=head2 add_item

Produces rectangular bar line on canvas for simple charts.

=cut

sub add_item {

   my $self = shift;

   # Produces bar line on canvas for simple charts.

   my (  $func,
         $c,
         $i,
         $T_Space,
         $Fname,
         $Total,
         $Used_Mg,
         $Free_Mg,
         $Use_Pct) = @_;

   my $old_length = 0;
   my $tab_str;

   unless($i == 0){
      if ($keep_tablespace eq $T_Space){
         $tab_str = sprintf("%${old_length}s ", '');
      } else {
         $old_length = length($T_Space);
         $tab_str = sprintf("%${old_length}s ", $T_Space);
      }
      $keep_tablespace = $T_Space;
   }
   my $thickness = 0.4;

   my $y_start = $self->work_out_why($i);

   my $y_end = $y_start + 0.4;
   my $chopper;
   if($func ne 'tune_health'){
      $chopper = 20.0;
   } else {
      $chopper = 10.0;
   }
   my $dst_f = ($Use_Pct/$chopper) + 0.4;

   $c->create( ( 'rectangle',
                 "$dst_f" . 'c',
                 "$y_start". 'c',
                 '0.4c',
                 "$y_end" . 'c'),

               -fill=>$main::lg{bar_col},

             );

   $y_start = $y_start - 0.4;

   my $this_text;

   if($i == 0){

      my $bit = '';

      $this_text = "$main::lg{db} " .
                   sprintf("%5.2f", $Use_Pct) .
                   '% '.
                   $main::lg{full} .
                   $bit;
   } else {

      $this_text = "$tab_str $Fname " .
                   sprintf("%5.2f", $Use_Pct) .
                   '%';

   }

   $c->create(   (   'text',
                     '0.4c',
                     "$y_start" . 'c',
                     -fill=>$main::fc,
                     -anchor=>'nw',
                     -justify=>'left',
                     -text=>$this_text  ,
                     -font => $main::font{name},
                 )
             );

   $y_start = $y_start + 0.4;

   if($func ne 'tune_health'){

      $c->create( ( 'text',
                    '5.2c',
                    "$y_start" . 'c',
                     -fill=>$main::fc,
                    -anchor=>'nw',
                    -justify=>'left',
                     -font => $main::font{name},
                    -text=>sprintf("%10.2fM Total %10.2fM Used %10.2fM Free",
                                   $Total,
                                   $Used_Mg,
                                   $Free_Mg
                                  )
                  )
                );
   }
}

=head2 dbwr_fileio

Works out File/IO and produces graphical report.

=cut

sub dbwr_fileio {
   my $self = shift;

   # Works out File/IO and produces graphical report.

   my $t_tit = "$main::lg{file_io} $main::v_db";

   my $d = $self->{Main_window}->Toplevel();
   $d->title($t_tit);

   my $loc_menu;
   my $balloon;
   $self->create_balloon_bars(\$loc_menu, \$balloon, \$d, );
   $self->window_exit_button(\$loc_menu, \$d, 1, \$balloon, );

   my $cf = $d->Frame;
   $cf->pack(-expand=>'1',-fill=>'both');

   $d->{text} = $cf->Scrolled(  'Canvas',
                           -relief=>'sunken',
                           -bd=>2,
                           -width=>500,
                           -height=>280,
                           -background=>$main::bc
                        );

   my $cm = $self->f_str('dbwr_fileio','1');

   my $sth = $self->{Database_conn}->prepare( $cm ) ||
                die $self->{Database_conn}->errstr;
   $sth->execute;
   my $max_value = 0;
   my $i = 0;

   my @res;
   my @dbwr_fi;

   while (@res = $sth->fetchrow) {
      $dbwr_fi[$i] = [ @res ];
      $i++;
      for $i (1 .. 6){
         if ($res[$i] > $max_value){
            $max_value = $res[$i];
         }
      }
   }
   $sth->finish;

   if($i > 0){

      $i--;

      for $i (0 .. $i){

         $self->dbwr_print_fileio(  $d->{text},
                                    $max_value,
                                    $i,
                                    $dbwr_fi[$i][0],
                                    $dbwr_fi[$i][1],
                                    $dbwr_fi[$i][2],
                                    $dbwr_fi[$i][3],
                                    $dbwr_fi[$i][4],
                                    $dbwr_fi[$i][5],
                                    $dbwr_fi[$i][6]
                                 );
      }
   }

   # Finally, give out a 'See SQL' button

   $self->see_sql_but(\$loc_menu, \$d, \$cm, 1, \$balloon, );

   $d->{text}->configure(-scrollregion=>[ $d->{text}->bbox("all") ]);
   $d->{text}->pack(-expand=>'yes',-fill=>'both');

   main::iconize( $d );
}

=head2 this_pak_get_y

Another small helper function to increment the Y-coord values
on simple Canvas line graphs.

=cut

sub this_pak_get_y {
   my $self = shift;
   return (($_[0] * 2.5) + 0.2);
}

=head2 dbwr_print_fileio

Prints out lines required for File/IO graphical report.

=cut

sub dbwr_print_fileio {
   my $self = shift;

   # Prints out lines required for File/IO graphical report.

   my (  $c,
         $max_value,
         $y_start,
         $name,
         $phyrds,
         $phywrts,
         $phyblkrd,
         $phyblkwrt,
         $readtim,
         $writetim    ) = @_;

   my @stf = ('', $phyrds,$phywrts,$phyblkrd,$phyblkwrt,$readtim,$writetim);

   my $local_max = $stf[1];
   my $i;

   for $i (2 .. 6){
      if($stf[$i] > $local_max){
         $local_max = $stf[$i];
      }
   }
   my @txt_stf = (   '',
                  'phyrds',
                  'phywrts',
                  'phyblkrd',
                  'phyblkwrt',
                  'readtim',
                  'writetim'
              );


   my $screen_ratio = 0.00;
   $screen_ratio = ($max_value/10.00);
   my $txt_name = 0.1;

   my $x_start = 2;
   $y_start = $self->this_pak_get_y($y_start);

   my $act_figure_pos = $x_start + ($local_max/$screen_ratio) + 0.5;
   my $txt_y_start;

   for $i (1 .. 6){
      my $x_stop = $x_start + ($stf[$i]/$screen_ratio);
      my $y_end = $y_start + 0.2;

      $c->create(   (  'rectangle',
                       "$x_start" . 'c',
                       "$y_start" . 'c',
                       "$x_stop" . 'c',
                       "$y_end" . 'c'
                    ),

                    -fill=>$main::lg{bar_col},

                );

      $txt_y_start = $y_start - 0.15;

      $c->create(   (   'text',
                        "$txt_name" . 'c',
                        "$txt_y_start" . 'c',
                        -fill=>$main::fc,
                        -anchor=>'nw',
                        -justify=>'left',
                        -font => $main::font{name},
                        -text=>"$txt_stf[$i]"
                    )
                );


      $c->create(   (   'text',
                        "$act_figure_pos" . 'c',
                        "$txt_y_start" . 'c',
                        -fill=>$main::fc,
                        -anchor=>'nw',
                        -justify=>'left',
                        -font => $main::font{name},
                        -text=>"$stf[$i]"
                    )
                );

      $y_start = $y_start + 0.3;
   }
   $txt_y_start = $y_start - 0.10;

   $c->create(   (   'text',
                     "$x_start" . 'c',
                     "$txt_y_start" . 'c',
                     -fill=>$main::fc,
                     -anchor=>'nw',
                     -justify=>'left',
                     -font => $main::font{name},
                     -text=>"$name"
                 )
             );

}

=head2 errors_orac

Creates Viewer window, for selecting invalid database objects.
Once this is done, all the reported compilation errors on the
object are printed in the main screen.

=cut

sub errors_orac {
   my $self = shift;

   # Creates Error Viewer window

   my $cm = $self->f_str('errors_orac','1');

   my $sth = $self->{Database_conn}->prepare( $cm ) ||
                die $self->{Database_conn}->errstr;

   $sth->execute;
   my $detected = 0;

   my @res;
   my $window;

   while (@res = $sth->fetchrow) {
      $detected++;
      if($detected == 1){

         $window = $self->{Main_window}->Toplevel();
         $window->title($main::lg{err_obj});

         my $err_menu;
         my $balloon;
         $self->create_balloon_bars(\$err_menu, \$balloon, \$window, );
         $self->window_exit_button(\$err_menu, \$window, 1, \$balloon, );
         $self->double_click_message(\$window);

         my $err_top = $window->Frame->pack(-side=>'top',
                                            -padx=>5,
                                            -expand=>'yes',
                                            -fill=>'both'
                                           );

         $window->{text} =
             $err_top->ScrlListbox(-width=>50,
                                   -font=>$main::font{name},
                                   -background=>$main::bc,
                                   -foreground=>$main::fc
                                  )->pack(-side=>'top',
                                          -expand=>'yes',
                                          -fill=>'both');

         main::iconize( $window );
      }
      $window->{text}->insert('end', @res);
   }
   $sth->finish;
   if($detected == 0){
      $self->{Main_window}->Busy(-recurse=>1);
      main::mes($self->{Main_window},$main::lg{no_rows_found});
      $self->{Main_window}->Unbusy;
   } else {

      $window->{text}->pack();

      $window->{text}->bind(
         '<Double-1>',
         sub{  $window->Busy(-recurse=>1);
               $self->selected_error(
               $window->{text}->get('active')
                                     );
               $window->Unbusy}
                                       );
   }
}

=head2 dbas_orac

Creates DBA Viewer window, for selecting various DBA_XXXX tables,
which can then be selected upon.

=cut

sub dbas_orac {
   my $self = shift;

   # Creates DBA Viewer window

   my $cm = $self->f_str('dbas_orac','1');
   my $sth = $self->{Database_conn}->prepare( $cm ) ||
                die $self->{Database_conn}->errstr;
   $sth->execute;
   my $detected = 0;

   my @res;
   my $window;

   while (@res = $sth->fetchrow) {
      $detected++;

      if($detected == 1){

         $window = $self->{Main_window}->Toplevel();
         $window->title($main::lg{dba_views});

         my $dba_menu;
         my $balloon;
         $self->create_balloon_bars(\$dba_menu, \$balloon, \$window, );
         $self->window_exit_button(\$dba_menu, \$window, 1, \$balloon, );
         $self->double_click_message(\$window);

         my(@dba_lay) = qw/-side top -padx 5 -expand yes -fill both/;
         my $dba_top = $window->Frame->pack(@dba_lay);

         $window->{text} =
            $dba_top->ScrlListbox(-width=>50,
                                  -font=>$main::font{name},
                                  -background=>$main::bc,
                                  -foreground=>$main::fc
                                 )->pack(-expand=>'yes',-fill=>'both');

         main::iconize($window);
      }
      $window->{text}->insert('end', @res);
   }
   $sth->finish;
   if($detected == 0){
      $self->{Main_window}->Busy(-recurse=>1);
      main::mes($self->{Main_window},$main::lg{no_rows_found});
      $self->{Main_window}->Unbusy;
   } else {

      $window->{text}->pack();

      $window->{text}->bind(
         '<Double-1>',
         sub{
              $window->Busy(-recurse=>1);
              $self->{Main_window}->Busy(-recurse=>1);

              $self->univ_form( 'SYS',
                                $window->{text}->get('active'),
                                'form'
                              );

              $self->{Main_window}->Unbusy;
              $window->Unbusy;
            }

                                   );
   }
}

=head2 addr_orac

Produces a list of all the PADDR addresses in the database, to
help a DBA examine what's running.  Useful info for deciding
what to kill off in a locked up database.

=cut

sub addr_orac {

   my $self = shift;

   # Creates DBA Viewer window

   my $cm = $self->f_str('addr_orac','1');
   my $sth = $self->{Database_conn}->prepare( $cm ) ||
                die $self->{Database_conn}->errstr;
   $sth->execute;
   my $detected = 0;

   my @res;
   my $window;

   while (@res = $sth->fetchrow) {
      $detected++;
      if($detected == 1){
         $window = $self->{Main_window}->Toplevel();
         $window->title($main::lg{spec_addrss});

         my $addr_menu;
         my $balloon;
         $self->create_balloon_bars(\$addr_menu, \$balloon, \$window, );
         $self->window_exit_button(\$addr_menu, \$window, 1, \$balloon, );
         $self->see_sql_but(\$addr_menu, \$window, \$cm, 1, \$balloon, );
         $self->double_click_message(\$window);

         my(@adr_lay) = qw/-side top -padx 5 -expand yes -fill both/;
         my $adr_top = $window->Frame->pack(@adr_lay);

         $window->{text} =
            $adr_top->ScrlListbox(-width=>20,
                                  -font=>$main::font{name},
                                  -background=>$main::bc,
                                  -foreground=>$main::fc
                                 )->pack(-expand=>'yes',-fill=>'both');

         main::iconize($window);
      }
      $window->{text}->insert('end', @res);
   }
   $sth->finish;

   if($detected == 0){

      $self->{Main_window}->Busy(-recurse=>1);
      main::mes($self->{Main_window},$main::lg{no_rows_found});
      $self->{Main_window}->Unbusy;

   } else {

      $window->{text}->pack();

      $window->{text}->bind(
         '<Double-1>',
         sub{
               my $loc_addr = $window->{text}->get('active');

               $self->f_clr( $main::v_clr );
               $self->show_sql( 'sel_addr' , '1',
                                $main::lg{sel_addr} . ': ' . $loc_addr,
                                $loc_addr );

            }
                                     );

   }
}

=head2 sids_orac

Produces a list of all the SIDs in the database, to
help a DBA examine what's running.  Useful info for deciding
what to kill off in a locked up database.

=cut

sub sids_orac {

   my $self = shift;

   # Creates DBA Viewer window

   my $cm = $self->f_str('sids_orac','1');
   my $sth = $self->{Database_conn}->prepare( $cm ) ||
                die $self->{Database_conn}->errstr;
   $sth->execute;
   my $detected = 0;

   my @res;
   my $window;

   while (@res = $sth->fetchrow) {
      $detected++;
      if($detected == 1){
         $window = $self->{Main_window}->Toplevel();
         $window->title($main::lg{spec_sids});

         my $sid_menu;
         my $balloon;
         $self->create_balloon_bars(\$sid_menu, \$balloon, \$window, );
         $self->window_exit_button(\$sid_menu, \$window, 1, \$balloon, );
         $self->see_sql_but(\$sid_menu, \$window, \$cm, 1, \$balloon, );
         $self->double_click_message(\$window);

         my(@sid_lay) = qw/-side top -padx 5 -expand yes -fill both/;
         my $sid_top = $window->Frame->pack(@sid_lay);

         $window->{text} =
            $sid_top->ScrlListbox(-width=>20,
                                  -font=>$main::font{name},
                                  -background=>$main::bc,
                                  -foreground=>$main::fc
                                 )->pack(-expand=>'yes',-fill=>'both');

         main::iconize($window);
      }
      $window->{text}->insert('end', @res);
   }
   $sth->finish;
   if($detected == 0){
      $self->{Main_window}->Busy(-recurse=>1);
      main::mes($self->{Main_window},$main::lg{no_rows_found});
      $self->{Main_window}->Unbusy;
   } else {

      $window->{text}->pack();

      $window->{text}->bind(
         '<Double-1>',
         sub { $window->Busy(-recurse=>1);

               $self->f_clr( $main::v_clr );

               # 5 jan 2000, Andre Seesink <Andre.Seesink@CreXX.nl>
               # Now we get sid and username

               my ($sid, $username) = split(' ',$window->{text}->get('active'));
               $self->show_sql( 'sel_sid' , '1',
                                $main::lg{sel_sid} . ': ' . $sid,
                                $sid );
               $window->Unbusy
             }
                                     );
   }
}

=head2 gh_roll_name

Produces Rollback report.

=cut

sub gh_roll_name {
   my $self = shift;

   my $cm = $self->f_str('time','2');
   my $sth = $self->{Database_conn}->prepare($cm) ||
                die $self->{Database_conn}->errstr;
   $sth->execute;
   my($sample_time) = $sth->fetchrow;

   $sth->finish;

   $self->{Text_var}->insert('end', "$sample_time\n");

   $self->show_sql( 'roll_orac','2',
                    $main::lg{roll_seg_stats}
                  );

   $self->about_orac('txt/Oracle/rollback.1.txt');

}

=head2 gh_roll_stats

Produces Rollback Statistics report.

=cut


sub gh_roll_stats {
   my $self = shift;

   my $cm = $self->f_str('time','2');
   my $sth = $self->{Database_conn}->prepare($cm) ||
                die $self->{Database_conn}->errstr;
   $sth->execute;
   my($sample_time) = $sth->fetchrow;
   $sth->finish;

   $self->{Text_var}->insert('end', "$sample_time\n");
   $self->show_sql( 'roll_orac','1',
                    $main::lg{roll_seg_stats}
                  );
   $self->about_orac('txt/Oracle/rollback.2.txt');
}

=head2 gh_pool_frag

Produces reports trying to determine shared pool fragmentation, etc.

=cut

sub gh_pool_frag {

   my $self = shift;

   $self->about_orac('txt/Oracle/pool_frag.1.txt');
   $self->show_sql( 'pool_frag','1',
                    $main::lg{pool_frag}
                  );
   $self->about_orac('txt/Oracle/pool_frag.2.txt');

}

=head2 explain_plan

Produces a scrolling box, with which to view all of the SQL code
in the database library.  If the user is the logged-on user, gives
Orac user opportunity to "Explain Plan".  Alternatively, Orac user
can clear screen and input their own new SQL to "Explain".

=cut


sub explain_plan {

   my $self = shift;

   # First of all, check if we have the correct PLAN_TABLE
   # on board?

   my $explain_ok = 0;

   if ($self->check_exp_plan() == 0){

      main::mes($self->{Main_window},$main::lg{use_utlxplan});

   } else {

      $explain_ok = 1;

   }

   my $window;

   $window = $self->{Main_window}->Toplevel();
   $window->title($main::lg{explain_plan});

   my $dmb;
   my $balloon;
   $self->create_balloon_bars(\$dmb, \$balloon, \$window );

   # Add buttons.  Add a holder for the actual explain plan
   # button so we can enable/disable it later

   if($explain_ok){

      my $img;
      $self->get_img( \$window, \$img, 'explain' );

      $expl_butt = $dmb->Button(-image=>$img,
                                -command=>sub{ $self->explain_it(\$window) }
                               )->pack(side=>'left');

      $balloon->attach($expl_butt, -msg => $main::lg{explain} );

      $self->get_img( \$window, \$img, 'eraser' );

      my $clr_b = $dmb->Button(  -image=>$img,
                                 -command=>sub{

                         $window->Busy(-recurse=>1);

                         $w_explain[2]->delete('1.0','end');
                         $w_holders[0] = $main::v_sys;
                         $w_holders[1] = $main::lg{explain_help};
                         $expl_butt->configure(-state=>'normal');

                         $window->Unbusy;
                                              }
                              )->pack(side=>'left');

      $balloon->attach($clr_b, -msg => $main::lg{clear} );
   }
   $self->window_exit_button(\$dmb, \$window, 1, \$balloon, );

   # Set counter up

   my $i;

   # Produce input/update screen.  First, get the SQL select
   # array filled, so we can work out the field titles

   my $cm = $self->f_str('explain_plan','2');
   my $sth;
   $sql_browse_arr = $self->do_query_fetch_all( $cm, \$sth );
   @w_titles = @{$sth->{NAME}};

   # Work out the length of the Titles fields

   my $num_cols = @w_titles;

   my $l_label_width = 5;
   my $l_entry_width = 55;
   my $l_entry_height = 13;

   for($i=0;$i<$num_cols;$i++){
      if( (length($w_titles[$i])) > $l_label_width){
         $l_label_width = length($w_titles[$i]);
      }
   }

   # Now work out screen sizings

   my(@exp_lay) = qw/-side top -padx 5 -expand yes -fill both/;
   my $top_slice = $window->Frame->pack(@exp_lay);

   for($i=0;$i<$num_cols;$i++){

      #  0  user
      #  1  address
      #  2  SQL

      $w_holders[$i] = '';
      $w_explain[$i] = $top_slice->Entry(
                              -textvariable=>\$w_titles[$i],
                              -width=>$l_label_width
                                        );

      Tk::grid(  $w_explain[$i],
                 -row=>$i,
                 -column=>0,
                 -sticky=>'ne',
              );

      if ($i == 2){
         $w_explain[$i] =
            $top_slice->Scrolled(
                                  'Text',
                                  -height=>$l_entry_height,
                                  -width=>$l_entry_width,
                                  -font=>$main::font{name},
                                  -foreground=>$main::fc,
                                  -background=>$main::ec
                                );

         Tk::grid(  $w_explain[$i],
                    -row=>$i,
                    -column=>1,
                    -sticky=>'nsew',
                 );
      }
      else {
         $w_explain[$i] =
              $top_slice->Entry(
                                 -textvariable=>\$w_holders[$i],
                                 -width=>$l_entry_width
                               );

         Tk::grid(  $w_explain[$i],
                    -row=>$i,
                    -column=>1,
                    -sticky=>'w',
                 );
      }
      $w_explain[$i]->configure(-background=>$main::ec,
                                -foreground=>$main::fc,
                                -font=>$main::font{name},
                               );
   }
   my($columns,$rows) = $top_slice->gridSize();
   for ($i = 0;$i < $columns; $i++){
      unless ($i == ($columns - 1))
      {
        $top_slice->gridColumnconfigure($i, -weight => 0);
      }
      else
      {
        $top_slice->gridColumnconfigure($i, -weight => $l_entry_width);
      }
   }
   for ($i = 0;$i < $rows; $i++){
      unless ($i == ($rows - 1))
      {
         $top_slice->gridRowconfigure($i, -weight => 0);
      }
      else
      {
         $top_slice->gridRowconfigure($i, -weight => $l_entry_height);
      }
   }

   # Now build up the slider, which will trawl through v$sqlarea to
   # paste up various bits of SQL text currently in database.

   my $sql_min_row = 0;
   my $sql_max_row = @$sql_browse_arr;

   unless ($sql_max_row == 0){
      $sql_row_count = $sql_min_row;

      # Build up scale slider button, and splatt onto window.

      my $bot_slice =
             $window->Frame->pack( -before=>$top_slice,
                                                    -side=>'bottom',
                                                    -padx=>5,
                                                    -expand=>'no',
                                                    -fill=>'both'
                                                  );

      $sql_slider =
         $bot_slice->Scale(
            -orient=>'horizontal',
            -label=>"$main::lg{rec_of} " . $sql_max_row,
            -length=>400,
            -sliderrelief=>'raised',
            -from=>1,
            -to=>$sql_max_row,
            -tickinterval=>($sql_max_row/8),
            -command=>[ sub {$self->calc_scale_sql($sql_slider->get(),
                                                   $explain_ok)} ]
                          )->pack(side=>'left');

      $self->see_sql_but(\$dmb, \$window, \$cm, 1, \$balloon, );
      $self->pick_up_sql($explain_ok);

   } else {
      # There are no rows (very unlikely) so blatt out memory
      undef $sql_browse_arr;
   }

   main::iconize( $window );

   return;
}

=head2 explain_it

Takes the SQL statement directly from the screen and tries an 'Explain Plan'
on it.  I'm leaving the SQL hard-coded here so you can see EXACTLY
what's going on, particularly as we're dipping our toes into DML.

=cut

sub explain_it {
   my $self = shift;

   my ($win_ref) = @_;

   my $cm = "";

   # Takes the SQL statement directly from the screen
   # and tries an 'Explain Plan' on it.  I'm leaving the
   # SQL hard-coded here so you can see EXACTLY what's
   # going on, particularly as we're dipping our toes
   # into DML.

   # BTW We're automatically set up for autocommit, with
   # DBI, so there's no need to commit the 'delete'
   # transaction

   my $sql_bit = $w_explain[2]->get("1.0", "end");

   # The following is the first (and hopefully only)
   # DML in the whole of Orac.

   my $ex_sql = ' explain plan set statement_id ' .
                '= \'orac_explain_plan\' for ' . $sql_bit . ' ';

   my $del_sql = ' delete from plan_table ' .
                 'where statement_id = \'orac_explain_plan\' ';

   my $rc  = $self->{Database_conn}->do( $del_sql );

   # Stop warning messages appearing.  Instead, put them
   # into an Explain plan window, should they occur.

   $main::conn_comm_flag = 1;
   my $output = "";

   $rc  = $self->{Database_conn}->do( $ex_sql );

   if (defined($DBI::errstr)){
      $output .= $DBI::errstr;
      $cm .= $ex_sql;
   }
   else
   {
      $cm =   ' select rtrim(lpad(\'  \',2*level)|| ' . "\n" .
              ' rtrim(operation)||\' \'|| ' . "\n" .
              ' rtrim(options)||\' \'|| ' . "\n" .
              ' object_name) query_plan ' . "\n" .
              ' from plan_table ' . "\n" .
              ' where statement_id = \'orac_explain_plan\' ' . "\n" .
              ' connect by prior id = parent_id ' .
              ' and statement_id = \'orac_explain_plan\' ' . "\n" .
              ' start with id = 0 and statement_id = \'orac_explain_plan\' ';

      my $sth = $self->{Database_conn}->prepare( $cm ) ||
                   die $self->{Database_conn}->errstr;

      if (defined($DBI::errstr)){
         $output .= $DBI::errstr;
      }
      else
      {
         $sth->execute;

         if (defined($DBI::errstr)){
            $output .= $DBI::errstr;
         }
         else
         {
            my @res;
            while (@res = $sth->fetchrow) {
               $output .= "$res[0]\n";
            }
            $sth->finish;
         }
      }
   }

   # Turn error reporting back on again :-)

   $main::conn_comm_flag = 0;

   # Tag on the actual SQL

   $output .= "\n\n${sql_bit}\n";

   # Get the references so we can add another button to the screen

   my($ss_menu_ref, $ss_ball_ref, $ss_win_ref, ) =
      $self->see_sql( $$win_ref,
                      $output,
                      $main::lg{explain_plan},
                    );

   # Add on a 'See SQL' button

   $self->see_sql_but($ss_menu_ref, $ss_win_ref, \$cm, 1, $ss_ball_ref, );

   return;
}

=head2 calc_scale_sql

Whizz backwards and forwards through the v$sqlarea records, picking up
the right ones to put into the SQL Browser.

=cut

sub calc_scale_sql {

   my $self = shift;

   # Whizz backwards and forwards through the
   # v$sqlarea records

   my($sv,$expl_ok) = @_;
   $sql_row_count = $sv - 1;

   $self->pick_up_sql($expl_ok);

}

=head2 pick_up_sql

Takes a DBI information array, and takes out the correct required line
from it, and pastes it onto the screen.  What fun!  :)

=cut

sub pick_up_sql {
   my $self = shift;

   my($expln_ok) = @_;

   # Work out which row of information to display,
   # and then display it.

   my $curr_ref = $sql_browse_arr->[$sql_row_count];

   # Now chop it up for formatting purposes.

   # Put up the name in the holding variable
   my $i;
   for ($i=0;$i<3;$i++)
   {
      if($i == 2){
         $w_explain[$i]->delete('1.0','end');
         $w_explain[$i]->insert('1.0',$curr_ref->[$i]);
      }
      else {
         $w_holders[$i] = $curr_ref->[$i];
      }
   }
   $sql_slider->set(($sql_row_count + 1));

   # Enable the 'Explain Plan' button, if the logged on
   # user, is the same as the SQL's user

   if($expln_ok){
      if($main::v_sys eq $w_holders[0]){
         $expl_butt->configure(-state => 'normal');
      } else {
         $expl_butt->configure(-state => 'disabled');
      }
   }
   return;
}

=head2 check_exp_plan

Check if the currently logged on DBA user has a valid PLAN_TABLE table to put
'Explain Plan' results to insert into.

=cut


sub check_exp_plan {
   my $self = shift;

   # Check if the currently logged on DBA user
   # has a valid PLAN_TABLE table to put
   # 'Explain Plan' results to insert into.

   my $cm = $self->f_str('explain_plan','1');
   my $sth = $self->{Database_conn}->prepare($cm) ||
                die $self->{Database_conn}->errstr;
   $sth->execute;
   my $detected = 0;

   my @res;

   while (@res = $sth->fetchrow) {
      $detected = $res[0];
   }
   $sth->finish;

   return $detected;
}

=head2 block_size

Reads storage of the required Block Size value from a package variable, and
then gives it back to the caller.

=cut

sub block_size {
   my $self = shift;
   return $Block_Size;
}

=head2 who_hold

One of my most life-saving functions.  This works out which user is blocking
which user is nasty lockup situations.  Kill, is usually the answer.

=cut

sub who_hold
{
   my $self = shift;

   # Slightly complicated.
   # Build up a scrolling list of all the users
   # who're holding everyone back.  This can be
   # double-clicked to bring up a 'See SQL' type
   # screen.  After scroll-list, insert the report.

   my $scrllist_str;

   my $l_osuser;
   my $l_username;
   my $l_serial;
   my $l_sid;
   my $l_pid;

   my $l_wait_title;
   my $l_hold_title;
   my $l_os_title;
   my $l_ser_title;
   my $l_sid_title;
   my $l_pid_title;

   my @res;
   my @title_values;

   my $cm = $self->f_str( 'wait_hold' , '1' );

   # Now show Report for finding Who's holding whom?
   # Make sure the screen isn't cleared beforehand.


   my $scroll_box;
   my $scroll_label;

   my $sth = $self->{Database_conn}->prepare( $cm ) ||
                die $self->{Database_conn}->errstr;
   $sth->execute;

   my $l_counter = 0;

   while ( @res = $sth->fetchrow ) {

      if ($l_counter == 0){
         my $i;
         for ($i = 0;$i < $sth->{NUM_OF_FIELDS};$i++){
            $title_values[$i] = $sth->{NAME}->[$i];
         }
         $l_wait_title = $title_values[0];
         $l_os_title = $title_values[7];
         $l_hold_title = $title_values[6];
         $l_ser_title = $title_values[8];
         $l_sid_title = $title_values[9];
         $l_pid_title = $title_values[10];

         $l_counter = 1;

         $scroll_label =
            $self->{Text_var}->Label(
               -cursor=>'hand2',
               -text=>"$main::lg{see_sql} $main::lg{doub_click}",
               -relief=>'raised'
                                    );

         $scroll_box =
            $self->{Text_var}->ScrlListbox(-width=>76,
                                           -cursor=>'hand2',
                                           -height=>3,
                                           -background=>$main::ec,
                                           -foreground=>$main::fc
                                          );

         $self->{Text_var}->windowCreate('end',-window=>$scroll_label);
         $self->{Text_var}->insert('end', "\n");

         $self->{Text_var}->windowCreate('end',-window=>$scroll_box);
         $self->{Text_var}->insert('end', "\n");
      }

      # Wait User first

      $l_username = $res[0];
      $l_osuser = $res[1];
      $l_serial = $res[2];
      $l_sid = $res[3];
      $l_pid = $res[4];

      $scrllist_str = "$l_wait_title:$l_username," .
                      "$l_os_title:$l_osuser," .
                      "$l_ser_title:$l_serial," .
                      "$l_sid_title:$l_sid," .
                      "$l_pid_title:$l_pid";

      $scroll_box->insert('end', $scrllist_str);

      # Hold User

      $l_username = $res[6];
      $l_osuser = $res[7];
      $l_serial = $res[8];
      $l_sid = $res[9];
      $l_pid = $res[10];

      $scrllist_str = "$l_hold_title:$l_username," .
                      "$l_os_title:$l_osuser," .
                      "$l_ser_title:$l_serial," .
                      "$l_sid_title:$l_sid," .
                      "$l_pid_title:$l_pid";

      $scroll_box->insert('end', $scrllist_str);
   }
   $sth->finish;

   if ($l_counter == 1){
      $scroll_box->bind(

            '<Double-1>',
            sub{  $self->{Main_window}->Busy(-recurse=>1);
                  my @first_string = split(',', $scroll_box->get('active') );

                  my @v_osuser = split('\:', $first_string[1]);
                  my @v_username = split('\:', $first_string[0]);
                  my @v_sid = split('\:', $first_string[2]);

                  $self->who_what( 1,
                                   $v_osuser[1],
                                   $v_username[1],
                                   $v_sid[1]
                                 );
                  $self->{Main_window}->Unbusy
               }
                       );
      $self->{Text_var}->insert('end', "\n");
   }

   # And finally, thank goodness, the actual report.

   $self->show_sql( 'wait_hold' , '1',
                    $main::lg{who_hold} );
}

=head2 mts_mem

Report for finding MTS statistics, and providing secondary button
to reveal further stats.

=cut

sub mts_mem
{
   my $self = shift;

   # Report for finding MTS statistics,
   # and providing secondary button to reveal further stats

   my $cm = $self->f_str( 'sess_curr_max_mem' , '1' );

   my $l_counter = 0;

   my $who_what_str;

   my $l_stat;
   my $l_stat_title;

   my $scroll_label;
   my $scroll_box;

   my @res;
   my @title_values;

   my $sth = $self->{Database_conn}->prepare( $cm ) ||
                die $self->{Database_conn}->errstr;
   $sth->execute;

   while ( @res = $sth->fetchrow ) {

      if ($l_counter == 0){
         my $i;
         for ($i = 0;$i < $sth->{NUM_OF_FIELDS};$i++){
            $title_values[$i] = $sth->{NAME}->[$i];
         }
         $l_stat_title = $title_values[0];

         $l_counter = 1;

         $scroll_label =
            $self->{Text_var}->Label(
               -cursor=>'hand2',
               -text=>"$main::lg{doub_click}",
               -relief=>'raised'
                                    );

         $scroll_box =
            $self->{Text_var}->ScrlListbox(-width=>40,
                                           -cursor=>'hand2',
                                           -height=>3,
                                           -background=>$main::ec,
                                           -foreground=>$main::fc
                                          );

         $self->{Text_var}->windowCreate('end',-window=>$scroll_label);
         $self->{Text_var}->insert('end', "\n");

         $self->{Text_var}->windowCreate('end',-window=>$scroll_box);
         $self->{Text_var}->insert('end', "\n");
      }

      $l_stat = $res[0];

      $who_what_str = "${l_stat_title}:$l_stat";
      $scroll_box->insert('end', $who_what_str);
   }
   $sth->finish;

   if ($l_counter == 1){
      $scroll_box->bind(

            '<Double-1>',
            sub{  $self->{Main_window}->Busy(-recurse=>1);
                  my @stat_str = split('\:', $scroll_box->get('active') );

                  $self->who_what( 2,
                                   $stat_str[1],
                                   "${l_stat_title}:$stat_str[1]",
                                 );
                  $self->{Main_window}->Unbusy
               }
                       );

      $self->{Text_var}->insert('end', "\n");
   }
   $self->show_sql( 'sess_curr_max_mem' , '1',
                    $main::lg{mts_mem} );

}

=head2 do_a_generic

On the final level of an HList, does the actual work required.

Takes the final PL/SQL function, runs it, and then splatts out the
results into a DialogBox for the User to peruse.

=cut

sub do_a_generic {

   my $self = shift;

   # On the final level of an HList, does the actual work
   # required.

   my ($l_mw, $l_gen_sep, $l_hlst, $input) = @_;

   $l_mw->Busy(-recurse=>1);
   my $owner;
   my $generic;
   my $dum;

   ($owner, $generic, $dum) = split("\\$l_gen_sep", $input);

   my $window = $self->{Main_window}->Toplevel();

   $window->bind('<Destroy>' => sub {
                                 $window = undef;
                                                    }
                                );

   # We may be using pretty :-) icons instead of text.  If so,
   # we gotta give help to let people know what the icons are.

   my $menu_bar;
   my $balloon;
   my %b_images;

   $self->create_balloon_bars(\$menu_bar, \$balloon, \$window );

   if ( ($l_hlst eq 'Tables') ||
        ($l_hlst eq 'Indexes') ||
        ($l_hlst eq 'Views') )
   {
      foreach my $bit ( 'form',
                        'freespace',
                        'index',
                        'sizeindex',
                        'constraint',
                        'trig',
                        'comment',
                     )
      {
         $self->get_img( \$window, \$b_images{$bit}, $bit );
      }
   }

   # An image for the 'Lines' button
   # Also, store the final variable here, which
   # is used to store the text

   my $text_lines = '';
   $self->get_img( \$window, \$b_images{lines}, 'lines' );

   my $label_text;

   if (!defined($generic)){
      $label_text = "$l_hlst $main::lg{sql_for} $owner";
   }
   else {
      $label_text = "$l_hlst $main::lg{sql_for} $owner.$generic";
   }

   $window->title($label_text);

   $window->{text} =
      $window->Scrolled(
                         'Text',
                         -height=>16,
                         -wrap=>'none',
                         -font=>$main::font{name},
                         -foreground=>$main::fc,
                         -background=>$main::bc
                        )->pack(-expand=>1,-fil=>'both');

   tie (*L_TEXT, 'Tk::Text', $window->{text} );

   my $cm;

   if ( $l_hlst eq 'Refreshgroups' )
   {
     $cm = $self->f_str( $l_hlst , '99' );

     $self->{Database_conn}->func(1000000, 'dbms_output_enable');
     my $second_sth = $self->{Database_conn}->prepare( $cm ) ||
        die $self->{Database_conn}->errstr;

     $second_sth->bind_param(1,$owner);
     $second_sth->bind_param(2,$generic);
     $second_sth->execute;

     my $j = 0;
     my $full_list;

     my $consec_empty = 0;

     while($j < 100000){
        $full_list = scalar $self->{Database_conn}->func('dbms_output_get');
        if ((!defined($full_list)) || (length($full_list) == 0)){
           $consec_empty++;
        }
        else {
           $consec_empty = 0;
           $text_lines = $text_lines . "$full_list\n";
        }
        if ($consec_empty > 100){
           last;
        }
        $j++;
     }
   }
   elsif (
              $l_hlst eq 'Triggers'
           or $l_hlst eq 'Tab_Indexes'
           or $l_hlst eq 'Tab_Constraints'
         )
   {
     my $stmt;
     my $type;

     if ( $l_hlst eq 'Triggers' )
     {
       $type = 'trigger';

       $stmt =
          "
           SELECT
                  '$owner'
                , trigger_name
           FROM
                  ${view}_triggers
           WHERE
                  table_name = '$generic'
          ";
     }
     elsif ( $l_hlst eq 'Tab_Indexes' )
     {
       $type = 'index';

       $stmt =
          "
           SELECT
                  '$owner'
                , index_name
           FROM
                  ${view}_indexes
           WHERE
                  table_name = '$generic'
          ";
     }
     elsif ( $l_hlst eq 'Tab_Constraints' )
     {
       $type = 'constraint';

       $stmt =
          "
           SELECT
                  '$owner'
                , constraint_name
           FROM
                  ${view}_constraints
           WHERE
                  table_name = '$generic'
          ";
     }

     if ( $view eq 'DBA' )
     {
       $stmt .=  "   AND  owner = '$owner'";
     }

     $stmt .=  "ORDER BY 2";

     my $sth = $self->{Database_conn}->prepare( $stmt ) ||
                die $self->{Database_conn}->errstr;
     $sth->execute;
     my $aref = $sth->fetchall_arrayref;
     $sth->finish;

     my $obj = DDL::Oracle->new(
                                 type => $type,
                                 list => $aref,
                               );
     $text_lines = $obj->create ;
   }
   else
   {

     my $obj = DDL::Oracle->new(
                                 type => $l_hlst_to_type{ $l_hlst },
                                 list => [
                                           [
                                             $owner,
                                             $generic || $owner,
                                           ]
                                         ],
                               );

     if (
             $l_hlst eq 'Tab_FreeSpace'
          or $l_hlst eq 'Index_FreeSpace'
        )
     {
       $text_lines = $obj->show_space ;
     }
     else
     {
       $text_lines = $obj->create ;
     }
   }

   # Finally, pump out the monkey

#here
   $window->{text}->insert('end', $text_lines);
#   $self->{Text_var}->delete('1.0', 'end');
#   $self->{Text_var}->insert('end', "$text_lines\n");

   $self->see_sql_but(\$menu_bar, \$window, \$cm, 1, \$balloon, );

   $b = $menu_bar->Button(-image=>$b_images{lines},

                             -command=> sub{

                         $window->Busy(-recurse=>1);

                         my @lines_of_txt = split(/^/, $text_lines);

                         my $line_counter = 1;
                         my $final_txt = '';

                         foreach my $line (@lines_of_txt)
                         {
                            $final_txt =
                               $final_txt .
                               sprintf(  "%5d: %s",
                                         $line_counter,
                                         $lines_of_txt[($line_counter - 1)]
                                      );
                            $line_counter++;
                         }

                         $self->see_sql($window,$final_txt,$label_text);
                         $window->Unbusy;

                                           }

                             )->pack(-side=>'left');

   $balloon->attach($b, -msg => $main::lg{lines} );

   if ( ($l_hlst eq 'Tables') || ($l_hlst eq 'Indexes') ){

      if ($l_hlst eq 'Tables') {

            my $b = $menu_bar->Button(-image=>$b_images{form},
                                     -command=> sub{

                                  $window->Busy(-recurse=>1);

                                  $self->univ_form($owner,
                                                   $generic,
                                                   'form');

                                  $window->Unbusy

                                                   }

                                      )->pack(-side=>'left');

            $balloon->attach($b, -msg => $main::lg{form});

            $b = $menu_bar->Button( -image=>$b_images{sizeindex},
                                    -command=> sub {

                              $window->Busy(-recurse=>1);
                              $self->univ_form($owner,
                                               $generic,
                                               'index'
                                              );
                              $window->Unbusy

                                                   }

                                  )->pack(-side=>'left');

            $balloon->attach($b, -msg => $main::lg{sizeindex});

      }
      my @tablist;
      my @tablist_2;

      if ($l_hlst eq 'Tables') {

         @tablist = ('Tab_Indexes',
                     'Tab_FreeSpace',
                     'Tab_Constraints',
                     'Triggers',
                     'Comments');
         @tablist_2 = ('index',
                       'freespace',
                       'constraint',
                       'trig',
                       'comment');
      }
      elsif ($l_hlst eq 'Indexes') {

         @tablist = ('Index_FreeSpace');
         @tablist_2 = ('freespace');
      }

      my $i = 0;
      foreach ( @tablist ) {

         my $this_txt = $_;

         $b = $menu_bar->Button( -image=>$b_images{$tablist_2[$i]},
               -text=>$tablist_2[$i],

               -command=> sub {

                    $self->do_a_generic($window, '.', $this_txt, $input);

                              },

                          )->pack(-side=>'left');
         $balloon->attach($b, -msg => $main::lg{$tablist_2[$i]});
         $i++;
      }

   } elsif ($l_hlst eq 'Views'){

         my $b = $menu_bar->Button(
            -image=>$b_images{form},
            -command=>sub{  $window->Busy(-recurse=>1);

                            $self->univ_form(  $owner,
                                               $generic,
                                               'form'
                                            );
                            $window->Unbusy }

                                 )->pack(-side=>'left');

         $balloon->attach($b, -msg => $main::lg{form});
   }

   $self->window_exit_button(\$menu_bar, \$window, 1, \$balloon, );

   main::iconize( $window );

   $l_mw->Unbusy;
}

=head2 tab_det_orac

Produces simple graphical representations of complex percentage style reports.

=cut

sub tab_det_orac {

   my $self = shift;

   # Produces simple graphical representations of complex
   # percentage style reports.

   my ( $title, $func, $file_number ) = @_;

   my $d = $self->{Main_window}->Toplevel();
   $d->title("$title: $main::v_db ($main::lg{blk_siz} $Block_Size)");

   my $loc_menu;
   my $balloon;
   $self->create_balloon_bars(\$loc_menu, \$balloon, \$d, );
   $self->window_exit_button(\$loc_menu, \$d, 1, \$balloon, );

   my $cf = $d->Frame;
   $cf->pack(-expand=>'1',-fill=>'both');

   $d->{text} = $cf->Scrolled( 'Canvas',
                          -relief=>'sunken',
                          -bd=>2,
                          -width=>500,
                          -height=>280,
                          -background=>$main::bc
                        );

   $keep_tablespace = 'XXXXXXXXXXXXXXXXX';

   my $cm = $self->f_str($func, $file_number, );

   my $sth = $self->{Database_conn}->prepare( $cm ) ||
                die $self->{Database_conn}->errstr;

   # 3 jan 2000, Andre Seesink <Andre.Seesink@CreXX.nl>
   # commented out, because we do not need this anymore
   # the new tab_det_orac.1.sql does not need the blocksize anymore
   #
   #   if($func eq 'tab_det_orac'){
   #      my $i;
   #      for ($i = 1;$i <= 6;$i++){
   #         $sth->bind_param($i,$Block_Size);
   #      }
   #   }

   $sth->execute;

   my $i = 1;

   my $Grand_Total = 0.00;
   my $Grand_Used_Mg = 0.00;
   my $Grand_Free_Mg = 0.00;

   my @res;

   my $Use_Pct;
   my $Used_Mg;
   my $Total;
   my $Fname;
   my $T_Space;
   my $Free_Mg;

   while (@res = $sth->fetchrow) {
     if($func eq 'tabspace_diag'){
        if($res[0] eq 'free'){
           $Free_Mg = $res[2];
           next;
        } else {
           $T_Space = $res[1];
           $Fname = '';
           $Total = $res[2];
           $Used_Mg = $Total - $Free_Mg;
           $Use_Pct = ($Used_Mg/$Total)*100;
        }
     } else {
        ($T_Space,$Fname,$Total,$Used_Mg,$Free_Mg,$Use_Pct) = @res;
     }
     # 3 jan 2000, Andre Seesink <Andre.Seesink@CreXX.nl>
     # there will be no more variables undefined after we use the new 
     # tab_det_orac.1.sql script
     #
     #     if ((!defined($Used_Mg)) || (!defined($Use_Pct))){
     #        $Used_Mg = 0.00;
     #        $Use_Pct = 0.00;
     #     }
     $Grand_Total = $Grand_Total + $Total;
     $Grand_Used_Mg = $Grand_Used_Mg + $Used_Mg;
     if (defined($Free_Mg)){
        $Grand_Free_Mg = $Grand_Free_Mg + $Free_Mg;
     }
     if($func ne 'tab_det_orac'){
        $Fname = '';
     }
     if($func eq 'tune_health'){
        $Use_Pct = $Total;
     }
     $self->add_item( $func,
                      $d->{text},
                      $i,
                      $T_Space,
                      $Fname,
                      $Total,
                      $Used_Mg,
                      $Free_Mg,
                      $Use_Pct
                    );
     $i++;
   }
   $sth->finish;

   if($func ne 'tune_health'){
      my $Grand_Use_Pct = (($Grand_Used_Mg/$Grand_Total)*100.00);

      $self->add_item(  $func,
                        $d->{text},
                        0,
                        '',
                        '',
                        $Grand_Total,
                        $Grand_Used_Mg,
                        $Grand_Free_Mg,
                        $Grand_Use_Pct
                     );
   }

   # Finally, give out a 'See SQL' button

   $self->see_sql_but(\$loc_menu, \$d, \$cm, 1, \$balloon, );

   $d->{text}->configure(-scrollregion=>[ $d->{text}->bbox("all") ]);
   $d->{text}->pack(-expand=>'yes',-fill=>'both');

   main::iconize( $d );

}

######################## Development ###########################################

=head2 dev_tables

Creates DBA Viewer window, for selecting various DBA_XXXX tables,
which can then be selected upon.

=cut

sub dev_tables {
   my $self = shift;
   my ( $obj_type ) = @_;

   # Creates Tables Viewer window

   my $cm = $self->f_str('dev_tables',$obj_type);
   my $sth = $self->{Database_conn}->prepare( $cm ) ||
                die $self->{Database_conn}->errstr;
   $sth->execute;
   my $detected = 0;

   if ($obj_type =~ /^PACKAGE_BODY$/){
      $obj_type = 'PACKAGE BODY';
   }

   my @res;
   my $window;

   my $schema = 0;
   my $prompt = 0;
   my $resize = 0;
   my $action = 'create';

   my $text ;
   my $current_index ;
   my $blue_tag ;
   my $purple_tag ;
   my $red_tag ;
   my $green_tag ;
   my $eraser ;
   my $b ;

   while (@res = $sth->fetchrow) {
      $detected++;

      if($detected == 1){

         $window = $self->{Main_window}->Toplevel();
         $window->title($obj_type . " DDL");

         my $dev_menu;
         my $balloon;
         $self->create_balloon_bars(\$dev_menu, \$balloon, \$window, );
         $self->window_exit_button(\$dev_menu, \$window, 1, \$balloon, );

         $eraser = $window->Photo(-file=>"$FindBin::RealBin/img/eraser.gif");
 	
         $b = $dev_menu->Button(-image=>$eraser,
                                -command=>sub{

              $window->Busy(-recurse=>1);
              $self->{Main_window}->Busy(-recurse=>1);

              $text->delete('1.0','end');

              $self->{Main_window}->Unbusy;
              $window->Unbusy;
                                             }

                               )->pack(side=>'right');

         $balloon->attach($b, -msg => $main::lg{clear});

         my $dev_2_menu;
         my $balloon2;
         $self->create_balloon_bars(\$dev_2_menu, \$balloon2, \$window, );

         $self->double_click_message(\$window);

         my $label1 = $dev_menu->Label(relief=>'ridge'
                               )->pack (-side=>'left',
                                        -anchor=>'w');

         $label1->Radiobutton(variable=>\$prompt,
                              text=>"Prompt Off",
                              value=>0
                             )->pack (-side=>'left',
                                      -anchor=>'w');

         $label1->Radiobutton(variable=>\$prompt,
                              text=>"On",
                              value=>1
                             )->pack (-side=>'left',
                                      -anchor=>'w');

         my $label2 = $dev_menu->Label(relief=>'ridge'
                               )->pack (-side=>'left',
                                        -anchor=>'w');

         $label2->Radiobutton(variable=>\$schema,
                              text=>"Schema Off",
                              value=>0
                             )->pack (-side=>'left',
                                      -anchor=>'w');

         $label2->Radiobutton(variable=>\$schema,
                              text=>"On",
                              value=>1
                             )->pack (-side=>'left',
                                      -anchor=>'w');

         my $resize_state = 'disabled';

         if (($obj_type =~ /^TABLE$/) || ($obj_type =~ /^INDEX$/)) {
            $resize_state = 'normal';
         }

         my $label3 = $dev_menu->Label(relief=>'ridge'
                               )->pack (-side=>'left',
                                        -anchor=>'w');

         $label3->Radiobutton(variable=>\$resize,
                              text=>"Extent Resize Off",
                              value=>0,
                              state=>$resize_state
                             )->pack (-side=>'left',
                                      -anchor=>'w');

         $label3->Radiobutton(variable=>\$resize,
                              text=>"On",
                              value=>1,
                              state=>$resize_state
                             )->pack (-side=>'left',
                                      -anchor=>'w');

         $dev_2_menu->Radiobutton(variable=>\$action,
                                  text=>"Create",
                                  value=>'create'
                                 )->pack (-side=>'left',
                                          -anchor=>'w');

         $dev_2_menu->Radiobutton(variable=>\$action,
                                  text=>"Drop",
                                  value=>'drop'
                                 )->pack (-side=>'left',
                                          -anchor=>'w');

         $resize_state = 'disabled';

         if ($Oracle_Version =~ /^8/){
            if (($obj_type =~ /^TABLE$/) || ($obj_type =~ /^INDEX$/)) {
               $resize_state = 'normal';
            }
         }

         $dev_2_menu->Radiobutton(variable=>\$action,
                                  text=>"Resize (Oracle 8 Tables & Indexes)",
                                  value=>'resize',
                                  state=>$resize_state
                                 )->pack (-side=>'left',
                                          -anchor=>'w');

         my $compile_state = 'disabled';

         if (($obj_type =~ /^FUNCTION$/) || 
             ($obj_type =~ /^PACKAGE$/) ||
             ($obj_type =~ /^PROCEDURE$/) ||
             ($obj_type =~ /^TRIGGER$/) ||
             ($obj_type =~ /^VIEW$/)
            ) {
            $compile_state = 'normal';
         }

         $dev_2_menu->Radiobutton(variable=>\$action,
                                  text=>"Compile",
                                  value=>'compile',
                                  state=>$compile_state
                                 )->pack (-side=>'left',
                                          -anchor=>'w');


         my $dev_top = $window->Frame( -relief => 'groove',
                                     )->pack(-fill=>'both', 
                                             -expand => 1,
                                             -padx => 5,
                                             -side => 'top' 
                                            );


         $window->{text} =
            $dev_top->ScrlListbox(-width=>20,
                                  -height => 18,
                                  -font=>$main::font{name},
                                  -background=>$main::bc,
                                  -foreground=>$main::fc
                                 )->pack(-side=>'left',
                                         -expand=>'yes',-fill=>'both');

         $text = $dev_top->Scrolled( "Text", 
                                     -relief => 'groove',
                                     -width => 40, 
                                     -height => 18,
                                     -cursor=>undef,
                                     -foreground=>'black',
                                     -background=>'white',
                                     -font=>$main::font{name},
                                     -wrap => "none",
                                     -takefocus => 0,
                                     -setgrid => 1
                                   )->pack(-side=>'left',
                                           -fill=>'both',
                                           -expand=>'both'
                                          );

         $purple_tag = $text->tagConfigure("purple", -foreground =>"purple");
         $blue_tag = $text->tagConfigure("blue", -foreground =>"blue");
         $red_tag = $text->tagConfigure("red", -foreground =>"red");
         $green_tag = $text->tagConfigure("green", -foreground =>"green");

         my $adjuster1 = $dev_top->Adjuster();
      
         $adjuster1->packAfter(  $window->{text}, 
                                 -side => 'left',
                              );


         main::iconize($window);
      }
      $window->{text}->insert('end', @res);
   }
   $sth->finish;
   if($detected == 0){
      $self->{Main_window}->Busy(-recurse=>1);
      main::mes($self->{Main_window},$main::lg{no_rows_found});
      $self->{Main_window}->Unbusy;
   } else {

      $window->{text}->selectionSet(0);
      $window->{text}->pack();

      $window->{text}->bind(
         '<Double-1>',
         sub{
              $window->Busy(-recurse=>1);
              $self->{Main_window}->Busy(-recurse=>1);

              DDL::Oracle->configure( 
                        dbh      => $self->{Database_conn},
                        resize   => $resize,
                        schema   => $schema,
                        prompt   => $prompt,
                        heading  => 0,
                        view     => $view,
                        blksize  => $Block_Size,
                        version  => $Oracle_Version
                      );

              if ($obj_type =~ /^TABLE$/){
                 $obj_type = 'TABLE FAMILY';
              }

              my $obj = DDL::Oracle->new(
                            type  => $obj_type,
                            list  => [
                                       [
                                         $main::v_sys,
                                         $window->{text}->get('active'),
                                       ]
                                     ]
                                        );

              my $sql;

              if ( $action eq "drop" ){
                  $sql = $obj->drop;
              }
              elsif ( $action eq "create" ){
                  $sql = $obj->create;
              }
              elsif ( $action eq "resize" ){
                  $sql = $obj->resize;
              }
              elsif ( $action eq "compile" ){
                  $sql = $obj->compile;
              }

              # What is the current mark?

              $current_index = $text->index('current');

              $text->insert('end', $sql . "\n\n");

              $self->search_text(\$text, $current_index);

	      $text->see( q{end linestart});

              $self->{Main_window}->Unbusy;
              $window->Unbusy;
            }
                                   );
   }
}

=head2 dev_jpeg_tunen

Creates various tuning pies and inserts them into a pop-up screen.

=cut

sub dev_jpeg_tunen {
   my $self = shift;

   # Creates Tables Viewer window

   my $cm = $self->f_str('tune_health', 1);
   my $sth = $self->{Database_conn}->prepare( $cm ) ||
                die $self->{Database_conn}->errstr;
   $sth->execute;

   my @res;
   my $window;

   my $dbh;
   my $rsth;
   my $csth;

   my $ratio;
   my $anti_ratio;
   my $real_ratio;

   while (@res = $sth->fetchrow) {

      $dbh = DBI->connect('dbi:Chart:');

      $dbh->do('CREATE TABLE pie (label CHAR(30), ratio FLOAT)');
      $csth = $dbh->prepare('INSERT INTO pie VALUES(?, ?)');

      $real_ratio = $res[2];
      $ratio = $real_ratio + 0.05;
      $real_ratio = sprintf("%.2f", $real_ratio);
      $ratio = sprintf("%.2f", $ratio);
      $anti_ratio = 100.0 - $res[2];
      $anti_ratio = sprintf("%.2f", $anti_ratio);

      $csth->execute("", $ratio);
      $csth->execute("", $anti_ratio);

      $csth->finish;
      $rsth = $dbh->prepare(
         'SELECT PIECHART FROM pie ' .
         'WHERE WIDTH=150 AND HEIGHT=150 ' .
         'AND TITLE = \'' . $res[0] . ' ' . $real_ratio . '%\' ' .
         'AND FORMAT=\'JPEG\' ' .
         'AND 3-D=1 ' .
         'AND SHOWVALUES=1 ' .
         'AND COLOR=(purple, pink)');

      # white, lgray, gray, dgray, black, 
      # lblue, blue, dblue, gold, lyellow, yellow, 
      # dyellow, lgreen, green. dgreen,
      # lred, red, dred, lpurple, purple, 
      # dpurple, lorange, orange, pink, 
      # dpink, marine, cyan, lbrown, dbrown. 

      my $buf;

      $rsth->execute;
      $rsth->bind_col(1, \$buf);
      $rsth->fetch;
      open OUTF, ">$main::orac_home/dev_jpeg_tunen." . $res[1] . ".jpeg";
      binmode OUTF;
      print OUTF $buf;
      close OUTF;
      $rsth->finish;
      $dbh->do('DROP CHART pie');
      $dbh->disconnect;
   }
   $sth->finish;

   $window = $self->{Main_window}->Toplevel();
   $window->title("Orac Hit Ratio Tuning Chart");

   my $dev_menu;
   my $balloon;
   $self->create_balloon_bars(\$dev_menu, \$balloon, \$window, );
   $self->window_exit_button(\$dev_menu, \$window, 1, \$balloon, );
   $self->see_sql_but(\$dev_menu, \$window, \$cm, 1, \$balloon, );

   my(@dev_lay) = qw/-side top -padx 5 -expand yes -fill both/;
   my $dev_top = $window->Frame->pack(@dev_lay);

   $window->{canv} =
      $dev_top->Scrolled( 'Canvas',
                          -relief=>'sunken',
                          -bd=>2,
                          -width=>540,
                          -height=>360,
                          -background=>$main::bc
                        );
   main::iconize($window);

   my $x_offset = 10;
   my $y_offset = 10;

   for (1..5)
   {
      my $img = 
         $window->{canv}->Photo( 
                 -file => "$main::orac_home/dev_jpeg_tunen." . $_ . ".jpeg",
                 -format => 'jpeg'
                               );
      $window->{canv}->create( 'image',$x_offset,$y_offset, 
                               '-anchor' => 'nw', 
                               '-image'  => $img );
      
      $window->{canv}->pack(-expand=>'yes',-fill=>'both');
      $x_offset += 180;

      if ($x_offset > 450){
         $x_offset = 10;
         $y_offset += 180;
      }
   }
}

=head2 dev_jpeg

Creates various graphs and inserts them into a pop-up screen.

=cut

sub dev_jpeg {
   my $self = shift;
   my ( $graph_type ) = @_;

   # Creates Tables Viewer window

   my $cm = $self->f_str('dev_jpeg',$graph_type);
   my $sth = $self->{Database_conn}->prepare( $cm ) ||
                die $self->{Database_conn}->errstr;
   $sth->execute;
   my $detected = 0;

   my @res;
   my $window;

   my $dbh;
   my $rsth;
   my $csth;
   my $title_element;
   my $x_axis;
   my $y_axis;
   my $show_values = 1;
   my $three_d = 1;

   my $flip_switch = 0;
   my $hold1 = 0.0;

   while (@res = $sth->fetchrow) {
      $detected++;

      if($detected == 1){

         $dbh = DBI->connect('dbi:Chart:');

         if (($graph_type =~ /^DBATABSPACE$/)) {
            $show_values = 0;
            $three_d = 0;
            $dbh->do('CREATE TABLE bars (tabspace CHAR(30), Total FLOAT, '.
                     'Used FLOAT, Free FLOAT)');
            $csth = $dbh->prepare('INSERT INTO bars VALUES(?, ?, ?, ?)');
         } else {
            $dbh->do('CREATE TABLE bars (objtype CHAR(20), objcnt FLOAT)');
            $csth = $dbh->prepare('INSERT INTO bars VALUES( ?, ?)');
         }

         $window = $self->{Main_window}->Toplevel();

         if (($graph_type =~ /^OBJCNT$/)) {
            $title_element = "User Objects";
            $x_axis = "Object Type";
            $y_axis = "Object Count";
         } elsif (($graph_type =~ /^DBAOBJCNT$/)) {
            $title_element = "DBA Objects";
            $x_axis = "Object Type";
            $y_axis = "Object Count";
         } elsif (($graph_type =~ /^INVDBAOBJCNT$/)) {
            $title_element = "All Invalid DBA Objects";
            $x_axis = "Invalid Object Type";
            $y_axis = "Invalid Object Count";
         } elsif (($graph_type =~ /^ALLOBJCNT$/)) {
            $title_element = "All Objects";
            $x_axis = "Object Type";
            $y_axis = "Object Count";
         } elsif (($graph_type =~ /^INVALLOBJCNT$/)) {
            $title_element = "All Invalid Objects";
            $x_axis = "Invalid Object Type";
            $y_axis = "Invalid Object Count";
         } elsif (($graph_type =~ /^INVOBJCNT$/)) {
            $title_element = "Invalid User Objects";
            $x_axis = "Invalid Object Type";
            $y_axis = "Invalid Object Count";
         } elsif (($graph_type =~ /^DBATABSPACE$/)) {
            $title_element = "TableSpace Allocations";
            $x_axis = "TableSpace";
            $y_axis = "Space Allocations (MB)";
         } elsif (($graph_type =~ /^TABSPACE$/)) {
            $title_element = "Free TableSpace";
            $x_axis = "TableSpace";
            $y_axis = "Free Space (MB)";
         } else {
            $title_element = $graph_type;
            $x_axis = "X-Axis";
            $y_axis = "Y-Axis";
         }

         $window->title("Orac " . $title_element . " Chart");

         my $dev_menu;
         my $balloon;
         $self->create_balloon_bars(\$dev_menu, \$balloon, \$window, );
         $self->window_exit_button(\$dev_menu, \$window, 1, \$balloon, );

         my(@dev_lay) = qw/-side top -padx 5 -expand yes -fill both/;
         my $dev_top = $window->Frame->pack(@dev_lay);

         $window->{canv} =
            $dev_top->Scrolled( 'Canvas',
                                -relief=>'sunken',
                                -bd=>2,
                                -width=>730,
                                -height=>330,
                                -background=>$main::bc
                              );
         main::iconize($window);
      }
      if (($graph_type =~ /^DBATABSPACE$/)) {
         if ($flip_switch){
            $csth->execute($res[1], $hold1, $hold1 - $res[2], $res[2]);
         } else {
            $hold1 = $res[2];
         }
      } else {
         $csth->execute($res[0], $res[1]);
      }

      if ($flip_switch){
         $flip_switch = 0;
      } else {
         $flip_switch = 1;
      }
   }
   $sth->finish;

   if($detected == 0){
      $self->{Main_window}->Busy(-recurse=>1);
      main::mes($self->{Main_window},$main::lg{no_rows_found});
      $self->{Main_window}->Unbusy;
   } else {
      $csth->finish;
      $rsth = $dbh->prepare(
         'SELECT BARCHART FROM bars ' .
         'WHERE WIDTH=700 AND HEIGHT=300 ' .
         'AND X-AXIS=\'' . $x_axis . 
         '\' AND Y-AXIS=\'' . $y_axis . '\' AND ' .
         'X-ORIENT=\'VERTICAL\' AND ' .
         'FORMAT=\'JPEG\' AND ' .
         'TITLE = \'' . $title_element . 
         '\' AND 3-D=' . $three_d . ' ' .
         'AND SHOWVALUES=' . $show_values . ' AND ' .
         'COLOR=(lred, lgreen, lorange, marine, pink, yellow, lpurple)');

         # white, lgray, gray, dgray, black, 
         # lblue, blue, dblue, gold, lyellow, yellow, 
         # dyellow, lgreen, green. dgreen,
         # lred, red, dred, lpurple, purple, 
         # dpurple, lorange, orange, pink, 
         # dpink, marine, cyan, lbrown, dbrown. 
      
      my $buf;

      $rsth->execute;
      $rsth->bind_col(1, \$buf);
      $rsth->fetch;
      open OUTF, ">$main::orac_home/dev_jpeg.jpeg";
      binmode OUTF;
      print OUTF $buf;
      close OUTF;
      $rsth->finish;
      $dbh->do('DROP CHART bars');
      $dbh->disconnect;
      
      my $img = 
         $window->{canv}->Photo( -file => "$main::orac_home/dev_jpeg.jpeg",
                                 -format => 'jpeg');
      $window->{canv}->create( 'image',5,5, 
                               '-anchor' => 'nw', 
                               '-image'  => $img );
      
      $window->{canv}->pack(-expand=>'yes',-fill=>'both');
   }
}

=head2 dev_tablespace

Creates DBA Viewer window, for selecting various tablespace,
which can then be selected upon.

=cut

sub dev_tablespace {
   my $self = shift;
   my ( $obj_type ) = @_;

   # Creates Tablespace Viewer window

   my $cm = $self->f_str('dev_tablespace',$obj_type);
   my $sth = $self->{Database_conn}->prepare( $cm ) ||
                die $self->{Database_conn}->errstr;
   $sth->execute;
   my $detected = 0;

   my @res;
   my $window;

   my $action = 'totalspace';

   while (@res = $sth->fetchrow) {
      $detected++;

      if($detected == 1){

         $window = $self->{Main_window}->Toplevel();
         $window->title($obj_type . " Drilldown");

         my $dev_menu;

         my $balloon;
         $self->create_balloon_bars(\$dev_menu, \$balloon, \$window, );
         $self->window_exit_button(\$dev_menu, \$window, 1, \$balloon, );

         $self->double_click_message(\$window);

         $dev_menu->Radiobutton(variable=>\$action,
                                text=>"Total Space",
                                value=>'totalspace'
                               )->pack (-side=>'left',
                                        -anchor=>'w');

         $dev_menu->Radiobutton(variable=>\$action,
                                text=>"Tables Breakdown",
                                value=>'tables'
                               )->pack (-side=>'left',
                                        -anchor=>'w');

         $dev_menu->Radiobutton(variable=>\$action,
                                text=>"Index Breakdown",
                                value=>'indexes'
                               )->pack (-side=>'left',
                                        -anchor=>'w');

         my(@dev_lay) = qw/-side top -padx 5 -expand yes -fill both/;
         my $dev_top = $window->Frame->pack(@dev_lay);

         $window->{canv} =
            $dev_top->Scrolled( 'Canvas',
                                -relief=>'sunken',
                                -bd=>2,
                                -width=>730,
                                -height=>330,
                                -background=>$main::bc
                              );
         $window->{text} =
            $dev_top->ScrlListbox(-width=>50,
                                  -font=>$main::font{name},
                                  -background=>$main::bc,
                                  -foreground=>$main::fc
                                 )->pack(-expand=>'yes',-fill=>'both');

         main::iconize($window);
      }
      $window->{text}->insert('end', @res);
   }
   $sth->finish;
   if($detected == 0){
      $self->{Main_window}->Busy(-recurse=>1);
      main::mes($self->{Main_window},$main::lg{no_rows_found});
      $self->{Main_window}->Unbusy;
   } else {

      $window->{text}->pack();

      $window->{text}->bind(
         '<Double-1>',
         sub{
              $window->Busy(-recurse=>1);
              $self->{Main_window}->Busy(-recurse=>1);

              # Function

              if ( $action eq "totalspace" ){
                 print "totalspace\n"; 
              }
              elsif ( $action eq "tables" ){
                 print "tables\n"; 
              }
              elsif ( $action eq "indexes" ){
                 print "indexes\n"; 
              }

              $self->{Main_window}->Unbusy;
              $window->Unbusy;
            }
                                   );
   }
}

sub search_text {
   my ($self, $t, $curr) = @_;

   my @blue_bits = ( 'ADD_MONTHS', 'ALTER', 'AND', 'AS', 'ASCII',
                     'AVG', 'BEGIN', 'BIT_LENGTH', 'BLOCK', 'BODY',
                     'CASE', 'CAST', 'CEIL', 'CHAR_LENGTH', 'CHR',
                     'CLOSE', 'COMMIT', 'CONCAT', 'CONSTRAINT', 'CONVERT',
                     'COUNT', 'CREATE', 'CURDATE','CURRENT_DATE','CURRENT_TIME',
                     'CURRENT_TIMESTAMP', 'CURSOR', 'CURTIME', 'DATABASE', 
                     'DAYOFMONTH',
                     'DAYOFWEEK', 'DAYOFYEAR', 'DECLARATION', 'DECLARE',
                     'DECODE', 'DELETE', 'END', 'EXCEPTION', 'EXCEPTION_INIT',
                     'EXIT',
                     'EXPLAIN', 'EXTRACT', 'FETCH', 'FLOOR', 'FOR',
                     'FOUND', 'FUNCTION', 'GOTO', 'GRANT', 'GREATEST',
                     'HINTS', 'HOUR', 'IF', 'IFNULL', 'INDEX',
                     'INDICATOR', 'INITCAP', 'INSERT', 'INSTR', 'INSTRB',
                     'INTERVAL', 'INTO', 'IS', 'ISOPEN', 'JAVA',
                     'LABEL', 'LAST_DAY', 'LCASE', 'LEAST', 'LENGTH',
                     'LENGTHB', 'LEVEL', 'LOCATE', 'LOCK', 'LOOP',
                     'LOWER', 'LPAD', 'LTRIM', 'MAX', 'MIN',
                     'MINUTE', 'MOD', 'MONTH', 'MONTHS_BETWEEN', 'NEXT_DAY',
                     'NOTFOUND', 'NOW', 'NULL', 'NVL', 'OCTET_LENGTH',
                     'OPEN', 'OR', 'PACKAGE', 'PLAN', 'POSITION',
                     'PRAGMA', 'PROCEDURE', 'QUARTER', 'RAISE', 'RECORD',
                     'REPLACE', 'REVOKE', 'ROLLBACK', 'ROUND', 'ROWCOUNT',
                     'ROWNUM', 'RPAD', 'SAVEPOINT', 'SCHEMA', 'SECOND',
                     'SELECT', 'SEQUENCE', 'SESSION', 'SET', 'SQL',
                     'SQLCODE', 'SQLERRM','SQLTERMINATOR','STDDEV','STRUCTURE',
                     'SUBSTR', 'SUBSTRB', 'SUM', 'SYNONYM', 'SYSDATE',
                     'TABLE', 'TERMINATOR', 'TIMESTAMPADD', 'TIMESTAMPDIFF', 
                     'TO_CHAR',
                     'TO_DATE', 'TO_NUMBER', 'TRANSACTION', 'TRANSLATE', 
                     'TRIGGER',
                     'TRIM', 'TRUNC', 'TYPE', 'UCASE', 'UPDATE',
                     'UPPER', 'USER', 'VARIABLE', 'VARIANCE', 'VIEW',
                     'WEEK', 'WHILE', 'YEAR', 
                   );

   #for (@blue_bits){
   #   $self->search_text_2(1, $_, "blue", $t, $curr);
   #}

   my @red_bits = ('[%(),;]'
                  );

   for (@red_bits){
      $self->search_text_2(0, $_, "red", $t, $curr);
   }

   my @purple_bits = ('DATE','VARCHAR2','NUMBER','BFILE','CLOB',
                      'LONG','CHAR'
                  );

   #for (@purple_bits){
   #   $self->search_text_2(1, $_, "purple", $t, $curr);
   #}
}

sub search_text_2 {
   my ($self, $word_bound, $string, $tag, $t, $curr) = @_;

   my($current, $length) = ($curr, 0);

   if ($word_bound){
      $string = '\b' . $string . '\b';
   }

   while (1){
      $current = $$t->search(-regexp, -nocase, 
                            -count=> \$length, $string, $current, 'end');
      last if not $current;
      $$t->tagAdd($tag, $current, "$current + $length char");
      $current = $$t->index("$current + $length char");
   }
}

# ======== Oracle Tablespace Tuning Tool ===========

my ($tab_hlst, $tab_hlvl, $tabsp_sep, );
my ($open_fold_bit,$close_fold_bit,$tabsp_bit);

sub tabsp_hlist
{
   my $self = shift;
   ($tab_hlst,$tabsp_sep) = @_;
   $tab_hlvl = 1;

   my $save_cb = $self->{Database_conn}->{ChopBlanks};

   my $window = $self->{Main_window}->Toplevel();
   $window->title("$tab_hlst");

   my $loc_menu;
   my $balloon;
   $self->create_balloon_bars(\$loc_menu, \$balloon, \$window, );
   $self->window_exit_button(\$loc_menu, \$window, 1, \$balloon, );

   my $curr_tabdata = "          ";

   $loc_menu->Label(-textvariable => \$curr_tabdata,
                    -relief=>'sunken',
                    -padx=>2,
                    -pady=>2,
                   )->pack(-side=>'left',
                           -anchor=>'w');

   my $frame1 = $window->Frame( -relief => 'groove',
                             )->pack(-fill=>'both', 
                                     -expand => 1,
                                     -side => 'top' 
                                    );

   my $frame2 = $frame1->Frame( -relief => 'groove',
                             )->pack(-fill=>'both', 
                                     -expand => 1,
                                     -side => 'top' 
                                    );
   my $canvas =
            $frame1->Scrolled( 'Canvas',
                               -relief=>'sunken',
                               -bd=>2,
                               -background=>$main::bc
                             )->pack(-side=>'left',
                                     -fill=>'both',
                                     -expand=>'both'
                             );

   my $text2 = $frame1->Scrolled( "Text", 
                                 -relief => 'groove',
                                 -width => 50, 
                                 -height => 10,
                                 -cursor=>undef,
                                 -foreground=>$main::fc,
                                 -background=>$main::bc,
                                 -font=>$main::font{name},
                                 -wrap => "none",
                                 -takefocus => 0,
                                 -setgrid => 1
                               )->pack(-side=>'left',
                                       -fill=>'both',
                                       -expand=>'both'
                                      );

   my $canvas_id;
   $self->dev_jpeg_tabsp(\$canvas, \$canvas_id, 'DBATABSPACE');

   $canvas->configure(-scrollregion=>[ $canvas->bbox("all") ]);
   $canvas->pack(-expand=>'yes',-fill=>'both');

   my $adjuster1 = $frame1->Adjuster();

   $adjuster1->packAfter(  $canvas, 
                           -side => 'left',
                        );

   $window->{text} =
      $frame2->Scrolled('HList',
                      -drawbranch=> 1,
                      -separator=> $tabsp_sep,
                      -indent=> 50,
                      -selectmode=>'single',
                      -browsecmd=>sub{
                         $curr_tabdata = shift;

                         if ($curr_tabdata =~ /:/){
                            my ($tabspace, $datafile) = 
                               split(/\:/, $curr_tabdata);
                            $main::conn_comm_flag = 1;
                            eval {
                               $canvas->delete($canvas_id);
                            };
                            $main::conn_comm_flag = 0;
   
                            $window->Busy(-recurse=>1);
                            $self->{Main_window}->Busy(-recurse=>1);

                            $self->dev_jpeg_tabsp(\$canvas, 
                                                 \$canvas_id, 
                                                 'EXTENTID',
                                                 $datafile
                                                );
                            $canvas->configure(
                               -scrollregion=>[ $canvas->bbox("all") ]);
                            $canvas->pack(-expand=>'yes',-fill=>'both');

                            $self->{Main_window}->Unbusy;
                            $window->Unbusy;
                         }
                                     },
                      -width=> 80,
                      -height=> 20,
                      -font=>$main::font{name},
                      -foreground=> $main::fc,
                      -background=> $main::bc,
                      -command=> sub {

                            $self->show_or_hide_tabsp( \$text2,
                                                       $_[0],
                                                       $window,
                                                       $window->{text},
                                                     );

                                     },

                     )->pack(-fill=>'both',
                             -expand=>'both',
                             -side=>'top'
                            );

   my $adjuster2 = $frame1->Adjuster();

   $adjuster2->packAfter(  $frame2,
                           -side => 'top'
                        );

   $self->get_img( \$window, \$open_fold_bit, 'folder.open' );
   $self->get_img( \$window, \$close_fold_bit, 'folder' );
   $self->get_img( \$window, \$tabsp_bit, 'text' );

   my $cm = $self->f_str( $tab_hlst ,'1');
   print "prepare1: $cm\n" if ($main::debug > 0);
   my $sth = $self->{Database_conn}->prepare( $cm )
             or die $self->{Database_conn}->errstr;
   $sth->execute;

   my $bitmap = (tabsp_file_exist($self->{Database_type}, $tab_hlst, 2)
                ? $close_fold_bit
                : $tabsp_bit);
   my @res;
 
   my $count = 0;

   while (@res = $sth->fetchrow)
   {
      my $owner = $res[0];
      if (!$count){
         $curr_tabdata = $owner;
         $count++;
      }
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

=head2 show_or_hide_tabsp

A support function of tabsp_hlist, DO NOT CALL DIRECTLY!!!

This is called when an entry is double-clicked.  It decides what to do.
Basically ripped off from the "Adv. Perl Prog." book. :-)

=cut

sub show_or_hide_tabsp
{
   my $self = shift;

   my (  $text2_ref,
         $path,
         $win,
         $text,

      ) = @_;

   my $next_entry = $text->info('next', $path);
   print "path=>$path< next_entry=$next_entry\n" if ($main::debug > 0);

   # Is there another level?
   my $x = $path;

   print "before x=>$x<\n" if ($main::debug > 0);
   #$x =~ s/[^.$tabsp_sep]//g;
   $x =~ s/[^$tabsp_sep]//g;
   print "after  x=>$x<\n" if ($main::debug > 0);

   $tab_hlvl = length($x) + 1;
   my $another_level = 
      tabsp_file_exist($self->{Database_type},$tab_hlst, $tab_hlvl + 1);
   if (!$another_level)
   {
      print "no more levels!\n" if ($main::debug > 0);
      # change this next line if we desire
      $self->do_a_tabsp($text2_ref, $win, $tabsp_sep, $tab_hlst, $path);
      return;
   }

   # decide what to do
   if (!$next_entry || (index ($next_entry, "$path$tabsp_sep") == -1))
   {
      # No. open it
      #print "NO!\n";

      $text->entryconfigure( $path,
                             '-image' => $open_fold_bit
                           );

      $self->add_tabsp_contents( $path,
                                 $text,
                               );
   }
   else
   {
      # Yes. Close it by changing the icon, and deleting its subnode.
      #print "YES!\n";

      $text->entryconfigure( $path,
                             '-image' => $close_fold_bit
                           );

      $text->delete('offsprings', $path);
   }
}

=head2 add_tabsp_contents

A support function of generic_hlist, DO NOT CALL DIRECTLY!!!

show_or_hide calls this when it needs to add new items.
Here is where the SQL is called.

=cut

sub add_tabsp_contents
{
   my $self = shift;

   my ( $path,
        $text,

      ) = @_;

   print "path=$path\n" if ($main::debug > 0);

   # is there another level down?
   my $x = $path;
   #$x =~ s/[^.$tabsp_sep]//g;
   $x =~ s/[^$tabsp_sep]//g;
   $tab_hlvl = length($x) + 2;
   my $bitmap = (tabsp_file_exist($self->{Database_type}, $tab_hlst, $tab_hlvl + 1)
                ? $close_fold_bit
                : $tabsp_bit);

   # get the SQL & execute!
   my $s = $self->f_str( $tab_hlst, $tab_hlvl);
   print "prepare2: SQL>\n$s\n<\n ($path)\n" if ($main::debug > 0);
   my $sth = $self->{Database_conn}->prepare( $s )
      or die $self->{Database_conn}->errstr;

   # in theory this should work, COOL! I didn't know you could
   # give split a variable for the RE pattern. :-)

   my @params = split("\\$tabsp_sep", $path);

   print "add_tabsp_contents: tabsp_sep >$tabsp_sep<\n" if ($main::debug > 0);
   print "add_tabsp_contents: params0 >$params[0]<\n" if ($main::debug > 0);
   print "add_tabsp_contents: params1 >$params[1]<\n" if ($main::debug > 0);

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
      $self->post_tabsp( $tab_hlst, $tab_hlvl, [ \@res ], \@params );
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
         my $gen_thing = "$path" . $tabsp_sep . "$res[0]";

         $text->add(  $gen_thing,
                                  -itemtype => 'imagetext',
                                  -image    => $bitmap,
                                  -text     => $gen_thing
                               );
      }
   }
   $sth->finish;
}

sub tabsp_file_exist
{
   my ($type, $sub, $number) = @_;

   # FindBin::RealBin patch below supplied by Bruce Albrecht,
   # 9/9/99

   my $file =
      sprintf("$FindBin::RealBin/sql/%s/%s.%d.sql",$type,$sub,$number);

   print "tabsp_file_exist: $file\n" if ($main::debug > 0);
   return (-r $file);
}

sub do_a_tabsp {

   my $self = shift;

   # On the final level of an HList, does the actual work
   # required.

   my ($text2_ref, $l_mw, $l_tabsp_sep, $l_hlst, $input) = @_;

   $l_mw->Busy(-recurse=>1);
   my $owner;
   my $generic;
   my $dum;

   ($owner, $generic, $dum) = split("\\$l_tabsp_sep", $input);

   # We may be using pretty :-) icons instead of text.  If so,
   # we gotta give help to let people know what the icons are.

   my $cm;

   #my $obj = DDL::Oracle->new(
   #                            type => $l_hlst_to_type{ $l_hlst },
   #                            list => [
   #                                      [
   #                                        $owner,
   #                                        $generic || $owner,
   #                                      ]
   #                                    ],
   #                          );
   #$text_lines = $obj->create ;

   # Finally, pump out the monkey

   $$text2_ref->insert('end', "$owner $generic");

   $l_mw->Unbusy;
}

=head2 post_tabsp

This subroutine is called with the results from show_sql() to allow DB
modules to "post process" the output, if required, before it is analyzed
to be shown.
This is useful for turning numeric flags into words, and other such DB
dependent things.
This generic one does NOTHING!

=cut

sub post_tabsp
{
   my $self = shift;
   return;
}

sub dev_jpeg_tabsp {
   my $self = shift;
   my ( $canv_ref, $canv_id_ref, $graph_type, $param1 ) = @_;

   # Creates Tables Viewer window

   my $cm = $self->f_str('dev_jpeg',$graph_type);
   my $sth = $self->{Database_conn}->prepare( $cm ) ||
                die $self->{Database_conn}->errstr;

   if ($graph_type =~ /^EXTENTID$/) {
      $sth->bind_param(1,$param1);
   }

   $sth->execute;
   my $detected = 0;

   my @res;
   my $window;

   my $dbh;
   my $rsth;
   my $csth;
   my $title_element;
   my $x_axis;
   my $y_axis;
   my $show_values = 1;
   my $three_d = 1;
   my $chart_width = 700;

   my $flip_switch = 0;
   my $old_hold ;
   my $hold1 = 0.0;
   my $hold2 = 0.0;

   my $color_string = 'COLOR=(lred,lgreen,lorange,marine,pink,yellow,lpurple)';

   while (@res = $sth->fetchrow) {
      $detected++;

      if($detected == 1){

         $dbh = DBI->connect('dbi:Chart:');

         if (($graph_type =~ /^DBATABSPACE$/)) {
            $show_values = 0;
            $three_d = 0;
            $dbh->do('CREATE TABLE bars (tabspace CHAR(30), Total FLOAT, '.
                     'Used FLOAT, Free FLOAT)');
            $csth = $dbh->prepare('INSERT INTO bars VALUES(?, ?, ?, ?)');
         } else {
            $dbh->do('CREATE TABLE bars (objtype CHAR(20), objcnt FLOAT)');
            $csth = $dbh->prepare('INSERT INTO bars VALUES( ?, ?)');
         }

         if ($graph_type =~ /^OBJCNT$/) {
            $title_element = "User Objects";
            $x_axis = "Object Type";
            $y_axis = "Object Count";
         } elsif ($graph_type =~ /^EXTENTID$/) {
            $three_d = 0;
            $chart_width = 0;
            $color_string = 'COLOR=(lgreen)';
            $title_element = $res[0] . "\n($Block_Size ".
                             "Bytes per Block)";
            $x_axis = "Segments";
            $y_axis = "Bytes";
         } elsif (($graph_type =~ /^DBAOBJCNT$/)) {
            $title_element = "DBA Objects";
            $x_axis = "Object Type";
            $y_axis = "Object Count";
         } elsif (($graph_type =~ /^INVDBAOBJCNT$/)) {
            $title_element = "All Invalid DBA Objects";
            $x_axis = "Invalid Object Type";
            $y_axis = "Invalid Object Count";
         } elsif (($graph_type =~ /^ALLOBJCNT$/)) {
            $title_element = "All Objects";
            $x_axis = "Object Type";
            $y_axis = "Object Count";
         } elsif (($graph_type =~ /^INVALLOBJCNT$/)) {
            $title_element = "All Invalid Objects";
            $x_axis = "Invalid Object Type";
            $y_axis = "Invalid Object Count";
         } elsif (($graph_type =~ /^INVOBJCNT$/)) {
            $title_element = "Invalid User Objects";
            $x_axis = "Invalid Object Type";
            $y_axis = "Invalid Object Count";
         } elsif (($graph_type =~ /^DBATABSPACE$/)) {
            $title_element = "TableSpace Allocations";
            $x_axis = "TableSpace";
            $y_axis = "Space Allocations (MB)";
         } elsif (($graph_type =~ /^TABSPACE$/)) {
            $title_element = "Free TableSpace";
            $x_axis = "TableSpace";
            $y_axis = "Free Space (MB)";
         } else {
            $title_element = $graph_type;
            $x_axis = "X-Axis";
            $y_axis = "Y-Axis";
         }
      }
      if (($graph_type =~ /^DBATABSPACE$/)) {
         if ($flip_switch){
            $csth->execute($res[1], $hold1, $hold1 - $res[2], $res[2]);
         } else {
            $hold1 = $res[2];
         }
      } elsif ($graph_type =~ /^EXTENTID$/) {

         if (length($res[1]) > 18){
            $res[1] = substr($res[1],1,18) . "..";
         }
         $csth->execute($res[1], $res[2]);
         $chart_width += 20;
      } else {
         $csth->execute($res[0], $res[1]);
      }

      if ($flip_switch){
         $flip_switch = 0;
      } else {
         $flip_switch = 1;
      }
   }
   $sth->finish;

   if($detected == 0){
      $self->{Main_window}->Busy(-recurse=>1);
      main::mes($self->{Main_window},$main::lg{no_rows_found});
      $self->{Main_window}->Unbusy;
   } else {
      $csth->finish;

      if ($chart_width < 700){
         $chart_width = 700;
      }

      $rsth = $dbh->prepare(
         'SELECT BARCHART FROM bars ' .
         'WHERE WIDTH=' . $chart_width . ' AND HEIGHT=300 ' .
         'AND X-AXIS=\'' . $x_axis . 
         '\' AND Y-AXIS=\'' . $y_axis . '\' AND ' .
         'X-ORIENT=\'VERTICAL\' AND ' .
         'FORMAT=\'JPEG\' AND ' .
         'TITLE = \'' . $title_element . 
         '\' AND 3-D=' . $three_d . ' ' .
         'AND SHOWVALUES=' . $show_values . ' AND ' .
         $color_string
      );

         # white, lgray, gray, dgray, black, 
         # lblue, blue, dblue, gold, lyellow, yellow, 
         # dyellow, lgreen, green. dgreen,
         # lred, red, dred, lpurple, purple, 
         # dpurple, lorange, orange, pink, 
         # dpink, marine, cyan, lbrown, dbrown. 
      
      my $buf;

      $rsth->execute;
      $rsth->bind_col(1, \$buf);
      $rsth->fetch;
      open OUTF, ">$main::orac_home/dev_jpeg.jpeg";
      binmode OUTF;
      print OUTF $buf;
      close OUTF;
      $rsth->finish;
      $dbh->do('DROP CHART bars');
      $dbh->disconnect;
      
      my $img = 
         $$canv_ref->Photo( -file => "$main::orac_home/dev_jpeg.jpeg",
                            -format => 'jpeg');
      $$canv_id_ref = $$canv_ref->create( 'image',5,5, 
                                          '-anchor' => 'nw', 
                                          '-image'  => $img );
      
      $$canv_ref->pack(-expand=>'yes',-fill=>'both');
   }
}
# ======== Oracle Tablespace Tuning Tool ===========

1;
