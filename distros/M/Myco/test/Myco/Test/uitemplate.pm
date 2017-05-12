# $Id: uitemplate.pm,v 1.1.1.1 2004/11/22 19:16:05 owensc Exp $
#
# module - Myco::Test::uitemplate
#
#     include in all ui test classes (via 'use')

use Myco::Test::Fodder;

#sub test_new_bogus_args {
#	my $self = shift;
#	eval { $uiclass->new(foo => "blah"); };
#	$self->assert($@);
#}

#sub test_create {
#    my $self = shift;
#    my $Tx = $uiclass->new;
#    my ($id, $obj2);
#    {
#	$self->assert(my $obj = $Tx->create($simple_accessor => "XMPG"));
#	eval { $id = Myco->storage->id($obj); };
#    }
#    $self->assert($id);
#    $self->assert(! exists Myco->storage->{classes}{$id});
#    eval { $obj2 = Myco->storage->load($id); };
#    $self->assert($obj2);
#    $self->assert($obj2->$simple_accessor eq "XMPG");
#    push @{ $self->{erase_targets} }, $obj2;
#}
#
1;
