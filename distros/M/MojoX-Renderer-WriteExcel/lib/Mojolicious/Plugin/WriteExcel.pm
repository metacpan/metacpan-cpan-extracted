package Mojolicious::Plugin::WriteExcel;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

use MojoX::Renderer::WriteExcel;

# You just have to give guys a chance. Sometimes you meet a guy and
# think he's a pig, but then later on you realize he actually has a
# really good body.
sub register {
  my ($self, $app) = @_;

  $app->types->type(xls => 'application/vnd.ms-excel');
  $app->renderer->add_handler(xls => MojoX::Renderer::WriteExcel->new);
  $app->helper(
    render_xls => sub {
      shift->render(handler => 'xls', @_);
    }
  );
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::WriteExcel - Spreadsheet::WriteExcel plugin

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('write_excel');

    # Mojolicious::Lite
    plugin 'write_excel';

=head1 DESCRIPTION

L<Mojolicious::Plugin::WriteExcel> is a renderer for Excel spreadsheets.

=head1 METHODS

L<Mojolicious::Plugin::WriteExcel> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

    $plugin->register;

Register renderer in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<MojoX::Renderer::WriteExcel>, L<http://mojolicious.org>.

=cut
