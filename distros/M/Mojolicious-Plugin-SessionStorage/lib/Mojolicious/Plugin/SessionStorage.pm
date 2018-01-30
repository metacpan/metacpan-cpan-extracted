package Mojolicious::Plugin::SessionStorage;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.02';

use Mojolicious::Sessions::Storage;

sub register {
  my ( $self, $app, $args ) = @_;
  $args = { session_store => $args } unless ( ref $args eq 'HASH' );
  my $sessions
    = Mojolicious::Sessions::Storage->new(%$args);
  $app->sessions($sessions);
  return $sessions;
}

=head1 NAME

Mojolicious::Plugin::SessionStorage - session data store plugin for Mojolicious

=head1 VERSION

Version 0.01

=cut



=head1 SYNOPSIS

    use Mojolicious::Lite;
    use Mojolicious::Session::Storage::File;
    plugin SessionStore => Mojolicious::Session::Storage::File->new;


=head1 AUTHOR

wfso, C<< <461663376 at qq.com> >>

=cut

1; # End of Mojolicious::Plugin::SessionStorage
