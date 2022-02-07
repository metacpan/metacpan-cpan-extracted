package PDL::NDBin::Action::Avg;
# ABSTRACT: Action for PDL::NDBin that computes average
$PDL::NDBin::Action::Avg::VERSION = '0.024';

use strict;
use warnings;
use PDL::Lite;		# do not import any functions into this namespace
use PDL::NDBin::Actions_PP;
use Params::Validate qw( validate OBJECT SCALAR );


sub new
{
	my $class = shift;
	my $self = validate( @_, {
			N    => { type => SCALAR, regex => qr/^\d+$/ },
			type => { type => OBJECT, isa => 'PDL::Type', default => PDL::double }
		} );
	return bless $self, $class;
}


sub process
{
	my $self = shift;
	my $iter = shift;
	$self->{out} = PDL->zeroes( $self->{type}, $self->{N} ) unless defined $self->{out};
	$self->{count} = PDL->zeroes( defined(&PDL::indx) ? PDL::indx() : PDL::long, $self->{N} ) unless defined $self->{count};
	my $data = $iter->data;
	my $idx = $iter->idx;
	$_ = PDL->zeroes( 0 ) for grep $_->isnull, $data, $idx;
	PDL::NDBin::Actions_PP::_iavg_loop( $data, $idx, $self->{out}, $self->{count}, $self->{N} );
	# as the plugin processes all bins at once, every variable
	# needs to be visited only once
	$iter->var_active( 0 );
	return $self;
}


sub result
{
	my $self = shift;
	$self->{out}->inplace->_setnulltobad( $self->{count} );
	return $self->{out};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PDL::NDBin::Action::Avg - Action for PDL::NDBin that computes average

=head1 VERSION

version 0.024

=head1 DESCRIPTION

This class implements an action for PDL::NDBin.

=head1 METHODS

=head2 new()

	my $instance = PDL::NDBin::Action::Avg->new(
		N    => $N,
		type => double,   # default
	);

Construct an instance for this action. Requires the number of bins $N as input.
Optionally allows the type of the output variable to be specified (defaults to
I<double>).

=head2 process()

	$instance->process( $iter );

Run the action with the given iterator $iter. This action will compute all bins
during the first call and will subsequently deactivate the variable.

=head2 result()

	my $result = $instance->result;

Return the result of the computation.

=head1 AUTHOR

Edward Baudrez <ebaudrez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Edward Baudrez.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
