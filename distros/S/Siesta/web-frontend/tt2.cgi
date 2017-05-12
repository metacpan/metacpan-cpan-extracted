#!/usr/local/bin/perl -w
use strict;
use Siesta::Member;
use Siesta::Web::FakeApache;
use Siesta::Web;

umask 002;

Siesta::Web::handler( Siesta::Web::FakeApache->new );
exit;

# fairly simple mod_perl emulation
# ScriptAliasMatch /siesta/.*\.tt2 /home/richardc/siesta-trunk/siesta/web-frontend/tt2.cgi
