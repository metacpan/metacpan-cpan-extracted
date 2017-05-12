#!perl 
use strict;
use warnings;
use Test::More tests => 1;

# use Data::Dumper;
# $Data::Dumper::Terse = 1;
# $Data::Dumper::Indent = 0;

use FindBin;
use lib "$FindBin::RealBin/../blib/lib";        # fails under -T
use Search::WuManber;


# /usr/src/linux/Documentation/ManagementStyle
my $text = qq( 
		Linux kernel management style

		This is a short document describing the preferred (or made up, depending
		on who you ask) management style for the linux kernel.  It's meant to
		mirror the CodingStyle document to some degree, and mainly written to
		avoid answering (*) the same (or similar) questions over and over again. 

		Management style is very personal and much harder to quantify than
		simple coding style rules, so this document may or may not have anything
		to do with reality.  It started as a lark, but that doesn't mean that it
		might not actually be true. You'll have to decide for yourself.

		Btw, when talking about "kernel manager", it's all about the technical
		lead persons, not the people who do traditional management inside
		companies.  If you sign purchase orders or you have any clue about the
		budget of your group, you're almost certainly not a kernel manager. 
		These suggestions may or may not apply to you. 
);

my @list = qw(Management DISTRIBUTIVE Algorithm equation Persons emEnt somebody suddenly dangerous preemptive decision person style);

my $search = Search::WuManber->new(\@list, { case_sensitive => 0 });
$search->{return_string}++;

# warn Dumper $search->all($text);

my $expected = [['17',0,'Management'],['22',5,'emEnt'],['28',12,'style'],['128',0,'Management'],['133',5,'emEnt'],['139',12,'style'],['201',12,'style'],['333',0,'Management'],['338',5,'emEnt'],['344',12,'style'],['358',11,'person'],['416',12,'style'],['697',11,'person'],['697',4,'Persons'],['740',0,'Management'],['745',5,'emEnt']];
is_deeply($search->all($text), $expected, "ManagementStyle words");
