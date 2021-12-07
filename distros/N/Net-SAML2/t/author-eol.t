
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
    'lib/Net/SAML2.pm',
    'lib/Net/SAML2/Binding/POST.pm',
    'lib/Net/SAML2/Binding/Redirect.pm',
    'lib/Net/SAML2/Binding/SOAP.pm',
    'lib/Net/SAML2/IdP.pm',
    'lib/Net/SAML2/Protocol/ArtifactResolve.pm',
    'lib/Net/SAML2/Protocol/Assertion.pm',
    'lib/Net/SAML2/Protocol/AuthnRequest.pm',
    'lib/Net/SAML2/Protocol/LogoutRequest.pm',
    'lib/Net/SAML2/Protocol/LogoutResponse.pm',
    'lib/Net/SAML2/Role/ProtocolMessage.pm',
    'lib/Net/SAML2/SP.pm',
    'lib/Net/SAML2/Util.pm',
    'lib/Net/SAML2/XML/Sig.pm',
    'lib/Net/SAML2/XML/Util.pm',
    't/00-basic.t',
    't/01-create-idp.t',
    't/02-create-sp.t',
    't/03-assertions.t',
    't/04-response.t',
    't/05-soap-binding.t',
    't/06-redirect-binding.t',
    't/07-logout-request.t',
    't/08-logout-response.t',
    't/09-authn-request.t',
    't/10-artifact-resolve.t',
    't/11-more-metadata.t',
    't/12-full-client.t',
    't/13-verify-issues.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-coverage.t',
    't/author-pod-syntax.t',
    't/author/notabs.t',
    't/author/pod.t',
    't/author/podcoverage.t',
    't/cacert.pem',
    't/idp-metadata.xml',
    't/idp-metadata2.xml',
    't/issues/issue-49.xml',
    't/lib/Test/Net/SAML2.pm',
    't/lib/Test/Net/SAML2/Util.pm',
    't/net-saml2-cacert.pem',
    't/net-saml2-cert.pem',
    't/net-saml2-idp-metadata.xml',
    't/net-saml2-key.pem',
    't/net-saml2-metadata.xml',
    't/sign-nopw-cert.pem'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
