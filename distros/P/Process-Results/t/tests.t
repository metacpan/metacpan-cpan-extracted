#!/usr/bin/perl -w
use strict;
BEGIN {$ENV{'PATH'} = ''}
BEGIN { if ($ENV{'AUTOCLEAR'}) { system('/usr/bin/clear') } }
# use lib '/home/miko/projects/IdocsLib/dev/trunk';
# use lib '/home/miko/projects/ShareLib/dev/trunk/lib';
use Process::Results ':all';
use JSON::Tiny 'decode_json';

# debug tools
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;
# println '[begin]';


#------------------------------------------------------------------------------
# purpose
#

=head1 Purpose

Test Process::Results.

=cut

#
# purpose
#------------------------------------------------------------------------------



###############################################################################
# MyHolder
#
package MyHolder;
use strict;
use Process::Results;
use base 'Process::Results::Holder';

# debug tools
# use Debug::ShowStuff ':all';


#------------------------------------------------------------------------------
# new
#
sub new {
	my ($class) = @_;
	my $holder = bless({}, $class);
	return $holder;
}
#
# new
#------------------------------------------------------------------------------


#
# MyHolder
###############################################################################



###############################################################################
# main
#
package main;
use strict;

# prepare for tests
use Test::Most;
$ENV{'IDOCSDEV'} and die_on_fail();
plan tests => 36;
my $name = 'Process::Results';


#------------------------------------------------------------------------------
## holder
#
if (1) {
	my ($holder, $results);
	my $n1 = "$name - holder";
	
	# holder
	$holder = MyHolder->new();
	isa_ok $holder, 'Process::Results::Holder', "$n1 - is a holder object";
	cmp_bool($holder->{'results'}, undef, "$n1 - no results");
	
	# results
	$results = $holder->results();
	isa_ok $results, 'Process::Results', "$n1 - is a results object";
	isa_ok $holder->{'results'}, 'Process::Results', "$n1 - is a results object";
	
	# results() should return same object
	# cmp_ok "$results", $holder->results() . '', "$n1 - results() should return same object";
	cmp_ok "$results", 'eq', $holder->results() . '', "$n1 - results() should return same object";
	
	# error
	$holder->error('error-1');
	cmp_ok $results->{'errors'}->[0]->{'id'}, 'eq', 'error-1', "$n1 - error()";
	
	# warning
	$holder->warning('warning-1');
	cmp_ok $results->{'warnings'}->[0]->{'id'}, 'eq', 'warning-1', "$n1 - warning()";
	
	# note
	$holder->note('note-1');
	cmp_ok $results->{'notes'}->[0]->{'id'}, 'eq', 'note-1', "$n1 - note()";
}
#
# holder
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## new
#
if (1) { ##i
	my $results = Process::Results->new();
	isa_ok $results, 'Process::Results', "$name - new";
}
#
# new
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## messages
#
if (1) { ##i
	my ($results, $msg, $subsub, $id);
	my $subname = "$name - messages";
	
	## error
	if (1) { ##i
		$subsub = "$subname - error";
		$id = 'my-error';
		$results = Process::Results->new();
		$msg = $results->error($id);
		cmp_ok $msg->{'id'}, 'eq', $id, "$subsub - object";
		cmp_ok $results->{'errors'}->[0]->{'id'}, 'eq', $id, "$subsub - array";
		cmp_bool($results->success, 0, $subsub);
	}
	
	## warning
	if (1) { ##i
		$subsub = "$subname - warning";
		$id = 'my-warning';
		$results = Process::Results->new();
		$msg = $results->warning($id);
		cmp_ok $msg->{'id'}, 'eq', $id, "$subsub - object";
		cmp_ok $results->{'warnings'}->[0]->{'id'}, 'eq', $id, "$subsub - array";
		cmp_bool($results->success, 1, $subsub);
	}
	
	## note
	if (1) { ##i
		$subsub = "$subname - note";
		$id = 'my-note';
		$results = Process::Results->new();
		$msg = $results->note($id);
		cmp_ok $msg->{'id'}, 'eq', $id, "$subsub - object";
		cmp_ok $results->{'notes'}->[0]->{'id'}, 'eq', $id, "$subsub - array";
		cmp_bool($results->success, 1, $subsub);
	}
}
#
# messages
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## implicit success|failure
#
if (1) {
	my ($results, $subsub);
	my $subname = "$name - implicit success|failure";
	
	## success
	$subsub = "$subname - success";
	$results = Process::Results->new();
	cmp_bool($results->success, 1, $subsub);
	cmp_bool($results->failure, 0, $subsub);
	
	## failure
	$subsub = "$subname - failure";
	$results = Process::Results->new();
	$results->error('a');
	cmp_bool($results->success, 0, $subsub);
	cmp_bool($results->failure, 1, $subsub);
}
#
# implicit success|failure
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## explicit success property
#
if (1) { ##i
	my ($results, $subsub);
	my $subname = "$name - explicit success";
	
	## success
	$subsub = "$subname - success";
	$results = Process::Results->new();
	$results->{'success'} = 1;
	$results->error('my-error');
	cmp_bool($results->success, 1, $subsub);
	cmp_bool($results->failure, 0, $subsub);
	
	## failure
	$subsub = "$subname - success";
	$results = Process::Results->new();
	$results->{'success'} = 0;
	cmp_bool($results->success, 0, $subsub);
	cmp_bool($results->failure, 1, $subsub);
}
#
# explicit success property
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# from existing results object
#
if (1) {
	my ($r_org, $r_new);
	
	# create initial results object, set a property
	$r_org = Process::Results->new();
	$r_org->{'details'} = {'a'=>123};
	
	# create new results object
	$r_new = Process::Results->new(results=>$r_org);
	
	# should have same a detail
	cmp_ok
		$r_org->{'details'}->{'a'},
		'eq',
		$r_new->{'details'}->{'a'},
		"$name - from existing results object";
}
#
# from existing results object
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## from json
#
if (1) { ##i
	my ($subname, $rand, $json, $results);
	$subname = "$name - from json";
	
	# generate random string
	$rand = rand();
	$rand =~ s|^.*\.||s;
	
	# build raw json
	$json = <<"(JSON)";
{
	"success":true,
	"details" : {
		"rand" : "$rand"
	}
}
(JSON)
	
	# TESTING
	# showvar $json;
	
	## create results object from json
	$results = Process::Results->new(json=>$json);
	
	## should have details
	cmp_ok $results->{'details'}->{'rand'}, 'eq', $rand, "$subname - details";
	
	## should be successful
	cmp_bool($results->success, 1, "$subname - successful");
}
#
# from json
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## to json
#
if (1) { ##i
	my ($subname, $results, $json, $decoded);
	$subname = "$name - to json";
	
	## create results object
	$results = Process::Results->new();
	$results->error('a');
	
	# get json
	$json = $results->json;
	
	# decode json
	$decoded = JSON::Tiny::decode_json($json);
	
	# compare deeply
	is_deeply(
		$decoded,
		$results,
		$subname,
	);
}
#
# to json
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
## default success
#
if (1) {
	my ($results);
	
	# create results object from json
	$results = Process::Results->new();
	
	# should be failed
	cmp_bool($results->success, 1, "$name - default success");
}
#
# default success
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## set success in instantiation
#
if (1) {
	my ($results);
	
	# create results object from json
	$results = Process::Results->new(success=>0);
	
	# should be failed
	cmp_bool($results->success, 0, "$name - fail");
}
#
# set success in instantiation
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## succeed, unsucceed
#
if (1) {
	my ($results);
	
	# create results object from json
	$results = Process::Results->new();
	
	# add error
	$results->error('a');
	
	# succeed
	$results->succeed();
	
	# should be successful
	cmp_bool($results->success, 1, "$name - succeed");
	
	# unsucceed
	$results->unsucceed();
	cmp_bool($results->success, 0, "$name - succeed");
}
#
# succeed, unsucceed
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## fail, unfail
#
if (1) {
	my ($results);
	
	# create results object from json
	$results = Process::Results->new();
	
	# succeed
	$results->fail();
	
	# should be failed
	cmp_bool($results->success, 0, "$name - fail");
	
	# unfail
	$results->fail();
	cmp_bool($results->success, 1, "$name - unfail");
}
#
# fail
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## json
#
if (1) {
}
#
# json
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# done
# The following code is purely for a home grown testing system. It has no
# purpose outside of my own system. -Miko
#
if ($ENV{'IDOCSDEV'}) {
	require FileHandle;
	FileHandle->new('> /tmp/regtest-done.txt') or die "unable to open check file: $!";
	print "[done]\n";
}
#
# done
#------------------------------------------------------------------------------


#
# main
###############################################################################


###############################################################################
# subs
#


#------------------------------------------------------------------------------
# cmp_bool
#
sub cmp_bool {
	my ($a, $b, $msg);
	$a = $a ? 1 : 0;
	$b = $b ? 1 : 0;
	return cmp_ok $a, '==', $b, $msg;
}
#
# cmp_bool
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# cmp_def
#
sub cmp_def {
	my ($a, $b, $msg);
	$a = defined($a) ? 1 : 0;
	$b = defined($b) ? 1 : 0;
	return cmp_ok $a, '==', $b, $msg;
}
#
# cmp_def
#------------------------------------------------------------------------------



#
# subs
###############################################################################

