#!/usr/bin/perl -w

use ExtUtils::testlib;
use Net::Z3950::SimpleServer;
use Net::Z3950::OID;
use Net::Z3950::GRS1;
use strict;


sub dump_hash {
	my $href = shift;
	my $key;

	foreach $key (keys %$href) {
		printf("%10s	=>	%s\n", $key, $href->{$key});
	}
}


sub my_init_handler {
	my $args = shift;
	my $session = {};

	$args->{IMP_NAME} = "DemoServer";
	$args->{IMP_VER} = "3.14159";
	$args->{ERR_CODE} = 0;
	$args->{HANDLE} = $session;
}

sub my_search_handler { 
	my $args = shift;
	my $data = [{
			name		=>	"Peter Dornan",
			title		=>	"Spokesman",
			collaboration	=>	"ATLAS"
	    	    }, {
			name		=>	"Jorn Dines Hansen",
			title		=>	"Professor",
			collaboration	=>	"HERA-B"
	    	    }, {
			name		=>	"Alain Blondel",
			title		=>	"Head of coll.",
			collaboration	=>	"ALEPH"
	   	    }];

	my $session = $args->{HANDLE};
	my $set_id = $args->{SETNAME};
	my @database_list = @{ $args->{DATABASES} };
	my $query = $args->{QUERY};
	my $hits = 3;

	print "------------------------------------------------------------\n";
	print "Processing query : $query\n";
	printf("Database set     : %s\n", join(" ", @database_list));
	print "Setname          : $set_id\n";
	print "------------------------------------------------------------\n";

	$args->{HITS} = $hits;
	$session->{$set_id} = $data;
	$session->{__HITS} = $hits;
}


sub my_fetch_handler {
	my $args = shift;
	my $session = $args->{HANDLE};
	my $set_id = $args->{SETNAME};
	my $data = $session->{$set_id};
	my $offset = $args->{OFFSET};
	my $grs1 = new Net::Z3950::GRS1;
	my $grs2 = new Net::Z3950::GRS1;
	my $grs3 = new Net::Z3950::GRS1;
	my $grs4 = new Net::Z3950::GRS1;
	my $field;
	my $record;
	my $hits = $session->{__HITS};
	my $href = $data->[$offset - 1];

	$args->{REP_FORM} = Net::Z3950::OID::grs1;
	foreach $field (keys %$href) {
		$grs1->AddElement(1, $field, &Net::Z3950::GRS1::ElementData::String, $href->{$field});
	}
	$grs4->AddElement(4,1, &Net::Z3950::GRS1::ElementData::String, "Level 4");
	$grs4->AddElement(4,2, &Net::Z3950::GRS1::ElementData::String, "Lige et felt mere");
	$grs3->AddElement(3,1, &Net::Z3950::GRS1::ElementData::String, "Mit navn er Svend Gønge");
	$grs3->AddElement(3,1, &Net::Z3950::GRS1::ElementData::Subtree, $grs4);
	$grs3->AddElement(3,1, &Net::Z3950::GRS1::ElementData::String, "Og det er bare dejligt");
	$grs2->AddElement(2,1, &Net::Z3950::GRS1::ElementData::Subtree, $grs3);
	$grs2->AddElement(2,2, &Net::Z3950::GRS1::ElementData::String, "Underfelt");
	$grs1->AddElement(1, 'subfield', &Net::Z3950::GRS1::ElementData::Subtree, $grs2);
	$grs1->AddElement(1, 10, &Net::Z3950::GRS1::ElementData::String, 'Imle bimle bumle');
	$grs1->Render(POOL => \$record);
	$args->{RECORD} = $record;
	if ($offset == $session->{__HITS}) {
		$args->{LAST} = 1;
	}
}


my $handler = new Net::Z3950::SimpleServer( 
		INIT	=>	\&my_init_handler,
		SEARCH	=>	\&my_search_handler,
		FETCH	=>	\&my_fetch_handler );

$handler->launch_server("ztest.pl", @ARGV);


## $Log: grs_test.pl,v $
## Revision 1.2  2001-09-11 13:07:07  sondberg
## Minor changes.
##
## Revision 1.1  2001/03/13 14:19:28  sondberg
## Added a modified version of ztest.pl called grs_test.pl, which shows how to
## implement support of GRS-1 record syntax.
##

