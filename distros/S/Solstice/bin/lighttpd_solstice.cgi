#!/usr/bin/perl

#### Installation in lighttpd:

# 1) Edit this "use lib" line to point to your Solstice lib dir.
use lib qw(/YOUR_SOLSTICE_ROOT/solstice/lib);

# 2) Copy this cgi into your web root.  You will need to create
#    both an unprotected and a protected copy (or symlink it).
#    Your structure should look like this:
#    web_root/
#    webroot/index.cgi
#    webroot/auth/index.cgi

# 3) Configure lighttpd to secure the /auth/ directory.
#    You can do this any way you'd like, but ensure that
#    the REMOTE_USER environment variable is filled out.
#    A basic auth solution might look like:
#     server.modules                += ( "mod_auth" )
#     auth.backend                 = "plain"
#     auth.backend.plain.userfile  = "/etc/lighttpd/lighttpd.user"
#     auth.require    = ( "/auth/" => (
#             "method"    => "basic",
#             "realm"     => "Solstice Auth",
#             "require"   => "valid-user",
#         )
#     )

# 4) Enable mod_rewrite for your lighttpd and redirect desired URLS 
#    to this cgi. For example, in your lighttpd configuration:
#     url.rewrite-once += (
#        "^/tools/_auth/"           => "/auth/index.pl",
#        "^/tools.*?(\?.*)"         => "index.pl$1",
#        "^/tools/"                 => "index.pl",
#     )
#    Make certain the /tools portion matches the virtual root you choose
#    in your solstice_config.xml or during installation!




#### No Need to Edit Below This Line ####

use strict;
use warnings;

use Solstice::Server::Lighttpd;
use CGI::Fast;

while( new Solstice::Server::Lighttpd(new CGI::Fast) )
