#!/opt/bin/speedy

# This is an example of how to use a papp application from CGI, using the
# SpeedyCGI module. You can still use this code as a "normal" CGI script
# by changing the path above to /usr/bin/perl

# This script only mounts a single application. Often you want to mount an
# appset: See eg/exec.cgi for an exampe of how to do this. Actually, the
# only difference is calling mount_appset instead of mount_app...

use PApp::CGI;

# initialize request. on the first one configure papp
init PApp::CGI and PApp::config_eval {
   configure PApp onerr => 'va';
   $handler = mount_app PApp "admin";
   configured PApp;
};

# run the application
&$handler;

