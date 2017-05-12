# Demo of themed toolbar

use vars qw/$TOP/;

sub toolbar{


        my($demo) = @_;
        $TOP = $MW->WidgetDemo(
                -name     => $demo,
                -title    => 'Themed Toolbar Demo',
                -text	  => '',
                -iconname => 'toolbar.pl',
        );

        
        if( $TOP->windowingsystem ne 'aqua'){
              $label = $TOP->ttkLabel(-wraplength => '4i', -text => " This is a demonstration of how to do a toolbar that is styled correctly and which can be torn off. The buttons are configured to be \u201Ctoolbar style\u201D buttons by telling them that they are to use the Toolbutton style. At the left end of the toolbar is a simple marker that the cursor changes to a movement icon over; drag that away from the toolbar to tear off the whole toolbar into a separate toplevel widget. When the dragged-off toolbar is no longer needed, just close it like any normal toplevel and it will reattach to the window it was torn off from.");
        }
        else{
              $label = $TOP->ttkLabel(-wraplength => '4i', -text => "This is a demonstration of how to do a toolbar that is styled correctly. The buttons are configured to be \u201Ctoolbar style\u201D buttons by telling them that they are to use the Toolbutton style.");
        }
        
        ## Set up the toolbar hull
        my $toolbar = $TOP->Frame;  # Must be a frame!
        my $sep = $TOP->ttkSeparator();
        my $tearoff = $toolbar->Frame(-cursor => 'fleur');
        my ($to, $to2);
        if( $TOP->windowingsystem ne 'aqua'){
            $to = $tearoff->ttkSeparator(-orient => 'vertical');
            $to2 = $tearoff->ttkSeparator(-orient => 'vertical');
            $to->pack(  qw/ -fill y -expand 1 -padx 2 -side left/ );
            $to2->pack( qw/ -fill y -expand 1 -padx 2 -side left /);
        }
        my $contents = $toolbar->Frame();
        $tearoff->grid($contents, -sticky => 'nsew');
        $toolbar->gridColumnconfigure( $contents,  -weight => 1);
        $contents->gridColumnconfigure( 1000,  -weight => 1);
        
        if( $TOP->windowingsystem ne 'aqua'){
            ## Bindings so that the toolbar can be torn off and reattached
            $tearoff->bind('<B1-Motion>', [\&tearoff, $toolbar, $tearoff, Ev('X'), Ev('Y')]);
            $to->bind(     '<B1-Motion>', [\&tearoff, $toolbar, $tearoff, Ev('X'), Ev('Y')]);
            $to2->bind(    '<B1-Motion>', [\&tearoff, $toolbar, $tearoff, Ev('X'), Ev('Y')]);
        
        }
        
        ## Toolbar contents
        my $text = $TOP->Text(-width => 40, -height => 10);
        my $button = $contents->ttkButton( -text =>  "Button",  -style => 'Toolbutton', 
                -command => sub{ $text->insert('end', "Button Pressed\n")});
        
        my $checkVar;
        my $check = $contents->ttkCheckbutton( -text =>  "Check", -variable => \$checkVar,  -style =>  'Toolbutton',
                -command => sub{ $text->insert('end', "check is $checkVar\n")} ); 
        
        my $menu = $contents->Menu();
        my $menub = $contents->ttkMenubutton(-text => "Menu", -menu => $menu);
        
        my $combo = $contents->ttkCombobox( -values => [$TOP->fontFamilies],  -state =>  'readonly');
        
        $menu->add('command', -label => "Just" => -command => sub{ $text->insert('end', "Just\n") });
        $menu->add('command', -label => "An" => -command => sub{ $text->insert('end', "An\n") });
        $menu->add('command', -label => "Example" => -command => sub{ $text->insert('end', "Example\n") });
        
        $combo->bind('<<ComboboxSelected>>', [\&changeFont, $text, $combo]);
        
        
        ## Arrange contents
        $button->grid($check, $menub, $combo, -padx => 2, -sticky => 'ns');
        
        $toolbar->grid( -sticky => 'ew');
        $sep->grid(     -sticky => 'ew');
        $label->grid(   -sticky => 'ew');
        $text->grid(    -sticky => 'nsew');
        $text->parent->gridRowconfigure( $text, -weight => 1);
        $text->parent->gridColumnconfigure( $text, -weight => 1);
        
      


}

 # Proc to handle tearoffs
sub tearoff{
         my ($widget, $w, $tearoff, $x, $y) = @_;
         
         #print "Tearoff $w, $tearoff, $x, $y\n";
         if( $w eq $w->containing($x, $y) ){
                 return;
         }
         $w->gridRemove();
         $tearoff->gridRemove();
         $w->Tcl::pTk::Wm::manage();
         my $toplevel = $w->toplevel();
         $w->protocol('WM_DELETE_WINDOW', [\&untearoff, $w, $tearoff]);
}

sub untearoff{
        my $w = shift;
        my $tearoff = shift;
        $w->forget();
        $tearoff->grid();
        $w->grid();
}    
    
sub changeFont{
        my $widget = shift;
        my $txt = shift;
        my $combo = shift;
        $txt->configure(-font => $combo->get . " 10");
}

