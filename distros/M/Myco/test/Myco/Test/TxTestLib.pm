# $Id: TxTestLib.pm,v 1.1.1.1 2004/11/22 19:16:05 owensc Exp $
#
# module - Myco::Test::TxTestLib
#
#     include in all transaction test classes (via 'use')

use Myco::Test::Fodder2;

sub test_new_empty {
	my $self = shift;
	$self->assert(defined $txclass->new);
}

sub test_new_bogus_args {
	my $self = shift;
	eval { $txclass->new(foo => "blah"); };
	$self->assert($@);
}

sub test_create {
    my $self = shift;
    my $Tx = $txclass->new;
    my $id;
    {
	$self->assert(my $obj = $Tx->create($simple_accessor => "XMPG"));
	eval {
	       $id = Myco->storage->id($obj); 
	       Myco->unload($obj);
	   };
    }
    $self->assert($id);
    # Object should not be in transient storage
    $self->assert(! exists Myco->storage->{objects}{$id});
    my $obj2;
    eval { $obj2 = Myco->storage->load($id); };
    $self->assert($obj2);
    $self->assert($obj2->$simple_accessor eq "XMPG");
    push @{ $self->{erase_targets} }, $obj2;
}

1;
