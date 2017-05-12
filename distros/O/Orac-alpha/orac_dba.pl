#!/usr/local/bin/perl
######################################################################
# Copyright (c) 1998,1999,2000,2001 Andy Duncan
#
# You may distribute under the terms of either the GNU General
# Public License or the Artistic License,as specified in the Perl
# README file,with the exception that it cannot be placed on a CD-ROM
# or similar media for commercial distribution without the prior
# approval of the author.
#
# This code is provided with no warranty of any kind,and is used
# entirely at your own risk. This code was written by the author as
# a private individual, and is in no way endorsed or warrantied.
#
# Support questions and suggestions can be directed to
# andy_j_duncan@yahoo.com
#
# Download from CPAN/authors/id/A/AN/ANDYDUNC
######################################################################

=head1 NAME

orac_dba.pl - the Main Oracle module of the Orac tool

=head1 DESCRIPTION

This module sets up the program, by pulling in the required modules,
setting up menus, providing the main screen, setting up global
variables and giving the other modules a small library of utility
functions.

=cut

# Pick up all the standard modules necessary to run the program
# Make sure we have the minimal versions of Perl, DBI and Tk.
# (thanks to Tom Lowery)

require 5.6.0;

use Tk '800.000';

use FindBin;
use lib $FindBin::RealBin;

# Splash Screen

main::splash_screen(0);

# More requirements, and the rest of the code to be loaded
# before the main loop.

use DBI '1.10';
$VERSION = '1.260';

# Now enter strict mode
use strict;

use Carp;
use FileHandle;
use Cwd;
use Time::Local;
use File::Copy;
use File::Basename;
# Thanks to Sean Kamath :-)
use File::Spec;

# A hunky clundgy kinda-of-a-thing to handle screen resizing

use Tk::DialogBox;
use Tk::Balloon;
use Tk::Pretty;
use Tk::HList;
require Tk::BrowseEntry;

# Pick up our specialised modules, plus some special
# flags for various database use.

use orac_Base;
use orac_Shell;
use orac_FileSelect;
use orac_Font;
use orac_Print;
use orac_Monitor;

# Bring up the main "Worksheet" window

$main::mw = MainWindow->new();

# Read the menu/English.txt file to pick up all text
# for use with the rest of the program

main::read_language();

# Some hard-coded defaults

$main::ssq = $main::lg{see_sql};

# Sybase warnings special variable

undef $main::store_msgs;

# Added by Alex Shnir to support color change in Create Table(Sybase)
undef $main::sc;
$main::sc = $main::lg{def_bg_col};

# Debugging flag for developers?
# for kevinb :)
# and now for thomasl too :)

if(defined($ENV{ORAC_DEBUG})) {
   $main::debug = int($ENV{ORAC_DEBUG});
}
else {
   $main::debug = 0;
}

if(defined($ENV{DBI_SHELL})) {
   $main::do_shell = int($ENV{DBI_SHELL});
}
else {
   $main::do_shell = 0;
}

$main::conn_ball{green} =
   $main::mw->Photo( -file => "$FindBin::RealBin/img/grn_ball.gif" );

$main::conn_ball{red} =
   $main::mw->Photo( -file => "$FindBin::RealBin/img/red_ball.gif" );

# Build up frames

my(@layout_mb) = qw/-side top -padx 5 -expand no -fill both/;

$main::mb = $main::mw->Frame( -relief => 'ridge',
                              -borderwidth => 2,

                            )->pack(@layout_mb);

my $bb = $main::mw->Frame( -relief => 'ridge',
                           -bd => 2,
                         )->pack(-side=>'top',
                                 -padx=>5,
                                 -expand=>'no',
                                 -fill=>'both',
                                 -anchor=>'s',
                                );

my $text_box = $main::mw->Frame->pack(-side => 'bottom',
                                      -expand => 'yes',
                                      -fill => 'both',
                                     );

# To do font stuff, we need to set up the main Text box here,
# so we can determine its available fonts, as
# unobtrusively as possible.  The orac_Font module
# relies on $main::v_text having been set up, before
# its blessed reference is created.

$main::v_text = $text_box->Scrolled(  'Text',
                                      -wrap=>'none',
                                   );

# Apparently, we don't need this tying code anymore.
#
#tie (*TEXT,'Tk::Text',$main::v_text);

my $status_bar = $main::mw->Frame( -relief => 'groove',
                                   -bd => 2
                                 )->pack( -side => 'bottom',
                                          -before=> $text_box,
                                          -fill => 'x',
                                        );

# Set up a few defaults, such as the lovely Steelblue2
# for the background colour.  We now need to do this
# here, as we have to have the $main::v_text widget
# set up to do some stuff with fonts.

main::pick_up_defaults();

# Now we have the foreground and background colours,
# + fonts, configure the main window.

$main::v_text->configure( -foreground=>$main::fc,
                          -background=>$main::bc,
                          -font=>$main::font{name},
                        );

# First of all, provide the only hard-coded menu that we
# do, for functions across all databases

my $file_mb = $main::mb->Menubutton(-text=>$main::lg{file},
                          )->pack(-side=>'left',
                                  -padx=>2);

$file_mb->command(-label=>$main::lg{reconn},
                  -command=>sub{main::get_db()});

$file_mb->separator();

$file_mb->command(-label=>$main::lg{about_orac},
                  -command=>
                      sub{

   main::bz();
   $main::current_db->f_clr($main::v_clr);
   $main::current_db->see_sql( $main::mw,
                               $main::current_db->gf_str(
                                             "$FindBin::RealBin/README"
                                                        ),
                               'README',
                             );
   main::ubz()
                         }
                 );

# The ordinary File Select Viewer is set here,
# and the help menu type thing, and the
# document viewer etc.

my @file_viewers = ('file_viewer', 'orac_home', 'docs', 'help', );

foreach my $key (@file_viewers)
{
   my $startdir = "$FindBin::RealBin";

   if ($key eq 'orac_home')
   {
      $startdir = $main::orac_home;
   }
   elsif ( ($key eq 'help') || ($key eq 'docs') )
   {
      $startdir = $startdir . '/' . $key;
   }

   my $dirname = File::Basename::dirname($startdir);
   my $basename = File::Basename::basename($startdir);
   $startdir = File::Spec->catfile($dirname, $basename);

   $main::fileselect{$key}->{startdir} = $startdir;
}

$file_mb->command(-label=>$main::lg{file_viewer},
                  -command=> sub{
      main::bz();
      my $fileselect = orac_FileSelect->new( $main::mw,
                                             $main::v_text,
                                             $main::lg{file_viewer},
                                           );
      $fileselect->req_filebox( $main::fileselect{file_viewer}->{startdir}
                              );
      main::ubz();
                                }
                    );

$file_mb->separator();

# Build up the colour options, so
# a nice lemonchiffon is possible as a backdrop :)

main::colour_menu(\$file_mb, $main::lg{back_col_menu}, \$main::bc);
main::colour_menu(\$file_mb, $main::lg{fore_col_menu}, \$main::fc);
main::colour_menu(\$file_mb, $main::lg{entry_col_menu}, \$main::ec);

# Now a Font option for KB :-)

my $font_button;

$file_mb->command(-label=>$main::lg{font_sel},
                  -command=> sub{
      main::bz();
      my $fonter = orac_Font->new( $main::mw,
                                   $main::v_text,
                                   $main::lg{font_sel},
                                 );
      $fonter->orac_fonter(\$main::balloon, \$font_button);
      main::ubz()
                                }
                  );

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

# Sort out the options to clear the screen on
# each report

my $balloon_status = $status_bar->Label(-relief=>'flat',
                                        -justify=>'left',
                                        -anchor=>'w',
                                        -width=>80,
                                       )->pack(-side=>'left',
                                              );

$main::balloon = $main::mw->Balloon(-statusbar => $balloon_status,
                                    -state => 'status',
                                   );

# The Orac Text Label

my $b_image = $main::mw->Photo(-file=>"$FindBin::RealBin/img/s_splash.gif");

my $b = $bb->Button(-image=>$b_image,
                    -command=>sub{main::bz();
                                  main::splash_screen(1);
                                  main::ubz()}
                   )->pack(side=>'left');

# The Reconnection Button

$b_image = $main::mw->Photo(-file=>"$FindBin::RealBin/img/recon.gif");

$b = $bb->Button(-image=>$b_image,
                 -command=>sub{main::bz();
                               main::get_db();
                               main::ubz()}
                )->pack(side=>'left');

$main::balloon->attach($b, -msg => $main::lg{reconn});

# The Monitor Button

$b_image = $main::mw->Photo(-file=>"$FindBin::RealBin/img/monitor.gif");

$b = $bb->Button(-image=>$b_image,
                 -command=>sub{

      main::bz();
      my $monitor = orac_Monitor->new( $main::mw,
                                       $main::v_text,
                                       $main::lg{db_mon},
                                 );
      $monitor->orac_monitor();
      main::ubz()}

                )->pack(side=>'left');

$main::balloon->attach($b, -msg => $main::lg{db_mon});

# The Font Button

$b_image = $main::mw->Photo(-file=>"$FindBin::RealBin/img/font.gif");

$font_button = $bb->Button(-image=>$b_image,
                           -command=>sub{

      main::bz();
      my $fonter = orac_Font->new( $main::mw,
                                   $main::v_text,
                                   $main::lg{font_sel},
                                 );
      $fonter->orac_fonter(\$main::balloon, \$font_button);
      main::ubz();
                                           }

                             )->pack(side=>'left');

main::font_button_message(\$main::balloon, \$font_button);

# The Print Button

$b_image = $main::mw->Photo(-file=>"$FindBin::RealBin/img/print.gif");

$b = $bb->Button(-image=>$b_image,
                 -command=>sub{

      main::bz();
      my $printer = orac_Print->new( $main::mw,
                                     $main::v_text,
                                     $main::lg{print_sel},
                                 );
      $printer->orac_printer();
      main::ubz()}

                )->pack(side=>'left');

$main::balloon->attach($b, -msg => $main::lg{print_sel});

$b_image = $main::mw->Photo(-file=>"$FindBin::RealBin/img/eraser.gif");
 	
$b = $bb->Button(-image=>$b_image,
                 -command=>sub{main::bz();
                               $main::current_db->must_f_clr();
                               main::ubz()}
                )->pack(side=>'left');

$main::balloon->attach($b, -msg => $main::lg{clear});

# Now Manual/Automatic clearing

$main::v_clr = 'Y';

my $man_auto_but = $bb->Button;

my %man_auto_img;

# Y is automatic, N is manual

$man_auto_img{Y} =
   $main::mw->Photo( -file => "$FindBin::RealBin/img/auto.gif" );

$man_auto_img{N} =
   $main::mw->Photo( -file => "$FindBin::RealBin/img/manual.gif" );

$man_auto_but->configure(-image => $man_auto_img{ $main::v_clr } );
   $man_auto_but->configure(-command => sub {

      if ( $main::v_clr eq 'Y' )
      {
         $main::v_clr = 'N';
         $main::balloon->attach($man_auto_but, -msg => $main::lg{man_clear} );
      }
      else
      {
         $main::v_clr = 'Y';
         $main::balloon->attach($man_auto_but, -msg => $main::lg{auto_clear} );
      }
      $man_auto_but->configure(-image => $man_auto_img{ $main::v_clr } );

                                           }
                        );

$man_auto_but->pack( -side => 'left' );
$main::balloon->attach($man_auto_but, -msg => $main::lg{auto_clear} );

# The File Viewer, Orac Home, Help and Docs Buttons

foreach my $key (@file_viewers)
{
   $b_image = $main::mw->Photo(-file=>"$FindBin::RealBin/img/${key}.gif");

   $b = $bb->Button(-image=>$b_image,
                    -command=>sub{

         main::bz();
         my $fileselect = orac_FileSelect->new( $main::mw,
                                                $main::v_text,
                                                $main::lg{$key},
                                              );

         $fileselect->req_filebox( $main::fileselect{$key}->{startdir}
                                 );
         main::ubz();

                                 }

                   )->pack(side=>'left');

   $main::balloon->attach($b, -msg => $main::lg{$key});

}

# Now the other end of the menubar

my $orac_li = $main::mw->Photo(-file=>"$FindBin::RealBin/img/orac.gif");

$bb->Label(-image=>$orac_li,
           -borderwidth=>2,
           -relief=>'flat'
          )->pack(-side=>'right',
                  -anchor=>'e'
                 );

my $shell_image = $main::mw->Photo(-file=>"$FindBin::RealBin/img/shell.gif");

$b = $bb->Button(
           -image=>$shell_image,
           -command=>
                 sub{
                       main::call_shell();
                    }
                )->pack(-side=>'right');

$main::balloon->attach($b, -msg => $main::lg{dbish});

# Slap up the main Output Box

$main::v_text->pack(-expand=>1,-fill=>'both');

# Set main window title and set window icon

$main::mw->title( "$main::lg{orac_pan} VERSION $main::VERSION" );
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

# 1.1.50 Change for Tom, to prevent splash screen interfering with login.

main::destroy_splash();

# Now we go to Login, and get the required database

main::get_db();

# Here we go, lights, cameras, action!

MainLoop();

# Clear out everything before exiting, and then draw
# those curtains

main::back_orac();

#################### Sub functions begin ####################

=head2 back_orac

Backs out of program as nicely as possible, and saves any chosen
options in the main configuration file.

=cut

sub back_orac {

   # Back out of program nicely, and save any chosen
   # options in the main configuration file

   if (defined($main::current_db)){
      $main::conn_comm_flag = 1;
      my $rc  = $main::dbh->disconnect;
      $main::conn_comm_flag = 0;
   }
   main::fill_defaults(  $main::orac_curr_db_typ,
                         $main::sys_user,
                         $main::bc,
                         $main::v_db,
                         $main::fc,
                         $main::ec
                      );
   exit 0;
}

=head2 fill_defaults

Picks up the users required defaults for the screen appearance,
database requirements etc.

=cut

sub fill_defaults {

   # Make sure defaults the way the user likes 'em.

   my($db_typ, $dba, $loc_bc, $db, $loc_fc, $loc_ec) = @_;

   my $filename = File::Spec->catfile($main::orac_home, 'what_db.txt');

   open(DB_FIL,">$filename");

   print DB_FIL $db_typ .  '^' .
                $dba .  '^' .
                $loc_bc .  '^' .
                $db .  '^' .
                $loc_fc .  '^' .
                $loc_ec .  '^' .  "\n";

   close(DB_FIL);

   # Now deal with fonts.

   $filename = File::Spec->catfile($main::orac_home, 'what_font.txt');

   open(FONT_FIL,">$filename");

   print FONT_FIL $main::font{family} .  '^' .
                  $main::font{size} .  '^' .
                  $main::font{weight} .  '^' .
                  $main::font{slant} .  '^' .
                  "\n";

   close(FONT_FIL);

   # Now deal with printing options.

   $filename = File::Spec->catfile($main::orac_home, 'what_print.txt');

   open(PRINT_FIL,">$filename");

   print PRINT_FIL $main::print{rotate} .  '^' .
                  $main::print{paper} .  '^' .
                  $main::print{command} .  '^' .
                  "\n";

   close(PRINT_FIL);
}

=head2 get_connected

Puts up the main dialogue to pick a new database.  Allows user to change
database type, if they wish.  Also, sets flag to help prevent connection
error messages, except on the last attempt at connection.

=cut

sub get_connected {

   # Put up dialogue to pick a new database.
   # Allow user to change database type, if they wish.  Also, set flag
   # to help prevent connection error messages, except on the
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
      $main::conn_comm_flag = 1;
      my $rc = $main::dbh->disconnect;
      $main::conn_comm_flag = 0;
      undef $main::current_db;
      $auto_log = 0;
   }

   do {
      # Create the new object

      if($main::orac_curr_db_typ eq 'Oracle'){

         print STDERR "New Oracle object\n" if ($main::debug > 0);

         require db::orac_Oracle;
         $main::current_db = orac_Oracle->new( $main::mw,
                                               $main::v_text,
                                               $main::VERSION);

      }
      elsif($main::orac_curr_db_typ eq 'Informix'){

         require db::orac_Informix;
         $main::current_db = orac_Informix->new( $main::mw,
                                                 $main::v_text,
                                                 $main::VERSION );

      }
      elsif($main::orac_curr_db_typ eq 'Sybase'){

         require db::orac_Sybase;
         $main::current_db = orac_Sybase->new( $main::mw,
                                               $main::v_text,
                                               $main::VERSION );

      }
      else {

         $main::current_db =
            orac_Base->new( 'Base',
                            $main::mw,
                            $main::v_text,
                            $main::VERSION );

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
                 $c_d->BrowseEntry(-variable=>\$main::v_db,
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
      for ($i = 0;$i < $h;$i++){
         @ic = split(/:/,$h[$i]);
         $ic = @ic;
         $ls_db{$ic[($ic - 1)]} = 101;
      }

      # Supplement these, with stored database to which they've
      # successfully connected in the past

      my $open_dbfile = "$main::orac_home/txt/$main::orac_curr_db_typ" .
                        "/orac_db_list.txt";

      my $dirname = File::Basename::dirname($open_dbfile);
      my $basename = File::Basename::basename($open_dbfile);
      $open_dbfile = File::Spec->catfile($dirname, $basename);

      if ( open(DBFILE, "$open_dbfile" ) )
      {
         while(<DBFILE>){
            chomp;
            $ls_db{$_} = 102;
         }
         close(DBFILE);
      }

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
                        -textvariable=>\$main::sys_user,
                        -foreground=>$main::fc,
                        -background=>$main::ec
                       )->pack(side=>'right');

      my $l3 = $c_d->Label(-text=>$main::lg{sys_pass} . ':',
                           -anchor=>'e',
                           -justify=>'right');

      $ps_e = $c_d->add("Entry",
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

      #$ENV{DBI_DSN} = "dbi:Oracle:orcl";
      #$ENV{DBI_USER} = "scott";
      #$ENV{DBI_PASS} = "tiger";

      print STDERR "Before DBI dsn>$ENV{DBI_DSN}<\n" if ($main::debug > 0);
      print STDERR "          user>$ENV{DBI_USER}<\n" if ($main::debug > 0);
      print STDERR "          pass>$ENV{DBI_PASS}<\n" if ($main::debug > 0);

      if ((defined($ENV{DBI_DSN}) && (length($ENV{DBI_DSN}) > 0)) &&
          (defined($ENV{DBI_USER}) && (length($ENV{DBI_USER}) > 0)) &&
          (defined($ENV{DBI_PASS}) && (length($ENV{DBI_PASS}) > 0)) &&
          ($auto_log == 1))
      {
         # Right, they're all defined, is the DSN one valid?
         # I'll define valid as it must be a colon-separated
         # list of three elements, the first one of which must
         # be 'dbi'.  Ok?

         my @test_arr = (split(/:/,$ENV{DBI_DSN}));
         my $length_test_arr = @test_arr;

         if (($test_arr[0] =~ /dbi/i) && ($length_test_arr == 3)){

            # Seems valid enough to me.

            $auto_log = 1;
         }
         else {

            # Seems invalid to me.

            $auto_log = 0;
         }
      }
      else {
         $auto_log = 0;
      }

      my $mn_b;

      if(!$auto_log) {

         $c_d->gridRowconfigure(1,-weight=>1,-pad=>5,);
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

                     my $dirname = "$main::orac_home/txt/" .
                               "$main::orac_curr_db_typ/dummy";

                     my $dir = File::Basename::dirname($dirname);
                     my $txt_dir = File::Basename::dirname($dir);

                     mkdir ($txt_dir, 0755)
                        unless -d $txt_dir;

                     mkdir ($dir, 0755) unless -d $dir;

                     my $file = File::Spec->catfile($dir, 'orac_db_list.txt');

                     if (open(DBFILE, ">>$file")) {
                        print DBFILE "$main::v_db\n";
                        close(DBFILE);
                     } else {
                        warn "Unable to open $file: $!\n";
                     }
                  }
                  $main_label->configure( -image => $main::conn_ball{green} );
                  $main::l_top_t = "$main::v_db";
                  $main::sys_user = $main::v_sys;
               } else {
                  $main_label->configure( -image => $main::conn_ball{red} );
                  $main::l_top_t = $main::lg{not_conn};
               }

               # auto_log Patch supplied below by Sean Hull

               $auto_log = 0;

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

=head2 connector

Actually attempts the DBI database connection.

=cut

sub connector {
   print STDERR "connecting: $_[0], $_[1], $_[2]\n" if ($main::debug > 0);
   $main::dbh = DBI->connect($_[0], $_[1], $_[2]);
   $main::current_db->set_db_handle($main::dbh);
}

=head2 select_dbtyp

User may either be picking default database type for the first time,
or changing database type.  Either way, this builds up a dialogue to allow
them to do this.

=cut

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

      my $b_d = $d->BrowseEntry(-state=>'readonly',
                                -variable=>\$loc_db,
                                -foreground=>$main::fc,
                                -background=>$main::ec,
                                -width=>40
                               );

      # Check out which DBs we're currently allowed to pick from

      my $first_place = File::Spec->catfile($main::orac_home, 'all_dbs.txt');
      my $second_place = File::Spec->catfile($FindBin::RealBin, 'config');
      $second_place = File::Spec->catfile($second_place, 'all_dbs.txt');

      open(DB_FIL, $first_place ) ||
		open(DB_FIL, $second_place );

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

   # Pick up the standard user for the particular database
   ($main::sys_user,$main::v_db) = get_dba_user($loc_db);
   main::fill_defaults($loc_db, 
                       $main::sys_user, 
                       $main::bc, 
                       $main::v_db,
                       $main::fc, 
                       $main::ec
                      );

   return $loc_db;
}

=head2 get_dba_user

Picks up the typical user for the particular database.

=cut

sub get_dba_user {

   my($db) = @_;
   my $dba_user;
   my $new_db;

   # Picks up the typical user for the particular database

   my $first_place = File::Spec->catfile($main::orac_home, 'all_dbs.txt');
   my $second_place = File::Spec->catfile($FindBin::RealBin, 'config');
   $second_place = File::Spec->catfile($second_place, 'all_dbs.txt');

   open(DB_FIL, $first_place ) ||
	 open(DB_FIL, $second_place );

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

=head2 get_db

Picks up database, and then configures menus accordingly.

=cut

sub get_db {
   # Picks up database, and then configures menus accordingly

   main::get_connected();
   unless (defined($main::current_db)){
     main::back_orac();
   }

   # Run the second initialisation routine
   $main::current_db->init2( $main::dbh );

   # Now sort out Jared's tools and configurable menus

   if (($main::orac_orig_db ne $main::orac_curr_db_typ) ||
       ($main::orac_curr_db_typ =~ /Oracle/)){

      # We do this, if either we're into the program for the first time,
      # or the user has changed the database type

      main::del_Jareds_tools(\$main::jareds_tool);
      main::config_menu();
      main::Jareds_tools();
      $main::orac_orig_db = $main::orac_curr_db_typ;
   }
}

=head2 bz

Makes the main GUI pointer go busy.

=cut

sub bz {
   # Make the main GUI pointer go busy
   $main::mw->Busy(-recurse=>1);
}

=head2 ubz

Makes the main GUI pointer go Un-busy.

=cut

sub ubz {
   # Make the main GUI pointer normalise to unbusy
   $main::mw->Unbusy;
}

sub mes {
   # Produce the box that contains viewable Error

   my $d = $_[0]->DialogBox();

   my $displayer;

   if (length($_[1]) > 200)
   {
      $displayer = $d->Scrolled( 'Text',
			         -setgrid => 1,
                                 -height=>10,
                               );
      $displayer->pack(-expand=>1,-fill=>'both');
      $displayer->insert('end', $_[1]);
   }
   else
   {
      $displayer = $d->Label(-text=>$_[1],
                             -relief=>'flat',
                            );
      $displayer->pack(-expand=>1,-fill=>'both');
   }
   $d->Show;
}

=head2 bc_upd

Change the background colour on all open windows.
Also foregrounds, where not a Canvas.
This is where all those text and window handles come in useful.

=cut

sub bc_upd {

   # Change the background colour on all open windows.
   # This is where all those text and window handles
   # come in useful.

   eval {
      $main::v_text->configure(-background=>$main::bc,
                               -foreground=>$main::fc,
                               -font=>$main::font{name});
   };
   my $comp_str = "";
   my $i;

   my @kids = $main::mw->children();
   foreach my $kid ( @kids )
   {
      if ($kid =~ /Toplevel/)
      {
         if ( exists( $kid->{text} ) )
         {
            eval {
               $kid->{text}->configure(-background=>$main::bc,
                                       -font=>$main::font{name}
                                      );
            };

            unless ($kid =~ /Canvas/)
            {
               eval {
                  $kid->{text}->configure(-foreground=>$main::fc);
               }
            }
         }
      }
   }
}

=head2 read_language

Open up the main configurable language file, and pick up all
the strings required by Orac.

=cut

sub read_language {

   # Open up the main configurable
   # language file, and pick up all
   # the strings required by Orac

   open(TITLES_FILE, "$FindBin::RealBin/txt/English.txt");
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

=head2 get_language_data

Opens up the main configurable language file, and picks up all
the strings required by Orac.

=cut

sub get_language_data {

   # Open up the main configurable
   # language file, and pick up all
   # the strings required by Orac

   open(TITLES_FILE, "$FindBin::RealBin/txt/languages.txt")
      or die "can't open $FindBin::RealBin/txt/languages.txt";

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

=head2 read_language_file

In the series of functions that will be modified at some unspecified
date in the future, to make Orac natural language independent.

=cut

sub read_language_file {

   # ARG1 = language_label picked

   my $file = "$FindBin::RealBin/txt/$main::languages{$_[0]}";

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

=head2 config_menu

Reads the database dependent menu configuration file, and build up menus.
This function gets pretty complex, and a strong drink may be
required beforehand, before attempting to work out what it is doing :)

=cut

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

   my $menu_file_name = "menu.txt";
   if ($main::orac_curr_db_typ eq "Oracle"){
      if (!$main::current_db->dba_user){       
         if ($main::current_db->jpeg_user){   
            $menu_file_name = "menu_dev_jpeg.txt";
         } else {                                
            $menu_file_name = "menu_dev.txt";   
         }                                     
      } else {
         if ($main::current_db->jpeg_user){   
            $menu_file_name = "menu_jpeg.txt";
         }
      }
   }
   my $file = "$FindBin::RealBin/menu/$main::orac_curr_db_typ/" .
              $menu_file_name;
   open(MENU_F, $file) or warn qq{Unable to open $file $!};;
   while(<MENU_F>){

      chomp;
        next if m/^$/;  # Skip blank lines.
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

            # The use of this has now been deprecated with the
            # constant use of Toplevel windows.  However,
            # we may use it again in the future,
            # therefore we'll leave it here.

            #$menu_command = $menu_command . ' $main::this_button' .
            #                ' = ';
         }

         if ($menu_line[0] eq 'command'){

            $menu_command =
               $menu_command .
               ' $main::tm_but[$main::tm_but_ct]->command(-label=>$main::lg{' .
               $menu_line[3] . '},' .
               ' -command=>sub{main::bz();';

         } elsif ($menu_line[0] eq 'casc_command'){

            $menu_command = $menu_command .
                            ' $main::but_' .
                            $menu_line[3] .
                            ' = $main::casc_item->command(-label=>$main::lg{' .
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
      if ($menu_line[0] eq 'add_cascade_button') {
         $menu_command .= $main::current_db->add_cascade_button($menu_line[1]);
      }
   }
   close(MENU_F);

   # And if you think it was fun writing that stuff above,
   # then you ain't coming to no parties of mine :)

   # Here we go!  Slap up those menus.

   print STDERR "config_menu: menu_command >\n$menu_command\n<\n"
      if ($main::debug > 0);

   eval $menu_command ; warn $@ if $@;

   $main::tm_but_ct++;
   $main::tm_but[$main::tm_but_ct] =
                   $main::mb->Menubutton(-text=>$main::lg{sql_menu},
                                        )->pack(-side=>'left',
                                                -padx=>2);
   $main::tm_but[$main::tm_but_ct]->command(

                         -label=>$main::lg{dbish},
                         -command=>sub{
                                          main::call_shell();
                                      }
                                           );
   return;
}

=head2 Jareds_tools

Builds up the 'My Tools' options, where Orac users can specify their own
local SQL files to generate Orac-like reports.

=cut

sub Jareds_tools {

   # Build up the 'My Tools' menu option.

   if(!defined($main::jareds_tool)){

      # Monster coming up.  You'll cope.

      my $comm_str =
          ' $main::jareds_tool = $main::mb->Menubutton( ' . "\n" .
          ' -text=>$main::lg{my_tools},' . "\n" .
          ' -menuitems=> ' . "\n" .
          ' [[Button=>$main::lg{help_with_tools},' .
          ' -command=>sub{main::bz();' . "\n" .
          ' $main::current_db->see_sql' .
          '($main::mw,$main::current_db->gf_str(' .
          '"$FindBin::RealBin/help/HelpTools.txt"),' .
          '$main::lg{help_with_tools});' . "\n" .
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

      my $jt_casc_file = File::Spec->catfile($main::orac_home, 'config.tools');

      if(open(JT_CASC, $jt_casc_file )){
         while(<JT_CASC>){
            my @jt_casc = split(/\^/, $_);
            if ($jt_casc[0] eq 'C'){

               $comm_str = $comm_str .
                           ' [Cascade  =>\'' .
                           $jt_casc[2] .
                           '\',-menuitems => [ ' . "\n";

               my $jt_casc_butts_file =
                     File::Spec->catfile($main::orac_home, 'config.tools');

               open(JT_CASC_BUTTS, $jt_casc_butts_file );
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

=head2 save_sql

Picks up the SQL the user has entered, and saves it into the appropriate file.

=cut

sub save_sql {

   # Pick up the SQL the user has entered, and
   # save it into the appropriate file

   my($txt_ref, $filename) = @_;

   my $dirname = File::Basename::dirname($filename);
   my $basename = File::Basename::basename($filename);
   $filename = File::Spec->catfile($dirname, $basename);

   copy($filename,"${filename}.old");

   open(SAV_SQL,">$filename");
   print SAV_SQL $$txt_ref->get("1.0", "end");
   close(SAV_SQL);

   return $filename;
}

=head2 ed_butt

Allows configuration of 'My Tools' menus, buttons, cascades, etc.  Tries
to make the setting up of new buttons, cascades etc, as painless as
possible.

=cut

sub ed_butt {

   # Allow configuration of 'My Tools' menus, buttons, cascades, etc

   my($casc,$butt) = @_;
   my $ed_fl_txt = main::get_butt_text($casc,$butt);

   my $sql_file = $main::orac_home.'/sql/tools/' . $casc . '.' . $butt . '.sql';
   my $dirname = File::Basename::dirname($sql_file);
   my $basename = File::Basename::basename($sql_file);
   $sql_file = File::Spec->catfile($dirname, $basename);

   my $window = $main::mw->Toplevel();

   $window->title(  "$main::lg{cascade} $casc,
                    $main::lg{button} $butt");

   my $ed_sql_txt = "$ed_fl_txt: $main::lg{ed_sql_txt}";
   my $ed_sql_txt_cnt = 0;

   $window->Label( -textvariable  => \$ed_sql_txt,
                   -anchor=>'n',
                   -relief=>'groove'
                 )->pack(-expand=>'no');

   $window->{text} =
      $window->Scrolled( 'Text',
                         -wrap=>'none',
                         -font=>$main::font{name},
                         -foreground=>$main::fc,
                         -background=>$main::bc

                       )->pack(-expand=>'yes',
                               -fill=>'both'
                              );

   my(@lay) = qw/-side bottom -padx 5 -fill both -expand no/;

   my $f = $window->Frame->pack(@lay);

   $f->Button(
      -text=>$main::lg{exit},
      -command=>sub{ $window->destroy() }

             )->pack(-side=>'right',
                     -anchor=>'e');

   $f->Button(
      -text => $main::lg{save},
      -command =>

          sub {

          my $file_name = main::save_sql(  \$window->{text},
                                           $sql_file,
                                        );
          $ed_sql_txt_cnt++;
          $ed_sql_txt = "$ed_fl_txt: $file_name $main::lg{saved}" .
                        ' #' .
                        $ed_sql_txt_cnt;
              },

             )->pack(-side=>'right',
                     -anchor=>'e');

   $f->Label(-text=>$main::lg{no_semi_colon},
             -relief=>'sunken'
            )->pack(-side=>'left',
                    -anchor=>'w');

   main::iconize( $window );

   if(open(SQL_SAV,$sql_file)){

      while(<SQL_SAV>){
         $window->{text}->insert("end", $_);
      }
      close(SQL_SAV);

   }
}

=head2 config_Jared_tools

More functionality required to allow on-the-fly configuration
of the 'My Tools' options.

This function is fairly overloaded, and may require some
detailed analysis, before it becomes clearer what it's doing.

My apologies to those who may want to re-write this, and provide something
much neater.

=cut

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

         my $jt_config_file =
               File::Spec->catfile($main::orac_home, 'config.tools');

         if(open(JT_CONFIG, $jt_config_file )){
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

         my $jt_config_read_file =
               File::Spec->catfile($main::orac_home, 'config.tools');

         open(JT_CONFIG_READ, $jt_config_read_file );

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
                       -foreground=>$main::fc,
                       -background=>$main::ec,
                       -width=>40

                      )->pack(side=>'right');

      # Stand by your priests!

      Tk::grid($l,-row=>0,-column=>0,-sticky=>'e');
      Tk::grid($cs,-row=>0,-column=>1,-sticky=>'ew');

      $d->gridRowconfigure(1,-weight=>1);
      my $rp = $d->Show;
      if ($rp eq $action) {
         if (defined($inp_text) && length($inp_text)){
            if(($param == 69)||($param == 49)){
               return (1,$inp_text);
            } else {

               my $jt_config_append_file =
                     File::Spec->catfile($main::orac_home, 'config.tools');

               open(JT_CONFIG_APPEND,">>$jt_config_append_file");
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

               my $sort1 =
                  File::Spec->catfile($main::orac_home, 'config.tools');

               my $sort2 =
                  File::Spec->catfile($main::orac_home, 'config.tools.sort');

               main::sort_this_file( $sort1,
                                     $sort2,
                                   );

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

      my $jt_config_file = File::Spec->catfile($main::orac_home,'config.tools');

      if(open(JT_CONFIG, $jt_config_file )){

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

      # Ok, Ok, this stuff is all horrible, but I ain't rewriting
      # it.  If you want to code improvements, please, please, please
      # get in touch!!!  :)

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

               $b_d = $d->BrowseEntry( -state=>'readonly',
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

                    my $new_file = File::Spec->catfile($main::orac_home,
                                                    'config.tools');

                    my $old_file = File::Spec->catfile($main::orac_home,
                                                    'config.tools.old');

                    copy(  $new_file,
                           $old_file,
                        );

                     open(JT_CONFIG_READ, $old_file );
                     open(JT_CONFIG_WRITE,">$new_file");

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

                     my $sort1 = File::Spec->catfile($main::orac_home,
                                                  'config.tools');
                     my $sort2 = File::Spec->catfile($main::orac_home,
                                                  'config.tools.sort');

                     main::sort_this_file(
                                           $sort1,
                                           $sort2,
                                         );
                  }

               } elsif($param == 3) {

                  main::config_Jared_tools(99, $fin_inp);

               } elsif($param == 5) {

                  main::config_Jared_tools(79,$fin_inp);

               } elsif($param == 79) {

                  my $filename = $main::orac_home .'/sql/tools/' .
                                 $loc_casc .
                                 '.' .
                                 $fin_inp .
                                 '.sql';

                  my $dirname = File::Basename::dirname($filename);
                  my $basename = File::Basename::basename($filename);
                  $filename = File::Spec->catfile($dirname, $basename);

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
   main::del_Jareds_tools(\$main::jareds_tool);
   main::Jareds_tools();
}

=head2 sort_this_file

Configures and sorts the users generated SQL reports buttons.

=cut

sub sort_this_file {

   my ($file_new, $file_old, ) = @_;

   copy($file_new, $file_old, );

   open(THIS_OLD, $file_old);
   my @file_old;
   my @file_new;
   my $i_count = 0;
   while(<THIS_OLD>){
      chomp;
      $file_old[$i_count] = $_;
      $i_count++;
   }
   close(THIS_OLD);

   open(THIS_NEW,">$file_new");
   @file_new = sort @file_old;
   $i_count = 0;
   foreach(@file_new){
      print THIS_NEW "$file_new[$i_count]\n";
      $i_count++;
   }
   close(THIS_NEW);

   return;

}
=head2 get_butt_text

Pick up more information on the configurable buttons.

=cut

sub get_butt_text {

   # Pick up more information on the configurable buttons

   my($casc,$butt) = @_;
   my $title = '';

   my $jared_file = File::Spec->catfile($main::orac_home, 'config.tools');

   open(JARED_FILE,"$jared_file");
   while(<JARED_FILE>){
      my @hold = split(/\^/, $_);
      if(($hold[0] eq 'B') && ($hold[1] eq $casc) && ($hold[2] eq $butt)){
         $title = $hold[3];
      }
   }
   close(JARED_FILE);
   return $title;
}

=head2 run_Jareds_tool

When user selects their own button, run the associated report.

=cut

sub run_Jareds_tool {

   # When user selects their own button, run the
   # associated report

   my($casc,$butt) = @_;

   # Before we run this, we have to change
   # the database type to 'tools', temporarily.

   print STDERR "\n\nOld db type >" . $main::current_db->{Database_type} .
                "<\n" if ($main::debug > 0);

   my $old_db_type = $main::current_db->{Database_type};

   $main::current_db->{Database_type} = 'tools';

   print STDERR "New db type >" . $main::current_db->{Database_type} .
                "<\n" if ($main::debug > 0);

   $main::current_db->show_sql ( $casc,
                                 $butt,
                                 main::get_butt_text( $casc, $butt )
                               );

   # Now change the database type back again.

   $main::current_db->{Database_type} = $old_db_type;

   print STDERR "Cur db type >" . $main::current_db->{Database_type} .
                "<\n\n\n" if ($main::debug > 0);

}

=head2 del_Jareds_tools

If the 'My Tools' menu currently exists, then destroy it.  This helps
regenerate "fresh" menus, as required.

=cut

sub del_Jareds_tools {

   # If the 'My Tools' menu currently exists, then
   # destroy it

   my ($but_ref) = @_;
   if(defined($$but_ref)){
      $$but_ref->destroy;
      $$but_ref = undef;
   }
}

=head2 iconize

Take a Window handle, and tie an icon to it.

=cut

sub iconize {

   # Take a Window handle, and tie an icon
   # to it.

   my($w) = @_;
   my $icon_img = $w->Photo('-file' => "$FindBin::RealBin/img/orac.gif");
   $w->Icon('-image' => $icon_img);
}

=head2 pick_up_defaults

This allows user to select main database type.  Also allows selection
of pre-defined background colour.  Assign some pre-defined values in case
the config file not yet available.

=cut

sub pick_up_defaults {

   # This allows user to select main database type.
   # Also allows selection of pre-defined background
   # colour.  Assign some pre-defined values in case
   # the config file not yet available.

   if ($ENV{ORAC_HOME})
   {
	 $main::orac_home = $ENV{ORAC_HOME};
   }
   elsif ($^O =~ /MSWin/ && $ENV{USERPROFILE})
   {
	 $main::orac_home = $ENV{USERPROFILE} . "/orac";
   }
   elsif ($ENV{HOME})
   {
	 $main::orac_home = $ENV{HOME} . "/.orac";
   }

   my $dirname = File::Basename::dirname($main::orac_home);
   my $basename = File::Basename::basename($main::orac_home);
   $main::orac_home = File::Spec->catfile($dirname, $basename);

   die "Please set environment variable ORAC_HOME to a " .
       "directory for user customization and rerun.\n"
      unless $main::orac_home;

   unless (-d $main::orac_home)
   {
	 die "Unable to create ORAC_HOME: $!\n"
            unless mkdir($main::orac_home, 0700);

         my $sql = File::Spec->catfile($main::orac_home, 'sql');

	 die "Unable to create ORAC_HOME/sql: $!\n"
            unless mkdir( $sql, 0700);

         my $tools = File::Spec->catfile($sql, 'tools');

	 die "Unable to create ORAC_HOME/sql/tools: $!\n"
            unless mkdir( $tools, 0700);
   }

   my $what_db = File::Spec->catfile($main::orac_home, 'what_db.txt');

   my $i = 0;
   my $file = $what_db;

   if(-e $file){
      open(DB_FIL,$file);
      while(<DB_FIL>){
         chomp;
         my @hold = split(/\^/, $_);
         $main::orac_curr_db_typ = $hold[0];
         $main::sys_user = $hold[1];
         $main::bc = $hold[2];
         $main::v_db = $hold[3];
         $main::fc = $hold[4];
         $main::ec = $hold[5];
         $i = 1;
      }
      close(DB_FIL);
   }

   if ((!defined($main::bc))||(length($main::bc) < 1))
      {$main::bc = $main::lg{def_backgr_col}}
   if ((!defined($main::fc))||(length($main::fc) < 1))
      {$main::fc = $main::lg{def_fg_col}}
   if ((!defined($main::ec))||(length($main::ec) < 1))
      {$main::ec = $main::lg{def_fill_fld_col}}

   # Now deal with fonts

   my $what_font = File::Spec->catfile($main::orac_home, 'what_font.txt');
   $file = $what_font;

   if(-e $file){
      open(FONT_FIL,$file);

      while(<FONT_FIL>){
         my @hold = split(/\^/, $_);
         $main::font{family} = $hold[0];
         $main::font{size} = $hold[1];
         $main::font{weight} = $hold[2];
         $main::font{slant} = $hold[3];
      }
      close(FONT_FIL);
   }
   else
   {
      # No font has previously been saved, therefore,
      # now is the time and the place.

      my $font;

      my $font_command =
         ' $font = $main::v_text->fontCreate(-family => \'courier\', ' .
                                           ' -size => 10, ' .
                                           ' -weight => \'normal\', ' .
                                           ' -slant => \'roman\' ' .
                                           '); ';

      eval $font_command;

      if ($@) {

         # Just gotta take the default

         $font = $main::v_text->fontCreate();

      }

      $main::font{family} = $main::v_text->fontConfigure($font, -family);
      $main::font{size} = $main::v_text->fontConfigure($font, -size);
      $main::font{weight} = $main::v_text->fontConfigure($font, -weight);
      $main::font{slant} = $main::v_text->fontConfigure($font, -slant);
   }
   $main::font{name} =
      $main::v_text->fontCreate( -family => $main::font{family},
                                 -size => $main::font{size},
                                 -weight => $main::font{weight},
                                 -slant => $main::font{slant},
                               );


   # Now deal with printing options

   my $what_print = File::Spec->catfile($main::orac_home, 'what_print.txt');
   $file = $what_print;

   if(-e $file){
      open(PRINT_FIL,$file);

      while(<PRINT_FIL>){
         my @hold = split(/\^/, $_);
         $main::print{rotate} = $hold[0];
         $main::print{paper} = $hold[1];
         $main::print{command} = $hold[2];
      }
      close(PRINT_FIL);
   }
   else
   {
      # No printing options have previously been saved, therefore,
      # now is the time and the place.

      $main::print{rotate} = 0;
      $main::print{paper} = 'A4';
      $main::print{command} = '';
   }

   return;

}

=head1 BEGIN

Special functionality to isolate acceptable errors, depending
on database type, and place other errors into readable GUI
windows for ease of debugging/reading by users.

=cut

BEGIN {

   # If any non-fatal warnings/errors are detected by
   # Orac, this should ensure they come up in "look-and-feel"
   # window.  Particularly useful for reporting back
   # database error messages.

   # We have one program flag for suppressing error messages
   # on database connection, until the last variation
   # on database connection is attempted.

   $SIG{__WARN__} = sub{

      my $warning = $_[0];

      if ( (!defined($main::conn_comm_flag)) ||
           ($main::conn_comm_flag == 0)
         )
      {
         chop $warning;

         my $loc_comp_str = 'Object does not have any ' .
                            'declarative constraints.';

	 if (defined($main::orac_curr_db_typ))
         {
	    if (($main::orac_curr_db_typ eq 'Sybase') &&
                (($warning eq $loc_comp_str) ||
                 ($warning eq ' ')
                )
               )
            {
               return;
            }
         }
	 if (defined $main::mw)
         {
	    main::mes($main::mw,$warning);
	 }
         else
         {
            print STDOUT join("\n",@_),"n";
         }

	 # Handle print command in SQL
         # (sybase print sends output to message handler)

      }
      elsif ($main::conn_comm_flag == 999)
      {
         $main::store_msgs .= $warning;
      }
   };
}

sub call_shell {

   main::bz();
              # Only define the shell instance if undefined.
   $main::shell = orac_Shell->new( $main::mw, $main::dbh )
              unless defined $main::shell;
   $main::shell->dbish_open();
   main::ubz()

}

sub font_button_message {

   my ($balloon_ref, $font_button_ref) = @_;

   my $font  = $main::font{family} .
               '-' .
               $main::font{size} .
               '-' .
               $main::font{weight} .
               '-' .
               $main::font{slant};

   my $message = $main::lg{font_sel} .
                 ' (' .
                 $font .
                 ')';

   $$balloon_ref->attach($$font_button_ref, -msg => $message );
   return $font;
}

sub splash_screen {

   my($please_destroy_flag) = @_;

   $main::splash_screen = MainWindow->new();
   $main::splash_screen->overrideredirect(1);

   my $splash_image = 
      $main::splash_screen->Photo(-file=>"$FindBin::RealBin/img/splash.gif");

   Tk::wm($main::splash_screen, "geometry",
          "+" . 
          int(($main::splash_screen->screenwidth)/2 - 
              ($splash_image->width)/2) .
          "+" . 
          int(($main::splash_screen->screenheight)/2 - 
              ($splash_image->height)/2));
   
   my $splash_label = 
      $main::splash_screen->Button( -image => $splash_image,
                                  )->pack(-fill=>'both', -expand => 1);
   Tk::update($main::splash_screen);

   if($please_destroy_flag){
      sleep 5;
      main::destroy_splash();
   }
}

sub destroy_splash {

   if ($main::splash_screen) {
      $main::splash_screen->destroy()
   }

}

sub colour_menu {

   my($file_mb_ref, $text, $col_ref) = @_;

   $$file_mb_ref->cascade(-label=>$text);

   my $col_men = $$file_mb_ref->cget(-menu);
   my $colour_cols = $col_men->Menu;

   # Now pick up all the lovely colours and build a radiobutton
   
   $$file_mb_ref->entryconfigure($text,-menu=>$colour_cols);
   open(COLOUR_FILE, "$FindBin::RealBin/txt/colours.txt");
   while(<COLOUR_FILE>){
      chomp;
      eval {
         $colour_cols->radiobutton(
            -label=>$_,-background=>$_,
            -command=>[ sub {main::bc_upd()}],
            -variable=>$col_ref,
            -value=>$_);
      };
   }
   close(COLOUR_FILE);
}

# EOF
