use v5.12;
use strict;
use warnings;
use Benchmark 'cmpthese';

BEGIN {
	package Local::Standard;
	use Moose;
	
	has n        => ( is => 'ro', isa => 'Int',      required => 1 );
	has children => ( is => 'ro', isa => 'ArrayRef', lazy => 1, builder => '_build_children' );
	has sum      => ( is => 'ro', isa => 'Int',      lazy => 1, builder => '_build_sum' );
	
	sub _build_children {
		my $self = shift;
		return [] if $self->n < 1;
		
		my @kids = map {
			my $n = $_;
			__PACKAGE__->new( n => $n );
		} 0 .. $self->n - 1;
		return \@kids;
	}
	
	sub _build_sum {
		my $self = shift;
		
		my $sum = $self->n;
		$sum += $_->sum for @{ $self->children };
		
		return $sum;
	}
	
	__PACKAGE__->meta->make_immutable;
};

BEGIN {
	package Local::XS;
	use Moose;
	use MooseX::XSAccessor;
	use MooseX::XSConstructor;
	use Types::Common -types;
		
	has n        => ( is => 'ro', isa => Int,      required => 1 );
	has children => ( is => 'ro', isa => ArrayRef, lazy => 1, builder => '_build_children' );
	has sum      => ( is => 'ro', isa => Int,      lazy => 1, builder => '_build_sum' );
	
	sub _build_children {
		my $self = shift;
		return [] if $self->n < 1;
		
		my @kids = map {
			my $n = $_;
			__PACKAGE__->new( n => $n );
		} 0 .. $self->n - 1;
		return \@kids;
	}
	
	sub _build_sum {
		my $self = shift;
		
		my $sum = $self->n;
		$sum += $_->sum for @{ $self->children };
		
		return $sum;
	}

	__PACKAGE__->meta->make_immutable;
};

for my $pkg ( qw/ Local::Standard Local::XS / ) {
	for my $meth ( qw/ new n children sum / ) {
		printf(
			"%-25s %2s\n",
			"${pkg}::${meth}",
			MooseX::XSConstructor::is_xs( \&{"${pkg}::${meth}"} )
				? 'XS'
				: 'PP',
		);
	}
}

print "----\n";

cmpthese -5, {
	Standard => q{ Local::Standard->new( n => 5 )->sum },
	XS       => q{ Local::XS->new( n => 5 )->sum },
};

__END__
Local::Standard::new      PP
Local::Standard::n        PP
Local::Standard::children PP
Local::Standard::sum      PP
Local::XS::new            XS
Local::XS::n              XS
Local::XS::children       PP
Local::XS::sum            PP
----
            Rate Standard       XS
Standard  6392/s       --     -43%
XS       11228/s      76%       --