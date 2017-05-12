use lib './../../';
use Schedule::TableImage;
use strict;

&main;

sub main {
    my $path = 'demo.png';

    # set information about which days to display
    my @days = ( 
	    { display =>'Mon',  
	      value   =>'1'},
	     {display =>'Tue',
	      value   =>'2'},
	     {display =>'Wed',
	      value   =>'3'},
	     {display =>'Thu',
	      value   =>'4'},
	     {display =>'Friday',
	      value   =>'5'},
	     {display =>'Sat',
	      value   =>'6'},
	     {display =>'Sun',
	      value   =>'7'},
	     );

    # set information about which hours to display
    my @hour = ( {display =>'9am',  value   =>'900'}, 
	     {display =>'10am', value   =>'1000'}, 
	     {display =>'11am', value   =>'1100'}, 
	     {display =>'12am', value   =>'1200'}, 
	     {display =>'1pm',  value   =>'1300'}, 
	     {display =>'2pm',  value   =>'1400'}, 
	     {display =>'3pm',  value   =>'1500'}, 
	     {display =>'4pm',  value   =>'1600'}, 
	     {display =>'5pm',  value   =>'1700'}, 
	     {display =>'6pm',  value   =>'1800'}, 
	     {display =>'7pm',  value   =>'1900'}, 
	     {display =>'8pm',  value   =>'2000'}, 
	     {display =>'9pm',  value   =>'2100'}, 
	     );

    # information about events
    # each event is a hash    
    my @events = (
		  { title      => 'Sample',
		    begin_time => '1800',
		    end_time   => '1930',
		    day_num    => '1',
		    fill_color => '#CCCCCC'                    
		    },
		  { title      => 'Second sample',
		    begin_time => '1000',
		    end_time   => '1346',
		    day_num    => '4',
		    fill_color => '#CCFFFF'                    
		    }		
		  );

        
    # TableImage takes array references to above arrays
    my $cal = Schedule::TableImage->new(days => \@days, hours => \@hour, font=>"Helvetica");
    $cal->add_events(\@events);
    $cal->write_image($path);
    print "wrote output to $path \n\n";
}









