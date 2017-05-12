use MsgQ::QueueMonitor;
$q = new MsgQ::QueueMonitor;


while(1)
{
	%STATUS = $q->get_status("./QueueMonitor.conf");
	for(0 .. 40)
	{
		print "\n";
	}

	print "SendQueue\tStatus\tFiles\n";
	print "=========\t======\t=====\n";

	for $queue (keys %STATUS)
	{
		if (defined $STATUS{$queue}{FILES})
		{
			$QUEUE{$queue}{FILES} = $STATUS{$queue}{FILES};
			$QUEUE{$queue}{STATUS} = "Up";
		}
		else
		{
			$QUEUE{$queue}{STATUS} = "Down";
		}


		
	}

	for $queue (keys %QUEUE)
	{
		print "$queue\t\t$QUEUE{$queue}{STATUS}\t$QUEUE{$queue}{FILES}\n";
		
	}

	sleep 10;
}


