package orac_Font;
use strict;

@orac_Font::ISA = qw{orac_Base};

=head1 NAME

orac_Font.pm - Orac Font Selector

=head1 DESCRIPTION

This code is provides a way of altering fonts
on the main configurable background widgets.

=head1 PUBLIC METHODS

&new()
&orac_fonter()

=cut

use vars qw( $curr_font @widths
             @fonts @sizes @weights @slants @old_font_bits
           );

=head2 new

Sets up the blessed object. Sets the window reference and screen title.
Picks up all the systems fonts.

=cut

sub new
{
   my $proto = shift;
   my $class = ref($proto) || $proto;

   my ($l_window, $l_text, $l_screen_title) = @_;

   my $self  = orac_Base->new("Font", $l_window, $l_text, $l_screen_title);

   bless($self, $class);

   # Pick up all the systems fonts, and other stuff.

   my @unsort_fonts = $self->{Text_var}->fontFamilies();
   @fonts = sort @unsort_fonts;

   my $width = 0;
   foreach my $font (@fonts)
   {
      if (length($font) > $width)
      {
         $width = length($font);
      }
   }

   @sizes = (8, 10, 12, 14, 16, 18, 20, 22, 24, );
   @weights = ('normal','bold');
   @slants = ('roman','italic');
   @widths = ($width, 2, 6, 6, );

   return $self;
}

=head2 orac_fonter

The function called, when in use from the main Orac menu.  Pumps up
the screen, and sets up the required font.

=cut

sub orac_fonter {

   my $self = shift;

   my ($balloon_ref, $font_button_ref) = @_;

   # Set up window, menus etc

   $self->{window} = $self->{Main_window}->Toplevel();
   $self->{window}->title( $self->{Version} );

   my(@fontsel_lay) = qw/-side top -expand no -fill both/;
   my $fontsel_menu = $self->{window}->Frame->pack(@fontsel_lay);

   my @font_names = $self->{Text_var}->fontNames();

   $curr_font =
      main::font_button_message ($balloon_ref, $font_button_ref, );

   $self->top_left_message( \$fontsel_menu, $main::lg{font_message } );
   $self->top_right_ball_message( \$fontsel_menu,
                                  \$curr_font,
                                  \$self->{window}
                                );

   # Now start the work

   my $balloon;
   $self->balloon_bar(\$balloon, \$self->{window}, 60, );

   my $f0 = $self->{window}->Frame(-relief=>'ridge',
                                   -bd=>2,
                                  )->pack( -side=>'top',
                                           -expand => 'n',
                                           -fill => 'both'
                                         );

   my @values;

   my $app_but = $f0->Button(-text => $main::lg{apply},
                              -command => sub {
                                 $self->apply_font( \@values,
                                                    $balloon_ref,
                                                    $font_button_ref
                                                  )
                                              }
                            )->pack(-side => 'left', -padx=>2, -fill => 'both');

   $balloon->attach($app_but, -msg => $main::lg{font_warning});

   $self->orac_image_label(\$f0, \$self->{window}, );
   $self->window_exit_button(\$f0, \$self->{window}, 1, \$balloon,);

   # Now we can do the original frame work

   my $f1 = $self->{window}->Frame;
   $f1->pack(-side=>'top', -expand => 'y', -fill => 'both');

   my @labels;
   my @entrys;
   my @txt_labs;

   $txt_labs[0] = 'Font';
   $txt_labs[1] = 'Size';
   $txt_labs[2] = 'Weight';
   $txt_labs[3] = 'Slant';

   $values[0] = $main::font{family};
   $values[1] = $main::font{size};
   $values[2] = $main::font{weight};
   $values[3] = $main::font{slant};

   @old_font_bits = @values;

   my @options = (\@fonts, \@sizes, \@weights, \@slants);

   # Go Grid crazy!  Assign the widgets to starting
   # racetrack postitions. Haven't I seen this somewhere
   # before?  :)


   foreach my $i (0..3)
   {
      $labels[$i] = $f1->Label(-text=>$txt_labs[$i] . ':',
                               -anchor=>'e',
                               -justify=>'right');

      $entrys[$i] = $f1->BrowseEntry(-state=>'readonly',
                                     -variable=>\$values[$i],
                                     -foreground=>$main::fc,
                                     -background=>$main::ec,
                                     -width=>$widths[$i],
                                     -choices=>$options[$i],

                                    );

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

sub apply_font {

   my $self = shift;

   my ( $vals_ref,
        $balloon_ref,
        $font_button_ref,

      ) = @_;

   my @vals = @$vals_ref;

   $main::font{family} = $vals[0];
   $main::font{size} = $vals[1];
   $main::font{weight} = $vals[2];
   $main::font{slant} = $vals[3];

   my $font_command =

   ' $main::font{name} = ' .
      ' $self->{Text_var}->fontCreate( -family => $main::font{family}, ' .
                                     ' -size => $main::font{size}, ' .
                                     ' -weight => $main::font{weight}, ' .
                                     ' -slant => $main::font{slant}, ' .
                                   ' ); ';

   eval $font_command;
   if ($@) {
      warn $@;
      main::mes($self->{window}, 'jesus wept' );
   } else {

      main::bc_upd();
      $curr_font =
         main::font_button_message ($balloon_ref, $font_button_ref, );
   }

   return;
}

1;
