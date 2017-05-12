# Demo of tile widget

use vars qw/$TOP/;

sub ttknote{


        my($demo) = @_;
        $TOP = $MW->WidgetDemo(
                -name     => $demo,
                -title    => 'Tile Widget PanedWindow Demo',
                -text	  => '',
                -iconname => 'ttkpane',
        );

        my $frame = $TOP->ttkFrame()->pack(qw/ -fill both -expand 1/);
        
        ## Make the notebook and set up Ctrl+Tab traversal
        my $note = $frame->ttkNotebook()->pack(qw/-fill both -expand 1 -padx 2 -pady 3/);
        $note->call('ttk::notebook::enableTraversal', $note); 
        
        ## Popuplate the first pane
        my $noteFrame = $note->ttkFrame();
        
        my $notemsg = $noteFrame->ttkLabel( -text => 
                "Ttk is the new Tk themed widget set. One of the widgets it includes is the notebook widget, which provides a set of tabs that allow the selection of a group of panels, each with distinct content. They are a feature of many modern user interfaces. Not only can the tabs be selected with the mouse, but they can also be switched between using Ctrl+Tab when the notebook page heading itself is selected. Note that the second tab is disabled, and cannot be selected.",
        qw/ -wraplength 4i -justify left/);
        
        my $neatText = '';
        my $msgb = $noteFrame->ttkButton(-text => 'Neat!', -underline => 0, -command => 
                sub{ 
                        $neatText = "Yeah, I know...";
                        $note->after(500, sub{ $neatText = '' });
                }
                );
        
        
        $frame->bind('<Alt-n>', sub{ $msgb->focus; $msgb->invoke });
        my $notelabel = $noteFrame->ttkLabel(-textvariable => \$neatText);
        
        $note->add($noteFrame, -text => 'Description', -underline => 0, -padding => 2);
        
        $notemsg->grid('-', -sticky => 'new', -pady => 2);
        $msgb->grid($notelabel, -pady => [2,5]);
        $noteFrame->gridRowconfigure(1, -weight => 1);
        $noteFrame->gridColumnconfigure([0,1],  -weight => 1, -uniform => 1);
        
        ## Populate the second pane. Note that the content doesn't really matter
        my $frame2 = $note->ttkFrame();
        $note->add($frame2, -text => "Disabled",  -state => 'disabled');
        
        ## Popuplate the third pane
        my $frame3 = $note->ttkFrame();
        $note->add($frame3, -text => "Text Editor",  -underline => 0);
        $frame3->Scrolled('Text', -width => 40, -height => 10, -wrap => 'char', 
                        -bd => '1', -scrollbars => 'e')->pack(-expand => 1, -fill => 'both', -pady => 2, -padx => [2,0]);
        


}


