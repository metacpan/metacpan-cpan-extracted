package Tangram::Expr::Select;

use strict;
use Tangram::Expr::Filter;
use Carp;

use vars qw(@ISA);
 @ISA = qw( Tangram::Expr );

sub new
{
	my ($type, %args) = @_;

	my $cols = join ', ', map
	{
		confess "column specification must be a Tangram::Expr" unless $_->isa('Tangram::Expr');
		$_->expr;
	} @{$args{cols}};

	my $filter = $args{filter} || $args{where} || Tangram::Expr::Filter->new;

	my $objects = Set::Object->new();

	if (exists $args{from})
	{
	    # XXX - not tested by test suite
		$objects->insert( map { $_->object } @{ $args{from} } );
	}
	else
	{
		$objects->insert( $filter->objects(), map { $_->objects } @{ $args{cols} } );
		$objects->remove( @{ $args{exclude} } ) if exists $args{exclude};
	}

	my $from = join ', ', map { $_->from } $objects->members;

	my $where = join ' AND ',
		$filter->expr ? "(".$filter->expr.")" : (),
			map { $_->where } $objects->members;

	my $sql = "SELECT";
	$sql .= ' DISTINCT' if $args{distinct};
	$sql .= "  $cols";
	if (exists $args{order}) {
	    # XXX - not tested by test suite
	    $sql .= join("", map {", $_"}
			 grep { $sql !~ m/ \Q$_\E(?:,|$)/ }
			 map { $_->expr } @{$args{order}});
	}
	$sql .= "\nFROM $from" if $from;
	$sql .= "\nWHERE $where" if $where;

	if (exists $args{order})
	{
		$sql .= "\nORDER BY " . join ', ', map { $_->expr } @{$args{order}};
	}

	my $self = $type->SUPER::new(Tangram::Type::Integer->instance, "($sql)");
	
	$self->{cols} = $args{cols};

	return $self;
}

# XXX - not tested by test suite
sub from
{
	my ($self) = @_;
	my $from = $self->{from};
	return $from ? $from->members : $self->SUPER::from;
}

# XXX - not tested by test suite
sub where
{
}

sub execute
{
	my ($self, $storage, $conn) = @_;
	return Tangram::Cursor::Data->open($storage, $self, $conn);
}


1;
