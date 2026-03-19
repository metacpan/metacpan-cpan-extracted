#!perl
use v5.36;

# In this example we store our config filename in the default ENV variable
# It must be in a begin block before our app is loaded.
BEGIN {
  # For app named A::B::C, use A_B_C_CONFIG as the $ENV key.
  $ENV{'MY_EXAMPLEAPP_CONFIG'} = './config.pl';
}

# Define our app
package My::ExampleApp {
  # Tell PXF to load the optional Config mode
  # (can also pass :config or :all)
  use PlackX::Framework qw(Config);

  # Use our auto-generated ::Config subclass
  # We could also pass the filename in here instead of in $ENV
  # e.g. as "use My::ExampleApp::Config '/path/to/config';"
  use My::ExampleApp::Config;

  # Make a simple app that dumps our config hashref
  use My::ExampleApp::Router;
  use Data::Dumper;
  route '/' => sub ($request, $response) {
    $response->content_type('text/plain');
    $response->print(Dumper config());
    return $response;
  };
}

# Return our app coderef
My::ExampleApp->app;
