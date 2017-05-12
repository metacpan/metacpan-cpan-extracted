# Demo of tile widget

use vars qw/$TOP/;

sub ttkmenu{


        my($demo) = @_;
        $TOP = $MW->WidgetDemo(
                -name     => $demo,
                -title    => 'Tile Widget Menubutton Demo',
                -text	  => '',
                -iconname => 'ttkmenu',
        );

        my $label = $TOP->ttkLabel( -text => 
                "Ttk is the new Tk themed widget set, and one widget that is available in themed form is the menubutton. Below are some themed menu buttons that allow you to pick the current theme in use. Notice how picking a theme changes the way that the menu buttons themselves look, and that the central menu button is styled differently (in a way that is normally suitable for toolbars). However, there are no themed menus; the standard Tk menus were judged to have a sufficiently good look-and-feel on all platforms, especially as they are implemented as native controls in many places.",
        qw/ -wraplength 4i -justify left/)->pack(-side => 'top', -fill => 'x', -expand => 1);
        
        my $buttonFrame = $TOP->ttkFrame()->pack(-fill => 'x');
        
        my $m1 = $buttonFrame->ttkMenubutton( -text =>  "Select a theme",  -direction => 'above');
        my $m2 = $buttonFrame->ttkMenubutton( -text =>  "Select a theme",  -direction => 'left');
        my $m3 = $buttonFrame->ttkMenubutton( -text =>  "Select a theme",  -direction => 'right');
        my $m5 = $buttonFrame->ttkMenubutton( -text =>  "Select a theme",  -direction => 'below');
        my $m4 = $buttonFrame->ttkMenubutton( -text =>  "Select a theme",  -direction => 'flush', -style => 'TMenubutton.Toolbutton');
        
        foreach my $mb ($m1, $m2, $m3, $m4, $m5){
                my $menu = $mb->Menu(-tearoff => 0);
                $mb->configure(-menu => $menu);
                foreach my $theme( $TOP->ttkThemes ){
                        $menu->add('command', -label, $theme, -command => sub{ $TOP->ttkSetTheme($theme) });
                }
        }
                        
        
        $buttonFrame->gridAnchor('center');
        $m1->grid(-column => 1, -padx => 3, -pady => 2);
        $m2->grid($m4, $m3, -padx => 3, -pady => 2);
        $m5->grid(-column => 1, -padx => 3, -pady => 2);
      


}


