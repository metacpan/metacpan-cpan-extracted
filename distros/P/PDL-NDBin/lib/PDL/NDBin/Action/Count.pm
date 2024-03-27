package PDL::NDBin::Action::Count;
# ABSTRACT: Action for PDL::NDBin that counts elements
$PDL::NDBin::Action::Count::VERSION = '0.027';

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
			type => { type => OBJECT, isa => 'PDL::Type', default => defined(&PDL::indx) ? PDL::indx() : PDL::long }
		} );
	return bless $self, $class;
}


sub process
{
	my $self = shift;
	my $iter = shift;
	my $out = $self->{out} //= PDL->zeroes( $self->{type}, $self->{N} );
	my $idx = $iter->idx;
	$_ = $out->zeroes for grep !defined || (ref && $_->isnull), $idx;
	my $data = $iter->data;
	$_ = $idx->zeroes for grep !defined || (ref && $_->isnull), $data;
	PDL::NDBin::Actions_PP::_icount_loop( $data, $idx, $self->{out}, $self->{N} );
	# as the plugin processes all bins at once, every variable
	# needs to be visited only once
	$iter->var_active( 0 );
	return $self;
}


sub result
{
	my $self = shift;
	return $self->{out};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PDL::NDBin::Action::Count - Action for PDL::NDBin that counts elements

=head1 VERSION

version 0.027

=head1 DESCRIPTION

This class implements an action for PDL::NDBin.

=head1 METHODS

=head2 new()

	my $instance = PDL::NDBin::Action::Count->new(
		N    => $N,
		type => indx,   # default
	);

Construct an instance for this action. Requires the number of bins $N as input.
Optionally allows the type of the output ndarray to be set (defaults to
I<indx>).

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

This software is copyright (c) 2024 by Edward Baudrez.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
