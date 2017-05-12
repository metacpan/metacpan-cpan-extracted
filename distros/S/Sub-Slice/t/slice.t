#!/usr/local/bin/perl -w

###############################################################################
# Purpose : Unit test for Sub::Slice
# Author  : Simon Flack, John Alden and Tim Sweetman
# Created : Jan 2003
# CVS     : $Header: /home/cvs/software/cvsroot/sub_slice/t/slice.t,v 1.18 2005/11/23 14:31:51 colinr Exp $
###############################################################################
# -t : trace
# -T : deep trace
# -s : save output
###############################################################################

use strict;
use Test::Assertions 'test';
use Log::Trace;
use Getopt::Std;
use File::Path;

$|++;
use lib './lib', '../lib';
plan tests => 63;

my $path = 'test_output';
my %default_options = (storage_options => { path => $path });
rmtree($path,1); #ensure clean even if last run was -s

getopts('tTs', \my %opt);

#
# START OF TESTS
#

my $Ends = 0;

eval { require Sub::Slice; };
ASSERT(!$@ && $INC{'Sub/Slice.pm'}, "Sub::Slice compiles");
TRACE($INC{'Sub/Slice.pm'});

import Log::Trace 'print' if $opt{t};
deep_import Log::Trace 'print' if $opt{T};

my $token = make_token();
ASSERT( real_token($token),  "Create new token");
DUMP($token);
ASSERT($token->{estimate} == 10, "Set estimate");
ASSERT($token->{status} eq 'not run', "Set status");

my $last_total = 0;
for (1 .. 30) {
	my $total = eval { keep_going( $token ) };
	if (my $e = $@) {
		print STDERR 'Error --> ', $e, $/;
	}
	ASSERT( real_token($token)  && $total && $total ne $last_total,
			'running slice #' . $token->count );
	ASSERT($token->stage() =~ m/^(first_stage|second_stage|final)$/,"token has next_stage property");
	$last_total = $total;
	last if $token->done;
}

# test iterate=0
$token = make_token(0);
eval {keep_going($token)};
ASSERT($token->done() && $token->count() > 1, 'unlimited iterations - pass through in one op');
DUMP($token);

# check tampering is trapped
$token = make_token();
$token->{id} = 0;
ASSERT( DIED(sub { keep_going($token) } ), "dies when ID is tampered with");

$token = make_token();
$token->{pin} = 0;
ASSERT( DIED(sub { keep_going($token) } ), "dies when pin is tampered with");

ASSERT($Ends == 2, "right number of cleanup steps done");

#
# Some tests on the $job itself
#

my $job = new Sub::Slice( 
	%default_options, 
	iterations => 1, 
	backend => 'Sub::Slice::Backend::Filesystem',
	pin_length => 1e7,
	auto_blob_threshold => 5,
);
DUMP($job);

#Pin length
ASSERT(length $job->token->{pin} == 7, "pin length");

#Auto blob storage
$job->store('non-blob', '12345'); #At BLOB threshold
ASSERT(! defined ($job->fetch_blob('non-blob')), "short value not stored as blob");
$job->store('is-blob', '123456'); #Over BLOB threshold
ASSERT($job->fetch_blob('is-blob') eq '123456' && $job->fetch('is-blob') eq '123456', "long value auto stored as blob");

# Test job accessors
$job->set_estimate(10);
ASSERT($job->estimate() == 10, "estimate accessor");
ASSERT($job->count() eq '0', "count accessor");

# Input checking
ASSERT(DIED(sub{ $job->id(1) }), "id mutator check");
ASSERT(DIED(sub{ $job->token(1) }), "token mutator check");
ASSERT(DIED(sub{ $job->estimate(1) }), "estimate mutator check");
ASSERT(DIED(sub{ $job->count(1) }), "count mutator check");
ASSERT(DIED(sub{ $job->is_done(1) }), "is_done mutator check");
ASSERT(DIED(sub{ $job->stage(1) }), "stage mutator check");
ASSERT(DIED(sub{ $job->done(1) }), "done() args check");

ASSERT(DIED(sub{ $job->store(undef,1) }) && DIED(sub{ $job->store([],1) }), "store input checks");
ASSERT(DIED(sub{ $job->fetch() }) && DIED(sub{ $job->fetch([]) }), "fetch input checks");
ASSERT(DIED(sub{ $job->next_stage() }) && DIED(sub{ $job->next_stage([]) }), "next_stage input checks");

# Constructor validation
ASSERT(DIED(sub{
	new Sub::Slice( %default_options, iterations => 1, backend => 'Sub::Slice::Backend::Missing' );
}), "Non-existant backend raises an exception");

ASSERT(DIED(sub{
	new Sub::Slice( %default_options, iterations => 1, backend => 'Sub::Slice::Backend::..' );
}), "Illegal backend name raises an exception");

ASSERT(DIED(sub{
	new Sub::Slice( %default_options, token => "fribble" );
}), "Garbage for token #1");

ASSERT(DIED(sub{
	new Sub::Slice( %default_options, token => [] );
}), "Garbage for token #2");

ASSERT(DIED(sub{
	new Sub::Slice( "fribble" );
}), "odd number of arguments");

#
# END OF TESTS
#

#Cleanup
undef $job; #Needed to release any open files on win32
if($opt{s}){
	warn("output files saved in $path\n");
} else {
	rmtree($path);
}

###################################################################################

sub real_token {
	return $_[0] &&  UNIVERSAL::isa(shift, 'Sub::Slice::Token');
}

sub make_token {
	my $iterate = shift;
	$iterate = 1 unless defined $iterate;
	my $job = new Sub::Slice( %default_options, iterations => $iterate, backend => 'Filesystem' );
	$job->set_estimate(10);
	$job->status("not run");
	DUMP($job);
	return $job->token
}

sub keep_going {
	# rather bloated example...
	my $token = shift;

	# Check that this all works the same if the token has lost its
	# blessedness (which happens if you serialise using XML::Simple,
	# for example)
	# However, if we were to actually USE this $job, the counter
	# ends up stuck at 0 because we're relying on the blessed hash
	# that's kept in $token. That's probably not ideal,
	# because, as I understand it, no transport mechanism emulates
	# call-by-reference.
	my $job = new Sub::Slice (%default_options, token => {%$token});
	my $id_again = $job->token->{id};
	ASSERT($id_again, "token has ID");

	undef $job;
	$job = new Sub::Slice (%default_options, token => $token);
	my $id = $job->token->{id};
	ASSERT($id, "token has ID");
	ASSERT($id_again eq $id, "reblessing fetch works identically");


	at_start $job sub {
			$job->store('CODE', __PACKAGE__);
			$job->store('name', 'Simon Flack');
			$job->store('count', 0);
			$job->store('total', 0.1);
			$job->store_blob('data/foo.txt', "data");
		};
	at_stage $job 'first_stage',
		sub {
			$job->next_stage('second_stage');
			ASSERT($job->fetch('count') == 0, "check 0/undef distinction");
			$job->store('count', 1);
			my $file_data = $job->fetch_blob('data/foo.txt');
			die "file data missing or incorrect" unless $file_data eq 'data';
		};
	at_stage $job 'second_stage',
		sub {
			my $count = $job->fetch('count');
			$job->store('count', $count + 1);
			$job->next_stage('final') if $job->fetch('count') == 5;
		};
	at_stage $job 'never_happens',
		sub {
			die("Should never happen");
		};
	at_stage $job 'final',
		sub {
			my $name = $job->fetch('name');
			$job->done;
		};
	at_end $job
		sub {
			TRACE ("at_end");
			$job->status("ended");
			$Ends++;
		};

	$job->store('total', $job->fetch('count') + $job->fetch('total'));
	return $job->fetch('total');
}
