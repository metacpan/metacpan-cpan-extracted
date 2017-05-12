
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

use Test::More;

eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD coverage"
    if $@;

my @stopwords;
for (<DATA>) {
    chomp;
    push @stopwords, $_
        unless /\A (?: \# | \s* \z)/msx;    # skip comments, whitespace
}

add_stopwords(@stopwords);
set_spell_cmd('aspell list -l en');

# This prevents a weird segfault from the aspell command - see
# https://bugs.launchpad.net/ubuntu/+source/aspell/+bug/71322
local $ENV{LC_ALL} = 'C';
all_pod_files_spelling_ok();

__DATA__
API
CGI
FastCGI
INI
JS
MACs
OpenID
POSTGRES
PSGI
PayPal
Postgres
Rolsky
Sendfile
Silki
Silki's
Starman
Storable
SystemLog
Testserver
UI
Wikis
antispam
backend
cgi
changeme
citext
contrib
dir
dirs
dzil
exisiting
fastcgi
geekery
hostname
hostnames
javascript
login
minifies
minifying
msgid
namespace
plugins
prepends
prereqs
runtime
spamminess
ssl
uber
unescapes
uri
username
usign
wiki
wikis
wikitext
writeable
www
