use v5.36;
package PXF::Example::HelloWorld {
  use PlackX::Framework;
  use PXF::Example::HelloWorld::Router;
  route '/' => sub ($request, $response) {
    $response->print('Hello ' . ($request->param('name') || 'World!'));
    return $response;
  };

  route '/{word:hello|world}' => sub ($request, $response) {
    my $word = $request->route_param('word');
    $response->print("You said ~$word~");
    return $response;
  };
}

PXF::Example::HelloWorld->app;
