use v5.26;
use warnings;
use experimental 'signatures';

package PXF::Example::WithMiddleware {
  use PlackX::Framework;
  use PXF::Example::WithMiddleware::Router;

  use Plack::Middleware::Auth::Basic;
  use Plack::Middleware::AccessLog;

  route '/' => sub ($request, $response) {
    $response->print('Hello ' . ($request->param('name') || 'World!'));
    return $response;
  };

  sub apply_middleware ($app) {

    $app = Plack::Middleware::Auth::Basic->wrap(
      $app,
      realm => 'User PlackX, Password Framework',
      authenticator => sub ($user, $pass, $env) {
        return 1 if $user eq 'PlackX' and $pass eq 'Framework';
        return 0;
      }
    );

    $app = Plack::Middleware::AccessLog->wrap($app);

    return $app;
  }

}

PXF::Example::WithMiddleware->app;
