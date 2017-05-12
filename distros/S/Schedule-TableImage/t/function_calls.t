use strict;
use Test::More tests=>6;


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
	     );


# information about events
my @events = (
		  { title      => 'SampleEventX',
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


my $path = 'test.png';

use_ok 'Schedule::TableImage';
isa_ok(my $cal = Schedule::TableImage->new(days => \@days, hours => \@hour, font=>"Helvetica"), 'Schedule::TableImage');

ok( $cal->add_events(\@events),  'add_events ');
ok( $cal->write_image($path)  ,  "write image to $path");
ok((-f $path) == 1,                     "output image $path is a file");
ok($cal->clear_events,           'clear_events');

unlink($path);



