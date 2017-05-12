package Mojolicious::Plugin::Sendgrid;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Sendgrid;

sub register {
  my ($self, $app, $conf) = @_;

  push @{$app->commands->namespaces}, 'Mojo::Sendgrid::Command';

  my $sendgrid = Mojo::Sendgrid->new({%{$app->config('sendgrid')||{}}, %{$conf||{}}}) or return;
  $app->helper(sendgrid => sub {$sendgrid});
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Sendgrid - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Sendgrid');

  # Mojolicious::Lite
  plugin 'Sendgrid';

=head1 DESCRIPTION

L<Mojolicious::Plugin::Sendgrid> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::Sendgrid> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
