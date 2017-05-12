use strict;

package Salvation::Service::OutputProcessor;

use Moose;

with 'Salvation::Roles::ServiceState', 'Salvation::Roles::SystemReference';

sub main
{
	my $self = shift;

	require Scalar::Util;
	require XML::Writer;
	require Salvation::Service::View::Stack::Convert::To::XML;

	my $data = $self -> state() -> view_output();

	if( Scalar::Util::blessed( $data ) and $data -> isa( 'Salvation::Service::View::Stack' ) )
	{
		$data = [ $data ];
	}

	my $writer = XML::Writer -> new(
		OUTPUT =>
			my $io = IO::String -> new(
				my $xml
			)
	);

	$writer -> xmlDecl( 'UTF-8' );

	$writer -> startTag( 'data' );

	if( ref( $data ) eq 'ARRAY' )
	{
		my $first = 1;

		foreach my $stack ( @$data )
		{
			Salvation::Service::View::Stack::Convert::To::XML -> parse( $stack, { writer => $writer, nocharset => 1 } );
		}
	}

	$writer -> endTag( 'data' );

	$io -> close();

	return $xml;
}

__PACKAGE__ -> meta() -> make_immutable();

no Moose;

-1;

# ABSTRACT: Base class for output processor engine

=pod

=head1 NAME

Salvation::Service::OutputProcessor - Base class for output processor engine

=head1 SYNOPSIS

 package YourSystem::Services::SomeService::Defaults::OutputProcessor;

 use Moose;

 extends 'Salvation::Service::OutputProcessor';

 no Moose;

=head1 REQUIRES

L<Moose> 

=head1 DESCRIPTION

=head2 Applied roles

L<Salvation::Roles::ServiceState>

L<Salvation::Roles::SystemReference>

=head1 METHODS

=head2 To be redefined

You can redefine following methods to achieve your own goals.

=head3 main

An actual output processing routine.
Should return any defined value which is suitable for your system. Also it is recommended to set this value to C<output> attribute of L<Salvation::Service::State> object instance.
The only argument is C<$self> which is current OutputProcessor's instance.

=cut

