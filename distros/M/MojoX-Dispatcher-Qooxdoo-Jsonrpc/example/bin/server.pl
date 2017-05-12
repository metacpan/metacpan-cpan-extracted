#!/usr/bin/env perl

# start a local server for testing

# $ ./server.pl daemon

# start a local server using the source version of the app

# $ env RUN_SOURCE=1 ./server daemon

# run under fastcgi within an apache webtree
# under http://server/test/myapp
#
# .htaccess
# RewriteEngine On
# RewriteBase /test/myapp
# RewriteCond %{REQUEST_FILENAME} !-f
# RewriteRule (.*) server.fcgi/$1
#
# server.fcgi
# #!/bin/sh
# exec "/path/to/myapp/backend/bin/server.pl" fastcgi
#
#
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";
use Mojolicious::Commands;

# Start commands
Mojolicious::Commands->start_app('QxExample');
