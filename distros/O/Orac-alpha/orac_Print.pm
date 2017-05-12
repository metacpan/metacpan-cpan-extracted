package orac_Print;
use strict;

@orac_Print::ISA = qw{orac_Base};

=head1 NAME

orac_Print.pm - Orac Print Selector

=head1 DESCRIPTION

This code is provides a way of producing PostScript files
for printing purposes.

=head1 PUBLIC METHODS

&new()
&orac_printer()

=cut

=head2 new

Sets up the blessed object. Sets the window reference and screen title.
Gets the text item ready for printing.

=cut

# Some standard paper sizes
#
my @papers = qw( Letter Legal Ledger Tabloid A0 A1 A2 A3 A4 A5 A6 A7 A8
                 A9 B0 B1 B2 B3 B4 B5 B6 B7 B8 B9 Envelope10 EnvelopeC5
                 EnvelopeDL Folio Executive );

# Dimensions of standard papers
#
my %width = (  Letter => 612,     Legal => 612,
               Ledger => 1224,    Tabloid => 792,
               A0 => 2384,        A1 => 1684,
               A2 => 1191,        A3 => 842,
               A4 => 595,         A5 => 420,
               A6 => 297,         A7 => 210,
               A8 => 148,         A9 => 105,
               B0 => 2920,        B1 => 2064,
               B2 => 1460,        B3 => 1032,
               B4 => 729,         B5 => 516,
               B6 => 363,         B7 => 258,
               B8 => 181,         B9 => 127,
               B10 => 91,         Envelope10 => 297,
               EnvelopeC5 => 461, EnvelopeDL => 312,
               Folio => 595,      Executive => 522
            );

my %height = ( Letter => 792,  Legal => 1008,
               Ledger => 792,  Tabloid => 1224,
               A0 => 3370,        A1 => 2384,
               A2 => 1684,        A3 => 1191,
               A4 => 842,         A5 => 595,
               A6 => 420,         A7 => 297,
               A8 => 210,         A9 => 148,
               B0 => 4127,        B1 => 2920,
               B2 => 2064,        B3 => 1460,
               B4 => 1032,        B5 => 729,
               B6 => 516,         B7 => 363,
               B8 => 258,         B9 => 181,
               B10 => 127,        Envelope10 => 684,
               EnvelopeC5 => 648, EnvelopeDL => 624,
               Folio => 935,      Executive => 756
    );

sub new
{
   my $proto = shift;
   my $class = ref($proto) || $proto;

   my ($l_window, $l_text, $l_screen_title) = @_;

   my $self  = orac_Base->new("Print", $l_window, $l_text, $l_screen_title);

   bless($self, $class);

   return $self;
}

=head2 orac_printer

The function called, when in use from the main Orac menu.  Pumps up
the screen, and sets up the required font.

=cut

sub orac_printer {

   my $self = shift;

   # Set up window, menus etc

   $self->{win} = $self->{Main_window}->Toplevel();
   $self->{win}->title( $self->{Version} );

   my(@printsel_lay) = qw/-side top -expand no -fill both/;
   my $printsel_menu = $self->{win}->Frame->pack(@printsel_lay);

   my $dirname = File::Basename::dirname($main::orac_home);
   my $basename = File::Basename::basename($main::orac_home);
   my $pre_filename = File::Spec->catfile($dirname, $basename);
   my $filename = File::Spec->catfile($pre_filename, 'orac.ps');

   $self->top_left_message( \$printsel_menu,
                            'Setup Printer Requirements'
                          );

   $self->top_right_ball_message( \$printsel_menu,
                                  \$filename,
                                  \$self->{win},
                                );

   # Now start the work

   my $balloon;
   $self->balloon_bar(\$balloon, \$self->{win}, 80, );

   my $f0 = $self->{win}->Frame(-relief=>'ridge',
                                   -bd=>2,
                                  )->pack( -side=>'top',
                                           -expand => 'n',
                                           -fill => 'both'
                                         );

   my @values;
   my ($x1, $y1, $x2, $y2);

   # Do the main print button

   my $print_img;
   $self->get_img( \$self->{win}, \$print_img, 'print' );

   my $print_but = $f0->Button;
   $print_but->configure( -image => $print_img );

   # Set up the print command postscript button

   $print_but->configure(-command => sub {

      $self->create_print_file( $x1,
                                $x2,
                                $y1,
                                $y2,
                                $filename,
                              );

      my $d = $self->{win}->DialogBox(-title=>$main::lg{print_sel});

      my $command = $main::print{command} . ' ' . $filename;

      # The dreaded system command

# !!! KEEP OUT !!! RESTRICTED AREA !!! POLICE LINE !!! DO NOT CROSS !!!

#######################################################################
      system($command);                                               #
#######################################################################

# !!! KEEP OUT !!! RESTRICTED AREA !!! POLICE LINE !!! DO NOT CROSS !!!

      $d->Label(

         -text=> 'File sent to Printer using command:' . "\n\n" .
                 $command

                )->pack(-side=>'top');
      $d->Show;

                                         }
                        );

   $print_but->pack(-side => 'left');
   $balloon->attach( $print_but,
                     -msg => 'Print Text - ' .
                             'Requires Valid System Printer Command',
                   );

   if ( (!defined($main::print{command})) ||
        (length($main::print{command}) < 1) )
   {
      $print_but->configure(-state => 'disabled');
   }

   # Do the main PostScript file creation button

   $self->get_img( \$self->{win}, \$print_img, 'ps' );

   my $ps_but = $f0->Button(-image => $print_img,
                            -command => sub {

      $self->create_print_file( $x1,
                                $x2,
                                $y1,
                                $y2,
                                $filename,
                              );

      my $d = $self->{win}->DialogBox(-title=>$main::lg{print_sel});

      $d->Label(-text => "PostScript File created:\n\n" . $filename
               )->pack(-side=>'top');
      $d->Show;
                                             }
                            );

   $ps_but->pack(-side => 'left');
   $balloon->attach($ps_but,
                    -msg => 'Create PostScript File ' .
                            ' - to Print later via System PostScript Tool'
                   );

   if ((!defined($main::print{command})) ||
       (length($main::print{command}) < 1) )
   {
      $print_but->configure(-state => 'disabled');
   }

   # Now paper orientation
   # 0 is portrait, 1 is landscape

   $self->get_img( \$self->{win}, \$self->{rot_img}->{0}, 'portrait');
   $self->get_img( \$self->{win}, \$self->{rot_img}->{1}, 'landscape');

   my $rot_but;
   $rot_but = $f0->Button(
         -image => $self->{rot_img}->{ $main::print{rotate} },
         -command => sub {

      if ($main::print{rotate})
      {
         $main::print{rotate} = 0;
      }
      else
      {
         $main::print{rotate} = 1;
      }
      $rot_but->configure(-image => $self->{rot_img}->{$main::print{rotate}} );

                         }
                         )->pack(-side => 'left');

   $balloon->attach($rot_but, -msg => 'Portrait/Landscape Switch' );

   my $paper_type = $f0->BrowseEntry(-state=>'readonly',
                                     -variable=>\$main::print{paper},
                                     -foreground=>$main::fc,
                                     -background=>$main::ec,
                                     -width=>10,
                                     -choices=>\@papers,

                                    )->pack(-side => 'left');

   $balloon->attach($paper_type, -msg => 'Preferred Printer Paper Size' );

   # Command Type

   my $command_but = $f0->Entry( -textvariable=>\$main::print{command},
                                 -foreground=>$main::fc,
                                 -background=>$main::ec,
                                 -width=>20,
                               );

   # Bind in 'Leave' Event to sort out the print button

   $command_but->bind( q{<Leave>},
                       sub {

      if ((!defined($main::print{command})) ||
          (length($main::print{command}) < 1) )
      {
         $print_but->configure(-state => 'disabled');
      }
      else
      {
         $print_but->configure(-state => 'normal');
      }
                           }
                     );

   $command_but->pack(-side => 'left');
   $balloon->attach($command_but, -msg => 'System Print Command' );

   # Help Button

   $self->get_img( \$self->{win}, \$print_img, 'help' );

   my $help_but = $f0->Button;
   $help_but->configure( -image => $print_img,
                         -command => sub {

      $self->see_sql( $self->{win},
                      $self->gf_str("$FindBin::RealBin/help/PrintSetup.txt"),
                      $main::lg{help},
                    );

                                         },
                       );

   $help_but->pack(-side => 'left');
   $balloon->attach($help_but, -msg => $main::lg{help} );


   # Now the other side of the menu bar

   $self->orac_image_label(\$f0, \$self->{win}, );
   $self->window_exit_button(\$f0, \$self->{win}, 1, \$balloon,);

   # Now we can do the original frame work

   my $f1 = $self->{win}->Frame;
   $f1->pack(-side=>'top', -expand => 'y', -fill => 'both');

   $self->{win}->{text} = $f1->Scrolled(  'Canvas',
                                             -relief=>'sunken',
                                             -bd=>2,
                                             -background=>$main::bc,
                                           );

   # Read the Text widget, and then slap it into the Canvas

   my $print_text = $self->{Text_var}->get( '1.0', 'end' );

   my $text_id = $self->{win}->{text}->createText(
                                           0,
                                           0,
                                           -text=>$print_text,
                                           -font=>$main::font{name},
                                           -anchor=>'se',
                                           -tags=>'orac_text',

                                                 );

   ($x1, $y1, $x2, $y2) = $self->{win}->{text}->bbox("orac_text") ;

   $self->{win}->{text}->configure( -scrollregion=>[ $x1, $y1, $x2, $y2 ],
                                     );

   $self->{win}->{text}->pack(-expand=>'yes',-fill=>'both');
   $self->{win}->{text}->focus($text_id);


   main::iconize( $self->{win} );
}

sub create_print_file {

   my $self = shift;

   my ( $x1,
        $x2,
        $y1,
        $y2,
        $filename,

      ) = @_;

   my $canvas_width = ($x2 - $x1) + 20;
   my $canvas_height = ($y2 - $y1) + 20;

   # Find out the page width/ratio
   # Remember, we could be dependent of the paper orientation

   my $page_ratio = 0.00;

   if (  $main::print{rotate}  )
   {
      $page_ratio = $width{ $main::print{paper} }/
                    $height{ $main::print{paper} } ;
   }
   else
   {
      $page_ratio = $height{ $main::print{paper} }/
                    $width{ $main::print{paper} } ;
   }

   # Find out the canvas width/ratio

   my $canvas_ratio = 0.00;
   $canvas_ratio = $canvas_height / $canvas_width ;

   # For some reason, this postscript function below, is Ok as scaling
   # to width, but rubbish at scaling to height.  Therefore let's keep
   # increasing the width, until the canvas height/width ratio is within
   # page height/width ratio.

   if ($canvas_ratio > $page_ratio)
   {
      while ($canvas_ratio > $page_ratio)
      {
         # Keep increasing the width, until
         # we come within the page ratio

         $canvas_width++;
         $canvas_ratio = $canvas_height / $canvas_width ;
      }
   }

   # By Jupiter, this stuff is tricky

   $self->{win}->{text}->postscript(

         -file       => "$main::orac_home/orac.ps",
         -rotate     => $main::print{rotate},
         -pagewidth  => $width{ $main::print{paper} },
         -pageheight => $height{ $main::print{paper} },
         -pageanchor => 'center',
         -pagex      => (($width{ $main::print{paper} })/2),
         -pagey      => (($height{ $main::print{paper} })/2),
         -x          => $x1,
         -y          => $y1,
         -width      => $canvas_width,
         -height     => $canvas_height,

                                      );

   return;

}

1;
