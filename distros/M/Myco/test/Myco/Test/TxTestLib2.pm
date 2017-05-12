# $Id: TxTestLib2.pm,v 1.1.1.1 2004/11/22 19:16:05 owensc Exp $
#
# module - Myco::Test::TxTestLib
#
#     include in all transaction test classes (via 'use')

package Myco::Test::TxTestLib2;

use base qw(Myco::Test::Fodder2);

sub test_create {
    my $test = shift;

    my $id;
    my $simple_accessor = $test->{myco}{accessor};
    {
	$test->assert(defined(my $obj =
		                $test->{myco}{class}
		                   ->create($simple_accessor => "XMPG")));
	eval {
	       $id = Myco->storage->id($obj); 
	       Myco->unload($obj);
	   };
    }
    $test->assert($id);
    # Object should not be in transient storage
    $test->assert(! exists Myco->storage->{objects}{$id});
    my $obj2;
    eval { $obj2 = Myco->storage->load($id); };
    $test->assert(defined $obj2);
    $test->assert($obj2->$simple_accessor eq "XMPG");
    push @{ $test->{erase_targets} }, $obj2;
}


sub test_fetch_all {
    my $test = shift;

    my $simple_accessor = $test->{myco}{accessor};
    my $class = $test->{myco}{class};
    my $obj1 = $class->create;
    my $obj2 = $class->create;
    push @{ $test->{erase_targets} }, $obj1, $obj2;

    my $cursor = $class->fetch_all;
    $test->assert( $cursor->isa('Tangram::Cursor') );
    $test->assert( $cursor->current->isa($class)  );

    my $set = Set::Object->new(@{[ $class->fetch_all ]});
    $test->assert( $set->includes($obj1, $obj2) );
}


1;
