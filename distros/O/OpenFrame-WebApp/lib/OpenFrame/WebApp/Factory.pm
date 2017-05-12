=head1 NAME

OpenFrame::WebApp::Factory - abstract factory class

=head1 SYNOPSIS

  # abstract class - must override to use
  use OpenFrame::WebApp::Factory::Foo;

  my $factory = new OpenFrame::WebApp::Factory::Foo()->type('bar');

  my $obj = $factory->new_object( @args );

=cut

package OpenFrame::WebApp::Factory;

use strict;
use warnings::register;

use Error;
use OpenFrame::WebApp::Error::Abstract;
use OpenFrame::WebApp::Error::LoadClass;

use base qw ( OpenFrame::Object );

our $VERSION = (split(/ /, '$Revision: 1.5 $'))[1];

sub type {
    my $self = shift;
    if (@_) {
	$self->{object_type} = shift;
	$self->error( "warning: $self->{object_type} has no known class!" )
	  unless ($self->get_types_class);
	return $self;
    } else {
	return $self->{object_type};
    }
}

sub get_types_class {
    my $self = shift;
    throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );
}

sub new_object {
    my $self = shift;
    return $self->load_types_class->new( @_ );
}

sub load_types_class {
    my $self  = shift;
    my $class = $self->get_types_class;
    unless ( $class->can( 'new' ) ) {
	eval "require $class;";
	throw OpenFrame::WebApp::Error::LoadClass( -text => $@ ) if ($@);
    }
    return $class;
}

1;

__END__

=head1 DESCRIPTION

The C<OpenFrame::WebApp::Factory> class is an abstract implementation of the
factory design pattern.  On creating a new factory you can specify the type of
object it should create.  Then you can ask the factory to create new objects
of this type for you.

=head1 METHODS

=over 4

=item $obj->type

set/get object type.  this is usually a mnemonic string, but it could even be
a class name.  how C<type> is interpreted depends on the implementation.

=item $class = $obj->get_types_class()

I<abstract> method to get the class associated with type().

=item $class = $obj->load_types_class()

load the class associated with type() if it has no C<new()> method.  throws
L<OpenFrame::WebApp::Error::LoadClass> if there was a problem loading the
class.

=item $new_obj = $obj->new_object( ... )

creates a new object of the apprpriate class.  passes all arguments on to the
new() method in this class.  tries to load the types class first.

=back

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame::WebApp>

=cut
