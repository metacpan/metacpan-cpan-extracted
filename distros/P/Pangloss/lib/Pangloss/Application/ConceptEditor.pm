=head1 NAME

Pangloss::Application::ConceptEditor - concept editor app for Pangloss.

=head1 SYNOPSIS

  use Pangloss::Application::ConceptEditor;
  my $editor = new Pangloss::Application::ConceptEditor();

  my $view0 = $editor->list();
  my $view1 = $editor->add( $concept );
  my $view2 = $editor->get( $conceptid );
  my $view3 = $editor->update( $conceptid, $concept );
  my $view4 = $editor->remove( $conceptid );

=cut

package Pangloss::Application::ConceptEditor;

use strict;
use warnings::register;

use Error;

use Pangloss::Concepts;
use Pangloss::Concept::Error;
use Pangloss::StoredObject::Error;

use base qw( Pangloss::Application::CollectionEditor );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.4 $ '))[2];

use constant object_name      => 'concept';
use constant objects_name     => 'concepts';
use constant collection_name  => 'concepts';
use constant collection_class => 'Pangloss::Concepts';

sub error_key_exists {
    my $self = shift;
    my $key  = shift;
    throw Pangloss::Concept::Error( flag => eExists,
				    name => $key );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class implements a concept editor application for Pangloss.

It inherits from L<Pangloss::Application::CollectionEditor>.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>, L<Pangloss::Concept>

=cut
