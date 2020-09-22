package Plasp::State;

use Module::Runtime qw(require_module);

use Moo::Role;
use Types::Standard qw(Object Str HashRef);

=head1 NAME

Plasp::State - Role for initializing State objects: $Session and $Application

=head1 SYNOPSIS

  package Plasp;

  use Moo;

  with 'Plasp::State'

  sub method {
      my $session = shift->Session;
  }

=head1 DESCRIPTION

This role is mainly consumed by the Plasp class in order to instantiate State
objects in the ASP object.

=cut

=head1 Attributes

=over

=item ApplicationClass

A string referencing the class to use to instatiate a new $Application object.
Defaults to C<'Plasp::Application'>.

=cut

has 'ApplicationClass' => (
    is      => 'rw',
    isa     => Str,
    default => "Plasp::Application",
);

=item ApplicationConfig

A hash reference to pass into the constructor of the Application class.
Defaults to an empty hash reference.

=cut

has "ApplicationConfig" => (
    is      => 'rw',
    default => sub { {} },
);

=item Application

A reference to the actual $Application global object. Defaults to
C<< Plasp::Application->new >>.

=cut

has "Application" => (
    is      => 'ro',
    isa     => Object,
    clearer => "clear_Application",
    lazy    => 1,
    default => sub {
        my ( $self ) = @_;

        my $class = $self->ApplicationClass;

        require_module $class;

        # Create the state object
        return $class->new( asp => $self, %{ $self->ApplicationConfig } );
    }
);

=item SessionClass

A string referencing the class to use to instatiate a new $Application object.
Defaults to C<'Plasp::Session'>.

=cut

has 'SessionClass' => (
    is      => 'rw',
    isa     => Str,
    default => "Plasp::Session",
);

=item ApplicationConfig

A hash reference to pass into the constructor of the Application class.
Defaults to an empty hash reference.

=cut

has "SessionConfig" => (
    is      => 'rw',
    default => sub { {} },
);

=item Session

A reference to the actual $Session global object. Defaults to
C<< Plasp::Session->new >>.

=cut

has "Session" => (
    is      => 'ro',
    isa     => Object,
    clearer => "clear_Session",
    lazy    => 1,
    default => sub {
        my ( $self ) = @_;

        my $class = $self->SessionClass;

        require_module $class;

        # Create the state object
        return $class->new( asp => $self, %{ $self->SessionConfig } );
    }
);

1;

=back

=head1 SEE ALSO

=over

=item * L<Plasp>

=item * L<Plasp::Session>

=item * L<Plasp::Application>

=back
