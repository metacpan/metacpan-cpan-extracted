package Mojolicious::Plugin::Mojolyst;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.01';

use Mojo::Loader qw/find_modules load_class/;

sub register {
  my ($self, $app, $conf) = @_;

  # Discover controllers
  for my $class ( find_modules $conf->{controllers} ) {

    # Steal children
    my $e = load_class $class;
    my @children = @{$class->new->routes->children};
    $app->routes->add_child($_) for @children;

    # Make DATA sections accessible
    push @{$app->static->classes},   $class;
    push @{$app->renderer->classes}, $class;
  }
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Mojolyst - Mojolicious::Lite syntax in a full Mojolicious
app.

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Mojolyst' => {controllers => 'MyApp::Controller'});

  # Mojolicious::Lite
  plugin 'Mojolyst' => {controllers => 'MyApp::Controller'};

  # In your MyApp::Controller controller
  package MyApp::Controller::Foo;
  use Mojolicious::Lite;

  get '/' => {text => 'Welcome to Mojolyst!'};

  1;

=head1 DESCRIPTION

L<Mojolicious::Plugin::Mojolyst> is a L<Mojolicious> plugin to hijack the
Mojolicious router and turn it into a more Catalyst-ish decentralized one.

=head1 METHODS

L<Mojolicious::Plugin::Mojolyst> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>,
L<http://blog.mojolicious.org/post/157278582436/mojolicious-hack-of-the-day-mojolyst>.

=cut
