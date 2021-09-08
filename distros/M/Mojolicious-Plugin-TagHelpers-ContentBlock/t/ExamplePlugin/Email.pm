package ExamplePlugin::Email;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($self, $app) = @_;

  # Load Oro plugin with a temporary database
  unless (exists $app->renderer->helpers->{content_block}) {
    $app->plugin('TagHelpers::ContentBlock');
  };

  $app->content_block(
    administration => {
      inline => q!<%= link_to stash('email_address'), '/email', rel => 'email' %>!,
      position => 1000
    }
  );

};

1;

__END__
