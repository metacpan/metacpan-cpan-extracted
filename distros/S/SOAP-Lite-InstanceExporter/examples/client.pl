#!/usr/bin/perl -w

use strict;

my $host = shift(@ARGV);
my $port = shift(@ARGV);
my $count = shift(@ARGV);

my $uri = "SOAP::Lite::InstanceExporter";
my $proxy = "http:\/\/$host:$port";

eval "
	use SOAP::Lite +autodispatch =>
	uri => '$uri',
	proxy => '$proxy',
	on_fault => sub { my (\$soap, \$result) = \@_;
			  if (ref \$result)
			  {
			  	die \$result->faultdetail;
			  }
			  else
			  { 
			  	die \$soap->transport->status;
			  }  
			};
";


# get a new InstanceExporter, telling it we want access to the 'counter'
# object.

	my $counter = new SOAP::Lite::InstanceExporter('counter'); 

	for (my $i = 0; $i < $count; $i++)
	{
		print $counter->count(), "\n";
	}


print "Done\n";

