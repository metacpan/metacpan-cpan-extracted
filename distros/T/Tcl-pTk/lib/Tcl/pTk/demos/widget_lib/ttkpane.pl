# Demo of tile widget

use vars qw/$TOP/;

sub ttkpane{


        my($demo) = @_;
        $TOP = $MW->WidgetDemo(
                -name     => $demo,
                -title    => 'Tile Widget PanedWindow Demo',
                -text	  => '',
                -iconname => 'ttkpane',
        );

        my $msg = $TOP->ttkLabel( -text => 
                "This demonstration shows off a nested set of themed paned windows. Their sizes can be changed by grabbing the area between each contained pane and dragging the divider.",
        qw/ -wraplength 4i -justify left/);
        
        my $msgSep = $TOP->ttkSeparator();
        
        $msg->pack($msgSep, -side => 'top', -fill => 'x');
         
        my $w = $TOP->ttkFrame()->pack( qw/ -fill both -expand 1 /);
        
        my $outer   = $w->ttkPanedwindow( qw/ -orient horizontal /);
        my $inLeft  = $w->ttkPanedwindow( qw/ -orient vertical /);
        my $inRight = $w->ttkPanedwindow( qw/ -orient vertical /);
        $outer->add( $inLeft);
        $outer->add( $inRight);
        
        my $inLeftTop  = $inLeft->ttkLabelframe(-text => 'Button');
        my $inLeftBot  = $inLeft->ttkLabelframe(-text => 'Clocks');
        my $inRightTop = $inRight->ttkLabelframe(-text => 'Progress');
        my $inRightBot = $inRight->ttkLabelframe(-text => 'Text');
        $inLeft->add(  $inLeftTop);
        $inLeft->add(  $inLeftBot);
        $inRight->add( $inRightTop);
        $inRight->add( $inRightBot);
        
        if( $TOP->windowingsystem eq "aqua" ) {
            foreach my $widget ( $inLeftTop, $inLeftBot, $inRightTop, $inRightBot ){
                $widget->configure( -padding => 3 );
            }
        }
        
        # Fill the button pane
        my $inLeftTopB = $inLeftTop->ttkButton( -text =>  "Press Me", 
                -command => sub{ $TOP->messageBox( -type => 'ok',  -icon => 'info', 
                                        -message => "Ouch!",  -detail =>  "That hurt...",
                                        -title => "Button Pressed");
                }
                )->pack( qw/ -padx 2 -pady 5/);
        
        # Fill the clocks pane
        my $i = 0;
        
        
        my @cities = ('Berlin', 'Buenos Aires', 'Johannesburg', 'London', 'Los Angeles', 'Moscow',
                     'New York', 'Singapore', 'Sydney', 'Tokyo');
        
        # Offsets from UTC
        my @TZoffsets = ( 2, -3, 2, 1, -7, 4, 
                          -4, 8, -14, 9);
        
        # Hash for quick lookup
        my %TZoffsets;
        @TZoffsets{@cities} = @TZoffsets;
        
        # Hash of times for the different cities
        my %times;
        
        # Initialize the times
        updateTimes(\%times, \%TZoffsets);
        
        
        foreach my $city(@cities){
                
                # pack a separator, if this isn't the first time 
                $inLeftBot->ttkSeparator()->pack( -fill => 'x') if( $i);
                
                # Create label/clocks
                my $label = $inLeftBot->ttkLabel( -text => $city, -anchor => 'w')->pack(-fill => 'x') ;
                my $clock = $inLeftBot->ttkLabel( -textvariable => \$times{$city}, -anchor => 'w')->pack(-fill => 'x');
                
                $i++;
        }
        
        # Setup to update the clocks
        $TOP->repeat( 1000, [\&updateTimes, \%times, \%TZoffsets] );
        
        # Fill the progress pane
        my $topProg = $inRightTop->ttkProgressbar(-mode => 'indeterminate')->pack(qw/-fill both -expand 1/);
        $topProg->start;
        
        # Fill the text pane
        if( $TOP->windowingsystem eq "aqua" ) {
            # The trick with the ttk::frame makes the text widget look like it fits with
            # the current Ttk theme despite not being a themed widget itself. It is done
            # by styling the frame like an entry, turning off the border in the text
            # widget, and putting the text widget in the frame with enough space to allow
            # the surrounding border to show through (2 pixels seems to be enough).
            my $botFrame = $inRightBot->ttkFrame( -style => 'TEntry');
            my $text = $botFrame->Scrolled('Text', -wrap => 'word', -width => 30, -bd => 0, -scrollbars => 'e');
            $text->pack(-fill => 'both', -expand => 1, -pady => 2, -padx => 2);
            $botFrame->pack(qw/ -fill both -expand 1/);
            $outer->pack( qw/ -fill both -expand 1 /);
        } else {
            my $text = $inRightBot->Scrolled('Text', -wrap => 'word', -width => 30, -bd => 0, -scrollbars => 'e');
            $text->pack(-fill => 'both', -expand => 1, -pady => 2, -padx => 2);
            $outer->pack( -fill =>  'both',  -expand =>  1,  -padx =>  10,  -pady => [6,10]);
        }
        


}

# Sub to update the times, based on the timezone offset
sub updateTimes{
        my $times     = shift; # hash of city => local-time
        my $tzoffsets = shift; # hash of city => tzoffset
        
        my $time = time();
        foreach my $city (sort keys %$tzoffsets){
                my $localeTime = $time + $tzoffsets->{$city}*3600;
                my (@timeElements) = gmtime($localeTime);
                my $timeString = sprintf("%02d:%02d:%02d", @timeElements[2,1,0]);
                $times->{$city} = $timeString;
        }
}

 

