use lib  qw(../blib/lib ../blib/lib/auto );
use strict;
use warnings;
use Data::Dumper;

use Test::More qw(no_plan);
use File::Temp qw(tempfile);

use RDF::Core::Model;
use RDF::Core::Model::Parser;
use RDF::Core::Storage::Memory;
use RDF::Core::Storage::DB_File;
use RDF::Core::Storage::Postgres;

my $one_labels	= <<"END";
<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF
	xmlns="http://kr.newco.com/test.owl#"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:owl="http://www.w3.org/2002/07/owl# "
	xml:base="http://kr.newco.com/test.owl"
	>
	<owl:Ontology rdf:about=""/>
	<owl:Class rdf:ID="Restaurants_fctsont_restaurantsF"> 
		<rdfs:label xml:lang="fr">Restaurants</rdfs:label>
	</owl:Class>
</rdf:RDF>
END

my $two_labels	= <<"END";
<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF
	xmlns="http://kr.newco.com/test.owl#"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:owl="http://www.w3.org/2002/07/owl# "
	xml:base="http://kr.newco.com/test.owl"
	>
	<owl:Ontology rdf:about=""/>
	<owl:Class rdf:ID="Restaurants_fctsont_restaurantsF"> 
		<rdfs:label xml:lang="en">Restaurants</rdfs:label>
		<rdfs:label xml:lang="fr">Restaurants</rdfs:label>
	</owl:Class>
</rdf:RDF>
END



my @storage	= (
		   ['Memory', sub { return (RDF::Core::Storage::Memory->new(), sub{}) }],
		   ['DB_File', sub {
			my ($fh, $filename) = tempfile();
			return (RDF::Core::Storage::DB_File->new( Name => $filename ), sub { unlink $filename });
		    }],
		   ['Postgres', sub{
			my $s = new RDF::Core::Storage::Postgres
			  ( ConnectStr=>'dbi:Pg:dbname=rdf',
			    DBUser=>'postgres',
			    Model=>'rdf-test-01',
			  );
			sub cleanup {
			    #warn "cleaning up...\n";
			    my $s = shift;
			    my $enum = $s->getStmts();
			    my $stmt = $enum->getNext;
			    while (defined $stmt) {
				$s->removeStmt($stmt);
				$stmt = $enum->getNext;
			    }
			}
			cleanup($s);
			return ($s,\&cleanup);
		    }],
		  );
my @labels	= (
		   [ $one_labels, 1, 3, [ qw(fr) ] ],
		   [ $two_labels, 2, 4, [ qw(en fr) ] ],
		  );


my $subj	= RDF::Core::Resource->new( 'http://kr.newco.com/test.owl#Restaurants_fctsont_restaurantsF' );
my $pred	= RDF::Core::Resource->new( 'http://www.w3.org/2000/01/rdf-schema#label' );

STORAGE:
foreach my $storage_data (@storage) {
    my ($storage_name, $storage_factory)	= @{ $storage_data };
    warn "\n# $storage_name\n";
    foreach my $data (@labels) {
	my ($source, $label_count, $st_count, $langs)	= @$data;
	my %langs	= map { $_ => 1 } @$langs;
	
	my ($storage, $storage_cleanup);
	eval {($storage, $storage_cleanup) = &$storage_factory};
	if (! $storage) {
	    warn "$storage_name NOT available, skipping tests...\n";
	    next STORAGE;
	}
	my $model	= new RDF::Core::Model (Storage => $storage);
	my $parser	= new RDF::Core::Model::Parser (
							Model		=> $model,
							Source		=> $source,
							SourceType	=> 'string',
							BaseURI		=> "http://www.foo.com/",
							BNodePrefix	=> 'genid',
						       );
	
	isa_ok( $parser, 'RDF::Core::Model::Parser' );
	
	is( $model->countStmts( undef, undef, undef ), 0, 'expected empty model' );
	$parser->parse;
	is( $model->countStmts( undef, undef, undef ), $st_count, 'expected statement count' );
	is( $model->countStmts( $subj, $pred, undef ), $label_count, 'expected label count from countStmts' );
	
	
	foreach my $lang (keys %langs) {
	    my $literal	= RDF::Core::Literal->new( 'Restaurants', $lang );
	    is( $model->countStmts( undef, undef, $literal ), 1, 'expected statement count from countStmts with language-typed literal' );
	    
	    
	    my $count	= 0;
	    my $enum	= $model->getStmts( undef, undef, $literal );
	    my $st		= $enum->getNext;
	    while (defined $st) {
		$count++;
		$st = $enum->getNext;
	    }
	    $enum->close;
	    is( $count, 1, 'expected statement count from getStmts with language-typed literal' );
	    
	    
	}
	
	my $count	= 0;
	my $enum	= $model->getStmts($subj, $pred, undef);
	my $st		= $enum->getNext;
	while (defined $st) {
	    my $literal	= $st->getObject;
	    my $lang	= $literal->getLang;
	    ok( exists( $langs{ $lang } ), "expected language: $lang" );
	    delete $langs{ $lang };
	    $count++;
	    $st = $enum->getNext;
	}
	$enum->close;
	is( $count, $label_count, 'expected label count' );
	my @keys	= keys %langs;
	is( scalar(@keys), 0, 'found all expected languages' );
	
	$storage_cleanup->($storage);
    }
}	




