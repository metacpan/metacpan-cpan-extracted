use Coro;
use EV;
use Coro::EV;
use Data::Dumper;
use strict;
use Benchmark ':all';
use blib;
use Coro::AnyEvent;

# this is for testing that module doesn't segfault when lot of parallel requests working


use MongoDB::Async;
my $dba = MongoDB::Async::Connection->new({"host" => "mongodb://127.0.0.1", ssl => 1 })->test->test;


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
	undf => undef,
	
	_id => 0
};

$dba->drop();

my $numofdoc = 50;
for(0...$numofdoc){
	$dba->save($doc); $doc->{_id}++;
}

$|=1;
my $reads = 0;
my $writes = 0;
# async {
	# while(1){
		
		
		# Coro::AnyEvent::sleep 1;
	# }
# };

new_threads() for 1...100;
sub new_threads {
	print "$reads reads and $writes writes\r";
	async {
		while(){
			my $db = MongoDB::Async::Connection->new({"host" => "mongodb://127.0.0.1" });
			
			for (1..2){
				$db->get_database('test')->get_collection( 'test' )->find({})->all;
				$reads++;
				print "$reads reads and $writes writes. Ready coros: ".Coro::nready."\r";
			}
		}
		
	};
}




EV::loop;