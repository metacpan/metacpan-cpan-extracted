use Mojo::Base -strict, -signatures;

use HTTP::Status qw(:constants);
use Sentry::Tracing::Status;
use Test::More;

is(Sentry::Tracing::Status->from_http_code(HTTP_OK),        'ok');
is(Sentry::Tracing::Status->from_http_code(HTTP_NOT_FOUND), 'not_found');
is(Sentry::Tracing::Status->from_http_code(HTTP_SERVICE_UNAVAILABLE),
  'unavailable');

done_testing;
