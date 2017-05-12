package Mojolicious::Plugin::Responsinator;

=head1 NAME

Mojolicious::Plugin::Responsinator - Simulate screen sizes

=head1 VERSION

0.03

=head1 DESCRIPTION

This module allow you to embed a given web page inside an iframe to see
how it would look on different screens.

This is probably just a module you want to use while developing, and not
bundle it with the final application. Example usage:

  sub startup {
    my $self = shift;
    $self->plugin("responsinator") if $ENV{ENABLE_RESPONSINATOR};
  }

=head1 SYNOPSIS

You need to enable the plugin in your L<Mojolicious> application:

  use Mojolicious::Lite;
  plugin "responsinator";
  get "/" => sub { shift->render(text => "test\n") };
  app->start;

Then from the browser, you can ask for an URL with the "_size" param to embed a
website inside an iframe. Example:

  http://localhost:3000/some/path?_size=iphone          # iphone landscape
  http://localhost:3000/some/path?_size=iphone:portrait # iphone portrait
  http://localhost:3000/some/path?_size=100x400         # width: 100px; height: 400px

=head1 PREDEFINED SIZES

You can replace "iphone" in the example above with any of the predefined sizes
below:

=over 4

=item * iphone

=item * iphone-5

=item * ipad

=item * wildfire

=item * nexus-4

=back

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Cwd;

our $VERSION = '0.03';

=head1 METHODS

=head2 register

  $self->reqister($app, \%config);
  $app->plugin(responsinator => \%config);

Will register an "around_dispatch" hook, which will trigger on the C<_size>
query param. C<%config> can contain:

=over 4

=item * param

Use this to specify another query param than the default "_size".

=back

=cut

sub register {
  my($self, $app, $config) = @_;
  my $param_name = $config->{param} || '_size';

  push @{ $app->static->paths }, $self->_asset_path;
  push @{ $app->renderer->paths }, $self->_asset_path;

  $app->hook(around_dispatch => sub {
    my($next, $c) = @_;
    my $size = $c->param($param_name) or return $next->();
    my $frame_url = $c->req->url->to_abs;
    my $orientation = $size =~ s!:(landscape|portrait)$!! ? $1 : 'landscape';
    my @size = $size =~ /^(\d*)x(\d*)$/;

    $frame_url->query->remove($param_name); # make sure it does not recurse
    $c->render(
      layout => $config->{layout} || undef,
      template => 'responsinator',
      frame_url => $frame_url,
      identifier => $size,
      orientation => $orientation,
      param_name => $param_name,
      height => $size[1] ? "$size[1]px" : 0,
      width => $size[0] ? "$size[0]px" : 0,
    );
  });
}

sub _asset_path {
  my $asset_path = Cwd::abs_path(__FILE__);
  $asset_path =~ s!\.pm$!!;
  $asset_path;
}

=head1 COPYRIGHT

=head2 Images

The images are provided by the The Responsinator Team, L<http://www.responsinator.com>.

=head2 Code

The code is written by Jan Henning Thorsen, L<http://thorsen.pm>.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
