# $Id: transactionTest.pm,v 1.1.1.1 2004/11/22 19:16:02 owensc Exp $

package Myco::Foo::TxTest;

use Myco;

our $entity_class = "Myco::Foo";

use Myco::Foo;

use base qw(Test::Unit::TestCase Myco::Test::TxTestLib2);
our $simple_accessor = do{my $x="\$${entity_class}::simple_accessor";eval $x;};
use strict;
use warnings;

sub new {
    my $self = shift;
    my $fixture = $self->init_fixture(@_);
    $fixture->{myco}{class} = $entity_class;
    $fixture->{myco}{accessor} = $simple_accessor;
    return $fixture;
}

sub set_up {
    my $self = shift;
    $self->help_set_up(@_);
}

sub tear_down {
    my $self = shift;
    $self->help_tear_down(@_);
}


1;
