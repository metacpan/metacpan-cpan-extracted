=head1 NAME

Pangloss::Application - the Pangloss application.

=head1 SYNOPSIS

  use Pangloss::Application;
  my $app = new Pangloss::Application()
    ->store( new Pixie()->connect('...') );

  my $view1 = $app->user_editor->update_user( ... );
  my $view2 = $app->term_editor->add_term( ... );
  ...

  # see respective classes for syntax

=cut

package Pangloss::Application;

use strict;
use warnings::register;

use Error;

use Pangloss::Application::UserEditor;
use Pangloss::Application::LanguageEditor;
use Pangloss::Application::CategoryEditor;
use Pangloss::Application::ConceptEditor;
use Pangloss::Application::TermEditor;
use Pangloss::Application::Searcher;

use base      qw( Pangloss::Object );
use accessors qw( user_editor   store    searcher
		  term_editor     category_editor
		  concept_editor  language_editor );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.11 $ '))[2];

sub init {
    my $self = shift;
    $self->user_editor( Pangloss::Application::UserEditor->new->parent($self) )
         ->language_editor( Pangloss::Application::LanguageEditor->new->parent($self) )
         ->category_editor( Pangloss::Application::CategoryEditor->new->parent($self) )
         ->concept_editor( Pangloss::Application::ConceptEditor->new->parent($self) )
         ->term_editor( Pangloss::Application::TermEditor->new->parent($self) )
         ->searcher( Pangloss::Application::Searcher->new->parent($self) );
}

1;

__END__

#------------------------------------------------------------------------------

=head1 DESCRIPTION

This class is the main entry point to the Pangloss system.

=head1 METHODS

=over 4

=item store()

set/get the L<Pixie> object store for this application.

=item user_editor()

set/get the L<Pangloss::Application::UserEditor>.

=item language_editor()

set/get the L<Pangloss::Application::LanguageEditor>.

=item category_editor()

set/get the L<Pangloss::Application::CategoryEditor>.

=item concept_editor()

set/get the L<Pangloss::Application::ConceptEditor>.

=item term_editor()

set/get the L<Pangloss::Application::TermEditor>.

=item searcher()

set/get the L<Pangloss::Application::Searcher>.

=back

=head1 AUTHOR

Steve Purkis <spurkis@quiup.com>

=head1 SEE ALSO

L<Pangloss>

=cut
