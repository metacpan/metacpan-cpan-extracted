use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/OIDC/Client.pm',
    'lib/OIDC/Client/AccessToken.pm',
    'lib/OIDC/Client/AccessTokenBuilder.pm',
    'lib/OIDC/Client/ApiUserAgentBuilder.pm',
    'lib/OIDC/Client/Config.pod',
    'lib/OIDC/Client/Error.pm',
    'lib/OIDC/Client/Error/Authentication.pm',
    'lib/OIDC/Client/Error/InvalidResponse.pm',
    'lib/OIDC/Client/Error/Provider.pm',
    'lib/OIDC/Client/Error/TokenValidation.pm',
    'lib/OIDC/Client/Identity.pm',
    'lib/OIDC/Client/Plugin.pm',
    'lib/OIDC/Client/ResponseParser.pm',
    'lib/OIDC/Client/Role/AttributesManager.pm',
    'lib/OIDC/Client/Role/ClaimsValidator.pm',
    'lib/OIDC/Client/Role/ClientAuthenticationHelper.pm',
    'lib/OIDC/Client/Role/ConfigurationChecker.pm',
    'lib/OIDC/Client/Role/LoggerWrapper.pm',
    'lib/OIDC/Client/TokenResponse.pm',
    'lib/OIDC/Client/TokenResponseParser.pm',
    'lib/OIDC/Client/User.pm',
    'lib/OIDC/Client/Utils.pm',
    't/00-compile.t',
    't/access-token-builder.t',
    't/access-token.t',
    't/api-useragent-builder.t',
    't/client.t',
    't/error-provider.t',
    't/identity.t',
    't/lib/OIDCClientTest.pm',
    't/plugin.t',
    't/resources/client.jwk',
    't/resources/client.key',
    't/response-parser.t',
    't/token-response-parser.t',
    't/user.t',
    't/utils.t'
);

notabs_ok($_) foreach @files;
done_testing;
