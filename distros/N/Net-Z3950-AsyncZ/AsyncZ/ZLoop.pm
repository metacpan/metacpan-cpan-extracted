# $Date: 2003/05/05 16:50:12 $
# $Revision: 1.4 $ 


package Net::Z3950::AsyncZ::ZLoop;
use Net::Z3950::AsyncZ::Errors;
use Event qw(loop unloop);
use Net::Z3950::AsyncZ::Report;
use Net::Z3950::AsyncZ::ZSend;

my $_ERROR_VAL = Net::Z3950::AsyncZ::Errors::errorval();

#$SIG{ALRM} = sub {   exit $_ERROR_VAL + 3;  };

use strict;



my($_host,$_port,$_db,$_query);

# $self->{options} is a _params object

sub new {
my ($class, $host,$port,$db,$query, $options)=@_;
	($_host,$_port,$_db,$_query) = ($host,$port,$db,$query);
	my $self = {
                    conn => 0, Zsend => 0, inLoop => 0, options=>$options,
                    pipetimeout=>undef, interval=>undef, rsize=>0
                   };
        
	my $tm = $self->{options}->_getFieldValue('pipetimeout');
        $self->{pipetimeout} = $tm ? $tm : 20; 
        
	my $interval = $self->{options}->_getFieldValue('interval');
        $self->{interval} = $interval ? $interval : 5;

	bless $self, $class;
}

sub setTimer {
my ($self, $interval)= @_; 

	$self->{start} = time();
	$self->{watcher} = Event->timer(at=>1,interval =>$self->{interval}, cb=> sub { $self->timerCallBack(); } );
	loop();
}

sub timerCallBack {
my $self=shift;

return if ($self->{Zsend}) && $self->{Zsend}->connection();
my $Seconds = time();
my $endval = $Seconds - $self->{start};

 if ($endval >= $self->{pipetimeout}) {
   exit $_ERROR_VAL + 2;
 }

 return if($self->{inLoop});

        $self->{inLoop}=1;
        $self->{Zsend} =
             Net::Z3950::AsyncZ::ZSend->new(
                               query=>$_query,host=>$_host,db=>$_db,
                               port=>$_port,options=>$self->{options}
                               );


		## alarms are set for some conditions in which the event loop is swallowed
		##  up by Net::Z3950 and either doesn't or takes too long to return

        # alarm($self->{pipetimeout}/2); ;
        $self->{conn} = $self->{Zsend}->connection();
        # alarm(0);  

        # alarm($self->{pipetimeout}); 
        if($self->{conn})
            {
		$self->{Zsend}->sendQuery();                 

		if(!$self->{Zsend}->rs() || !$self->{Zsend}->rsize()) {
		  Net::Z3950::AsyncZ::Errors::reportNoEntries();
		  $self->{Zsend}->closedown();
		}
                 $self->{rsize} = $self->{Zsend}->rsize() if $self->{Zsend}->rs();
                 my $report = Net::Z3950::AsyncZ::Report->new($self->{Zsend}->rs(), $self->{options});
                 $report->reportResult();		
                 $self->{report} = $report->{result}; 

		 $self->{Zsend}->closedown();
	   } else {
   		    exit $_ERROR_VAL + 1;
        	}
	 # alarm(0);
$self->{watcher}->cancel();
unloop();
}


1;

__END__


