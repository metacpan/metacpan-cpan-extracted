#!perl
use v5.36;
package MyApp {
  # Use PXF and enable optional config and template features (or use :all)
  use PlackX::Framework qw(:config :template);

  # Use templating (Template.pm aka Template Toolkit by default).
  # Note, we only need to "use" our Template subclass once, but calling it
  # multiple times is ok, it won't re-initialize the class once it's set up.
  use MyApp::Template;

  # We stored our template config data in our config file, but we could also
  # set up Template Toolkit like this:
  #   use MyApp::Template { TT_OPTION => 'value', TT_OPTION_2 => 'value_2', ... };
  #
  # or manually like so:
  #   use MyApp::Template (); # or qw(:manual) or qw(:no-auto);
  #
  # and tell it what object to use; this can use any template object with a
  # TT-compatible interface:
  #   use Template ();
  #   MyApp::Template->set_engine(
  #     Template->new(...);
  #   };

  # Import routing DSL into this module
  use MyApp::Router;

  route '/{template-name}' => sub ($request, $response) {
    my $template_name = $request->route_param('template-name');

    # Check validity of template
    unless ($template_name =~ m/^[a-z0-9_]+$/) {
      $response->status(404);
      return $response->template->render("not_found.phtml");
    }

    # Check template exists
    my $template_file .= "$template_name.phtml";
    unless (-e config()->{pxf}{template}{INCLUDE_PATH} . '/' . $template_file) {
      $response->status(404);
      return $response->template->render("not_found.phtml");
    }

    # You would not typically need this, but for the purpose of illustration,
    # we'll allow our templates to access our config data
    $response->template->set(config => config());

    return $response->template->render($template_file);
  };
}

1;
