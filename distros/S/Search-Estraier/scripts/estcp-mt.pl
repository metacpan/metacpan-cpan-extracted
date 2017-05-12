#!/usr/bin/perl -w

use strict;
use Search::Estraier 0.06;
use URI::Escape qw/uri_escape/;
use Time::HiRes;
use POSIX qw/strftime/;
use Config;
use threads; 
use Thread::Queue;

=head1 NAME

estcp.pl - copy Hyper Estraier index from one node to another

=cut

die "Your perl isn't compiled with support for ithreads\n" unless ($Config{useithreads});


my ($from,$to) = @ARGV;

die "usage: $0 http://localhost:1978/node/from http://remote.example.com:1978/node/to\n" unless ($from && $to);

my $debug = 0;
my $max = 256;

# create and configure node
my $from_n = new Search::Estraier::Node(
	url => $from,
	croak_on_error => 1,
	debug => $debug,
	user => 'admin',
	passwd => 'admin',
);
my $to_n = new Search::Estraier::Node(
	url => $to,
	croak_on_error => 1,
	debug => $debug,
	user => 'admin',
	passwd => 'admin',
	create => 1,
	label => $from_n->label,
);

unless(eval{ $to_n->name }) {
	if ($to =~ m#^(http://.+)/node/([^/]+)$#) {
		my ($url,$name) = ($1,$2);
		print "Creating '$name' on $url\n";
		$to_n->shuttle_url( $url . '/master?action=nodeadd',
			'application/x-www-form-urlencoded',
			'name=' . uri_escape($name) . '&label=' . uri_escape( $name ),
			undef,
		);
	} else {
		die "can't extract node name from $to\n";
	}
}

# total processed elements
my $i : shared = 1;

my $q_id = Thread::Queue->new;
my $q_drafts = Thread::Queue->new;

my $get_thr = threads->new( sub {
	while (my $id = $q_id->dequeue) {
		#warn "get ", $id || 'undef',"\n";
		if ($id < 0) {
			$q_drafts->enqueue( '' );	# abort put thread
			last;
		};
		print STDERR "get_thr, id: $id\n" if ($debug);
		my $doc_draft = $from_n->_fetch_doc( id => $id, chomp_resbody => 1 );
		$q_drafts->enqueue( $doc_draft );
	}
} );

my $t = time();
my $t_refresh = time();
my $doc_num = $from_n->doc_num || 1;

my $put_thr = threads->new( sub {
	while (my $doc_draft = $q_drafts->dequeue) {
		last unless ($doc_draft);
		print STDERR "put_thr, $doc_draft\n" if ($debug);
		$to_n->shuttle_url( $to_n->{url} . '/put_doc', 'text/x-estraier-draft', $doc_draft, undef) == 200 or die "can't insert $doc_draft\n";

		$i++;
		if (time() - $t_refresh > 3) {
			my $rate = ( $i / ((time() - $t) || 1) );
			printf("%d records, %1.2f%% [%1.2f rec/s] estimated finish: %s\n",
				$i,
				($i * 100 / $doc_num),
				$rate, 
				strftime("%Y-%m-%d %H:%M:%S", localtime( time() + int(($doc_num-$i) / $rate))),
			);
			$t_refresh = time();
		}

	}
} );

print "Copy from ",$from_n->name," (",$from_n->label,") to ",$to_n->name," (",$to_n->label,") - ",$from_n->doc_num," documents (",$from_n->word_num," words, ",$from_n->size," bytes)\n";

my $prev;
my $more = 1;

while($more) {
	my $res;
	$from_n->shuttle_url( $from_n->{url} . '/list',
		'application/x-www-form-urlencoded',
		'max=' . $max . ( $prev ? '&prev=' . uri_escape( $prev ) : '' ),
		\$res,
	);
	if (! $res || $res eq '') {
		$more = 0;
		last;
	}
	foreach my $l (split(/\n/,$res)) {
		(my $id, $prev) = split(/\t/,$l, 2);

		#$to_n->put_doc( $from_n->get_doc( $id ));

		#my $doc_draft = $from_n->_fetch_doc( id => $id, chomp_resbody => 1 );
		#$to_n->shuttle_url( $to_n->{url} . '/put_doc', 'text/x-estraier-draft', $doc_draft, undef) == 200 or die "can't insert $doc_draft\n";

		$q_id->enqueue( $id );
	}
	warn "$prev\n" if ($debug);

}
$q_id->enqueue( -1 );	# last one

$get_thr->join;
$put_thr->join;

printf "Copy of %d records completed [%1.2f rec/s]\n", $i, 
	( $i / ((time() - $t) || 1) );

