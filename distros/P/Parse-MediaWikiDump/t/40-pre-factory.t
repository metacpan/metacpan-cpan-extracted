use Test::Simple tests => 3;
use strict;
use Parse::MediaWikiDump;


ok(defined(Parse::MediaWikiDump::Pages->new('t/pages_test.xml')));
ok(defined(Parse::MediaWikiDump::Revisions->new('t/revisions_test.xml')));
ok(defined(Parse::MediaWikiDump::Links->new('t/links_test.sql')));