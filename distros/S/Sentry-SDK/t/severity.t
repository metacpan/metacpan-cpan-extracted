use Mojo::Base -strict, -signatures;

use Sentry::Severity;
use Test::More;

is(Sentry::Severity->Fatal   => 'fatal');
is(Sentry::Severity->Error   => 'error');
is(Sentry::Severity->Warning => 'warning');
is(Sentry::Severity->Info    => 'info');
is(Sentry::Severity->Debug   => 'debug');

done_testing;
