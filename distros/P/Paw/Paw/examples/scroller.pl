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
use Paw::Label;

*PI = \(atan2(1,1)*4);

($columns, $rows)=Paw::init_widgetset;
$win=Paw::Window->new(height=>$rows, width=>$columns, color=>1, orientation=>"grow", time_function=>\&tf);
$text_data=" Circle Scroller";
$text_data2=" Sinus Scroller";
$text_data3=" Jump-Scroller";
$merker = 0;
$merker2 = 0;
$merker3 = $columns;

$circ_xamp     = 20;
$circ_yamp     = 7;
$circ_xpos     = $columns/2;
$circ_ypos     = $circ_yamp+1;
$circ_slowness = ($PI*4);

$sin_yamp     = 3;
$sin_ypos     = $rows-$sin_yamp-2;
$sin_slowness = 8;

$jump_slowness = 10;

for ( my $i=0; $i < length $text_data; $i++ ) {
    $char{$i} = Paw::Label->new(text=>(substr $text_data, (length $text_data)-$i-1, 1) );
    $win->put( $char{$i} );
}
for ( my $i=0; $i < length $text_data2; $i++ ) {
    $char2{$i} = Paw::Label->new(text=>(substr $text_data2, (length $text_data2)-$i-1, 1) );
    $win->put( $char2{$i} );
    $char2{$i}->abs_move_widget( new_x=>$columns-($i*2) );
}
for ( my $i=0; $i < length $text_data3; $i++ ) {
    $char3{$i} = Paw::Label->new(text=>(substr $text_data3, (length $text_data3)-$i-1, 1) );
    $win->put( $char3{$i} );
    $char3{$i}->abs_move_widget( new_x=>$columns-($i*3) );
}


$win->raise();

sub tf {
    $old_merker=$merker;
    $old_merker2=$merker2;
    
    for ( my $i=0; $i<length $text_data; $i++ ) {
        $char{$i}->abs_move_widget(new_x=>($circ_xamp*cos($merker+$PI)+$circ_xpos),
                                   new_y=>($circ_yamp*sin($merker)+$circ_ypos));
        $merker += $PI/$circ_slowness;
    }
    for ( my $i=0; $i<length $text_data2; $i++ ) {
        my ($x,$y)=$char2{$i}->get_widget_pos();
        $char2{$i}->abs_move_widget(new_x=>($x-1),
                                    new_y=>($sin_yamp*sin($merker2)+$sin_ypos));
        ($x,$y)=$char2{$i}->get_widget_pos();
        $char2{$i}->abs_move_widget( new_x=>$columns ) if ( $x < 0 );
        $merker2 += $PI/$sin_slowness;

    }
    for ( my $i=0; $i<length $text_data3; $i++ ) {
        my ($x,$y)=$char3{$i}->get_widget_pos();
        $char3{$i}->abs_move_widget(new_x=>($x-3),
                                    new_y=>($rows-12*sin($merker3)-12));
        ($x, $y) = $char3{$i}->get_widget_pos();
        $char3{$i}->abs_move_widget( new_x=>$columns ) if ( $x < 0 );
    }
    $merker3 += $PI/$jump_slowness;
    $merker3 = 0 if $merker3 > $PI;
    $merker = ($old_merker+$PI/10);
    $merker = 0 if $merker > 2*$PI;
    $merker2 = ($old_merker2+$PI/10);
    $merker2= 0 if $merker2 > 2*$PI;
    return;
}
