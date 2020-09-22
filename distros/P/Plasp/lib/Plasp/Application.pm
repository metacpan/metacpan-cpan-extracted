package Plasp::Application;

use Moo;
use namespace::clean;

with 'Plasp::State::Application';

=head1 NAME

Plasp::Application - Default class for $Application objects

=head1 SYNOPSIS

  package MyApp;

  use Moo;

  sub BUILD {
    my ( $self, @args ) = @_;

    $self->Application;
  };

=head1 DESCRIPTION

Like the C<$Session> object, you may use the C<$Application> object to store
data across the entire life of the application.

A Plasp::Application composes the L<Plasp::State::Application> role, which
implements the API a C<$Application> object. Please refer to
L<Plasp::State::Application> for the C<$Application> API.

Plasp::Application is simply stored in memory. Whatever is stored here will
last as long as the application runs. This will depend on the server
implementation and how it manages its processes.

=cut

1;

=head1 SEE ALSO

=over

=item * L<Plasp::State>

=item * L<Plasp::State::Application>

=item * L<Plasp::State::Session>

=item * L<Plasp::Session>

=back
