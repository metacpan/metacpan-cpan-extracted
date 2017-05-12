#---------------------------------------------------------
# Documentation is at the end of the file in POD format.
#-------------------------------------------------------
package Schedule::TableImage;

use strict;
use Image::Magick;
use Text::Wrapper;
require Exporter;

use fields qw(days hours events width height xoffset yoffset totaldays totalhours daywidth hourheight image max_textlen);
use vars qw(%FIELDS $VERSION);

$VERSION = '1.13';

#-----------------------------
# new
#------------------------------
sub new {
    my ($invocant) = shift;    

    my $type = ref($invocant) || $invocant;
    my $self = { @_ };

    #--- bless ---#
    bless $self, $type;

    $self->_init();		
    return $self;
}

#--------------------------------------------------
# get as much info as we can based on text and filename
#--------------------------------------------------
sub _init {
    my ($self) = @_;

    $self->_check_hours();
    unless ( (defined $self->{days}) && (defined $self->{hours}) ){
              $self->error("Days and hours must be defined.", "The call to new must include an array of hashes for the days and for the hours");
	  }

    my @days = @{$self->{days}}; 
    my @hours = @{$self->{hours}};
   
    $self->{font} = '@/usr/local/share/fonts/ttf/arial.ttf' unless ($self->{font});
    $self->{pointsize} = '12';


    $self->_set_text_size();
    $self->{width} = "500" unless ($self->{width});
    $self->{height} = "500" unless ($self->{height});
    $self->{xoffset} = $self->{pt_txt_width} + 1;
    $self->{yoffset} = $self->{pt_txt_height} + 1 ;
    $self->{totaldays} = @days + 0 ;
    $self->{totalhours} = $#hours + 1;
    $self->{daywidth}   = ($self->{width}  - $self->{xoffset}  - 5) / $self->{totaldays};
    $self->{hourheight} = ($self->{height} -  $self->{yoffset} - 5)/ $self->{totalhours};
    $self->{minuteheight} = $self->{hourheight} / 60 ;
    $self->{max_textlen} = $self->_max_textlength($self->{daywidth});   

    $self->{schedule} = {}; # all events keyed by day and start time

    return;
}



#-----------------------------------
# get size values based on font
#------------------------------------
sub _set_text_size {
    my ($self) = @_;
    my ($x_ppem, $y_ppem, $ascender, $max_advance);
    my $text = "12:00 PM";
    my $im = Image::Magick->new();    
    my $rc = $im->Read("label:$text");
    $self->error("Error finding text size",
		 "Could not create image to read text size: $rc") if $rc;
    
   ($x_ppem, $y_ppem, $ascender, $self->{pt_txt_desc},$self->{pt_txt_width}, $self->{pt_txt_height}, $max_advance) 
       = $im->QueryFontMetrics( text=>$text, font=>$self->{font}, pointsize=>$self->{pointsize} );
    $self->{txt_width} = int $self->{pt_txt_width} / length($text);
    

    $im ="";

    return 1;
}


#-----------------------------------------------
# how many characters can fit in the width given
#-----------------------------------------------
sub _max_textlength {
    my ($self, $width) = @_;
    my $num_chars = int( $width / $self->{txt_width});
    return $num_chars - 1;
}

#--------------------------------------------
# create image reference
#---------------------------------------------
sub _setup_image {
    my ($self, $w, $h) = @_;

    # some typeing shortcuts
    my $im = Image::Magick->new(size => "$w".'x'."$h" );
    my ($rc);  #errors

    $rc = $im->Read('xc:white');
    $self->error("Error creating schedule", "Could not create image to write text to: $rc") if $rc;


    $self->{image} = $im;

    return 1;
}


#--------------------------------
# create schedule background               
#---------------------------------
sub create_schedule {
    my ($self) = @_;
    my $text_color= "#000000";
    my $rc;  #errors


    # do calculations to prepare width of hours and days and prepare events
    $self->_prepare_schedule();
    $self->_setup_image($self->{width}, $self->{height}) unless (defined $self->{image});

    my $im = $self->{image};
    my ($xoffset, $yoffset) = ($self->{xoffset}, $self->{yoffset});

#    print "Self is ".Dumper($self);
    #----- days 
    for (my $i=0;$i<$self->{totaldays};$i++ ) {

	# create the rectangles for each day
	my $x1 = $self->{schedule}->{$i}->{startpixels};
	my $x2 = $self->{schedule}->{$i}->{endpixels};
	my $y1 = $yoffset;
	my $y2 = $yoffset + $self->{totalhours}*$self->{hourheight};

	$rc = $im->Draw(primitive => 'rectangle',
			points    => "$x1, $y1, $x2, $y2",
			stroke    => "$text_color");
	$self->error("Error creating line", "Could not draw day line at $x1, $y1, $x2, $y2 with $text_color: $rc") if $rc;


	# add the day labels
	# put middle of label in middle of column
	my $textlen = int($self->{txt_width} * length($self->{days}->[$i]->{display}));
 	my $x = $x1 + (($x2 - $x1)/2) - $textlen/2 ;

	my $y = ($yoffset - 1);
	$rc = $im->Annotate(text     => $self->{days}->[$i]->{display}, 
			    font      => $self->{font},
			    pointsize => $self->{pointsize},
			    fill      => $text_color,
			    gravity   => 'NorthWest',
			    geometry  => "+$x+$y",
		    );
	$self->error("Error creating day label", "Could not annotate image with text: $rc") if $rc;
    }

    #----- hours
    foreach my $i ( 0..$self->{totalhours} ) {

	# create the lines for each hour
	my $y1 = $yoffset + ($i * $self->{hourheight});
	my $x2 = $self->{width} - $xoffset ;
	my $y2 = $yoffset  + ($i * $self->{hourheight});

	$rc = $im->Draw(primitive => 'line',
			points    => "$xoffset, $y1,
                                      $x2, $y2",
			stroke    => $text_color);
	$self->error("Error creating line", "Could not draw hour line: $rc") if $rc;

	# add the hour labels

	# get middle of text right on hour line
	my $y = ($i * $self->{hourheight})  + $yoffset + $self->{pointsize}/2 ;

	# put the text right aligned with cal
	my $textlen = int($self->{txt_width} * length($self->{hours}->[$i]->{display}));
	my $x = $xoffset - $textlen - 2*($self->{txt_width});

	$rc = $im->Annotate(text     => $self->{hours}->[$i]->{display}, 
			    font      => $self->{font},
			    pointsize => $self->{pointsize},
			    fill      => $text_color,
			    gravity   => 'NorthWest',
 			    geometry  => "+$x+$y",
		    );
	$self->error("Error annotating hour line", "Could not annotate image with text: $rc") if $rc;

    }

   return 1;
}

#----------------------------
# given an array of event hashes
# add the events 
#------------------------------
sub add_events {
    my ($self, $events) = @_;
    $self->error("Events must be defined.", "The add_events function takes as a parameter an array of events.") unless ($events);

    my ($fill_color, $text_color) = ("#999999", "#000000");
    my ($rc);  #errors
    $self->{events} = $events;

    # create the background and labels
    $self->create_schedule();

    my $im = $self->{image};
    
    # print out event rectangles
    foreach my $event ( @{$self->{events}} ) {
        $fill_color = $event->{fill_color} if (defined $event->{fill_color});
	$self->_event_coordinates($event);

	my ($x1, $x2, $y1, $y2) = @{$event->{rectangle}};
	next unless($x1 && $x2);
	
	$rc = $im->Draw(primitive => 'rectangle',
			points    => "$x1, $y1, $x2, $y2",
			fill      => $fill_color,
			stroke    => "#000000"); 
	$self->error("Error creating event", "Could not draw rectangle: $rc") if $rc;


	my $x = $x1 + 1;
	my $y = $y1 + $self->{yoffset} + 1;
	
	# if event size changes, change wrapper size
	my $title = $self->_wrap_text($event->{title}, $event->{max_textlen});
	$rc = $im->Annotate(text     => $title, 
			    font      => $self->{font},
			    pointsize => $self->{pointsize},
			    fill      => $text_color,
			    gravity   => 'NorthWest',
			    geometry  => "+$x+$y",
			    );
	$self->error("Error creating event title", "Could not annotate image with text: $rc") if $rc;
    }
    return 1;
}


#---------------------------------
# remove current list of events and schedule
#--------------------------------------
sub clear_events {
    my ($self) = @_;
    $self->{events} = ();
    $self->{schedule} = {};
    return 1;
}

 

#-----------------------------------------
# _prepare_schedule
# does all prep work to allow event rects to be calculated
#------------------------------------------
sub _prepare_schedule {
    my ($self) = @_;

    # go through events, find relative positions
    # start building schedule
    foreach my $event (@{$self->{events}}) {
	$self->_event_geometry($event);
    }

    # based on the schedule, calculate overlap information
    my $day;
    for ( $day=0;$day<$self->{totaldays};$day++ ) {

	foreach my $hour (sort keys %{$self->{schedule}->{$day}}) {
	    next if ($hour =~ /num_events/i);	    
	    $self->_calculate_overlap($day, $hour);
	}

	if ($day == 0) {
	    $self->{schedule}->{$day}->{startpixels} = $self->{xoffset};
	}
	else {
	    $self->{schedule}->{$day}->{startpixels} = 
		$self->{schedule}->{$day-1}->{endpixels};
	}
	$self->{schedule}->{$day}->{endpixels} = 
	    $self->{schedule}->{$day}->{startpixels} + 
		 ( ($self->{schedule}->{$day}->{num_events}+1) * $self->{daywidth} );
    }
    $self->{width} = $self->{schedule}->{$day-1}->{endpixels} + $self->{xoffset};

}


#--------------------------------
# remove any empty days
#-----------------------------
sub _check_hours {
    my ($self) = @_;
    
    my @hours = @{$self->{hours}};
    for (my $i=0;$i<=@hours;$i++ ) {
	if ((! $hours[$i] )
	    || (! exists $hours[$i]->{display} )
	    || (! exists $hours[$i]->{value} )
	    || (! defined $hours[$i]->{display}  )
	    || ( $hours[$i] eq "" ) ) {	    
	    splice @hours, $i;
	}
    }
    @{$self->{hours}} = @hours;

}

#----------------------------------------
# get the relative, but not pixel position
# of all the events
#----------------------------------------- 
sub _event_geometry {
    my ($self, $event) = @_;
    my ($startmin, $endmin) = (0, 0);

    my $dayindex   = $self->_get_index($event->{day_num}, $self->{days} );
    my $startindex = $self->_get_index($event->{begin_time}, $self->{hours} );
    my $endindex   = $self->_get_index($event->{end_time}, $self->{hours} );
    if ($startindex == -1) {
	($startindex, $startmin) = $self->_get_minute($event->{begin_time}) ;
	if ($startindex == -1) {
	    $startindex = 0;
	    $startmin = 0;
	}
    }
    if ($endindex == -1) {
	($endindex, $endmin) = $self->_get_minute($event->{end_time}) ;
	$endindex = $self->{totalhours} if ($endindex == -1);
    }
    return if ($dayindex == -1); 


    $event->{startindex} = $startindex;
    $event->{endindex} = $endindex;  
    $event->{startminute} = $startmin;
    $event->{endminute}  = $endmin;   


    # push info into schedule data structure
    # which allows us later to check for overlap
    my $hourspan = $startindex;
    while ($hourspan < $endindex) {
        # add the event to the place in the schedule
	push @{$self->{schedule}->{$dayindex}->{$hourspan}}, $event;
	$hourspan++;
    }
    # does not end on that hour... ends after that hour
    if ($endmin > 0 ){
	push @{$self->{schedule}->{$dayindex}->{$endindex}}, $event;
    }

}


#-----------------------------------
# figure out event coordinates
# based on the geometry
#-----------------------------------
sub _event_coordinates {
    my ($self, $event) = @_;

    my $dayindex   = $event->{day_num} - 1;
    my $startindex = $event->{startindex};
    my $endindex   = $event->{endindex};

    my $x2;
    my $x1 =  $self->{schedule}->{$dayindex}->{startpixels} +
	( $event->{day_order} * $self->{daywidth} );


    # if day is stetched, but this event does not overlap
    # make the day stretch across the whole day
    if ( ($self->{schedule}->{$dayindex}->{num_events} > 0) &&
	 ($event->{overlap} != 1 )  )
    {
	$x2= $self->{schedule}->{$dayindex}->{endpixels};
	
    }
    else {
	$x2 =  $x1 + $self->{daywidth} ;
    }
    my $y1 = ( $startindex * $self->{hourheight}) + $self->{yoffset} + $event->{startminute};
    my $y2 = ( $endindex   * $self->{hourheight}) + $self->{yoffset} + $event->{endminute};
    $event->{rectangle} = [$x1, $x2, $y1, $y2];
    $event->{max_textlen} = $self->_max_textlength($x2 - $x1);

    return;
}



#--------------------------------
# modify rectangles or events
# to show an overlap
#------------------------------------
sub _calculate_overlap {
    my ($self, $daykey, $hourkey) = @_;

    my @list  = @{$self->{schedule}->{$daykey}->{$hourkey}}; 

    # if only one event there is no overlap
    if (@list + 0 == 1) {
	# default the day_order to 0 if not set
	unless ( exists $self->{schedule}->{$daykey}->{$hourkey}->[0]->{day_order} ) 
	{
	    $self->{schedule}->{$daykey}->{$hourkey}->[0]->{day_order} = 0;
	}
	return ;
    }   

    # the first event of day should be to the leftmost side of day
    my @eventlist =
	sort {   $a->{startindex} <=> $b->{startindex}  } @list;

    # don't put any two events in same spot
    my @spots = (0..@eventlist);
    my @taken_spots;
    foreach my $e (@eventlist) {
	next unless ( (exists $e->{day_order}) && ($e->{day_order} !~ /^\s*$/) );
	push @taken_spots, $e->{day_order};
    }
    my $day_order =0;

       
    # give an event an unassigned day order
    foreach my $event (@eventlist) {	
	$event->{overlap} = 1;
	if ( exists $event->{day_order} )  {
	    next;
	}
	while ( grep /^$day_order$/, @taken_spots ) {
	    $day_order++;
	}
	$event->{day_order} = $day_order;
	push @taken_spots, $day_order;

    }

 
    # set maximum num events found so far for this day 
    if ($#taken_spots  > $self->{schedule}->{$daykey}->{num_events} ) {
	$self->{schedule}->{$daykey}->{num_events} = $#taken_spots  ;
    }

}


#------------------------------------
# given a width (for an event) 
# wrap the text
#--------------------------------------
sub _wrap_text {
    my ($self, $text, $width) = @_;
    
    my $wrapper = Text::Wrapper->new(columns=>$width, body_start => '');
    return $wrapper->wrap($text);
}


#------------------------------
# _get_index
# takes array & value
# returns array index for which the value matches
#-----------------------------
sub _get_index {
    my ($self, $value, $array) = @_;
    for my $i (0.. @$array) {
	if ( $array->[$i]->{value} eq $value) {
	    return $i;
	}
    }
    return -1;
}


#---------------------------------------
# _get_minute
# based on an hhmm time, seperates the minute and hour index
#----------------------------------------
sub _get_minute {
    my ($self, $time) = @_;
    if ($time =~ /(.+)(\d\d)$/ ) {
	my $hour = $1."00";
	my $min = $2;
	my $minpoint = $min * $self->{minuteheight};
	my $hpoint = $self->_get_index($hour, $self->{hours} );
	return ($hpoint, $minpoint);	
    }

    #TODO throw exception
    #print "time $time does not end with two digits \n";

    return (-1, -1);
}




#------------------------------------
# write the image file
# to specified place
#---------------------------------------
sub write_image {
    my ($self, $fp, $qualitymetric) = @_;

    my $rc;

    if (defined $qualitymetric) {	
	$rc = $self->{image}->Set('quality'=>'90');
    }
    $rc = $self->{image}->Write($fp);
    $self->error("Error writing image", "Could not write schedule file: $rc") if $rc;
    return 1;
}


#---------------------------
# the error method
#--------------------------
sub error {
    my ($self, $text, $text2) = @_;
    die "$text \n $text2 \n";
}

#------------------------------
1;
__END__

#------------------------------
# POD from here to end of file
#---------------------------------

=head1 NAME

Schedule::TableImage - creates a graphic schedule with labelled events.  User inputs the hours, days, and events to show.  Uses Image::Magick to generate the image file.

=head1 SYNOPSIS

    use Schedule::TableImage;
    my $cal = Schedule::TableImage->new(days => \@days, hours => \@hour);
    $cal->add_events(\@events);
    $cal->write_image($path);

=head1 DESCRIPTION

    Creates a image of a schedule with labelled events. 
    This schedule image is a grid in which days are labelled horizontally and hours are labelled vertically.  
    This is useful to a week view, although you can have as many days as you would like, with any label you like.
    Events are colored boxes with text labels for a given time and day. 
    If events overlap on a given day or time, the width of the day expands to accomodate both (or all) events.

    Requires Image::Magick, and Text::Wrapper. 

=head1 FUNCTIONS

=head2 new

Schedule::TableImage->new(days => \@days, hours => \@hour, width=> 450, height=>600, font=>'path/to/font');

    Hours is the display name and value is the 4 digit hour code
    The hours will be displayed in the order they appear in this array.

    Two examples:

  @hours = (
	     {display =>'10am', value   =>'1000'}, 
	     {display =>'11am', value   =>'1100'} )

  @hours = (
	     {display =>'wakeup', value   =>'0835'}, 
	     {display =>'drink coffee', value   =>'0900'} )


    Days is an array of hashes of the display name and a correlation value.  The 'value' field is used by the event table to indicate which day the event is.

    The days will be displayed in the order they appear in this array.

    Two examples:

    @days = ( {display => 'Monday', value='1'}, 
            {display => 'Tuesday', value='2'});

    @days = ( {display => 'Sept 3', value='3'}, 
            {display => 'Sept 5', value='5'}); 


    For both the days and hours hashes, the display field is only used to print some text on the margins of the image. The value field is what will be compared to the information in your event to see where the event should be placed. The order of the array of hashes determines how to order your days and hours on the schedule.

    Width is the starting width of the image. Width defaults to 500px.
    Width may change depending on the number of overlapping events.
    Height is the start (and end) height of image.   Height defaults to 500px.

=head2 add_events

    $cal->add_events(\@events);

    Events are an array of hashes.
    The hashes must contain a title, begin_time, end_time, and day_num.
    The default fill_color is "#999999" (grey).
    The time fields must be a 4 digit military time format HHMM. For example, 7:30pm would be represented as 1930.
    The day_num must correspond to one of the "val" elements in your array of day hashes (See new).
    Each event is one block on your schedule - it can only be on one day within one set of times. 

    my @events = (
		  { title      => 'SampleEvent',
		    begin_time => '1800',
		    end_time   => '1930',
		    day_num    => '1',
		    fill_color => '#CCCCCC'                    
		    },
		  { title      => 'Second sample',
		    begin_time => '1000',
		    end_time   => '1300',
		    day_num    => '4',
		    fill_color => '#CFF66C'                    
		    }		
		  );
   $cal->add_events(\@events);

=head2 write_image 

    $cal->write_image('/public_html/myimage.png' [, '90']);

    Writes the Image to the given path and filename.  You can use any image type your Image::Magick installation supports.
    Review the Image::Magick docs to see whether a quality metric is useful to you and your filetype.

=head2 clear_events

    clear_events removes all events from your schedule object.

=head2 create_schedule

    $cal->create_schedule();
    Creates only a blank schedule based on the days and hours.
    Does not add the events to the schedule image. 
    You do not need to call this if you call add_events.  Only call this if you want a blank schedule.

=head2 error

    $cal->error("one error message", "a different error message");
    The current error functionality simply dies with the error messages.
    You probably never need to call this, but you may see the effects.
    The first error message is something the user might want to see.
    The second message has information for the programmer or debugger, 
    and includes any Image::Magick error messages.  

=head1 AUTHOR

Rebecca Hunt (rahunt@mtholyoke.edu)

=head1 BUGS

If the text is too long for an event, the text is not truncated. Instead, it wraps below the bottom line of the event.

=head1 SEE ALSO

ImageMagick, Text::Wrapper

=head1 COPYRIGHT

Copyright (c) 2003 Rebecca A Hunt. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut
