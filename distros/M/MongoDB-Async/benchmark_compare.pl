
use Coro;
use EV;
use Coro::EV;
use Data::Dumper;
use strict;
use Benchmark ':all';
use blib;

use MongoDB::Async;
my $dba = MongoDB::Async::Connection->new({"host" => "mongodb://localhost"})->test->test;

use MongoDB;
my $db = MongoDB::Connection->new({"host" => "mongodb://localhost"})->test->test;

my $doc = {
	"somename1" => "somedatasomedatasomedatasomedatasomedata",
	"somename2" => "somedatasomedatasomedatasomedatasomedata",
	"somename3" => "somedatasomedatasomedatasomedatasomedata",
	"somename4" => "somedatasomedatasomedatasomedatasomedata",
	"somename5" => "somedatasomedatasomedatasomedatasomedata",
	array => [
		"somedatasomedatasomedatasomedatasomedata",
		"somedatasomedatasomedatasomedatasomedata",
		"somedatasomedatasomedatasomedatasomedata",
		"somedatasomedatasomedatasomedatasomedata",
		"somedatasomedatasomedatasomedatasomedata",
		{}
	],
	
	hash => {
		"somename1" => "somedatasomedatasomedatasomedatasomedata",
		"somename2" => "somedatasomedatasomedatasomedatasomedata",
		"somename3" => "somedatasomedatasomedatasomedatasomedata",
		"somename4" => "somedatasomedatasomedatasomedatasomedata",
		"somename5" => "somedatasomedatasomedatasomedatasomedata",
	},
	
	_id => 0
};




use Benchmark ':all';
async { # use thread and run EV. You can use MongoDB::Async not in Coro threads, but it's ineffective, because coro must run EV every time you waiting for data.
	
	print "Save 20000 docs\n";
	cmpthese ( 20000, {

		'MongoDB::Async save' => sub {$dba->save($doc); $doc->{_id}++ },		
		'MongoDB save' => sub {$db->save($doc); $doc->{_id}++ },
				
	});

	print "\nGet 20000 docs\n";
	cmpthese ( 3, {
	
		# 'MongoDB::Async data' => sub { @{$dba->find()->data}; }, # ->all inplemented as    sub all {@{shift->data}}
		'MongoDB::Async all ' => sub { $dba->find()->all; },
		'MongoDB all' => sub {$db->find()->all;},
		
	});
	
	print "\nGet 100 docs\n";
	cmpthese ( 2000, {
	
		# 'MongoDB::Async data' => sub { @{$dba->find({ _id => [1...50]})->data}; },
		'MongoDB::Async all ' => sub { $dba->find({ _id => [1...100]})->all; },
		'MongoDB all' => sub {$db->find({ _id => [1...100]})->all;},
		
	});
	
	print "\nGet 1 doc\n";
	cmpthese ( 10000, {
		'MongoDB::Async find_one' => sub {$dba->find_one({_id => int(rand 20000)});},
		'MongoDB find_one' => sub {$db->find_one({_id => int(rand 20000)});},
	});
			
	
};	

EV::loop;