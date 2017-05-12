package orac_Monitor;

=head1 NAME

orac_Monitor.pm - Orac Font Selector

=head1 DESCRIPTION

This code is provides a way of continuously monitoring
selected databases.

It has been heavily inspired by the work of Sean Hull, on the
Karma web tool program.  You can find Sean at <shull@pobox.com>, and the
Karma tool at:

=> http://www.panix.com/~shull/karma/index.html

=head1 PUBLIC METHODS

&new()
&orac_monitor()

=cut

use strict;
use Tk::Tiler;
use Tk::LabFrame;
use Tk::MonitorBar;
use Tk::Scale;
use File::Basename;

@orac_Monitor::ISA = qw{orac_Base};

# set this to how many seconds you want between updates to the progress bar
my $countdown_amount = 1.0;

use vars qw();

=head2 new

Sets up the blessed object. Sets the window reference and screen title.
Picks up all the systems fonts.

=cut

sub new
{
   my $proto = shift;
   my $class = ref($proto) || $proto;

   my ($l_window, $l_text, $l_screen_title) = @_;

   my $self  = orac_Base->new("Monitor", $l_window, $l_text, $l_screen_title);

   bless($self, $class);

   return $self;
}

=head2 orac_monitor

Interrogates the user for the required database information.
Once it has the information, the user can start/stop a screen
which will monitor the series of databases for you.

=cut

sub orac_monitor {

   my $self = shift;

   # Set up window, menus etc

   $self->{window} = $self->{Main_window}->Toplevel();
   $self->{window}->title( $self->{Version} );

   my(@monitorsel_lay) = qw/-side top -expand no -fill both/;
   my $monitorsel_menu = $self->{window}->Frame->pack(@monitorsel_lay);

   # Establish we have a directory for
   # storing all our stuff in locally

   my $dir = File::Spec->catfile($main::orac_home, 'monitor');

   mkdir ($dir, 0755) unless -d $dir;
   my $monitor_file = File::Spec->catfile($dir, 'monitor.txt');

   my $mon_img;
   $self->get_img( \$self->{window}, \$mon_img, 'monitor' );

   $monitorsel_menu->Label(-image=>$mon_img,
                           -anchor=>'w',
                           -relief=>'flat',
                           -justify=>'left',
                          )->pack(-expand=>'no',
                                  -side=>'left',
                                 );

   $self->top_right_ball_message( \$monitorsel_menu,
                                  \$monitor_file,
                                  \$self->{window}
                                );

   # Now start the work

   my @values;
   my @dbs;

   my $balloon;
   $self->balloon_bar(\$balloon, \$self->{window}, 80, );

   my $f0 = $self->{window}->Frame(-relief=>'ridge',
                                   -bd=>2,
                                  )->pack( -side=>'top',
                                           -expand => 'n',
                                           -fill => 'both'
                                         );

   my $add_but = $f0->Button;
   my $upd_but = $f0->Button;
   my $del_but = $f0->Button;
   my $title_but = $f0->Button;
   my $label_but = $f0->Button;
   my $ball_but = $f0->Button;
   my $help_but = $f0->Button;

   $add_but->configure(-text => 'Add');
   $add_but->configure(-command => sub {

      $self->upd_monitor( 'Added',
                        $monitor_file,
                        \@values,
                      );
                                       }

                      );

   $upd_but->configure(-text => 'Update');
   $upd_but->configure(-command => sub {

      $self->upd_monitor( 'Updated',
                        $monitor_file,
                        \@values,
                      );
                                       }

                      );

   $del_but->configure(-text => 'Delete');
   $del_but->configure(-command => sub {

      $self->upd_monitor( 'Deleted',
                        $monitor_file,
                        \@values,
                      );
                                       }

                      );

   # Do we want a Database title?
   # Y is for labels, N is for no labels

   $self->{f_title}->{value} = 'Y';

   $self->get_img( \$self->{window}, \$self->{f_title}->{Y}, 'title' );
   $self->get_img( \$self->{window}, \$self->{f_title}->{N}, 'notitle' );

   $title_but->configure(
      -image => $self->{f_title}->{ $self->{f_title}->{value} },
                        );

   $title_but->configure(-command => sub {

      if ( $self->{f_title}->{value} eq 'Y')
      {
         $self->{f_title}->{value} = 'N';
         $balloon->attach(
            $title_but,
            -msg => 'No Database Titles on Flags - Press for Titles');
      }
      else
      {
         $self->{f_title}->{value} = 'Y';
         $balloon->attach(
            $title_but,
            -msg => 'Database Titles on Flags - Press for No Titles');
      }
      $title_but->configure(
         -image => $self->{f_title}->{ $self->{f_title}->{value} },
                           );

                                           }
                        );

   $balloon->attach(
      $title_but,
      -msg => 'Database Titles on Flags - Press for No Titles');

   # Do we want Labels?
   # Y is for labels, N is for no labels

   $self->{labs_req}->{value} = 'Y';

   $self->get_img( \$self->{window}, \$self->{labs_req}->{Y}, 'label');
   $self->get_img( \$self->{window}, \$self->{labs_req}->{N}, 'auto');

   $label_but->configure(
      -image => $self->{labs_req}->{ $self->{labs_req}->{value} },
                        );

   $label_but->configure(-command => sub {

      if ( $self->{labs_req}->{value} eq 'Y')
      {
         $self->{labs_req}->{value} = 'N';
         $balloon->attach(
            $label_but,
            -msg => 'No Labels on Monitor Flags - Press for Labels');
      }
      else
      {
         $self->{labs_req}->{value} = 'Y';
         $balloon->attach(
            $label_but,
            -msg => 'Labels on Monitor Flags - Press for No Labels');
      }
      $label_but->configure(
         -image => $self->{labs_req}->{ $self->{labs_req}->{value} },
                           );

                                           }
                        );

   $balloon->attach(
      $label_but,
      -msg => 'Labels on Monitor Flags - Press for No Labels');

   # Do we want small Balls?
   # (no...missus)
   # Y is for big balls, N is for small balls

   $self->{ball_req}->{value} = 'Y';

   $self->get_img( \$self->{window}, \$self->{ball_req}->{Y}, 'white_ball');
   $self->get_img( \$self->{window}, \$self->{ball_req}->{N}, 's_white_ball');

   $ball_but->configure(
      -image => $self->{ball_req}->{ $self->{ball_req}->{value} },
                        );

   $ball_but->configure(-command => sub {

      if ( $self->{ball_req}->{value} eq 'Y')
      {
         $self->{ball_req}->{value} = 'N';
         $balloon->attach(
            $ball_but,
            -msg => 'Small Flags - Press for Large Flags');
      }
      else
      {
         $self->{ball_req}->{value} = 'Y';
         $balloon->attach(
            $ball_but,
            -msg => 'Large Flags - Press for Small Flags');
      }
      $ball_but->configure(
         -image => $self->{ball_req}->{ $self->{ball_req}->{value} },
                           );

                                           }
                        );

   $balloon->attach(
      $ball_but,
      -msg => 'Large Flags - Press for Small Flags');

   # Help Button

   my $help_img;
   $self->get_img( \$self->{window}, \$help_img, 'help');

   $help_but->configure( -image => $help_img,
                         -command => sub {

     $self->see_sql($self->{window},
                    $self->gf_str("$FindBin::RealBin/help/DatabaseMonitor.txt"),
                    $main::lg{help},
                   );

                                         },
                       );

   $balloon->attach($help_but, -msg => $main::lg{help} );

   # Now arrange the Buttons

   $add_but->pack(-side => 'left', -fill => 'both');
   $upd_but->pack(-side => 'left', -fill => 'both');
   $del_but->pack(-side => 'left', -fill => 'both');
   $title_but->pack(-side => 'left', -fill => 'both');
   $label_but->pack(-side => 'left', -fill => 'both');
   $ball_but->pack(-side => 'left', -fill => 'both');
   $help_but->pack(-side => 'left', -fill => 'both');

   # Right hand side of screen

   $self->orac_image_label(\$f0, \$self->{window}, );
   my $b_ref = $self->window_exit_button(\$f0, \$self->{window}, 1, \$balloon,);

   my $img;
   $self->get_img( \$self->{window}, \$img, 'right');

   my $run_but = $f0->Button(-image => $img,
                             -command => sub {$self->run_monitor($monitor_file)}

                            )->pack(-side => 'right',);

   $balloon->attach($run_but, -msg => 'Run the Database Monitor');

   # Now we can do the original frame work

   # Now build up the screen

   my $f1 = $self->{window}->Frame;
   $f1->pack(-side=>'top', -expand => 'y', -fill => 'both');

   my @labels;
   my @entrys;
   my @txt_labs;

   $txt_labs[0] = 'Database Connection String';
   $txt_labs[1] = 'User';
   $txt_labs[2] = 'Password';

   # Go Grid crazy!  Assign the widgets to starting
   # racetrack postitions. Haven't I seen this somewhere
   # before?  :)

   my @widths = ( 20, 20, 20, );

   $self->fill_options($monitor_file,\@dbs,);

   my @options = (\@dbs,);

   foreach my $i (0..2)
   {
      $labels[$i] = $f1->Label(-text=>$txt_labs[$i] . ':',
                               -anchor=>'e',
                               -justify=>'right');

      if ($i == 0)
      {
         $entrys[$i] = $f1->BrowseEntry(-variable=>\$values[$i],
                                        -foreground=>$main::fc,
                                        -background=>$main::ec,
                                        -width=>$widths[$i],
                                        -choices=>$options[$i],
                                    );
      }
      else
      {
         $entrys[$i] = $f1->Entry(-textvariable=>\$values[$i],
                                  -foreground=>$main::fc,
                                  -background=>$main::ec,
                                  -width=>$widths[$i],
                                 );
      }
      if ($i == 2)
      {
         $entrys[$i]->configure(-show => '*');
      }

      Tk::grid(  $labels[$i],
                 -row=>$i,
                 -column=>0,
                 -sticky=>'e',
                 -padx=>10,
                 -pady=>10
              );

      Tk::grid(  $entrys[$i],
                 -row=>$i,
                 -column=>1,
                 -sticky=>'w',
                 -padx=>10,
                 -pady=>10
              );
   }

   $f1->gridRowconfigure(1,-weight=>1);
   $entrys[0]->focusForce;

   main::iconize( $self->{window} );
}

sub upd_monitor {

   my $self = shift;

   # Primitive database engine?
   # Look no further.  It don't get much more primitive
   # than this :-)

   my ($switch, $file, $val_ref) = @_;

   my @vals = @$val_ref;

   # Put some basic validation in place.
   # This can be expanded later

   for my $i (0..2)
   {
      if (!defined($vals[$i]) or (length($vals[$i]) < 1))
      {
         if ($i == 0)
         {
            main::mes($self->{window},
                      'Database Connection String undefined.');
            return;
         }
         else
         {
            $vals[$i] = '';
         }
      }
   }

   if (($switch eq 'Updated') ||
       ($switch eq 'Added') ||
       ($switch eq 'Deleted'))
   {
      my @hold;

      my @lines;
      my $line_counter = 0;

      if(open(KARMA_FIL,"${file}"))
      {
         while(<KARMA_FIL>)
         {
            @hold = split(/\^/, $_);

            unless ($hold[0] eq $vals[0])
            {
               $lines[$line_counter] = $_;
               $line_counter++;
            }
         }
         close(KARMA_FIL);
      }

      open(KARMA_FIL,">${file}");

      foreach my $line (@lines)
      {
         print KARMA_FIL $line;
      }
      close(KARMA_FIL);
   }

   if (($switch eq 'Updated') || ($switch eq 'Added'))
   {
      open(KARMA_FIL,">>${file}");

      print KARMA_FIL $vals[0] .
                      '^' .
                      $vals[1] .
                      '^' .
                      $vals[2] .
                      '^' .
                      "\n";

      close(KARMA_FIL);
   }

   main::sort_this_file(${file}, "${file}.old");

   main::mes($self->{window}, $vals[1] . '/' . $vals[2] . '@' . $vals[0] .
                              " " . $switch
            );

   return;
}

sub run_monitor {

   my $self = shift;

   my ($file,

      ) = @_;

   unless (open(KARMA_FILE, "$file"))
   {
      main::mes($self->{window}, "No databases to monitor.");
      return;
   }

   my @hold;
   my $i_counter = 0;

   my @db;
   my @user;
   my @password;

   while(<KARMA_FILE>)
   {
      @hold = split(/\^/, $_);

      $db[$i_counter] = $hold[0];
      $user[$i_counter] = $hold[1];
      $password[$i_counter] = $hold[2];
      $i_counter++;
   }
   close(KARMA_FILE);

   if ($i_counter == 0)
   {
      main::mes($self->{window}, "No databases defined");
      return;
   }
   $i_counter--;

   # Now, let's get going

   $self->{mon_win} = $self->{Main_window}->Toplevel();
   $self->{mon_win}->title( 'Database Monitor' );

   # Make sure any loose connections are tidied up

   $self->{mon_win}->bind( q{<Destroy>},
                           sub {

         foreach my $db ( keys(%{$self->{nm}} ))
         {
            if (defined ( $self->{nm}->{$db}->{connect} ))
            {
               $self->{nm}->{$db}->{connect}->disconnect;
               $self->{nm}->{$db}->{connect} = undef;
            }
         }
                               },
                         );

   my $stopper;
   my $exit_but;

   my(@lay) = qw/-side top -expand no -fill both/;
   my $mon_menu = $self->{mon_win}->Frame->pack(@lay);

   # Balls - large or small?
   # (Frankie Howard roolz Ok)

   my $ball_prefix;
   if ($self->{ball_req}->{value} eq 'Y')
   {
      $ball_prefix = '';
   }
   elsif ($self->{ball_req}->{value} eq 'N')
   {
      $ball_prefix = 's_';
   }

   my %b_hld = ( 'white' => 'white_ball', 'green' => 'grn_ball',
                 'red' => 'red_ball', 'yellow' => 'yel_ball' );

   foreach my $b_key ( keys(%b_hld)){
      $self->get_img( \$self->{mon_win},
                      \$self->{ball}->{$b_key},
                      $b_hld{$b_key}
                    );
   }

   # Get the filename of the Config file

   my $monitor_config =
      sprintf(  "$FindBin::RealBin/monitor/%s/config.txt",
                $main::orac_curr_db_typ,
             );

   $self->{monitor_dir} = File::Basename::dirname($monitor_config);
   my $basename = File::Basename::basename($monitor_config);

   $monitor_config = File::Spec->catfile($self->{monitor_dir}, $basename);

   my $mon_text = $monitor_config;

   my $mon_img;
   $self->get_img( \$self->{mon_win}, \$mon_img, 'monitor');

   $mon_menu->Label(-image=>$mon_img,
                    -anchor=>'w',
                    -relief=>'flat',
                    -justify=>'left',
                   )->pack(-expand=>'no',
                           -side=>'left',
                          );
   $self->top_right_ball_message( \$mon_menu,
                                  \$mon_text,
                                  \$self->{window}
                                );

   # Now start the work

   my $balloon;
   $self->balloon_bar(\$balloon, \$self->{mon_win}, 60, );

   my $f0 = $self->{mon_win}->Frame(-relief=>'ridge',
                                    -bd=>2,
                                   )->pack( -side=>'top',
                                            -expand => 'n',
                                            -fill => 'both'
                                          );

   my $f1 = $self->{mon_win}->Frame(
                                   )->pack( -side=>'top',
                                            -expand => 'y',
                                            -fill => 'both'
                                          );

   my $f2 = $self->{mon_win}->Frame(
                                   )->pack( -side=>'top',
                                            -expand => 'n',
                                            -fill => 'both',
                                            -before => $f1,
                                          );

   my $prog_bar;
   my $countdown = 0;

   my $start_but = $f0->Button;
   my $stop_but = $f0->Button;

   my $time_delay;
   my $b_time_delay;

   my $img;
   $self->get_img( \$self->{mon_win}, \$img, 'right');

   $start_but->configure(-image => $img, );
   $start_but->configure(-command => sub {

             $self->run_the_startup( \$countdown,
                                    \$mon_text,
                                    \$stopper,
                                    \$self->{mon_win},
                                    \$prog_bar,
                                    \$time_delay,
                                    \$b_time_delay,
                                    \$exit_but,
                                    \$start_but,
                                    \$stop_but,
                                  );

                                         }
                        );

   $start_but->pack(-side => 'left', -padx=>2, -fill => 'both');

   $balloon->attach(
      $start_but,
      -msg => 'Start Monitor',
                   );

   $self->get_img( \$self->{mon_win}, \$img, 'stop');

   $stop_but->configure(-image => $img, );
   $stop_but->configure(-command => sub {
                                                $stopper = 0;
                                                $mon_text = $monitor_config;
                                                $countdown = 0;
                                        }

                      );

   $stop_but->pack(-side => 'left', -padx=>2, -fill => 'both');

   $balloon->attach(
      $stop_but,
      -msg => 'Stop Monitor',
                   );

   $stop_but->configure(-state => 'disabled');

   # Set a default time delay to 60 seconds
   $time_delay = 60;

   my @time_delays = (15, 30, 45, 60, 120, 300, 600, 3600, 86400);

   $b_time_delay = $f0->BrowseEntry(-variable=>\$time_delay,
                                    -foreground=>$main::fc,
                                    -background=>$main::ec,
                                    -width=>5,
                                    -choices=>\@time_delays,
                                   );

   $b_time_delay->pack(-side => 'left');

   $balloon->attach(

      $b_time_delay,
      -msg => 'Time Delay Poll Loopback between Monitor Events (seconds)',

                   );

   $self->orac_image_label(\$f0, \$self->{mon_win}, );
   $self->get_img( \$self->{mon_win}, \$img, 'exit');

   $exit_but = $f0->Button(
                          -image=>$img,
                          -command=>

                             sub{
                                   $stopper = 0;
                                   $mon_text = '';
                                   $countdown = 0;

                                   $self->{mon_win}->destroy();
                                }

                          )->pack(-side=>'right');

   $balloon->attach(
      $exit_but,
      -msg => 'Exit from Monitor Run Screen',
                   );

   # Now we can do the original frame work

   my $tiler = $f1->Scrolled(  'Tiler',
                            );
   my $label;

   my $count_db = @db;

   for my $i (0..($count_db - 1))
   {
      my @top_bits = [];
      my @bot_bits = [];
      my $bits_counter = 0;

      # Create the Label Frame.  Start the $self variable
      # with a new key, 'nm' (Database Names), in order
      # to isolate it from all other $self keys (like 'mon_win').

      if ($self->{f_title}->{value} eq 'Y')
      {
         $tiler->Manage  ( $self->{nm}->{$db[$i]}->{labf} =
                              $tiler->LabFrame(
                                                -borderwidth=>2,
                                                -labelside=>'acrosstop',
                                                -label=>$db[$i],
                                              )
                         );

      }
      else
      {
         $tiler->Manage  ( $self->{nm}->{$db[$i]}->{labf} =
                              $tiler->Label(
                                             -relief=>'groove',
                                             -borderwidth=>2,
                                           )
                         );

      }

      # Set the passwords and the users

      $self->{nm}->{$db[$i]}->{user} = $user[$i];
      $self->{nm}->{$db[$i]}->{password} = $password[$i];

      # Now set the labels and stuff

      if ($self->{labs_req}->{value} eq 'Y')
      {
         $top_bits[$bits_counter] =
            $self->{nm}->{$db[$i]}->{labf}->Label( -text=> "up",
                                                 );
      }

      # Drop another key down, 'flag', to isolate the Labframe key,
      # 'labf', from the bits of the Labframe we need to monitor
      # and update.

      $bot_bits[$bits_counter] =
      $self->{nm}->{$db[$i]}->{labf}->{flag}->{up} =
         $self->{nm}->{$db[$i]}->{labf}->Button(
                                         -cursor=>'hand2',
                                         -image=> $self->{ball}->{white},
                                         -padx=>0,
                                         -pady=>0,
                                                        );
      $balloon->attach(
         $bot_bits[$bits_counter],
         -msg => $db[$i] . ' ' . 'up' . ' ' . 'flag',
                      );

      $bits_counter++;

      my $loc_db = $db[$i];

      # Configure the Button, to return various information

      $self->{nm}->{$loc_db}->{labf}->{flag}->{up}->{errstr} =
         $loc_db . ' ' . 'up' . ' ' . 'flag' . "\n\n" .
         'Last Possible Error? : ' .
         '<No Error Yet Found>';

      $self->{nm}->{$loc_db}->{labf}->{flag}->{up}->configure(

               -command => sub {

             $self->see_sql(

               $self->{mon_win},
               $self->{nm}->{$loc_db}->{labf}->{flag}->{up}->{errstr},
               $loc_db . ': up',

                           );
                               },
                                                                 );

      my @k_hld;

      if (open(KARMA_FILE, "$monitor_config"))
      {
         while(<KARMA_FILE>)
         {
            @k_hld = split(/\^/, $_);

            if ($self->{labs_req}->{value} eq 'Y')
            {
               $top_bits[$bits_counter] =
                  $self->{nm}->{$db[$i]}->{labf}->Label(
                                                   -text=> $k_hld[1],
                                                       );
            }
            $bot_bits[$bits_counter] =
            $self->{nm}->{$db[$i]}->{labf}->{flag}->{$k_hld[0]} =
               $self->{nm}->{$db[$i]}->{labf}->Button(
                                         -cursor=>'hand2',
                                         -image=> $self->{ball}->{white},
                                         -padx=>0,
                                         -pady=>0,
                                                        );

            $balloon->attach(
               $bot_bits[$bits_counter],
               -msg => $db[$i] . ' ' . $k_hld[0] . ' ' . 'flag',
                            );

            $bits_counter++;

            my $db = $db[$i];
            my $key = $k_hld[0];

            # Configure the Button, to return various information

            $self->{nm}->{$db}->{labf}->{flag}->{$key}->configure(

               -state => 'disabled',
               -command => sub {

         my $text =
           $db . ' ' . $key . ' ' . 'flag' . "\n\n" .
           "Red flag given by less than   : " .
           $self->{nm}->{$db}->{labf}->{flag}->{$key}->{redf} .
           "\n" .
           "Yellow flag given by less than: " .
           $self->{nm}->{$db}->{labf}->{flag}->{$key}->{yelf} .
           "\n" .
           "Last value found              : " .
           $self->{nm}->{$db}->{labf}->{flag}->{$key}->{lastval} .
           "\n\n" .
           $self->{nm}->{$db}->{labf}->{flag}->{$key}->{sql_command};

         $self->see_sql(

           $self->{mon_win},
           $text,
           $db . ': ' . $key,

                       );

                               },
                                                                 );

            # Now set red and yellow flags.
            # By God, have you ever seen a longer set of
            # $self keys? :-)

            # 'lastval' initialised to undef, this is the last value
            # that a particular SQL statement finds, against which
            # the warning values are compared

            # 'redf' => Red Flag Severe Warning Value Condition
            # 'yelf' => Yellow Flag Mild Warning Value Condition

            $self->{nm}->{$db[$i]}->{labf}->{flag}->{$k_hld[0]}->{lastval} =
               undef;

            $self->{nm}->{$db[$i]}->{labf}->{flag}->{$k_hld[0]}->{redf} =
               $k_hld[2];

            $self->{nm}->{$db[$i]}->{labf}->{flag}->{$k_hld[0]}->{yelf} =
               $k_hld[3];
         }

         close(KARMA_FILE);
      }
      $bits_counter--;

      my $b_cnt = 0;
      my $row_liner;

      foreach my $all_bit (@bot_bits)
      {
         $row_liner = 0;

         if ($self->{labs_req}->{value} eq 'Y')
         {
            Tk::grid(  $top_bits[$b_cnt],
                       -row=>$row_liner++,
                       -column=>$b_cnt,
                    );
         }

         Tk::grid(  $bot_bits[$b_cnt],
                    -row=>$row_liner,
                    -column=>$b_cnt,
                 );

         $b_cnt++;
      }
      $self->{nm}->{$db[$i]}->{labf}->gridRowconfigure(1,-weight=>1);

   }

   # We need a blank label to make sure the Tiler doesn't
   # get its knickers in a twist

   $tiler->Manage  ( $tiler->Label( -relief=>'flat',
                                  )
                   );

   $tiler->pack(qw/-expand yes -fill both/);

   # Now the MonitorBar Bar

   $countdown = 0;

   $prog_bar = $f2->MonitorBar (

            -borderwidth => 2,
            -relief => 'sunken',
            -width => 100,
            -padx => 2,
            -pady => 2,
            -variable => \$countdown,
            -colors => [ 0 => 'darkblue',
                       ],
            -resolution => 0,
            -blocks => 15,
            -anchor => 'e',
            -from => 0,
            -to => 15,
                                )->pack( -padx => 10,
                                         -pady => 10,
                                         -side => 'top',
                                         -fill => 'both',
                                         -expand => 1
                                       );

   # When the window is destroyed, flush the associated
   # queues.

   $prog_bar->OnDestroy( sub { $prog_bar->{'layout_pending'} = 1; } );

   # Now iconize the slapper, and get moving

   main::iconize( $self->{mon_win} );
   return;
}

sub fill_options {

   my $self = shift;

   my ($file,$dbs_ref,) = @_;

   unless (open(KARMA_FILE, "$file"))
   {
      return;
   }

   splice(@$dbs_ref, 0);

   my @hold;
   my $i_counter = 0;

   while(<KARMA_FILE>)
   {
      @hold = split(/\^/, $_);

      $dbs_ref->[$i_counter] = $hold[0];
      $i_counter++;
   }
   close(KARMA_FILE);

   return;
}

sub run_the_startup {

   my $self = shift;

   my ($countdown_ref,
       $mon_text_ref,
       $stop_ref,
       $win_ref,
       $prog_bar_ref,
       $delay_ref,
       $browse_but_ref,
       $exit_but_ref,
       $start_but_ref,
       $stop_but_ref,

      ) = @_;

   # Get the original top right text.

   my $top_right_txt = $$mon_text_ref;

   # Check the delay is acceptable

   if ($$delay_ref < 15)
   {
      main::mes($self->{mon_win},
                "Time Delay must be at least 15 seconds",
               );
      return;
   }

   # Size up the Progress Bar and shutdown the Browse Button,
   # and the Exit button.  Also flick round the
   # start and stop buttons.

   $$browse_but_ref->configure(-state => 'disabled');
   $$exit_but_ref->configure(-state => 'disabled');
   $$start_but_ref->configure(-state => 'disabled');
   $$stop_but_ref->configure(-state => 'normal');

   $$prog_bar_ref->configure(
      -to => $$delay_ref,
                            );
   $$prog_bar_ref->update;

   # Now, into the main while loop

   $$countdown_ref = $$delay_ref;

   $$mon_text_ref = 'Preparing for Launch...';

   $$stop_ref = 1;

   # Run some checking Baby!

   $self->{mon_win}->Busy(-recurse=>1);

   $self->check_the_monitor;

   $self->{mon_win}->Unbusy;

   while($$stop_ref)
   {
      select(undef, undef, undef, $countdown_amount);
      $$countdown_ref = $$countdown_ref - $countdown_amount;

      my $countdown_bit = sprintf("%5.2f", $$countdown_ref);
      $$mon_text_ref = 'T-minus ' . $countdown_bit . ' (secs)';


      if ( Tk::Exists($$prog_bar_ref) )
      {
         $$prog_bar_ref->update;
      }
      else
      {
         last;
      }

      if (($$stop_ref) && ($$countdown_ref <= 0.05)) # $countdown_amount/2 ?
      {
         $$mon_text_ref = 'Initialising...';

         # Lock out the screen, then Launch, Launch, Launch!!!

         $self->{mon_win}->Busy;
         $self->check_the_monitor;
         $self->{mon_win}->Unbusy;

         if ( Tk::Exists($$prog_bar_ref) )
         {
            $$prog_bar_ref->update();
         }
         else
         {
            last;
         }

         # Reset the countdown

         $$countdown_ref = $$delay_ref;

      }
   }

   $$mon_text_ref = $top_right_txt;
   $$countdown_ref = 0;

   # Heck, these keys are taking over the asylum! :-)

   foreach my $key_db ( keys(%{$self->{nm}} ))
   {
      foreach my $key ( keys(%{$self->{nm}->{$key_db}->{labf}->{flag}} ))
      {
         if ( Tk::Exists( $self->{nm}->{$key_db}->{labf}->{flag}->{$key} ) )
         {
            $self->{nm}->{$key_db}->{labf}->{flag}->{$key}->configure(

                                          -image=> $self->{ball}->{white},

                                                                     );
         }
      }
   }

   # Enable the Browse Button

   if ( Tk::Exists($$browse_but_ref) )
   {
      $$browse_but_ref->configure(-state => 'normal');
   }

   # Enable the Exit Button


   if ( Tk::Exists($$exit_but_ref) )
   {
      $$exit_but_ref->configure(-state => 'normal');
   }

   # Flick round the start and stop buttons.

   if ( Tk::Exists($$stop_but_ref) )
   {
      $$stop_but_ref->configure(-state => 'disabled');
   }

   if ( Tk::Exists($$start_but_ref) )
   {
      $$start_but_ref->configure(-state => 'normal');
   }

   return;
}

sub check_the_monitor {

   my $self = shift;

   foreach my $db ( keys(%{$self->{nm}} ))
   {
      # we actually need to reconnect every time;
      # if we don't how else does this flag get updated?
      # we can force this by disconnecting below.  kevinb

      if (not (defined ( $self->{nm}->{$db}->{connect} )))
      {
         # Unlike main program, to avoid ENV variables
         # interfering with connection, we'll use fully qualified
         # database name.

         # switch off warnings.

         $main::conn_comm_flag = 1;

#print STDERR "check_the_monitor about to get a connection...\n";
         my $data_source_1 = 'dbi:' .
                             $main::orac_curr_db_typ .
                             ':' .
                             $db;

         $self->base_connector(  $db,
                                 $data_source_1,
                                 $self->{nm}->{$db}->{user},
                                 $self->{nm}->{$db}->{password}
                              );

         # Now we go back to normal error reporting

         $main::conn_comm_flag = 0;
      }

      # Now we've attempted, or have a connection,
      # Now we can start assigning ball colours.

      if (not (defined ( $self->{nm}->{$db}->{connect} )))
      {
         # No connection defined, therefore set red for the 'up' flag,
         # and set blank (white) for everything else, as we do
         # not know whether they are good, bad or ugly.

#print STDERR "check_the_monitor going red on $db...\n";
         $self->shutdown_db($db);

      } else {

         # Connection defined, therefore set green.

         $self->{nm}->{$db}->{labf}->{flag}->{up}->configure(
                                             -image=> $self->{ball}->{green}
                                                            );
#print STDERR "check_the_monitor going green on $db...\n";

         # Now run through the rest of the checks required,
         # and set flags accordingly.

         my $ret_value = 0;

         foreach my $key ( keys(%{$self->{nm}->{$db}->{labf}->{flag}} ))
         {
            unless ($key eq 'up')
            {
               $ret_value = $self->refresh_the_monitor( $db, $key, );
            }

            if ($ret_value)
            {
               last;
            }
         }
      }
      if ($self->{Database_type} eq "Informix")
      {
	 # disconnect, this will force us to reconnect next time in, KevinB
	 # required for everyone but Oracle?
	 if (defined ( $self->{nm}->{$db}->{connect} ))
	 {
#print STDERR "check_the_monitor about to disconnect...\n";
	    $self->{nm}->{$db}->{connect}->disconnect;
	    $self->{nm}->{$db}->{connect} = undef;
	 }
      }
   }
   return;
}

sub base_connector {

   my $self = shift;

   my ( $db, $dbi_string, $user, $password) = @_;

   $self->{nm}->{$db}->{connect} =
              DBI->connect($dbi_string, $user, $password);

   if (defined($DBI::errstr)){

      # Wipe out any possible duff value, if we fail to connect

      $self->{nm}->{$db}->{connect} = undef;
   }
   return;
}

sub shutdown_db {

   my $self = shift;
   my ($database) = @_;

   my $colour;

   foreach my $key ( keys(%{$self->{nm}->{$database}->{labf}->{flag}} ))
   {
      if ($key eq 'up') { $colour = 'red' } else { $colour = 'white' }

      $self->{nm}->{$database}->{labf}->{flag}->{$key}->configure(
                                    #-state=> 'disabled',
                                    -image=> $self->{ball}->{$colour},
                                                                 );
      if ($self->{Database_type} eq "Informix")
      {
	 # try to change the text, but doesn't seem to work for me, KevinB
	 if ($self->{labs_req}->{value} eq 'Y')
	 {
	    $self->{nm}->{$database}->{labf}->Label( -text=> ($colour eq "red" ? "down" : "neutral"),
						   );
	 }
      }
   }
   if (defined($self->{nm}->{$database}->{connect}))
   {
      $self->{nm}->{$database}->{connect} = undef;
   }
   return;
}
sub refresh_the_monitor {

   my $self = shift;

   my ( $db, $key, ) = @_;

   my $colour = 'white';
   my $ret_value = 0;

   my $sql_file =
      $self->{nm}->{$db}->{labf}->{flag}->{$key}->{sql_file} =

      File::Spec->catfile(  $self->{monitor_dir}, $key . '.' . 'sql');

   my $sql_command =
      $self->{nm}->{$db}->{labf}->{flag}->{$key}->{sql_command} =
         $self->gf_str($sql_file);

   # Right, we have the particular db, and the particular
   # check we are carrying out.  We also have the connection
   # flag, which may or may not be valid.

   # If any part of this fails, the whole thing is set to 'shutdown'
   # on the screen.

   # Switch off Error reporting.  Check for Sean H, on 
   # the connection handle.  If not there, bail out.

   $main::conn_comm_flag = 1;

   if (not (defined ( $self->{nm}->{$db}->{connect} )))
   { 
      $self->shutdown_db($db);
      $ret_value = 1;
   }
   else
   {
      my $ary_ref =
         $self->{nm}->{$db}->{connect}->selectall_arrayref($sql_command);

      if (defined($DBI::errstr)){
   
         # A problem has occurred.  Therefore, switch the whole thing off.
   
         $self->shutdown_db($db);
         $ret_value = 1;
      }
      else
      {
         # Finally, finally, we have a key value.
         # Compare this to our warning flag values
   
         my $curr_ref = $ary_ref->[0];
   
         my $key_value =
            $self->{nm}->{$db}->{labf}->{flag}->{$key}->{lastval} =
            $curr_ref->[0];
   
         if ($key_value <= $self->{nm}->{$db}->{labf}->{flag}->{$key}->{redf})
         {
            $colour = 'red';
         }
         elsif ($key_value <= 
                   $self->{nm}->{$db}->{labf}->{flag}->{$key}->{yelf})
         {
            $colour = 'yellow';
         }
         else
         {
            $colour = 'green';
         }
   
         $self->{nm}->{$db}->{labf}->{flag}->{$key}->configure(
   
                                              -state=>'normal',
                                              -image=> $self->{ball}->{$colour},
   
                                                              );
         $ret_value = 0;
   
      }
   }

   # Switch normal erroring back on

   $main::conn_comm_flag = 0;

   return $ret_value;
}
1;
