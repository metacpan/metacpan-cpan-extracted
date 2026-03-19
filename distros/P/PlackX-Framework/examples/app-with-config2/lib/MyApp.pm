#!perl
use v5.36;
package MyApp {
  use PlackX::Framework;
  use MyApp::Router;
  use Data::Dumper;
  route '/' => sub ($request, $response) {
    $response->content_type('text/plain');
    $response->print(Dumper config());
    return $response;
  };
}

1;
