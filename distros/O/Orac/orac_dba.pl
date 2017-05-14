#!/usr/local/bin/perl
################################################################################
# Copyright (c) 1998,1999 Andy Duncan
#
# You may distribute under the terms of either the GNU General Public License
# or the Artistic License,as specified in the Perl README file,with the
# exception that it cannot be placed on a CD-ROM or similar media for commercial
# distribution without the prior approval of the author.
#
# This code is provided with no warranty of any kind,and is used entirely at
# your own risk. This code was written by the author as a private individual,
# and is in no way endorsed or warrantied.
#
# Support questions and suggestions can be directed to andy_j_duncan@yahoo.com
# Download from CPAN/authors/id/A/AN/ANDYDUNC
################################################################################

# Pick up all the standard modules necessary to run the program

use Tk;
use strict;
use Carp;
use FileHandle;
use Cwd;
use Time::Local;
use DBI;

# A hunky clundgy kinda-of-a-thing
# to handle screen resizing

use Tk::DialogBox;
use Tk::Pretty;
use Tk::HList;
require Tk::BrowseEntry;

# Pick up our specialised modules, plus some special
# flags for various database use.

use orac_Base;
use orac_QuickSQL;
use orac_Shell;

use orac_Oracle;
use orac_Informix;

# Read the menu/English.txt file to pick up all text
# for use with the rest of the program

main::read_language();

# Set up a few defaults, such as the lovely Steelblue2
# for the background colour

main::pick_up_defaults();

$main::orac_version = '1.1.11';

$main::hc = $main::lg{bar_col};
$main::ssq = $main::lg{see_sql};
$main::ec = $main::lg{def_fill_fld_col};
$main::fc = $main::lg{def_fg_col};

# Debugging flag for developers?
# for kevinb :)
# and now for thomasl too :)

$main::debug = exists($ENV{ORAC_DEBUG}) ? int($ENV{ORAC_DEBUG}) : 0;
$main::do_shell = exists( $ENV{DBI_SHELL} ) ? 1:0;

# Bring up the main "Worksheet" window

$main::mw = MainWindow->new();

# Start work on the menu, with the Orac badge,
# and then build up the menu buttons

my(@layout_mb) = qw/-side top -padx 5 -expand no -fill both/;
$main::mb = $main::mw->Frame->pack(@layout_mb);

my $orac_li = $main::mw->Photo(-file=>'img/orac.gif');

$main::conn_ball{green} = $main::mw->Photo( -file => "img/grn_ball.gif" );
$main::conn_ball{red} = $main::mw->Photo( -file => "img/red_ball.gif" );

$main::mb->Label(-image=>$orac_li,
                 -borderwidth=>2,
                 -relief=>'flat'
                )->pack(-side=>'left',
                        -anchor=>'w');

# First of all, provide the only hard-coded menu that we
# do, for functions across all databases

my $file_mb = $main::mb->Menubutton(-text=>$main::lg{file},
                          )->pack(-side=>'left',
                                  -padx=>2);

$file_mb->command(-label=>$main::lg{reconn},
                  -command=>sub{main::get_db()});

$file_mb->command(-label=>$main::lg{about_orac},
                  -command=>
                      sub{ main::bz();
                           $main::current_db->f_clr($main::v_clr);
                           $main::current_db->about_orac('README');
                           main::ubz()
                         }
                 );

$file_mb->command(-label=>$main::lg{menu_config},
                  -command=>
                     sub{  main::bz();
                           $main::current_db->f_clr($main::v_clr);
                           $main::current_db->about_orac('txt/menu_config.txt');
                           main::ubz()
                        }
                 );
$file_mb->separator();

# Build up the colour options, so
# a nice lemonchiffon is possible as a backdrop

$main::bc_txt = $main::lg{back_col_menu};
$file_mb->cascade(-label=>$main::bc_txt);
$main::bc_men = $file_mb->cget(-menu);
$main::bc_cols = $main::bc_men->Menu;

# Now pick up all the lovely colours and build a radiobutton

$file_mb->entryconfigure($main::bc_txt,-menu=>$main::bc_cols);
open(COLOUR_FILE, "txt/colours.txt");
while(<COLOUR_FILE>){
   chomp;
   eval {
      $main::bc_cols->radiobutton(
         -label=>$_,-background=>$_,
         -command=>[ sub {main::bc_upd()}],
         -variable=>\$main::bc,
         -value=>$_);
   };
}
close(COLOUR_FILE);

# Now give them the 'Exit Orac' option

$file_mb->separator();
$file_mb->command(-label=>$main::lg{exit},-command=>sub{main::back_orac()});

# Let them know the state of play, on connections

$main::l_top_t = $main::lg{not_conn};
$main::mb->Label(-textvariable => \$main::l_top_t,
                 -padx=>2,
                 -pady=>2,
                )->pack(-side=>'right',
                        -anchor=>'e');
my $main_label = $main::mb->Label( -image => $main::conn_ball{red},
                                   -padx=>2,
                                   -pady=>2,
                                 )->pack(-side=>'right',
                                         -anchor=>'e');

(@layout_mb) = qw/-side top -expand yes -fill both/;
my $middle_box = $main::mw->Frame->pack(@layout_mb);

$main::v_text = $middle_box->Scrolled(  'Text',
                                        -wrap=>'none',
                                        -cursor=>undef,
                                        -foreground=>$main::fc,
                                        -background=>$main::bc
                                     );

$main::v_text->pack(-expand=>1,-fil=>'both');
tie (*TEXT,'Tk::Text',$main::v_text);

# Sort out the options to clear the screen on
# each report

my $bb = $main::mw->Frame->pack(-side=>'bottom',
                                -padx=>5,
                                -expand=>'no',
                                -fill=>'both',
                                -anchor=>'s',
                                -before=>$middle_box);

$bb->Button(-text=>$main::lg{clear},
            -command=>sub{main::bz();
                          $main::current_db->must_f_clr();
                          main::ubz()}
           )->pack(side=>'left');

$main::v_clr = 'Y';
$bb->Radiobutton(-variable=>\$main::v_clr,
                 -text=>$main::lg{man_clear},
                 -value=>'N'
                )->pack (side=>'left');

$bb->Radiobutton(-variable=>\$main::v_clr,
                 -text=>$main::lg{auto_clear},
                 -value=>'Y'
                )->pack (side=>'left');

$bb->Button(-text=>$main::lg{reconn},
            -command=>sub{main::bz();
                          main::get_db();
                          main::ubz()}
           )->pack(side=>'right');

# Set main window title and set window icon

$main::mw->title( "$main::lg{orac_pan} $main::orac_version" );
main::iconize($main::mw);

# Sort out which database we're going to be working with
# Once this is done, connect to a database.

$main::orac_orig_db = 'XXXXXXXXXX'; # I just love kludging :)

# If no default database type selected,
# pick it up.

if ((!defined($main::orac_curr_db_typ)) || 
    (length($main::orac_curr_db_typ) == 0)){

   $main::orac_curr_db_typ = main::select_dbtyp(1);
}

main::get_db();

$main::sub_win_but_hand{dbish}->[0]->invoke('GUI Dbish') if $main::do_shell;

# Here we go, lights, cameras, action!

MainLoop();

# Clear out everything before exiting, and then draw
# those curtains

main::back_orac();

#################### Sub functions begin ####################

sub back_orac {

   # Back out of program nicely, and save any chosen
   # options in the main configuration file

   if (defined($main::current_db)){
      my $rc  = $main::dbh->disconnect;
   }
   main::fill_defaults(  $main::orac_curr_db_typ, 
                         $main::sys_user, 
                         $main::bc, 
                         $main::v_db
                      );
   exit 0;
}
sub fill_defaults {

   # Make sure defaults the way the user likes 'em.

   my($db_typ, $dba, $loc_bc, $db) = @_;

   open(DB_FIL,'>config/what_db.txt');

   print DB_FIL $db_typ . 
                '^' . 
                $dba . 
                '^' . 
                $loc_bc . 
                '^' . 
                $db . 
                '^' . 
                "\n";

   close(DB_FIL);
}
sub get_connected {

   # Put up dialogue to pick a new database.
   # Allow user to change database type,
   # if they wish.  Also, set flag
   # to help prevent connection
   # error messages, except on the
   # last attempt at connection.

   my $ps_u;
   my $ps_e;
   my $auto_log = 1;

   my $dn = 0;
   $main::conn_comm_flag = 0;

   if (defined($main::current_db)){

      $main::current_db->must_f_clr();
      $main_label->configure( -image => $main::conn_ball{red} );
      $main::l_top_t = $main::lg{disconn};
      my $rc = $main::dbh->disconnect;
      undef $main::current_db;
      $auto_log = 0;
   }

   do {
      # Create the new object

      if($main::orac_curr_db_typ eq 'Oracle'){

         print STDERR "New Oracle object\n" if ($main::debug > 0);

         $main::current_db = orac_Oracle->new( $main::mw, 
                                               $main::v_text,
                                               $main::orac_version );

      }
      elsif($main::orac_curr_db_typ eq 'Informix'){

         $main::current_db = orac_Informix->new( $main::mw, 
                                                 $main::v_text,
                                                 $main::orac_version );

      }
      else {

         $main::current_db = 
            orac_Base->new( 'Base', 
                            $main::mw, 
                            $main::v_text,
                            $main::orac_version );

      }

      print STDERR "After New object\n" if ($main::debug > 0);

      my $c_d = 
       $main::mw->DialogBox(-title=>$main::lg{login_txt},
                            -buttons=>[ $main::lg{connect}, 
                                        $main::lg{change_dbtyp}, 
                                        $main::lg{exit} ]
                           );

      my $l1 = $c_d->Label(-text=>$main::lg{db} . ':',
                           -anchor=>'e',
                           -justify=>'right');

      my $db_list = 
                 $c_d->BrowseEntry(-cursor=>undef,
                                   -variable=>\$main::v_db,
                                   -foreground=>$main::fc,
                                   -background=>$main::ec);
      my %ls_db;

      # Pick up all the databases currently available to this user
      # directly from here

      my @h = DBI->data_sources('dbi:' . $main::orac_curr_db_typ . ':');
      my $h = @h;
      my @ic;
      my $ic;
      my $i;
      for ($i = 1;$i < $h;$i++){
         @ic = split(/:/,$h[$i]);
         $ic = @ic;
         $ls_db{$ic[($ic - 1)]} = 101;
      }
      
      # Supplement these, with stored database to which they've
      # successfully connected in the past 

      open(DBFILE,"txt/" . $main::orac_curr_db_typ . "/orac_db_list.txt");
      while(<DBFILE>){
         chomp;
         $ls_db{$_} = 102;
      }
      close(DBFILE);

      my $key;
      my @hd;
      undef @hd;
      $i = 0;
      foreach $key (keys %ls_db) {
         $hd[$i] = "$key";
         $i++;
      }
      my @hd2;
      @hd2 = sort @hd;

      foreach(@hd2){
         $db_list->insert('end',$_);
      }

      # Now put up the rest of the widgets with this Dialogue

      my $l2 = $c_d->Label(-text=>$main::lg{sys_user} . ':',
                           -anchor=>'e',
                           -justify=>'right');

      $ps_u = $c_d->add("Entry",
                        -cursor=>undef,
                        -textvariable=>\$main::sys_user,
                        -foreground=>$main::fc,
                        -background=>$main::ec
                       )->pack(side=>'right');

      my $l3 = $c_d->Label(-text=>$main::lg{sys_pass} . ':',
                           -anchor=>'e',
                           -justify=>'right');

      $ps_e = $c_d->add("Entry",
                        -cursor=>undef,
                        -show=>'*',
                        -foreground=>$main::fc,
                        -background=>$main::ec
                       )->pack(side=>'right');

      my $l4 = $c_d->Label(-text=>$main::lg{db_type} . ':',
                           -anchor=>'e',
                           -justify=>'right');

      my $l4a = $c_d->Label(-text=>$main::orac_curr_db_typ,
                            -anchor=>'w',
                            -justify=>'left');


      # Go Grid crazy!  Assign the widgets to starting 
      # racetrack postitions

      Tk::grid($l1,-row=>0,-column=>0,-sticky=>'e');
      Tk::grid($db_list,-row=>0,-column=>1,-sticky=>'ew');
      Tk::grid($l2,-row=>1,-column=>0,-sticky=>'e');
      Tk::grid($ps_u,-row=>1,-column=>1,-sticky=>'ew');
      Tk::grid($l3,-row=>2,-column=>0,-sticky=>'e');   # Schumacher!!!
      Tk::grid($ps_e,-row=>2,-column=>1,-sticky=>'ew');
      Tk::grid($l4,-row=>3,-column=>0,-sticky=>'e');
      Tk::grid($l4a,-row=>3,-column=>1,-sticky=>'ew');

      # Now put up the dialogue on the main screen
      # Determine if auto log on will work. If the env
      # variables are not set, no auto log.

      $auto_log = ( defined($ENV{DBI_DSN}) &&
                    defined($ENV{DBI_USER}) &&
                    defined($ENV{DBI_PASS}) ) && $auto_log;
  
      my $mn_b;

      if(!$auto_log) {

         $c_d->gridRowconfigure(1,-weight=>1);
         $db_list->focusForce;
         $mn_b = $c_d->Show;

      } else {
         $mn_b = $main::lg{connect};

         $ps_u->delete( 0, 'end' );
         $ps_e->delete( 0, 'end' );

         $ps_u->insert( 'end', $ENV{DBI_USER} );
         $ps_e->insert( 'end', $ENV{DBI_PASS} );

         $main::v_db = (split(/:/,$ENV{DBI_DSN}))[2];
      }
  
      # Now verify all input and attempt connection to chosen database
  
      if ($mn_b eq $main::lg{connect}) {

         $main::v_sys = $ps_u->get;

         if ( ( $main::current_db->need_sys ) || 
              (  defined($main::v_sys) && length($main::v_sys) )
            )
         {
            my $v_ps = $ps_e->get;
            if ( $main::current_db->need_ps || 
                 ( defined($v_ps) && length($v_ps)
                 )
               )
            {
               # Build up Primary database independent initialisation
               # and set all environmental variables required for 
               # this database type

               $main::current_db->init1( $main::v_db );

               # Now attempt connection, first tell user what we're doing

               $main_label->configure( -image => $main::conn_ball{red} );
               $main::l_top_t = $main::lg{connecting};
               main::bz();

               # Try a double whammy on connecting, to help out
               # various operating systems. Set a flag
               # to later suppress connection errors,
               # except on the last one.  Try the full connection
               # option first, the one needed for NT.

               my $data_source_1 = 'dbi:' . 
                                   $main::orac_curr_db_typ . 
                                   ':';

               my $data_source_2 = 'dbi:' . 
                                   $main::orac_curr_db_typ . 
                                   ':' . 
                                   $main::v_db;

               $main::conn_comm_flag = 1;

               main::connector($data_source_2, $main::v_sys, $v_ps);

               if (defined($DBI::errstr)){

                  # Set flag, to now allow proper warnings, on the last
                  # attempted connection

                  $main::conn_comm_flag = 0;
                  main::connector($data_source_1, $main::v_sys, $v_ps);
               }

               $main::conn_comm_flag = 0;

               if (!defined($DBI::errstr)){

                  $dn = 1;

                  if ((!defined($ls_db{$main::v_db})) || 
                      ($ls_db{$main::v_db} != 102)){

                     # If we connected successfully to a new 
                     # database, store this fact, and put it 
                     # in the browse option for later use

                     open(DBFILE,
                          ">>txt/" . 
                          $main::orac_curr_db_typ . 
                          "/orac_db_list.txt");

                     print DBFILE "$main::v_db\n";
                     close(DBFILE);
                  }
                  $main_label->configure( -image => $main::conn_ball{green} );
                  $main::l_top_t = "$main::v_db";
                  $main::sys_user = $main::v_sys;
               } else {
                  $main_label->configure( -image => $main::conn_ball{red} );
                  $main::l_top_t = $main::lg{not_conn};
               }
               main::ubz();
            } else {
               # Various error messages for invalid input

               main::mes($main::mw, $main::lg{system_please});
            }
         } else {
            main::mes($main::mw,$main::lg{user_please});
         }
      } elsif ($mn_b eq $main::lg{change_dbtyp}) {
         
         # User may have decided to change database type 

         $main::orac_curr_db_typ = main::select_dbtyp(2);
      } else {
       
         undef $main::current_db;
         $dn = 1;
      }
   } until $dn;

   # Ok, we're done here.  Now Orac can start work.  Stand by your beds.
}
sub connector {
   print STDERR "connecting: $_[0], $_[1], $_[2]\n" if ($main::debug > 0);
   $main::dbh = DBI->connect($_[0], $_[1], $_[2]);
   $main::current_db->set_db_handle($main::dbh);
}
sub select_dbtyp {

   # User may either be picking default database type for the first
   # time, or changing database type.  Either way, build up
   # dialogue to allow them to do this.

   my ($option) = @_;
   my $mess;
   my $tit;
   my $loc_db;
   if ($option == 1){
      $mess = $main::lg{please_pick_db};
      $tit = $main::lg{new_dbtyp};
   } else {
      $mess = $main::lg{db_change_mess};
      $tit = $main::lg{change_dbtyp};
      $loc_db = $main::orac_curr_db_typ;
   }
   my $dn = 0;
   do {
      my $d = $main::mw->DialogBox(-title=>$tit);

      my $l1 = $d->Label(-text=>$mess,
                         -anchor=>'n'
                         )->pack(-side=>'top');

      my $l2 = $d->Label(-text=>$main::lg{db_type} . ':',
                         -anchor=>'e',
                         -justify=>'right'
                        );

      my $b_d = $d->BrowseEntry(-cursor=>undef,
                                -variable=>\$loc_db,
                                -foreground=>$main::fc,
                                -background=>$main::ec,
                                -width=>40
                               );
   
      # Check out which DBs we're currently allowed to pick from

      open(DB_FIL,'config/all_dbs.txt');
      my $i = 0;
      while(<DB_FIL>){
         my @hold = split(/\^/, $_);
         if (($option == 1) && ($i == 0)) {
            $loc_db = $hold[0];
            $i++;
         }
         $b_d->insert('end', $hold[0]);
      }
      close(DB_FIL);
      
      # It's grid crazy time again.  Don't ya love it!

      Tk::grid($l1,-row=>0,-column=>1,-sticky=>'e');
      Tk::grid($l2,-row=>1,-column=>0,-sticky=>'e');
      Tk::grid($b_d,-row=>1,-column=>1,-sticky=>'ew');  # Eddie Irvine!!!
      $d->gridRowconfigure(1,-weight=>1);
      $d->Show;
   
      # Check out that that they the correct DBI module loaded.
      # If not, give them a politically correct virtual slap!

      my $db_init_command = 'DBI->data_sources(\'dbi:' . $loc_db . ':\');';
      eval $db_init_command;
      if ($@) {
         warn $@;
         main::mes($main::mw,$main::lg{wrong_dbi});
      } else {
         $dn = 1;
      }
   } until $dn;

   # A successful connection means we store the variable for later

   # Pick up the standard DBA user for the particular database
   ($main::sys_user,$main::v_db) = get_dba_user($loc_db);
   main::fill_defaults($loc_db, $main::sys_user, $main::bc, $main::v_db);

   return $loc_db;
}
sub get_dba_user {
   my($db) = @_;
   my $dba_user;
   my $new_db;

   # Picks up the typical DBA user for the particular database

   open(DB_FIL,'config/all_dbs.txt');
   while(<DB_FIL>){
      my @hold = split(/\^/, $_);
      if ($db eq $hold[0]){
         $dba_user = $hold[1];
         $new_db = $hold[2];
      }
   }
   close(DB_FIL);
   return ($dba_user,$new_db);
}
sub get_db {
   # Picks up database, and then configures menus accordingly

   main::get_connected();
   unless (defined($main::current_db)){
     main::back_orac();
   }

   # Run the second initialisation routine 
   $main::current_db->init2( $main::dbh );

   # Now sort out Jared's tools and configurable menus
   if ($main::orac_orig_db ne $main::orac_curr_db_typ){

      # We do this, if either we're into the program for the first time,
      # or the user has changed the database type

      main::del_Jareds_tools();
      main::config_menu();
      main::Jareds_tools();
      $main::orac_orig_db = $main::orac_curr_db_typ;
   }
}

sub bz {
   # Make the main GUI pointer go busy
   $main::mw->Busy;
}
sub ubz {
   # Make the main GUI pointer normalise to unbusy
   $main::mw->Unbusy;
}
sub get_Jared_sql {

   # Takes pointers to which cascade and button the user
   # wishes to run, and sucks SQL info out of the appropriate
   # file, before returning as a Perl string variable

   my($casc,$butt) = @_;
   my $filename = 'tools/sql/' . $casc . '.' . $butt . '.sql';
   my $cm = '';
   open(JARED_FILE, "$filename");
   while(<JARED_FILE>){
      $cm = $cm . $_;
   }
   close(JARED_FILE);
   return $cm;
}

sub mes {
   # Produce the box that contains viewable Error

   my $d = $_[0]->DialogBox();
   my $t = $d->Scrolled( 'Text',
                         -cursor=>undef,
                         -foreground=>$main::fc,
                         -background=>$main::bc);
   $t->pack(-expand=>1,-fil=>'both');
   $t->insert('end', $_[1]);
   $d->Show;
}

sub bc_upd {

   # Change the background colour on all open windows.
   # This is where all those text and window handles
   # come in useful.

   eval {
      $main::v_text->configure(-background=>$main::bc);
   };
   my $comp_str = "";
   my $i;

   my $f;
   foreach $f (keys(%main::swc))
   {
      if (defined($main::swc{$f})){

         print STDERR "main swc f state >" . $main::swc{$f}->state . "< \n" if ($main::debug > 0);

         my $comp_str = $main::swc{$f}->state;

         if("$comp_str" ne 'withdrawn'){
            eval {
               $main::swc{$f}->{text}->configure(-background=>$main::bc);
            }
         }
      }
   }
}
sub read_language {

   # Open up the main configurable
   # language file, and pick up all
   # the strings required by Orac

   open(TITLES_FILE, "txt/English.txt");
   my $lhand;
   my $rhand;
   while(<TITLES_FILE>){
      ($lhand,$rhand) = split(/\^/, $_);
      $main::lg{$lhand} = $rhand;
   }
   close(TITLES_FILE);
}

#############################################################
# new language stuff!
# use keys(%main::languages) to populate the drop down

sub get_language_data {

   # Open up the main configurable
   # language file, and pick up all
   # the strings required by Orac

   open(TITLES_FILE, "txt/languages.txt") or die "can't open txt/languages.txt";
   # expect to find:  language_label,language_file
   my $lhand;
   my $rhand;
   undef %main::languages;
   while(<TITLES_FILE>){
      ($lhand,$rhand) = split(/,/);
      $main::languages{$lhand} = $rhand;
   }
   close(TITLES_FILE);
}
sub read_language_file {
   # ARG1 = language_label picked
   my $file = "txt/$main::languages{$_[0]}";
   open(TITLES_FILE, "<$file") or die "can't open language file $file";
   my $lhand;
   my $rhand;
   while(<TITLES_FILE>){
      ($lhand,$rhand) = split(/\^/, $_);
      $main::lg{$lhand} = $rhand;
   }
   close(TITLES_FILE);
}
#############################################################

sub config_menu {

   # Read the database dependent menu configuration
   # file, and build up menus.

   my $i;
   my $func_line_ct;
   my $menu_command = "";

   # Does a configurable menu currently exist?
   # If so, destroy it.

   $main::tm_but_ct = 0;
   if(defined(@main::tm_but)){
      my $i;
      my $ct = @main::tm_but;
      for ($i = ($ct - 1);$i >= 0;$i--){
         $main::tm_but[$i]->destroy();
      }
      @main::tm_but = undef;
   }
   $main::tm_but_ct = -1;

   # Initialize variables to prevent
   # warnings

   my $file = "menu/$main::orac_curr_db_typ/menu.txt";
   open(MENU_F, $file);
   while(<MENU_F>){

      chomp;
      my $chop_bit = $_;
      my @menu_line = split(/\^/, $chop_bit);

      if ($menu_line[0] eq 'Menubutton'){
         $menu_command = 
            $menu_command . 
            ' $main::tm_but_ct++; ' . "\n" .
            ' $main::tm_but[$main::tm_but_ct] = ' . "\n" .
            ' $main::mb->Menubutton(-text=>$main::lg{' . 
            $menu_line[1] . '},' . "\n" .
            ' )->pack(-side=>\'left\',-padx=>2); ' . "\n";
      }

      if (($menu_line[0] eq 'command') || 
          ($menu_line[0] eq 'casc_command')){

         if ($menu_line[1] ne '0'){

            $menu_command = $menu_command . ' $main::sub_win_but_hand{' . 
                            $menu_line[1] . '} = ';
         }

         if ($menu_line[0] eq 'command'){

            $menu_command = 
               $menu_command . 
               ' $main::tm_but[$main::tm_but_ct]->command(-label=>$main::lg{' . 
               $menu_line[3] . '},' . 
               ' -command=>sub{main::bz();';

         } elsif ($menu_line[0] eq 'casc_command'){

            $menu_command = $menu_command . 
                            ' $main::casc_item->command(-label=>$main::lg{' . 
                            $menu_line[3] . '},' . 
                            ' -command=>sub{main::bz();';

         }
         if ($menu_line[2] == 1){
            $menu_command = $menu_command . 
                            ' $main::current_db->f_clr($main::v_clr); ';
         }
         $menu_command = $menu_command . $menu_line[4] . '(';

         if(defined($menu_line[5])){

            # Now build the function's parameters we're going to run.
            # (if any parameters exist)

            my @func_line = split(/\+/, $menu_line[5]);
            $func_line_ct = @func_line;
   
            for ($i = 0;$i < $func_line_ct;$i++){
               $menu_command = $menu_command . $func_line[$i];
               if (($i + 1) < $func_line_ct){
                  $menu_command = $menu_command . ', ';
               }
            }
         }
         $menu_command = $menu_command . ');main::ubz()}); ' . "\n";
      }
      if ($menu_line[0] eq 'separator'){
         $menu_command = $menu_command . 
                         ' $main::tm_but[$main::tm_but_ct]->separator(); ' . 
                         "\n";
      }
      if ($menu_line[0] eq 'cascade'){
 
         # Ok, it ain't pretty, but then are you first thing
         # of a morning?  :)

         $menu_command = 
            $menu_command . 
            ' $main::tm_but[$main::tm_but_ct]->cascade(-label=>$main::lg{' . 
            $menu_line[1] . '}); ' . 
            "\n" .
            ' $main::casc = $main::tm_but[$main::tm_but_ct]->cget(-menu); ' . 
            "\n" .
            ' $main::casc_item = $main::casc->Menu; ' . 
            "\n" .
            ' $main::tm_but[$main::tm_but_ct]->entryconfigure($main::lg{' . 
            $menu_line[1] . 
            '}, -menu => $main::casc_item); ' . 
            "\n";
      }
   }
   close(MENU_F);

   # Here we go!  Slap up those menus.

   print STDERR "config_menu: menu_command >\n$menu_command\n<\n" 
      if ($main::debug > 0);

   eval $menu_command ; warn $@ if $@;

   $main::tm_but_ct++;
   $main::tm_but[$main::tm_but_ct] = 
                   $main::mb->Menubutton(-text=>$main::lg{sql_menu},
                                        )->pack(-side=>'left',
                                                -padx=>2);
   $main::sub_win_but_hand{quick_sql} =
      $main::tm_but[$main::tm_but_ct]->command(
                         -label=>$main::lg{quick_sql},

                         -command=>sub{  main::bz();
                                         orac_QuickSQL::quick_sql();
                                         main::ubz()
                                      }
                                              );
   $main::sub_win_but_hand{dbish} =
      $main::tm_but[$main::tm_but_ct]->command(
                         -label=>$main::lg{dbish},

                         -command=>sub{  main::bz();

         print STDERR "mw >$main::mw<,  dbh >$main::dbh< \n" if ($main::debug > 0);

                                         $main::shell = orac_Shell->new( $main::mw, $main::dbh );
                                         $main::shell->dbish_open();
                                         main::ubz()
                                      }
                                              );
   return;
}
sub Jareds_tools {

   # Build up the 'My Tools' menu option.

   if(!defined($main::jt)){

      # Monster coming up.  You'll cope.

      my $comm_str = 
          ' $main::jt = $main::mb->Menubutton( ' . "\n" . 
          ' -text=>$main::lg{my_tools},' . "\n" .
          ' -menuitems=> ' . "\n" .
          ' [[Button=>$main::lg{help_with_tools},' .
          ' -command=>sub{main::bz();' . "\n" .
          ' $main::current_db->f_clr($main::v_clr);' . "\n" .
          ' $main::current_db->about_orac(\'txt/help_with_tools.txt\');' . 
          "\n" .
          ' main::ubz()}], ' . "\n" .
          '  [Cascade=>$main::lg{config_tools},-menuitems => ' . "\n" .
          '   [[Button=>$main::lg{config_add_casc},' . "\n" .
          '      -command=>sub{' . "\n" .
          '      main::bz();' . "\n" .
          '      main::config_Jared_tools(1);' . "\n" .
          '      main::ubz()},], ' . "\n" .
          '    [Button=>$main::lg{config_edit_casc},-command=>sub{' . "\n" .
          '      main::bz();' . "\n" .
          '      main::config_Jared_tools(6);' . "\n" .
          '      main::ubz()},], ' . "\n" .
          '    [Button=>$main::lg{config_del_casc},-command=>sub{' . "\n" .
          '      main::bz();' . "\n" .
          '      main::config_Jared_tools(2);' . "\n" .
          '      main::ubz()},], ' . "\n" .
          '    [Separator=>\'\'], ' . "\n" .
          '    [Button=>$main::lg{config_add_butt},-command=>sub{' . "\n" .
          '      main::bz();' . "\n" .
          '      main::config_Jared_tools(3);' . "\n" .
          '      main::ubz()},], ' . "\n" .
          '    [Button=>$main::lg{config_edit_butt},-command=>sub{' . "\n" .
          '      main::bz();' . "\n" .
          '      main::config_Jared_tools(7);' . "\n" .
          '      main::ubz()},], ' . "\n" .
          '    [Button=>$main::lg{config_del_butt},-command=>sub{' . "\n" .
          '      main::bz();' . "\n" .
          '      main::config_Jared_tools(4);' . "\n" .
          '      main::ubz()},], ' . "\n" .
          '    [Separator=>\'\'], ' . "\n" .
          '    [Button=>$main::lg{config_edit_sql},-command=>sub{' . "\n" .
          '      main::bz();' . "\n" .
          '      main::config_Jared_tools(5);' . "\n" .
          '      main::ubz()},],], ' . "\n" .
          '  ], ' . "\n" .
          '  [Separator=>\'\'], ' . "\n";

      if(open(JT_CASC,'tools/config.tools')){
         while(<JT_CASC>){
            my @jt_casc = split(/\^/, $_);
            if ($jt_casc[0] eq 'C'){

               $comm_str = $comm_str . 
                           ' [Cascade  =>\'' . 
                           $jt_casc[2] . 
                           '\',-menuitems => [ ' . "\n";

               open(JT_CASC_BUTTS,'tools/config.tools');
               while(<JT_CASC_BUTTS>){
                  my @jt_casc_butts = split(/\^/, $_);
                  if (($jt_casc_butts[0] eq 'B') && 
                      ($jt_casc_butts[1] eq $jt_casc[1])){

                     # Bit of a pig below, but you'll get through it
                     # if you have a quick lager

                     $comm_str = 
                        $comm_str . 
                        ' [Button=>\'' . 
                        $jt_casc_butts[3] . 
                        '\',' .
                        '-command=>sub{main::bz(); ' .
                        '$main::current_db->f_clr($main::v_clr); ' . 
                        "\n" .
                        ' main::run_Jareds_tool(\'' . 
                        $jt_casc[1] . 
                        '\',\'' . 
                        $jt_casc_butts[2] . 
                        '\');main::ubz()}], ' . "\n";
                  }
               }
               close(JT_CASC_BUTTS);
               $comm_str = $comm_str . ' ],], ' . "\n";
            }
         }
         close(JT_CASC);
      }
      $comm_str = $comm_str . 
                  ' ])->pack(-side=>\'left\',-padx=>2) ; ';

      eval $comm_str ; warn $@ if $@;
   }
}
sub save_sql {

   # Pick up the SQL the user has entered, and
   # save it into the appropriate file

   my($filename) = @_;
   main::orac_copy($filename,"${filename}.old");

   open(SAV_SQL,">$filename");
   print SAV_SQL $main::swc{ed_butt_win}->{text}->get("1.0", "end");
   close(SAV_SQL);

   return $filename;
}
sub ed_butt {

   # Allow configuration of 'My Tools' menus, buttons, cascades, etc

   my($casc,$butt) = @_;
   my $ed_fl_txt = main::get_butt_text($casc,$butt);
   my $sql_file = 'tools/sql/' . $casc . '.' . $butt . '.sql';
   
   $main::swc{ed_butt_win} = MainWindow->new();

   $main::swc{ed_butt_win}->title(  "$main::lg{cascade} $casc, 
                                    $main::lg{button} $butt");

   my $ed_sql_txt = "$ed_fl_txt: $main::lg{ed_sql_txt}";
   my $ed_sql_txt_cnt = 0;

   $main::swc{ed_butt_win}->Label( 
                                  -textvariable  => \$ed_sql_txt, 
                                  -anchor=>'n', 
                                  -relief=>'groove'
                                )->pack(-expand=>'no');

   $main::swc{ed_butt_win}->{text} = 
      $main::swc{ed_butt_win}->Scrolled('Text',
                                  -wrap=>'none',
                                  -cursor=>undef,
                                  -foreground=>$main::fc,
                                  -background=>$main::bc
   
                                 )->pack(-expand=>'yes',
                                         -fill=>'both');
   
   my(@lay) = qw/-side bottom -padx 5 -fill both -expand no/;

   my $f = $main::swc{ed_butt_win}->Frame->pack(@lay);

   $f->Button(
      -text=>$main::lg{exit},
      -command=>sub{ $main::swc{ed_butt_win}->withdraw() }

             )->pack(-side=>'right',
                     -anchor=>'e');

   $f->Button(
      -text=>$main::lg{save},
      -command=>

          sub{ my $file_name = main::save_sql($sql_file, $ed_fl_txt);
               $ed_sql_txt_cnt++;
               $ed_sql_txt = "$ed_fl_txt: $file_name $main::lg{saved}" . 
                             ' #' . 
                             $ed_sql_txt_cnt;
             }

             )->pack(-side=>'right',
                     -anchor=>'e');

   $f->Label(-text=>$main::lg{no_semi_colon},
             -relief=>'sunken'
            )->pack(-side=>'left',
                    -anchor=>'w');

   main::iconize($main::swc{ed_butt_win});

   if(open(SQL_SAV,$sql_file)){

      while(<SQL_SAV>){ 
         $main::swc{ed_butt_win}->{text}->insert("end", $_); 
      }
      close(SQL_SAV);

   }
}
sub config_Jared_tools {

   # More functionality required to allow on-the-fly configuration
   # of the 'My Tools' options.

   # This function is fairly overloaded, and may require some
   # detailed analysis, before it becomes clearer what it's doing.

   my($param,$loc_casc,$loc_butt) = @_;
   my $main_check;
   my $title;
   my $action;
   my $inp_text;
   my $sec_check;

   if(($param == 1)||($param == 99)||($param == 69)||($param == 49)){

      $main_check = 'C';
      $title = $main::lg{add_cascade};
      my $main_field = 1;
      my $main_inp_value;
      my $add_text = $main::lg{casc_text};
      $action = $main::lg{add};

      if($param == 69){

         $title = $main::lg{upd_cascade};
         $action = $main::lg{upd};

      } elsif($param == 49) {

         $main_check = 'B';
         $title = "$main::lg{cascade} $loc_casc, $main::lg{button}";
         $add_text = $main::lg{upd_button};
         $action = $main::lg{upd};

      } elsif($param == 99) {

         $main_field = 2;
         $main_check = 'B';
         $title = "$main::lg{cascade} $loc_casc: $main::lg{add_button}";
         $add_text = $main::lg{butt_text};
      }

      if(($param == 69)||($param == 49)){

         $main_inp_value = $loc_casc;

      } else {

         my @inp_value;
         my $inp_count = 0;
         if(open(JT_CONFIG,'tools/config.tools')){
            while(<JT_CONFIG>){
               my @hold = split(/\^/, $_);

               # Jesus, I can't believe I wrote the 'if' statement
               # below.  If you can figure it out, can you let me know
               # what it's doing?  ;-)

               if ((($param == 1) && 
                    ($hold[0] eq $main_check)) ||
                   (($param == 99) && 
                    ($hold[0] eq $main_check) && 
                    ($hold[1] eq $loc_casc))) {
      
                  $inp_value[ $inp_count ] = $hold[ $main_field ];
                  $inp_count++;
               }
            }
            close(JT_CONFIG);
         }
         if($inp_count > 0){
            $inp_count--;
            my $flag = 0;
            my $flag2 = 0;
            $main_inp_value = 1;
            while($flag == 0){
               my $i;
               $flag2 = 0;
               for ($i = 0;$i <= $inp_count;$i++){
                  if($main_inp_value == $inp_value[$i]){
                     $main_inp_value++;
                     $flag2 = 1;
                     last;
                  }
               }
               if ($flag2 == 0){
                  $flag = 1;
               }
            }
         } else {
            $main_inp_value = 1;
         }
         $main_inp_value = sprintf("%03d", $main_inp_value);
      }

      # Now get to main dialogue and pick up the reqd. info

      my $d = $main::mw->DialogBox(-title=>"$title $main_inp_value",
                                   -buttons=>[ $action,
                                               $main::lg{cancel} ]
                            );

      my $l = $d->Label(-text=>$add_text . ':',
                        -anchor=>'e',
                        -justify=>'right'
                       );

      $inp_text = '';

      if(($param == 69)||
         ($param == 49)){

         open(JT_CONFIG_READ,'tools/config.tools');

         while(<JT_CONFIG_READ>){

            my @hold = split(/\^/, $_);

            if($param == 69){

               if (($hold[0] eq $main_check) && 
                   ($hold[1] eq $loc_casc)){

                  $inp_text = $hold[2];
               }
            } elsif($param == 49){

               if (($hold[0] eq $main_check) && 
                   ($hold[1] eq $loc_casc) && 
                   ($hold[2] = $loc_butt)){

                  $inp_text = $hold[3];
               }
            }
         }
         close(JT_CONFIG_READ);
      }

      my $cs = $d->add("Entry",
                       -textvariable=>\$inp_text,
                       -cursor=>undef,
                       -foreground=>$main::fc,
                       -background=>$main::ec,
                       -width=>40

                      )->pack(side=>'right');

      # Stand by your grids!

      Tk::grid($l,-row=>0,-column=>0,-sticky=>'e');
      Tk::grid($cs,-row=>0,-column=>1,-sticky=>'ew');

      $d->gridRowconfigure(1,-weight=>1);
      my $rp = $d->Show;
      if ($rp eq $action) {
         if (defined($inp_text) && length($inp_text)){
            if(($param == 69)||($param == 49)){
               return (1,$inp_text);
            } else {

               open(JT_CONFIG_APPEND,'>>tools/config.tools');
               if($param == 1){

                  print JT_CONFIG_APPEND $main_check . 
                                         '^' . 
                                         $main_inp_value . 
                                         '^' . 
                                         $inp_text . 
                                         '^' . 
                                         "\n";

               } elsif($param == 99) {

                  print JT_CONFIG_APPEND $main_check . 
                                         '^' . 
                                         $loc_casc . 
                                         '^' . 
                                         $main_inp_value . 
                                         '^' . 
                                         $inp_text . 
                                         '^' . 
                                         "\n";
               }
               close(JT_CONFIG_APPEND);

               main::sort_Jareds_file();

               if($param == 99){
                  main::ed_butt($loc_casc,$main_inp_value);
               }
            }
         } else {
            main::mes($d,$main::lg{no_val_def});
            if($param == 69){
               return (0,$inp_text);
            }
         }
      }
   } elsif(($param == 2)||
           ($param == 3)||
           ($param == 4)||
           ($param == 5)||
           ($param == 6)||
           ($param == 7)||
           ($param == 59)||
           ($param == 79)||
           ($param == 89)){
      my $d_inp;
      my $b_d;
      my $tl;
      my $l;
      my @casc1;
      my @casc2;
      my $d;
      my $message;

      $main_check = 'C';
      my $del_text = $main::lg{casc_text};

      if($param == 2){

         $title = $main::lg{del_cascade};
         $action = $main::lg{del};
         $message = $main::lg{del_message};

      } elsif($param == 3) {

         $title = $main::lg{add_button};
         $action = $main::lg{next};
         $message = $main::lg{add_butt_mess};

      } elsif($param == 4) {

         $title = $main::lg{del_button};
         $action = $main::lg{next};
         $message = $main::lg{del_butt_mess};

      } elsif($param == 5) {

         $title = $main::lg{config_edit_sql};
         $action = $main::lg{next};
         $message = $main::lg{ed_sql_mess};

      } elsif($param == 6){

         $title = $main::lg{config_edit_casc};
         $action = $main::lg{next};
         $message = $main::lg{choose_casc};

      } elsif($param == 7){

         $sec_check = 'B';
         $title = $main::lg{config_edit_butt};
         $action = $main::lg{next};
         $message = $main::lg{choose_casc};

      } elsif($param == 59) {

         $main_check = 'B';
         $title = $main::lg{config_edit_butt};
         $action = $main::lg{next};
         $message = "$main::lg{cascade} $loc_casc: $main::lg{choose_butt}";
         $del_text = $main::lg{choose_butt};

      } elsif($param == 79) {

         $main_check = 'B';
         $title = $main::lg{config_edit_sql};
         $action = $main::lg{next};
         $message = $main::lg{ed_sql_mess2};

      } elsif($param == 89) {

         $main_check = 'B';
         $title = $main::lg{del_button};
         $action = $main::lg{del};
         $message = "$main::lg{cascade} $loc_casc: $main::lg{del_butt_mess2}";
         $del_text = $main::lg{del_butt_text};
      }

      my $i_count = 0;

      if(open(JT_CONFIG,'tools/config.tools')){

         while(<JT_CONFIG>){
            my @hold = split(/\^/, $_);

            if(($param != 89) && 
               ($param != 79) && 
               ($param != 59)){

               if ($hold[0] eq $main_check){

                  $casc1[$i_count] = sprintf("%03d",$hold[1]) . ":$hold[2]";
                  $i_count++;
               }

            } else {
               if (($hold[0] eq $main_check) && 
                   ($hold[1] eq $loc_casc)){

                  $casc1[$i_count] = sprintf("%03d",$hold[2]) . ":$hold[3]";
                  $i_count++;
               }
            }
         }
      }
      if ($i_count > 0){
         @casc2 = sort @casc1;
         $i_count = 0;

         my $t_l;

         foreach(@casc2){

            if($i_count == 0){

               $d = $main::mw->DialogBox(-title=>$title,
                                         -buttons=>[ $action,
                                                     $main::lg{cancel} ]
                                  );

               $t_l = $d->Label(-text=>$message,
                                -anchor=>'n'
                               )->pack(-side=>'top');

               $l = $d->Label(-text=>$del_text . ':',
                              -anchor=>'e',
                              -justify=>'right'
                             );

               $d_inp = $casc2[$i_count];

               $b_d = $d->BrowseEntry( -cursor=>undef,
                                       -variable=>\$d_inp,
                                       -foreground=>$main::fc,
                                       -background=>$main::ec,
                                       -width=>40
                                     );
            }
            $b_d->insert('end', $casc2[$i_count]);
            $i_count++;
         }
         close(JT_CONFIG);
   
         # Let's do a chessboard, or is that a cheeseboard?

         Tk::grid($t_l,-row=>0,-column=>1,-sticky=>'e');
         Tk::grid($l,-row=>1,-column=>0,-sticky=>'e');
         Tk::grid($b_d,-row=>1,-column=>1,-sticky=>'ew');
         $d->gridRowconfigure(1,-weight=>1);

         my $rp = $d->Show;
         if ($rp eq $action) {
            my $fin_inp = sprintf("%03d", split(/:/,$d_inp));
            my $sec_inp;
            my $ed_txt;

            if (defined($fin_inp) && length($fin_inp)){

               if(($param == 2)     ||
                  ($param == 59)    ||
                  ($param == 89)    ||
                  ($param == 6)     ||
                  ($param == 7)) {

                  my $safe_flag = 0;

                  if($param == 6) {

                     ($safe_flag,$ed_txt) = 
                        main::config_Jared_tools(69,$fin_inp);

                  } elsif($param == 7) {

                     ($safe_flag,$sec_inp) = 
                        main::config_Jared_tools(59,$fin_inp);

                     if ((defined($safe_flag)) && 
                         (length($safe_flag)) && 
                         ($safe_flag == 1)){

                        ($safe_flag,$ed_txt) = 
                           main::config_Jared_tools(49,$fin_inp,$sec_inp);
                     }

                  } elsif($param == 59) {

                     $safe_flag = 0;
                     return (1,$fin_inp);

                  } else {

                     $safe_flag = 1;

                  }

                  # OK, Ok, I've forgotten how this works too, but it
                  # seemed to make sense at the time?

                  if ((defined($safe_flag)) && 
                      (length($safe_flag)) && 
                      ($safe_flag == 1)){

                     main::orac_copy('tools/config.tools',
                                     'tools/config.tools.old');

                     open(JT_CONFIG_READ,'tools/config.tools.old');
                     open(JT_CONFIG_WRITE,'>tools/config.tools');

                     while(<JT_CONFIG_READ>){
                        chomp;
                        my @hold = split(/\^/, $_);
                        if($param == 2){
                           unless ($hold[1] eq $fin_inp){
                              print JT_CONFIG_WRITE "$_\n";
                           }
                        } elsif($param == 6){

                           unless (($hold[0] eq $main_check) && 
                                   ($hold[1] eq $fin_inp)){

                              print JT_CONFIG_WRITE "$_\n";

                           } else {

                              print JT_CONFIG_WRITE $hold[0] . 
                                                    '^' . 
                                                    $hold[1] . 
                                                    '^' . 
                                                    $ed_txt . 
                                                    '^' . 
                                                    "\n";
                           }
                        } elsif($param == 7){

                           unless (($hold[0] eq $sec_check) && 
                                   ($hold[1] eq $fin_inp) && 
                                   ($hold[2] eq $sec_inp)){

                              print JT_CONFIG_WRITE "$_\n";

                           } else {

                              print JT_CONFIG_WRITE $hold[0] . 
                                                    '^' . 
                                                    $hold[1] . 
                                                    '^' . 
                                                    $hold[2] . 
                                                    '^' . 
                                                    $ed_txt . 
                                                    '^' . 
                                                    "\n";
                           }

                        } else {

                           unless (($hold[0] eq $main_check) && 
                                   ($hold[1] eq $loc_casc) && 
                                   ($hold[2] eq $fin_inp)){ 

                              print JT_CONFIG_WRITE "$_\n";

                           }
                        }
                     }
                     close(JT_CONFIG_READ);
                     close(JT_CONFIG_WRITE);
                     main::sort_Jareds_file();
                  }

               } elsif($param == 3) {

                  main::config_Jared_tools(99,$fin_inp);

               } elsif($param == 5) {

                  main::config_Jared_tools(79,$fin_inp);

               } elsif($param == 79) {

                  my $filename = 'tools/sql/' . 
                                 $loc_casc . 
                                 '.' . 
                                 $fin_inp . 
                                 '.sql';

                  main::ed_butt($loc_casc,$fin_inp);

               } else {

                  main::config_Jared_tools(89,$fin_inp);

               }

            } else {

               main::mes($d,$main::lg{no_val_def});

            }
         }

      } else {

         main::mes($main::mw,$main::lg{no_cascs});

         if ($param == 59){
            return (0,'');
         }
      }
   }
   main::del_Jareds_tools();
   main::Jareds_tools();
}
sub sort_Jareds_file {
   main::orac_copy('tools/config.tools','tools/config.tools.sort');
   open(JT_CONFIG_READ,'tools/config.tools.sort');
   my @file_read;
   my @file_write;
   my $i_count = 0;
   while(<JT_CONFIG_READ>){
      chomp;
      $file_read[$i_count] = $_;
      $i_count++;
   }
   close(JT_CONFIG_READ);

   open(JT_CONFIG_WRITE,'>tools/config.tools');
   @file_write = sort @file_read;
   $i_count = 0;
   foreach(@file_write){
      print JT_CONFIG_WRITE "$file_write[$i_count]\n";
      $i_count++;
   }
   close(JT_CONFIG_WRITE);
}
sub get_butt_text {

   # Pick up more information on the configurable buttons

   my($casc,$butt) = @_;
   my $title = '';
   open(JARED_FILE,'tools/config.tools');
   while(<JARED_FILE>){
      my @hold = split(/\^/, $_);
      if(($hold[0] eq 'B') && ($hold[1] eq $casc) && ($hold[2] eq $butt)){
         $title = $hold[3];
      }
   }
   close(JARED_FILE);
   return $title;
}

sub run_Jareds_tool {

   # When user selects their own button, run the 
   # associated report

   my($casc,$butt) = @_;

   $main::current_db->show_sql ( main::get_Jared_sql( $casc, $butt ),
                                 main::get_butt_text( $casc, $butt )
                               );
}

sub del_Jareds_tools {

   # If the 'My Tools' menu currently exists, then
   # destroy it

   if(defined($main::jt)){
      $main::jt->destroy();
      $main::jt = undef;
   }
}
sub orac_copy {

   # This is to avoid Orac becoming OS dependent.
   # Obviously, on UNIX it would be easy to write
   # system("cp $file1 $file2");, but this would
   # make us dependent on UNIX.  Hopefully, this
   # function provided file copying functionality
   # without tying Orac down to the OS.

   my($ammo,$target) = @_;
   if(open(ORAC_AMMO,"$ammo")){
      if(open(ORAC_TARGET,">${target}")){
         while(<ORAC_AMMO>){
            print ORAC_TARGET $_;
         }
         close(ORAC_TARGET);
      }
      close(ORAC_AMMO);
   }
}
sub iconize {

   # Take a Window handle, and tie an icon 
   # to it.

   my($w) = @_;
   my $icon_img = $w->Photo('-file' => 'img/orac.gif');
   $w->Icon('-image' => $icon_img);
}
sub pick_up_defaults {

   # This allows user to select main database type.
   # Also allows selection of pre-defined background
   # colour.  Assign some pre-defined values in case
   # the config file not yet available.

   $main::bc = $main::lg{def_backgr_col};

   my $i = 0;
   my $file = 'config/what_db.txt';
   if(-e $file){
      open(DB_FIL,$file);
      while(<DB_FIL>){
         my @hold = split(/\^/, $_);
         $main::orac_curr_db_typ = $hold[0];
         $main::sys_user = $hold[1];
         $main::bc = $hold[2];
         $main::v_db = $hold[3];
         $i = 1;
      }
      close(DB_FIL);
   }
   return;
}
BEGIN {

   # If any non-fatal warnings/errors are detected by
   # Orac, this should ensure they come up in "look-and-feel"
   # window.  Particularly useful for reporting back
   # database error messages.

   # We have one program flag for suppressing error messages
   # on database connection, until the last variation
   # on database connection is attempted.

   $SIG{__WARN__} = sub{
      if ((!defined($main::conn_comm_flag)) || ($main::conn_comm_flag == 0)){
         if (defined $main::mw) {
            main::mes($main::mw,$_[0]);
         } else {
            print STDOUT join("\n",@_),"n";
         }
      }
   };
}

# my $e = $cw->Subwidget("top")->pack(side=>'top',fill=>'both',expand=>'y');
# $cw->Subwidget("bottom")->pack(side=>'bottom',before=>$e,expand=>'n');

