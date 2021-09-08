package ExamplePlugin::Preferences;
use Mojo::Base 'Mojolicious::Plugin';
use File::Basename 'dirname';
use File::Spec::Functions qw/catdir/;

sub register {
  my ($self, $app) = @_;

  # Load Oro plugin with a temporary database
  unless (exists $app->renderer->helpers->{content_block}) {
    $app->plugin('TagHelpers::ContentBlock');
  };

  # The plugin path
  my $path = catdir(dirname(__FILE__));
  push @{$app->renderer->paths}, $path;

  $app->content_block(
    administration => {
      template => 'preferences',
      position => 15
    }
  );
};

1;

__END__
