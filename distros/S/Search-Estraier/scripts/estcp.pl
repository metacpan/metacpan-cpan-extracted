#!/usr/bin/perl -w

use strict;
use Search::Estraier 0.06;
use URI::Escape qw/uri_escape/;
use Time::HiRes;
use POSIX qw/strftime/;

=head1 NAME

estcp.pl - copy Hyper Estraier index from one node to another

=cut

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

print "Copy from ",$from_n->name," (",$from_n->label,") to ",$to_n->name," (",$to_n->label,") - ",$from_n->doc_num," documents (",$from_n->word_num," words, ",$from_n->size," bytes)\n";

my $doc_num = $from_n->doc_num || 1;

my $prev;
my $i = 0;
my $more = 1;

my $t = time();

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

		my $doc_draft = $from_n->_fetch_doc( id => $id, chomp_resbody => 1 );
		$to_n->shuttle_url( $to_n->{url} . '/put_doc', 'text/x-estraier-draft', $doc_draft, undef) == 200 or die "can't insert $doc_draft\n";

		$i++;
	}
	warn "$prev\n" if ($debug);

	my $rate = ( $i / (time() - $t) );
	printf("%d records, %1.2f%% [%1.2f rec/s] estimated finish: %s\n",
		$i,
		($i * 100 / $doc_num),
		$rate, 
		strftime("%Y-%m-%d %H:%M:%S", localtime( time() + int(($doc_num-$i) / $rate))),
	);

}

print "Copy completed.\n";

