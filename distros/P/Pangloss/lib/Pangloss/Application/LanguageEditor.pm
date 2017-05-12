=head1 NAME

Pangloss::Application::LanguageEditor - language editor app for Pangloss.

=head1 SYNOPSIS

  use Pangloss::Application::LanguageEditor;
  my $editor = new Pangloss::Application::LanguageEditor();

  my $view0 = $editor->list();
  my $view1 = $editor->add( $lang );
  my $view2 = $editor->get( $iso_code );
  my $view3 = $editor->update( $iso_code, $lang );
  my $view4 = $editor->remove( $iso_code );

=cut

package Pangloss::Application::LanguageEditor;

use strict;
use warnings::register;

use Error;

use Pangloss::Languages;
use Pangloss::Language::Error;
use Pangloss::StoredObject::Error;

use base qw( Pangloss::Application::CollectionEditor );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.8 $ '))[2];

use constant object_name      => 'language';
use constant objects_name     => 'languages';
use constant collection_name  => 'languages';
use constant collection_class => 'Pangloss::Languages';

sub error_key_exists {
    my $self = shift;
    my $key  = shift;
    throw Pangloss::Language::Error( flag     => eExists,
				     iso_code => $key );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class implements a language editor application for Pangloss.

It inherits from L<Pangloss::Application::CollectionEditor>.

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>, L<Pangloss::Language>

=cut
