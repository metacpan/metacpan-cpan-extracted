package Tangram::Expr::QueryObject;

use strict;
use Tangram::Expr::Filter;
use Carp;
use Set::Object qw(set);

sub new
{
    # $obj is a Tangram::Expr::RDBObject
	my ($pkg, $obj) = @_;
	bless $obj->expr_hash(), $pkg;
}

sub object
{
	shift->{_object}
}

sub table_ids
{
	shift->{_object}->table_ids()
}

sub class
{
	shift->{_object}{class}
}

sub eq
{
	my ($self, $other) = @_;

	if (!defined($other))
	{
	    # XXX - not reached by test suite
		$self->{id} == undef
	}
	elsif ($other->isa('Tangram::Expr::QueryObject'))
	{
		$self->{id} == $other->{id}
	}
	else
	{
		my $other_id = $self->{_object}{storage}->id($other)
			or confess "'$other' is not a persistent object";
		$self->{id} == $self->{_object}{storage}->export_object($other)
	}
}

# XXX - not tested by test suite
sub is_kind_of
{
	my ($self, $class) = @_;

	my $object = $self->{_object};
	my $root = $object->{tables}[0][1];
	my $storage = $object->{storage};

	Tangram::Expr::Filter->new(
						 expr => "t$root.$storage->{class_col} IN (" . join(', ', $storage->_kind_class_ids($class) ) . ')',
						 tight => 100,
						 objects => Set::Object->new( $object ) );
}


# XXX - not tested by test suite
sub in
{
	my $self = shift;

	my $object = $self->{_object};
	my $root = $object->{tables}[0][1];
	my $storage = $object->{storage};

	my $objs = Set::Object->new();

	while ( my $item = shift ) {
	    if ( ref $item eq "ARRAY" ) {
		$objs->insert(@$item);
	    } elsif ( UNIVERSAL::isa($item, "Set::Object") ) {
		if ( $objs->size ) {
		    $objs->insert($item->members);
		} else {
		    $objs = $item;
		}
	    } else {
		$objs->insert($item);
	    }
	}

	my $expr;
	if ( $objs->size ) {
	    $expr = ("t$root.$storage->{id_col} IN ("
		     . join(', ',
			    # FIXME - what about table aliases?  Hmm...
			    map { $storage->export_object($_) }
			    $objs->members )
		     . ')');
	} else {
	    # hey, you never know :)
	    $expr = ("t$root.$storage->{id_col} IS NULL");
	}

	Tangram::Expr::Filter->new(
			     expr => $expr,
			     tight => 100,
			     objects => Set::Object->new( $object )
			    );

}

sub expr
{
  shift->{id}{expr}
}


sub count
{
  my ($self, $val) = @_;

  # $DB::single = 1;

  Tangram::Expr->new(Tangram::Type::Integer->instance,
		     "COUNT(" . $self->{id}{expr} . ")",
		     $self->{id}->objects,
		     );

}

# XXX - not tested by test suite
sub is_null
{
    my $self = shift;
    Tangram::Expr::Filter->new
	    ( expr => "$self->{id}{expr} IS NULL",
	      tight => 100,
	      objects => set($self->{id}->objects),
	    );

}

use overload
    "==" => \&eq, "!=" => \&ne,
    "!" => \&is_null,
    fallback => 1;

1;
