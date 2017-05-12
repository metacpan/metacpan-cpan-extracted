#!/usr/bin/perl -w

use strict;
use Search::Estraier 0.06;
use DBI;
use Data::Dumper;
use Encode qw/from_to/;
use Time::HiRes qw/time/;
use Getopt::Long;

=head1 NAME

dbi-indexer.pl - example indexer of DBI sources for Search::Estraier

=cut

my $c = {
	node_url => 'http://localhost:1978/node/dbi-template1',
	dbi => 'Pg:dbname=template1',
	dbuser => 'postgres',
	sql => qq{
		select * from pg_database
	},
	pk_col => 'datname',
	db_encoding => 'iso-8859-2',
	debug => 0,
	estuser => 'admin',
	estpasswd => 'admin',
	quiet => 0,
};

GetOptions($c, qw/node_url=s dbi=s sql=s pk_col=s eb_encoding=s debug+ quiet+ estuser=s estpasswd=s dbuser=s dbpasswd=s/);

warn "# c: ", Dumper($c) if ($c->{debug});

# create and configure node
my $node = new Search::Estraier::Node(
	url => $c->{node_url},
	user => $c->{estuser},
	passwd => $c->{estpasswd},
	croak_on_error => 1,
	create => 1,
	debug => $c->{debug} >= 4 ? 1 : 0,
);

# create DBI connection
my $dbh = DBI->connect("DBI:$c->{dbi}", $c->{dbuser}, $c->{dbpasswd}) || die $DBI::errstr;

my $sth = $dbh->prepare($c->{sql}) || die $dbh->errstr();
$sth->execute() || die $sth->errstr();

warn "# columns: ",join(",",@{ $sth->{NAME} }),"\n" if ($c->{debug});

my $total = $sth->rows;
my $i = 1;

my $t = time();
my $pk_col = $c->{pk_col} || 'id';

while (my $row = $sth->fetchrow_hashref() ) {

	warn "# row: ",Dumper($row) if ($c->{debug} >= 3);

	# create document
	my $doc = new Search::Estraier::Document;

	if (my $id = $row->{$pk_col}) {
		$doc->add_attr('@uri', $id);
	} else {
		die "can't find pk_col column '$pk_col' in results\n";
	}

	my $out = '';
	$out .= sprintf("%4d ",$i);

	while (my ($col,$val) = each %{$row}) {

		if ($val) {
			# change encoding?
			from_to($val, ($c->{db_encoding} || 'ISO-8859-1'), 'UTF-8');

			# add attributes (make column usable from attribute search)
			$doc->add_attr($col, $val);

			# add body text to document (make it searchable using full-text index)
			$doc->add_text($val);

			$out .= "R";
		} else {
			$out .= ".";
		}

	}

	warn "# doc draft: ",$doc->dump_draft, "\n" if ($c->{debug} >= 2);

	die "error: ", $node->status,"\n" unless (eval { $node->put_doc($doc) });

	printf ("%s %d%% %.1f/s\n", $out, int(( $i++ / $total) * 100), ( $i / (time() - $t) ) ) unless ($c->{quiet});

}
