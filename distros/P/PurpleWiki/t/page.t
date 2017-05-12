# page.t
# vi:sw=4:ts=4:ai:sm:et

use strict;
use warnings;
use Test;

BEGIN { plan tests => 12};

use PurpleWiki::Database::Page;
use PurpleWiki::Database::KeptRevision;
use PurpleWiki::Parser::WikiText;
use PurpleWiki::Config;

my $configdir = 't';
my $lockdir = 't/temp/lockmain';
my $id = 'WikiPage';
my $idFilename = 't/page/W/WikiPage.db';
my $newcontent = "Describe the new page here.\n";
my $content=<<"EOF";
Hello this is a wiki page, using WikiPage as a WikiWord.

== Header Injection ==

* this is a list one
* this is a list two

[http://www.burningchrome.com/ this is a link]
EOF

my $expected_content=<<"EOF";
Hello this is a wiki page, using WikiPage as a WikiWord. {nid 1}

== Header Injection {nid 2} ==

* this is a list one {nid 3}
* this is a list two {nid 4}

[http://www.burningchrome.com/ this is a link] {nid 5}
EOF

my $second_content=<<"EOF";
Hello this is a wiki page, using WikiPage as a WikiWord. {nid 1}

== Header Injection ==

* this is a list one {nid 3}
* this is a list two {nid 4}

[http://www.burningchrome.com/ this is a link] {nid 5}
EOF

my $second_expected_content=<<"EOF";
Hello this is a wiki page, using WikiPage as a WikiWord. {nid 1}

== Header Injection {nid 6} ==

* this is a list one {nid 3}
* this is a list two {nid 4}

[http://www.burningchrome.com/ this is a link] {nid 5}
EOF

# parse first content
my $config = new PurpleWiki::Config($configdir);
my $parser = PurpleWiki::Parser::WikiText->new();
my $wiki = $parser->parse($content, add_node_ids => 1);
my $output = $wiki->view('wikitext');
$output =~ s/\r//g;

# is what we parsed what we expected
ok($output, $expected_content);

## now save it, be amazed how complicated this is...
## we'll do the whole bag
# lock
ok(PurpleWiki::Database::RequestLock() && -d $lockdir);
my $keptRevision = new PurpleWiki::Database::KeptRevision(
    id => $id);
my $page = new PurpleWiki::Database::Page('id' => $id,
                                          'now' => time);
$page->openPage();

# stored id should be the same as what we gave it
ok($page->getID(), $id);

# stored text should be empty at this stage
my $text = $page->getText();
my $section = $page->getSection();
my $oldText = $text->getText();
ok($oldText, $newcontent);

# revision should be 0
my $oldrev = $section->getRevision();
ok($oldrev, 0);

# set text
$text->setText($output);
ok($text->getText(), $expected_content);

# set revision
ok($section->setRevision($section->getRevision() + 1), 1);

# save page
ok($page->save(), -f $idFilename);

# get rid of lock
ok(PurpleWiki::Database::ReleaseLock() && ! -d $lockdir);
undef($page);

# load the page up and make sure the id and text are right
my $newPage = new PurpleWiki::Database::Page('id' => $id);
$newPage->openPage();
ok($newPage->getID(), $id);
ok($newPage->getText()->getText(), $expected_content);

# parse second content
$wiki = $parser->parse($second_content, add_node_ids => 1);
$output = $wiki->view('wikitext');
$output =~ s/\r//g;

# is what we parsed what we expected
ok($output, $second_expected_content);

sub END {
    unlink('t/sequence');
    unlink($idFilename);
    rmdir($lockdir);
}
