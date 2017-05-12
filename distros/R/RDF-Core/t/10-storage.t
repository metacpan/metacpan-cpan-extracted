use lib  qw(../blib/lib ../blib/lib/auto );
use strict;
use warnings;
use Data::Dumper;

use Test::More qw(no_plan);
use File::Temp qw(tempfile);

use RDF::Core::Model;
use RDF::Core::Literal;
use RDF::Core::Storage::Memory;
use RDF::Core::Storage::DB_File;
use RDF::Core::Storage::Postgres;




my @storage = 
  ( ['Memory', sub { return (RDF::Core::Storage::Memory->new(), sub{}) }],
    ['DB_File', sub {
	 my ($fh, $filename) = tempfile();
	 return (RDF::Core::Storage::DB_File->new( Name => $filename ), sub { unlink $filename });
     }],
    ['Postgres', sub{
	 my $s = new RDF::Core::Storage::Postgres
	   ( ConnectStr=>'dbi:Pg:dbname=rdf', DBUser=>'postgres', Model=>'rdf-test-01');
	 sub cleanup {
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


my $subj = RDF::Core::Resource->new( 'http://kr.newco.com/test.owl#Restaurants_fctsont_restaurantsF' );
my $pred = RDF::Core::Resource->new( 'http://www.w3.org/2000/01/rdf-schema#label' );
my @obj = (RDF::Core::Literal->new("Restaurant"),
	   RDF::Core::Literal->new("Restaurant","en"),
	   RDF::Core::Literal->new("Restaurant","fr"),
	   RDF::Core::Literal->new("Restaurant",undef,"http://www.w3.org/2001/XMLSchema#string"),
	   RDF::Core::Literal->new("Restaurant","en","http://www.w3.org/2001/XMLSchema#string"),
	   RDF::Core::Literal->new("Restaurant","fr","http://www.w3.org/2001/XMLSchema#string"),
	  ); 

foreach my $storage_data (@storage) {
    my ($storage_name, $storage_factory)	= @{ $storage_data };
    warn "\n# $storage_name\n";
    
    my ($storage, $storage_cleanup);
    eval {($storage, $storage_cleanup) = &$storage_factory};
    if (! $storage) {
	warn "$storage_name NOT available, skipping tests...\n";
	next;
    }
    my $model = new RDF::Core::Model (Storage => $storage);

    # Empty model initiated ####################################################
    is ($model->existsStmt, 0, "empty model");
    
    my $cnt = 1;
    foreach (@obj) {
	$model->addStmt(new RDF::Core::Statement($subj, $pred, $_));
	is ($model->countStmts, $cnt, "countStmts raised to $cnt");
	is (get_and_count($model), $cnt, "getStmts count raised to $cnt");
	$cnt++;
    }

    # statements added #########################################################
    is ($model->existsStmt, 1, "not empty model (statements added)");


    $storage_cleanup->($storage);

}	

# TOOLS ########################################################################
sub get_and_count {
    my ($model, $sub, $pred, $obj) = @_;
    my $enum = $model->getStmts($sub, $pred, $obj);
    my $cnt = 0;
    while (defined $enum->getNext) {
	    $cnt++;
    }
    $enum->close;
    return $cnt;
}




