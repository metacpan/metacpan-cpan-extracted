#!/usr/bin/perl -w
#########################################################################
# Copyright (c) 1999 SuSE Gmbh Nuernberg, Germany.  All rights reserved.
#
# Author  : Uwe Gansert <ug@suse.de>
# License : GPL, see LICENSE File for further information
#
#
# just for fun .... 
#
use Curses;
use Paw;
use Paw::Window;
use Paw::Line;
use Paw::Label;

*PI = \3.1415927;
    
($columns, $rows)=Paw::init_widgetset;
init_pair(2, COLOR_WHITE, COLOR_BLACK);
init_pair(3, COLOR_CYAN, COLOR_BLACK);
init_pair(4, COLOR_GREEN, COLOR_BLACK);
$win=Paw::Window->new(height=>$rows, width=>$columns, color=>2, orientation=>"grow", time_function=>\&tf);
$line0=Paw::Line->new(length=>$columns);

$scr_x = $columns/2;
$scr_y = $rows/2;

$points = 35;

$jump_slowness = 20;
$merker = 0;
for ( my $i=0; $i<$points; $i++ ) {
    $point{$i}{xx} = int(rand 1000)-500;
    $point{$i}{yy} = int(rand 1000)-500;
    $point{$i}{zz} = 1+int(rand 1000);
    $point{$i}{ref} = Paw::Label->new(text=>".");
    $win->put($point{$i}{ref});
}

$merker3 = 0;
$logo{0}{data} = "   __   _";
$logo{1}{data} = "  / /  (_)__  __ ____  __";
$logo{2}{data} = " / /__/ / _ \\/ // /\\ \\/ /";
$logo{3}{data} = "/____/_/_//_/\\___/ /_/\\_\\";

for ( my $i=0; $i<4; $i++ ) {
    $logo{$i}{ref} = Paw::Label->new(text=>$logo{$i}{data});
    $win->put($logo{$i}{ref});
}


$win->put($line0);
$dist = 8;

$text_data = " just a little Demo ! I am working on phong shaded vectors ;-)";
for ( my $i=0; $i < length $text_data; $i++ ) {
    $char{$i} = Paw::Label->new(color=>4, text=>(substr $text_data, (length $text_data)-$i-1, 1) );
    $win->put( $char{$i} );
    $char{$i}->abs_move_widget(new_x=>($columns-$i-3));
}

$sin_yamp     = 3;
$sin_ypos     = $rows-$sin_yamp-2;
$sin_slowness = 8;
$merker2 = 0;
$line0->abs_move_widget(new_x=>0, new_y=>9);

$text_data2 = " Sinus Scroller ----------- ";
for ( my $i=0; $i < length $text_data2; $i++ ) {
    $char2{$i} = Paw::Label->new(text=>(substr $text_data2, (length $text_data2)-$i-1, 1), color=>3 );
    $win->put( $char2{$i} );
    $char2{$i}->abs_move_widget( new_x=>$columns-($i*2) );
}

$win->raise();

sub tf {

    $old_merker2=$merker2;
    $angle += $PI/20;
    $angle = $PI/20 if ($angle > 2*$PI);
    for ( my $i=0; $i<4; $i++ ) {
        $logo{$i}{ref}->abs_move_widget( new_y=>(12+$i),
                                         new_x=>(12*sin($merker3)+$columns/2-10));
    }
    #    $logo{4}{ref}->abs_move_widget( new_y=>(24),
    #                                 new_x=>(12*sin($merker3)+30 ));
    #
    # Projection
    #
    for ( my $i=0; $i<$points; $i++ ) {
        $point{$i}{zz}-=12;
        $z_val = $point{$i}{zz};
        $z_val = -1 if ( $z_val == 0 );
        $y_val = $point{$i}{yy};
        $x_val = $point{$i}{xx};
        #$z_val = $point{$i}{zz};

        #
        # Rotation around x-axis
        #
        #$y_val=$point{$i}{yy}*cos($angle)-$point{$i}{zz}*sin($angle);
        #$z_val=$point{$i}{zz}*cos($angle)+$point{$i}{yy}*sin($angle);
        #$x_val=$point{$i}{xx};

        #
        # Rotation around y-axis
        #
        #$x_val=$point{$i}{xx}*cos($angle)+$point{$i}{zz}*sin($angle);
        #$z_val=$point{$i}{zz}*cos($angle)-$point{$i}{xx}*sin($angle);
        #$y_val=$point{$i}{yy};

        #
        # Rotation around z-axis (best for starscroller)
        #
        $x_val=$point{$i}{xx}*cos($angle)-$point{$i}{yy}*sin($angle);
        $y_val=$point{$i}{yy}*cos($angle)+$point{$i}{xx}*sin($angle);
        #$z_val=$point{$i}{zz};


        $x_pos = int($scr_x+$dist*( ($x_val)/$z_val ));
        $y_pos = int($scr_y-$dist*( ($y_val)/$z_val ));

        #
        # Point behind user or out of screen ? Kill it !
        #
        if ( $x_pos > $columns or $x_pos < 0 or $y_pos < 10 or $z_val < 8) {
            $point{$i}{xx} = int(rand 1000)-500;
            $point{$i}{yy} = int(rand 1000)-500;
            $point{$i}{zz} = 1+int(rand 1000);
        }
        else {
            $point{$i}{ref}->abs_move_widget( new_x=>$x_pos, new_y=>$y_pos );
        }
    }
    for ( my $i=0; $i<length $text_data; $i++ ) {
        my (my $x, my $y) = $char{$i}->get_widget_pos();
        $char{$i}->abs_move_widget(new_x=>($x-1), new_y=>(-6*sin(2*$merker)+8));
        $char{$i}->abs_move_widget( new_x=>$columns ) if ( $x < 0 );
    }

    $merker += $PI/$jump_slowness;
    $merker = 0 if $merker > $PI/2;   # only 1 Sinus-Phase for jumping

    $merker3 += $PI/20;
    $merker3 = 0 if $merker3 > 2*$PI;
    
    for ( my $i=0; $i<length $text_data2; $i++ ) {
        my ($x,$y)=$char2{$i}->get_widget_pos();
        $char2{$i}->abs_move_widget(new_x=>($x-1),
                                    new_y=>($sin_yamp*sin($merker2)+$sin_ypos));
        ($x,$y)=$char2{$i}->get_widget_pos();
        $char2{$i}->abs_move_widget( new_x=>$columns ) if ( $x < 0 );
        $merker2 += $PI/$sin_slowness;
    }

    
    $merker2 = ($old_merker2+$PI/10);
    $merker2 = 0 if $merker2 > 2*$PI;

    return;
}
