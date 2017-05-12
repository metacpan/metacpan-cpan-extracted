# Demo of tile widget

use vars qw/$TOP/;

sub ttkprogressbar{


        my($demo) = @_;
        $TOP = $MW->WidgetDemo(
                -name     => $demo,
                -title    => 'Tile Widget Progressbar Demo',
                -text	  => '',
                -iconname => 'ttkprogress',
        );

        my $msg = $TOP->ttkLabel( -text => 
                "Below are two progress bars. The top one is a \u201Cdeterminate\u201D progress bar, which is used for showing how far through a defined task the program has got. The bottom one is an \u201Cindeterminate\u201D progress bar, which is used to show that the program is busy but does not know how long for. Both are run here in self-animated mode, which can be turned on and off using the buttons underneath.",
        qw/ -wraplength 4i -justify left/)->pack(-side => 'top', -fill => 'x');
         
        my $frame = $TOP->ttkFrame()->pack(-fill => 'both', -expand => 1);
        
        sub doBars{
                my ($op, @args) = @_;
                foreach my $arg(@args){
                        $arg->$op();
                }
        }
        
        my $p1 = $frame->ttkProgressbar(-mode => 'determinate');
        my $p2 = $frame->ttkProgressbar(-mode => 'indeterminate');
        
        my $startB = $frame->ttkButton(-text => 'Start Progress', -command => [\&doBars, 'start', $p1, $p2]);
        my $stopB  = $frame->ttkButton(-text => 'Stop Progress', -command => [\&doBars, 'stop', $p1, $p2]);
        
        $p1->grid( '-', qw/ -pady 5 -padx 10/);
        $p2->grid( '-', qw/ -pady 5 -padx 10/);
        $startB->grid( $stopB, qw/ -padx 10 -pady 5/);
        $startB->gridConfigure( -sticky => 'e');
        $stopB->gridConfigure(  -sticky => 'w');
        $frame->gridColumnconfigure('all', -weight => 1);

}

 

