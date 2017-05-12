# $Id: template.pm,v 1.1.1.1 2004/11/22 19:16:05 owensc Exp $
#
# module - Myco::Test::entity
#
#     include in all entity test classes (via 'use')

sub test_new_empty {
	my $self = shift;
	$self->assert(defined $class->new);
}

sub test_new_bogus_args {
	my $self = shift;
	eval { $class->new(foo => "blah"); };
	$self->assert($@);
}

sub test_accessor {
	my $self = shift;
        my $obj = $class->new;
        my $simple_setter = 'set_'.$simple_accessor;
	$self->assert($obj->$simple_accessor ne "Test");
	$obj->$simple_setter("Test");
	$self->assert($obj->$simple_accessor eq "Test");
}

1;
