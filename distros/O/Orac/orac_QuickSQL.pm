package orac_QuickSQL;
use strict;

my $quick_sql_txt;

sub quick_sql {
   package main;

   $main::swc{quick_sql} = MainWindow->new();
   $main::swc{quick_sql}->title($main::lg{quick_sql});

   my(@exp_lay) = qw/-side top -padx 5 -expand no -fill both/;

   my $dmb = $main::swc{quick_sql}->Frame->pack(@exp_lay);

   my $orac_li = $main::swc{quick_sql}->Photo(-file=>'img/orac.gif');

   $dmb->Label(  -image=>$orac_li,
                 -borderwidth=>2,
                 -relief=>'flat'

              )->pack(  -side=>'left',
                        -anchor=>'w');

   # Add buttons.  

   $dmb->Button( -text=>$main::lg{execute_sql},
                 -command=>sub{ orac_QuickSQL::execute_sql() }
               )->pack(side=>'left');

   $dmb->Button(-text=>$main::lg{clear},

                -command=>sub{
                      $main::swc{quick_sql}->Busy;
                      $quick_sql_txt->delete('1.0','end');
                      $main::swc{quick_sql}->Unbusy;
                             }

               )->pack(side=>'left');

   $dmb->Button(
      -text=>$main::lg{exit},

      -command=> sub{

                  $main::swc{quick_sql}->withdraw();
                  $main::sub_win_but_hand{quick_sql}->configure(-state=>'active');

                    } 

               )->pack(-side=>'left');


   (@exp_lay) = qw/-side top -padx 5 -expand yes -fill both/;

   my $top_slice = $main::swc{quick_sql}->Frame->pack(@exp_lay);

   my $quick_sql_txt_width = 50;
   my $quick_sql_txt_height = 12;

   $main::swc{quick_sql}->{text} = 
      $top_slice->Scrolled('Text',-wrap=>'none',
                           -cursor=>undef,
                           -height=>($quick_sql_txt_height + 8),
                           -width=>($quick_sql_txt_width + 12),
                           -foreground=>$main::fc,
                           -background=>$main::bc
                          );

   $quick_sql_txt = 
      $main::swc{quick_sql}->{text}->Scrolled( 'Text',
                                           -wrap=>'none',
                                           -cursor=>undef,
                                           -height=>$quick_sql_txt_height,
                                           -width=>$quick_sql_txt_width,
                                           -foreground=>$main::fc,
                                           -background=>$main::ec
                                         );

   # A little help:

   $main::swc{quick_sql}->{text}->insert( 'end', 
                                      $main::current_db->gf_str('txt/onthefly_sql.txt') );

   $main::swc{quick_sql}->{text}->windowCreate('end',-window=>$quick_sql_txt);
   $main::swc{quick_sql}->{text}->insert('end', "\n");
   $main::swc{quick_sql}->{text}->pack(-expand=>1,-fil=>'both');

   # Now disable calling button, and iconize window

   $main::sub_win_but_hand{quick_sql}->configure(-state=>'disabled');

   main::iconize( $main::swc{quick_sql} );

   # Disable, to prevent removal of embedded widgets

   $main::swc{quick_sql}->{text}->configure( -state=>'disabled' );

   return;
}
sub execute_sql {

   my $self = shift;

   # Takes the SQL statement directly from the screen
   # and then pumps out report
   # Using KevinB's stuff, go!

   $main::current_db->f_clr($main::v_clr);
   $main::current_db->show_sql ( $quick_sql_txt->get("1.0", "end"),
                                 $main::lg{quick_sql}
                               );
}
1;
