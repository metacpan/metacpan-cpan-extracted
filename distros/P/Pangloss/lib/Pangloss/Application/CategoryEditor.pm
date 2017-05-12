=head1 NAME

Pangloss::Application::CategoryEditor - category editor app for Pangloss.

=head1 SYNOPSIS

  use Pangloss::Application::CategoryEditor;
  my $editor = new Pangloss::Application::CategoryEditor();

  my $view0 = $editor->list();
  my $view1 = $editor->add( $cat );
  my $view2 = $editor->get( $name );
  my $view3 = $editor->update( $name, $cat );
  my $view4 = $editor->remove( $name );

=cut

package Pangloss::Application::CategoryEditor;

use strict;
use warnings::register;

use Error;

use Pangloss::Categories;
use Pangloss::Category::Error;
use Pangloss::StoredObject::Error;

use base qw( Pangloss::Application::CollectionEditor );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.6 $ '))[2];

use constant object_name      => 'category';
use constant objects_name     => 'categories';
use constant collection_name  => 'categories';
use constant collection_class => 'Pangloss::Categories';

sub error_key_exists {
    my $self = shift;
    my $key  = shift;
    throw Pangloss::Category::Error( flag => eExists,
				     name => $key );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class implements a category editor application for Pangloss.

It inherits from L<Pangloss::Application::CollectionEditor>.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>, L<Pangloss::Category>

=cut
