package Template::Direct::SubPage;

use base Template::Direct::Page;
use Template::Direct;

use strict;
use warnings;

=head1 NAME

Template::Direct::SubPage - Handle a sub page load

=head1 DESCRIPTION

  Provide support for loading other templates from the current template.

=head1 METHODS

=cut

use Carp;

=head2 I<$class>->new( $index, $line )

  Create a new instance object.

=cut
sub new {
	my ($class, $index, $location, %p) = @_;
	my $self = $class->SUPER::new(undef, %p);
	$self->{'startTag'} = $index;
	$self->{'Location'} = $location;
	return $self;
}

=head2 $object->compile( )

  Modifies a template with the data listed correctly.

=cut
sub compile {
	my ($self, $data, $template, %p) = @_;
	return if ref($template) ne 'SCALAR';
	my $section = $self->getContents( $data );

	# Mark the section as being processed
	$self->getLocation( $template, $self->{'startTag'} );

	# Set the section in the Location
	$self->setSection($template, $section);
}

=head2 I<$page>->getContents( $data )

  Returns the compiled template by loading the file
  and passing the right scoped data to it.

=cut
sub getContents {
	my ($self, $data) = @_;
	if(not $self->{'content'}) {
		$self->{'content'} = $self->loadTemplate();
		chomp($self->{'content'});
	}
	return $self->SUPER::compile( $data );
}

=head2 I<$page>->loadTemplate( )

  Load a Template object with the location of the sub page.

=cut
sub loadTemplate {
	my ($self) = @_;
	my $newdoc = Template::Direct->new(
		Directory => $self->{'Directory'},
		Location  => $self->{'Location'},
	);
	return $newdoc->load( Language => $self->{'Language'} );
}

=head1 AUTHOR

  Martin Owens - Copyright 2007, AGPL

=cut
1;
