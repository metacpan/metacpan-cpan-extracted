#!perl
use strict;
use warnings;
use lib qw(./lib t/lib);

use Test::More 0.94;
use Test::Exception;
use Test::Warnings;


use Neo4j::Error;
use Neo4j_Test::ErrorNoSource;
use Devel::StackTrace;

plan tests => 8 + 1;

my ($e, $v);


subtest 'new source/class' => sub {
	plan tests => 4 * 4;
	ok $e = Neo4j::Error->new(Server => {raw=>11}), 'new 1';
	isa_ok $e, 'Neo4j::Error::Server', 'class Server';
	is $e->source(), 'Server', 'source Server';
	is $e->{raw}, 11, 'params 1';
	ok $e = Neo4j::Error->new(Network => {raw=>12}), 'new 2';
	isa_ok $e, 'Neo4j::Error::Network', 'class Network';
	is $e->source(), 'Network', 'source Network';
	is $e->{raw}, 12, 'params 2';
	ok $e = Neo4j::Error->new(Internal => {raw=>13}), 'new 3';
	isa_ok $e, 'Neo4j::Error::Internal', 'class Internal';
	is $e->source(), 'Internal', 'source Internal';
	is $e->{raw}, 13, 'params 3';
	ok $e = Neo4j::Error->new(Usage => {raw=>14}), 'new 4';
	isa_ok $e, 'Neo4j::Error::Usage', 'class Usage';
	is $e->source(), 'Usage', 'source Usage';
	is $e->{raw}, 14, 'params 4';
};


subtest 'new source/class subclass' => sub {
	plan tests => 4 * 4;
	ok $e = Neo4j::Error::Server->new(Server => {raw=>21}), 'new 1';
	isa_ok $e, 'Neo4j::Error::Server', 'class Server';
	is $e->source(), 'Server', 'source Server';
	is $e->{raw}, 21, 'params 1';
	ok $e = Neo4j::Error::Network->new(Network => {raw=>22}), 'new 2';
	isa_ok $e, 'Neo4j::Error::Network', 'class Network';
	is $e->source(), 'Network', 'source Network';
	is $e->{raw}, 22, 'params 2';
	ok $e = Neo4j::Error::Internal->new(Internal => {raw=>23}), 'new 3';
	isa_ok $e, 'Neo4j::Error::Internal', 'class Internal';
	is $e->source(), 'Internal', 'source Internal';
	is $e->{raw}, 23, 'params 3';
	ok $e = Neo4j::Error::Usage->new(Usage => {raw=>24}), 'new 4';
	isa_ok $e, 'Neo4j::Error::Usage', 'class Usage';
	is $e->source(), 'Usage', 'source Usage';
	is $e->{raw}, 24, 'params 4';
};


subtest 'new with string instead of hashref' => sub {
	plan tests => 2 * 3;
	ok $e = Neo4j::Error->new(Internal => 'string'), 'new';
	isa_ok $e, 'Neo4j::Error::Internal', 'param Internal';
	is $e->as_string(), 'string', 'as_string';
	ok $e = Neo4j::Error::Internal->new(Internal => 'subclass'), 'new subclass';
	is $e->source(), 'Internal', 'source Internal';
	is $e->as_string(), 'subclass', 'as_string subclass';
};


subtest 'new source/class errors' => sub {
	plan tests => 10;
	$e = bless {}, 'Neo4j::Error';
	throws_ok {
		$e->new(Server => {});
	} qr/\binstance method\b.* unsupported\b/i, 'instance method';
	throws_ok {
		Neo4j::Error->new(foo => {});
	} qr/\bfoo\b.* unsupported\b/i, 'unknown source';
	throws_ok {
		Neo4j::Error->new(server => {});
	} qr/\bServer\b.* unsupported\b/i, 'wrong case source';
	throws_ok {
		Neo4j::Error->new('Server');
	} qr/\bHash ?ref\b/i, 'params missing';
	throws_ok {
		Neo4j::Error->new(Server => $e);
	} qr/\bHash ?ref\b/i, 'params no hashref';
	throws_ok {
		Neo4j::Error->new(Server => {}, 'extra');
	} qr/\bToo many arguments\b/i, 'extra args';
	throws_ok {
		Neo4j::Error->new({});
	} qr/\bSource\b.* required\b/i, 'no source';
	throws_ok {
		Neo4j::Error->new();
	} qr/\bSource\b.* required\b/i, 'params and source missing';
	throws_ok {
		Neo4j_Test::ErrorNoSource->new(Internal => {});
	} qr/\bfails to implement source\b/i, 'subclass missing source method';
	throws_ok {
		Neo4j::Error::Server->new(Internal => {});
	} qr/\bAmbiguous source\b/i, 'subclass ambiguous source';
};


subtest 'stack trace' => sub {
	plan tests => 7 + 4 + 2 + 2;
	my $can_message = eval { Devel::StackTrace->VERSION('2.03') };
	
	ok $e = Neo4j::Error->new(Internal => {}), 'new no config';
	isa_ok $e->trace(), 'Devel::StackTrace', 'trace';
	ok $v = $e->trace->frame(0), 'trace frame';
	is $v->line(), __LINE__ - 3, 'trace line';
	is $v->filename(), __FILE__, 'trace file';
	is $v->subroutine(), 'Neo4j::Error::new', 'trace sub';
	SKIP: { skip 'Devel::StackTrace < 2.03', 1 unless $can_message;
		is $e->trace->message(), undef, 'trace no message';
	}
	
	$v = { skip_frames => -1 };
	ok $e = Neo4j::Error->new(Internal => {trace => $v}), 'new config 1';
	ok $v = $e->trace->frame(0), 'trace up frame';
	like $v->filename(), qr{\bNeo4j/Error\.pm$}, 'trace up file';
	is $v->subroutine(), 'Devel::StackTrace::new', 'trace up sub';
	
	$v = { message => 'foo' };
	ok $e = Neo4j::Error->new(Internal => {trace => $v}), 'new config 2';
	SKIP: { skip 'Devel::StackTrace < 2.03', 1 unless $can_message;
		is $e->trace->message(), 'foo', 'trace config message';
	}
	
	ok $e = Neo4j::Error->new(Internal => {as_string => 'bar'}), 'new as_string';
	SKIP: { skip 'Devel::StackTrace < 2.03', 1 unless $can_message;
		is $e->trace->message(), 'bar', 'trace as_string message';
	}
};


subtest 'related' => sub {
	plan tests => 9;
	ok $e = Neo4j::Error->new(Internal => 'param undef'), 'new 1';
	ok $e = Neo4j::Error->new(Usage => {
		related => $e,
		as_string => 'Undefined parameter not supported',
	}), 'new 2';
	is $e->source(), 'Usage', 'primary source Usage';
	is $e->as_string(), 'Undefined parameter not supported', 'primary as_string';
	ok $e = $e->related, 'primary related';
	is $e->source(), 'Internal', 'next source Internal';
	is $e->as_string(), 'param undef', 'next as_string';
	my @r = $e->related;
	ok ! defined $r[0], 'no next related';
	is scalar(@r), 1, 'no related returns scalar in list context';
};


subtest 'append_new' => sub {
	plan tests => 4 + 4 + 7 + 2;
	
	ok $e = Neo4j::Error->append_new(Server => {raw=>31}), 'new direct';
	isa_ok $e, 'Neo4j::Error::Server', 'direct class server';
	is $e->{raw}, 31, 'params 1';
	is $e->related(), undef, 'no related 1';
	
	ok $e = Neo4j::Error::Internal->append_new(Internal => {raw=>32}), 'new subclass';
	isa_ok $e, 'Neo4j::Error::Internal', 'subclass class internal';
	is $e->{raw}, 32, 'params 2';
	is $e->related(), undef, 'no related 2';
	
	ok $v = $e->append_new(Usage => {raw=>33}), 'new related';
	is $v, $e, 'append returns self';
	is $e->{raw}, 32, 'params 2 redux';
	ok $v = $e->related(), 'related 2';
	isa_ok $v, 'Neo4j::Error::Usage', 'related class usage';
	is $v->{raw}, 33, 'params 3';
	is $v->related(), undef, 'no related 3';
	
	ok $e = Neo4j::Error->append_new(Internal => '34'), 'new with string';
	is $e->as_string, '34', 'as_string';
};


subtest 'append_new errors' => sub {
	plan tests => 8;
	$e = 'Neo4j::Error';
	throws_ok {
		$e->append_new(foo => {});
	} qr/\bfoo\b.* unsupported\b/i, 'unknown source';
	throws_ok {
		$e->append_new(server => {});
	} qr/\bServer\b.* unsupported\b/i, 'wrong case source';
	throws_ok {
		$e->append_new('Server');
	} qr/\bHash ?ref\b/i, 'params missing';
	throws_ok {
		$e->append_new(Server => []);
	} qr/\bHash ?ref\b/i, 'params no hashref';
	throws_ok {
		$e->append_new(Server => {}, 'extra');
	} qr/\bToo many arguments\b/i, 'extra args';
	throws_ok {
		Neo4j::Error::Internal->append_new({});
	} qr/\bSource\b.* required\b/i, 'no source';
	throws_ok {
		Neo4j::Error::Internal->append_new(Server => {});
	} qr/\bAmbiguous source\b/i, 'ambiguous source';
	throws_ok {
		Neo4j::Error::Internal->append_new();
	} qr/\bSource\b.* required\b/i, 'params and source missing';
};


done_testing;
