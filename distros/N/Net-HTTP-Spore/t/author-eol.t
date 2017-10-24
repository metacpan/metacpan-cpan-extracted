
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Net/HTTP/Spore.pm',
    'lib/Net/HTTP/Spore/Core.pm',
    'lib/Net/HTTP/Spore/Meta.pm',
    'lib/Net/HTTP/Spore/Meta/Class.pm',
    'lib/Net/HTTP/Spore/Meta/Method.pm',
    'lib/Net/HTTP/Spore/Meta/Method/Spore.pm',
    'lib/Net/HTTP/Spore/Meta/Types.pm',
    'lib/Net/HTTP/Spore/Middleware.pm',
    'lib/Net/HTTP/Spore/Middleware/Auth.pm',
    'lib/Net/HTTP/Spore/Middleware/Auth/Basic.pm',
    'lib/Net/HTTP/Spore/Middleware/Auth/Header.pm',
    'lib/Net/HTTP/Spore/Middleware/Auth/OAuth.pm',
    'lib/Net/HTTP/Spore/Middleware/DoNotTrack.pm',
    'lib/Net/HTTP/Spore/Middleware/Format.pm',
    'lib/Net/HTTP/Spore/Middleware/Format/Auto.pm',
    'lib/Net/HTTP/Spore/Middleware/Format/JSON.pm',
    'lib/Net/HTTP/Spore/Middleware/Format/XML.pm',
    'lib/Net/HTTP/Spore/Middleware/Format/YAML.pm',
    'lib/Net/HTTP/Spore/Middleware/LogDispatch.pm',
    'lib/Net/HTTP/Spore/Middleware/Mock.pm',
    'lib/Net/HTTP/Spore/Middleware/Redirection.pm',
    'lib/Net/HTTP/Spore/Middleware/Runtime.pm',
    'lib/Net/HTTP/Spore/Middleware/UserAgent.pm',
    'lib/Net/HTTP/Spore/Request.pm',
    'lib/Net/HTTP/Spore/Response.pm',
    'lib/Net/HTTP/Spore/Role.pm',
    'lib/Net/HTTP/Spore/Role/Debug.pm',
    'lib/Net/HTTP/Spore/Role/Description.pm',
    'lib/Net/HTTP/Spore/Role/Middleware.pm',
    'lib/Net/HTTP/Spore/Role/Request.pm',
    'lib/Net/HTTP/Spore/Role/UserAgent.pm',
    't/specs/api.json',
    't/specs/api2.json',
    't/spore-method/base.t',
    't/spore-method/payload.t',
    't/spore-middleware/anonymous.t',
    't/spore-middleware/auth-basic.t',
    't/spore-middleware/auth-header.t',
    't/spore-middleware/auth-oauth.t',
    't/spore-middleware/format-auto.t',
    't/spore-middleware/format-json.t',
    't/spore-middleware/format-xml.t',
    't/spore-middleware/format-yaml.t',
    't/spore-middleware/ns.t',
    't/spore-middleware/redirection.t',
    't/spore-middleware/runtime.t',
    't/spore-middleware/useragent.t',
    't/spore-middleware/x-do-not-track.t',
    't/spore-request/base.t',
    't/spore-request/exception.t',
    't/spore-request/finalize.t',
    't/spore-request/form_data.t',
    't/spore-request/headers.t',
    't/spore-request/new.t',
    't/spore-request/request_uri.t',
    't/spore-request/script_name.t',
    't/spore-request/uri.t',
    't/spore-response/body.t',
    't/spore-response/debug.t',
    't/spore-response/headers.t',
    't/spore-response/new.t',
    't/spore-response/response.t',
    't/spore-response/timeout.t',
    't/spore-role/basic.t',
    't/spore/01_new_from_string.t',
    't/spore/02_enable.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
