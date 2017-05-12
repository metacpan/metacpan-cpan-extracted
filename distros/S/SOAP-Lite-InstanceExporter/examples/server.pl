#! /usr/bin/perl -w

use SOAP::Transport::HTTP;
  
$SIG{PIPE} = 'IGNORE'; # don't want to die on 'Broken pipe'
                       # What about CTRL-C????

# change LocalPort to 81 if you want to test it with soapmark.pl

# Tell our InstanceExporter which objects in the main package namespace
# to allow SOAP clients access to.
use SOAP::Lite::InstanceExporter ('counter', 'counters[1]');

package main;

# Initialize some Counter objects, which we are exporting for SOAP
# access
$counter = new Counter();

$counters[0] = new Counter();   # not allowing access to this one
$counters[1] = new Counter();

my $localport = shift(@ARGV);

unless (defined $localport && $localport){
	$localport = 8060;
}

my $daemon = SOAP::Transport::HTTP::Daemon
  -> new (LocalAddr => 'localhost', LocalPort => $localport, Reuse => 1) 
  # you may also add other options, like 'Reuse' => 1 and/or 'Listen' => 128
  # specify list of objects-by-reference here 
  -> objects_by_reference(qw(SOAP::Lite::InstanceExporter))
  # specify path to My/Examples.pm here
  -> dispatch_to('SOAP::Lite::InstanceExporter') 
  # enable compression support
  #-> options({compress_threshold => 10000})
;
print "Contact to SOAP server at ", $daemon->url, "\n";
$daemon->handle;


package Counter;      # Working class

sub new {
	my $self = shift(@_);
	my $class = ref($self) || $self;

	bless {count=>0}, $class;
}

sub count {	     # Returns the old count, increments by one
	my $self = shift(@_);
	my $count = $self->{count};
	$self->{count}++;
	return $count;
}
