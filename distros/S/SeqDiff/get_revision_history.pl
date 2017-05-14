#!/usr/bin/perl -w 

use strict;
use LWP::UserAgent;
use URI::Escape;
use Getopt::Std;
use Data::Dumper;


# get things from the commandline
my %options;
getopt('i', \%options);
die ("usage:
$0
    -i [RefSeqID]
") unless ($options{'i'});

# create a user agent
my $ua = LWP::UserAgent->new;
$ua->agent('Get_Revision_History.pl/0.1 ');

# create a new request 
my $req = HTTP::Request->new(
	GET => 'http://www.ncbi.nlm.nih.gov/sviewer/girevhist.cgi?val=' . $options{'i'} . '&log$=seqview'
);

# pass request to the user agent
my $res = $ua->request($req);

# check the outcome
die( $res->status_line . "\n" ) unless ( $res->is_success );

# get all the matching identifiers
# my %files = $res->content =~ m/<a\s+href=".*?viewer.fcgi\?(\d+:\w+:\d+)">([^<]*?)<\/a>/g;

my $content = $res->content;
my @files = ();
while ( $content  =~ /viewer.fcgi\?(\d+:\w+:\d+)/gs ) {
	push @files, $1;
}


my $i = 0;
foreach my $id (@files) {	

	my $url = sprintf("http://www.ncbi.nlm.nih.gov/sviewer/viewer.fcgi?db=nuccore&qty=1&c_start=1&list_uids=%s&uids=&dopt=genbank&dispmax=5&sendto=t&fmt_mask=0&from=begin&to=end&extrafeatpresent=1&ef_MGC=16&ef_HPRD=32&ef_STS=64&ef_tRNA=128&ef_microRNA=256&ef_Exon=512", uri_escape($id));
	my $req = HTTP::Request->new(
		GET => $url
	);
	my $res = $ua->request( $req );
	
	if ( !$res->is_success ) {
		print STDERR "$id could not be downloaded.\n";
		next;	
	}
	
	mkdir( $options{'i'} );
	my $filename = sprintf("%s.%d.txt", $options{'i'}, $i);
	open( my $fh, '>', $options{'i'} . "/" . $filename) or die $1;
	print $fh $res->content . "\n";
	close $fh;
	
	print "created $filename\n";
	$i++;
}