package Parse::Highlife::AST;

use strict;
use Parse::Highlife::Utils qw(params);

our $ASTElementCounter = 0;

sub new
{
	my( $class, @args ) = @_;
	my $self = bless {}, $class;
	return $self -> _init( @args );
}

sub _init
{
	my( $self, $category, $rulename, $value ) = @_;
	$ASTElementCounter ++;
	$self->{'category'} 	= $category;
	$self->{'id'} 				= $ASTElementCounter;
	$self->{'children'} 	= $value;
	$self->{'parent'} 		= undef;
	$self->{'parent-id'}	= 0;
	$self->{'rulename'} 	= $rulename;
	return $self;
}

# returns the first leaf value
sub value
{
	my( $self ) = @_;
	my @values = $self->values();
	return ( scalar @values ? $values[0] : '' );
}

# returns all leaf values
sub values
{
	my( $self ) = @_;
	my @values;
	if( $self->{'category'} eq 'leaf' ) {
		push @values, $self->{'children'};
	}
	else { # group
		map { push @values, $_->values() } @{$self->{'children'}};
	}
	return @values;
}

sub has_ancestor
{
	my( $self, $rulename ) = @_;
	return ref $self->ancestor( $rulename );
}

sub ancestor
{
	my( $self, $rulename ) = @_;
	my @asts = $self->ancestors( $rulename );
	return scalar @asts ? $asts[0] : 0;
}

sub ancestors
{
	my( $self, $rulename ) = @_;
	if( $self->{'rulename'} eq $rulename ) {
		return ($self);
	}
	elsif( $self->{'category'} eq 'group' ) {
		return map { $_->ancestors( $rulename ) } @{$self->{'children'}};
	}
	return ();
}

sub nth_child
{
	my( $self, $n ) = @_;
	if( $self->{'category'} eq 'group' ) {
		if( scalar @{$self->{'children'}} >= $n ) {
			return $self->{'children'}->[$n-1];
		}
		else {
			return 0;
		}
	}
	elsif( $self->{'category'} eq 'leaf' ) {
		return $self->{'children'};
	}
}

sub children
{
	my( $self ) = @_;
	if( $self->{'category'} eq 'group' ) {
		return @{$self->{'children'}};
	}
	return ();
}

sub first_child
{
	my( $self ) = @_;
	return $self->nth_child(1);
}

sub second_child
{
	my( $self ) = @_;
	return $self->nth_child(2);
}

sub third_child
{
	my( $self ) = @_;
	return $self->nth_child(3);
}

1;
