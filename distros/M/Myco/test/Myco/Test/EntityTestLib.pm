# $Id: EntityTestLib.pm,v 1.1.1.1 2005/12/09 18:08:47 sommerb Exp $
#
# module - Myco::Test::entity
#
#     include in all entity test classes (via 'use')

package Myco::Test::EntityTestLib;

use base qw(Test::Unit::TestCase);

sub init_fixture {
    my $self = shift()->SUPER::new(@_);
    return $self;
}

sub test_new_empty {
	my $self = shift;
	$self->assert(defined $self->{myco}{class}->new);
}

sub test_new_bogus_args {
	my $self = shift;
	eval { $self->{myco}{class}->new(foo => "blah"); };
	$self->assert($@);
}

sub test_accessor {
	my $self = shift;
        my $obj = $self->{myco}{class}->new;
	my $simple_accessor = $self->{myco}{accessor};
        my $simple_setter = 'set_'.$simple_accessor;
        my $simple_getter = 'get_'.$simple_accessor;
        my $val = $obj->$simple_getter;
        $val = '' unless defined $val;
	$self->assert($val ne "5551212");
	$obj->$simple_setter("5551212");
	$self->assert($obj->$simple_accessor eq "5551212");
}

1;
