# The demo identity provider, on port 5001.
#
#   plackup -p 5001 app.psgi
#
# Start example/SSO on 5000 first; this is only useful as the far side of
# a login that begins there.
use strict;
use warnings;
use lib 'lib';
use SSODemoIdP;
SSODemoIdP->to_app;
