=head1 NAME

Pangloss::Application::TermEditor - term editor app for Pangloss.

=head1 SYNOPSIS

  use Pangloss::Application::TermEditor;
  my $editor = new Pangloss::Application::TermEditor();

  my $view0 = $editor->list();
  my $view1 = $editor->list_status_codes();
  my $view2 = $editor->add( $term );
  my $view3 = $editor->get( $key );
  my $view4 = $editor->modify( $key, $new_term );
  my $view5 = $editor->modify_status( $key, $new_status );
  my $view6 = $editor->remove( $key );

=cut

package Pangloss::Application::TermEditor;

use strict;
use warnings::register;

use Error qw( :try );

use Pangloss::Terms;
use Pangloss::Term::Error;
use Pangloss::StoredObject::Error;

use base qw( Pangloss::Application::CollectionEditor );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.7 $ '))[2];

use constant object_name      => 'term';
use constant objects_name     => 'terms';
use constant collection_name  => 'terms';
use constant collection_class => 'Pangloss::Terms';

sub list_status_codes {
    my $self = shift;
    my $view = shift || new Pangloss::Application::View;
    $view->{status_codes} = Pangloss::Term::Status->status_codes;
    return $view;
}

sub modify_status {
    my $self       = shift;
    my $key        = shift;
    my $status     = shift;
    my $view       = shift || new Pangloss::Application::View;
    my $collection = $self->get_or_create_collection;
    my $name       = $self->object_name;

    try {
	# there must be a collection element to modify
	my $term = $collection->get( $key );

	# save the current object incase there's an error
	$view->{modify}->{$name} = $term->clone;

	$status->date( time );
	# TODO:
	#$status->validate;

	$term->status->copy( $status );

	$self->save( $term );

	$view->{modify}->{$name} = $term->clone;
	$view->{modify}->{$name}->status->{modified} = 1;
    } catch Pangloss::StoredObject::Error with {
	$view->{modify}->{$name}->{error} = shift;
    };

    $view->{$name} = $view->{modify}->{$name};

    return $view;
}

sub error_key_exists {
    my $self = shift;
    my $key  = shift;
    throw Pangloss::Term::Error( flag => eExists,
				 name => $key );
}

1;


__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class implements a term editor application for Pangloss.

Inherits from L<Pangloss::Application::CollectionEditor>.

=head1 METHODS

=over 4

=item $view = $obj->list_status_codes( [ $view ] )

sets $view->{status_codes} to a hash of available status codes:

  pending
  approved
  rejected
  deprecated

=item $view = $obj->modify_status( $key, $status [, $view ] );

modifies the status of the term specified by $key, and sets $view->{term}
$view->{modify}->{term}, $view->{term}->status->{modified}.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>, L<Pangloss::Term>, L<Pangloss::Term::Status>

=cut
