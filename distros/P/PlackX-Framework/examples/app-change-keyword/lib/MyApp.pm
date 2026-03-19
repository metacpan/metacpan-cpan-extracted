#!perl
use v5.36;
package MyApp {
  use PlackX::Framework;
  use MyApp::Router;

  pxf_filter before => sub ($request, $response) {
    $response->content_type('text/plain');
    $response->print("Welcome.\n");
    return;
  };

  pxf_filter after => sub ($request, $response) {
    $response->print("\nCopyright (C) by the author\n");
    return;
  };

  pxf_base '/myapp';

  pxf_route '/' => sub ($request, $response) {
    $response->print('In this example we have customized the routing DSL.');
    return $response;
  };

}

1;
