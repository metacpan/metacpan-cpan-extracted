#!/usr/local/bin/perl -w

#
# Unit test for Sub::Slice::Backend::Filesystem
#
# -t Trace
# -T Deep trace
# -s save output
# -b baseline (generate new data files to compare against)
#

use strict;
BEGIN{ unshift @INC, "../lib" };
use Test::Assertions qw(test);
use Log::Trace;
use Getopt::Std;
use File::Path;

use vars qw($opt_t $opt_T $opt_s $opt_b);
getopts("tTsb");

plan tests => 29;

#Move into the t directory
chdir($1) if($0 =~ /(.*)\/(.*)/);

#Compilation
require Sub::Slice::Backend::Filesystem;
ASSERT($INC{'Sub/Slice/Backend/Filesystem.pm'}, "Compiled Sub::Slice::Backend::Filesystem version $Sub::Slice::Backend::Filesystem::VERSION");

#Log::Trace
import Log::Trace qw(print) if($opt_t);
deep_import Log::Trace qw(print) if($opt_T);

#Control everything
my $path = "test_output/";
my $prefix = "prefix_";
my $mask_length = "10";
my $job_filename = "job.file";
rmtree($path,1); #ensure clean even if last run was -s
mkdir($path);

#Construction
my $obj = new Sub::Slice::Backend::Filesystem({
	prefix => $prefix, 
	unique_key_length => $mask_length, 
	job_filename => $job_filename,
	path => $path
});
ASSERT(ref $obj eq 'Sub::Slice::Backend::Filesystem', 'Constructor');

ASSERT($obj->default_path, "Uses a default path if path unspecificied");
ASSERT($obj->default_path("foo") eq "foo/", "appends / to path");

#Check ID allocation
my $id = $obj->new_id();
TRACE("id=$id");
ASSERT(scalar $id =~ /^$prefix\w{$mask_length}$/, "ID has expected form");
my $id2 = $obj->new_id();
TRACE("id2=$id2");
ASSERT($id2 ne $id, "IDs appear to change");

#Check save/load preserves state
my $job = new Sub::Slice($id);
TRACE("Job id:" . $job->id);
$obj->save_job($job);
my $loaded = $obj->load_job($id);
ASSERT( EQUAL( $loaded, $job ), "job persisted"); 

#Test blob functions
my $blob_data = "MyBlobData";
$obj->store_blob($job,"mykey",$blob_data);
$loaded = $obj->fetch_blob($job, "mykey");
ASSERT( EQUAL( $loaded, $blob_data ), "blob saved/restored"); 
$obj->store_blob($job,"mykey","");
$loaded = $obj->fetch_blob($job, "mykey");
ASSERT( EQUAL( $loaded, "" ), "blob overwritten"); 
ASSERT(!defined($obj->fetch_blob($job, 'nonexistant')), "fetch nonexistant blob");



#Check expected files are on the filesystem
my @jobs = <$path*>;
TRACE(@jobs);
ASSERT(scalar @jobs == 2, "expected number of job dirs");
my $jobdir = "$path/$job->{id}";
my %files = map {$_ => 1} <$jobdir/*>;
DUMP(\%files);
ASSERT($files{"$jobdir/$job_filename"}, "located job file in job dir");
ASSERT(scalar keys %files == 2, "expected number of files in job dir");

#Test deleting a job
$obj->delete_job($job->id);
@jobs = <$path*>;
ASSERT(scalar @jobs == 1, "job dir has gone");

#Create a new job for the rest of the tests
$job = new Sub::Slice($id2); 
$obj->save_job($job);

#Test strict and lax mode
my $obj2 = new Sub::Slice::Backend::Filesystem({
	prefix => $prefix, 
	unique_key_length => $mask_length - 1, 
	job_filename => $job_filename,
	path => $path,
});
ASSERT(DIED(sub { $obj2->load_job($id2) }) && $@ =~ /invalid/, "strict mode");

$obj2 = new Sub::Slice::Backend::Filesystem({
	prefix => $prefix, 
	unique_key_length => $mask_length - 1, 
	job_filename => $job_filename,
	path => $path,
	lax => 1
});
ASSERT($obj2->load_job($id2), "lax mode");


#
# Test some error conditions
#

my $nonexistant = $prefix.('x' x $mask_length);

ASSERT(
	DIED(sub{ $obj->load_job($nonexistant) }) && 
	(chomp $@, $@) =~ /can't open/
, "load nonexistant job");

ASSERT(
	DIED(sub{ $obj->delete_job($nonexistant) }) && 
	(chomp $@, $@) =~ /does not exist/i
, "del nonexistant job");

ASSERT(
	DIED(sub{ $obj->save_job(1) }) && 
	(chomp $@, $@) =~ /job should be a Sub::Slice object/
, "save invalid job");

ASSERT(
	DIED(sub{ $obj->store_blob(1,"key","value") }) && 
	(chomp $@, $@) =~ /job should be a Sub::Slice object/
, "store blob for invalid job");

ASSERT(
	DIED(sub{ $obj->fetch_blob(1,"key") }) && 
	(chomp $@, $@) =~ /job should be a Sub::Slice object/
, "fetch blob for invalid job");

ASSERT(
	DIED(sub{ $obj->load_job() }) && 
	(chomp $@, $@) =~ /without an id/
, "load missing id");

ASSERT(
	DIED(sub{ $obj->delete_job() }) && 
	(chomp $@, $@) =~ /without an id/
, "del missing id");

ASSERT(
	DIED(sub{ $obj->store_blob($job) }) && 
	(chomp $@, $@) =~ /you must supply a key/i
, "store without key");

ASSERT(
	DIED(sub{ $obj->fetch_blob($job) }) && 
	(chomp $@, $@) =~ /you must supply a key/i
, "fetch without key");

#
# Cleanup
#

# recreate $obj, since a cleanup will typically run as an occasional
# batch job
$obj = new Sub::Slice::Backend::Filesystem({path => $path});
ASSERT(ref $obj eq 'Sub::Slice::Backend::Filesystem', 'Constructor');

if (!$opt_s) {  
	my $cu = $obj->cleanup(-1); # 0 fails occasionally - floating point?
	# clock variability?
	ASSERT($cu == 2, "Cleanup removed right things");
	ASSERT(rmdir($path), "Cleanup left empty tree");
	rmtree($path);
	ASSERT(!defined $obj->cleanup(), "Cleanup undef on empty dir");
}
else { 
	for (my $i = 1; ($i <= 3); $i++) { 
		ASSERT(1, "cleanup skipped");
	};
};

#
# Package to emulate a Sub::Slice object
# All the backend should know about is that it has an id() method
#
package Sub::Slice;

sub new {
	my ($class, $id) = @_;
	return bless({id =>$id}, $class);	
}

sub id {
	my $self = shift;
	return $self->{id};
}

sub TRACE {}
sub DUMP {}

1;
