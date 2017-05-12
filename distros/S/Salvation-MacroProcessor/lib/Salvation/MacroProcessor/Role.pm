use strict;

package Salvation::MacroProcessor::Role;

use Moose::Role;

sub smp_spec
{
	my $self = shift;

	require Salvation::MacroProcessor::Spec;

	return Salvation::MacroProcessor::Spec -> parse_and_new(
		$self,
		\@_
	);
}

sub smp_select
{
	return shift -> smp_spec( @_ ) -> select();
}

sub smp_check
{
	my $self = shift;

	return $self -> smp_spec( @_ ) -> check( $self );
}

no Moose::Role;

-1;

__END__

# ABSTRACT: A role with most common methods for L<Salvation::MacroProcessor>-enabled classes

=pod

=head1 NAME

Salvation::MacroProcessor::Role - A role with most common methods for L<Salvation::MacroProcessor>-enabled classes

=head1 DESCRIPTION

=head2 Example usage

 package MyClass;

 use Moose;

 with 'Salvation::MacroProcessor::Role';

 no Moose;

=head1 REQUIRES

L<Moose> 

=head1 METHODS

=head2 smp_spec

 $object -> smp_spec( @query );

This method is a shorcut for:

 require Salvation::MacroProcessor::Spec;

 Salvation::MacroProcessor::Spec -> parse_and_new( $object, \@query );

=head2 smp_check

 $object -> smp_check( @query );

This method is a shortcut for:

 $object -> smp_spec( @query ) -> check( $object );

=head2 smp_select

 $object -> smp_select();

This method is a shortcut for:

 $object -> smp_spec( @query ) -> select();

=cut

