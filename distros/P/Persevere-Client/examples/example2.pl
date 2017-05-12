#!/usr/bin/perl
use warnings;
use strict;
use Persevere::Client;
use JSON::XS;

my $json = JSON::XS->new->ascii->shrink->allow_nonref;
my $persvr = Persevere::Client->new(
	host => "localhost", 
	port => "8080", 
	auth_type => "none",
#	auth_type => "basic", 
#	username => "test", 
#	password => "pass",
	debug => 1 
);

die "Unable to connect to $persvr->{uri}\n" if !($persvr->testConnection);
my $status;
my $statusreq = $persvr->serverInfo;
if ($statusreq->{success}){
	$status = $statusreq->{data};
}
print "VM: $status->{vm}\nVersion: $status->{version}\n";

my $createdForTest;

sub createTestObjects {
	my $total = shift;
	my @data;
	my $type;
	for (my $loop = 1; $loop <= $total; $loop++){
		if (($loop % 2) == 0) {
			$type = "even";
		}else{
			$type = "odd";
		}
		chomp $type;
		my %hash = ("name$loop" => "test$loop", "type" => $type);
		print "Push: " . $json->encode(\%hash) . "\n";
		push @data, \%hash;
	}
	return @data;
}

my $testClassName = "TestClass";

my $testclass = $persvr->class($testClassName);
if ($persvr->classExists($testClassName)){
	print "Class $testClassName already exists\n";
}else{
	print "Creating Class $testClassName: ";
	$testclass->create;
	$createdForTest = 1;
}

if ($testclass->exists){
	print " Success\n";
}else{
	print " Error\n";
}

# An example object
my @example_data = createTestObjects(4);

# Create 4 objects, store copies locally
my @ret; 
my $retreq = $testclass->createObjects(\@example_data);
if ($retreq->{success}){
	@ret = @{$retreq->{data}};
}
# Create 4 more objects, and add them to local array 
my $retreq2 = $testclass->createObjects(\@example_data);
if ($retreq2->{success}){
	push @ret, @{$retreq->{data}};
}
#print "Created: " . $json->encode(\@ret) . "\n";

my @data;
my $datareq = $testclass->query("[?type='odd']");
if ($datareq->{success}){
	@data = @{$datareq->{data}}; 
}
print $json->encode(\@data) . "\n";
print "Found " . scalar(@data) . " Matches\n";

if ($createdForTest){
	print "Deleting Class $testClassName: " ;
	$testclass->delete;
}
if ($persvr->classExists($testClassName)){
	print "Error\n";
}else{
	print "Success\n";
}

my $class = $persvr->class("Transport");
die "Transport class doesn't exist, don't worry though, these tests aren't packaged with the module yet" if (!($class->exists));
die "a class doesn't exist" if (!($persvr->classExists("Transport")));
my $query = '[?artist="Elucidate"]';
print "Running Query $query in " . $class->fullname . "\n";
my @results;
my $resultreq = $class->query($query);
if ($resultreq->{success}){
	@results = @{$resultreq->{data}};
}

print scalar(@results) . " Results from query $query\n";

my $another_query = '[?artist="Elucidate" & filename="*White*"]';
my @data1;
my $data1req = $class->queryRange($another_query, 0, 999);
if ($data1req->{success}){
	@data1 = @{$data1req->{data}};
}
print $json->pretty->encode(\@data1) . "\n";
print "total: " . scalar (@data1) . "\n";

if ($class->idExists("25")){
	my $request = $class->idGet("25");
	if ($request->{success}){
		my %hdata = %{$request->{data}};
		print "ID 25: \n" . $json->encode(\%hdata) . "\n";
	} 
}
my @data2;
my $data2req = $class->queryRange('[*]', 1000, 1999);
if ($data2req->{success}){
	@data2 = @{$data2req->{data}};
}
print "Total query 2: " . scalar(@data2) . "\n";

print "Query All\n";
my @all;
my $allreq = $class->query('[?type="audio"]');
if ($allreq->{success}){
	@all = @{$allreq->{data}};
}
print "Results: " . scalar (@all) . "\n";
#print $json->pretty->encode(\@all);
