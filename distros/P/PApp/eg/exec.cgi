#!/opt/bin/speedy

# This is an example of how to use a papp application from CGI, using the
# SpeedyCGI module. You can still use this code as a "normal" CGI script
# by changing the path above to /usr/bin/perl

# This script mounts a full appset.

use PApp::CGI;

# initialize request. on the first one configure papp
init PApp::CGI and PApp::config_eval {
   configure PApp
      onerr => 'va',
      checkdeps => 1,
      delayed => 1,
   ;
   $handler = mount_appset PApp "default";
   configured PApp;
};

# run the appset
&$handler;

