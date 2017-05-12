#!/usr/bin/perl
# vi:sw=4:ts=4:ai:sm:et

# A script to convert the purple numbers in PurpleWiki v0.1
# to the format used in PurpleWiki v0.2. 
#
# Using this script will _break_ any purple number references
# that were made to your content in the past. The links
# will still go to the page, but not to the node. In exchange
# the wiki pages will have document indepdent NIDs.
#
# To use this script you must first translate your existing
# config to the new format. The easiest thing to do to do 
# that is to take the new example format and port your config
# to it. It is especially important that you get the ScriptName
# configuration variable set correctly. If you do not, transclusion
# will not work correctly.
#
# You will want to have editing on your wiki shutdown for the
# brief time it takes to run this script. You can do this
# by removing or changing the permissions on the installed
# wiki.pl or wiki.cgi script.
#
# Usage:
#
#   purpleConvert </path/to/wiki/data/directory> http://<your host>
#
# For the URL portion you just provide the protocol, host and port
# (if not 80) information. Do not provide the path. That comes
# from the ScriptName in the config.
#

use PurpleWiki::Config;
use PurpleWiki::Parser::WikiText;
use PurpleWiki::Database;
use PurpleWiki::Database::KeptRevision;
use PurpleWiki::Database::Page;

my $CONVERT_MESSAGE = "Automatic Purple Number Update";

my $configDir = $ARGV[0] or die "you must provide a data directory\n";
die "$configDir not a directory\n" unless -d $configDir;

my $url = $ARGV[1] or "die you must provide a url host information\n";

my $config = new PurpleWiki::Config($configDir);
my $wikiParser = new PurpleWiki::Parser::WikiText();

my @pageList = &PurpleWiki::Database::AllPagesList($config);

PurpleWiki::Database::RequestLock($config);
foreach $id (@pageList) {
    my $now = time;
    my $keptRevision = new PurpleWiki::Database::KeptRevision(
        id => $id,
        config => $config
    );
    my $page = new PurpleWiki::Database::Page(
        id => $id,
        now => $now,
        config => $config
    );
    $page->openPage();

    my $text = $page->getText();
    my $section = $page->getSection();
    my $oldText = $text->getText(); # this is the text of the page

    # strip all the nid and lastnid references
    #print "#\n$oldText\n#\n";
    $oldText =~ s/\s+\[nid\s+\d+\]//gs;
    $oldText =~ s/\[lastnid\s+\d+\]\n?//gs;

    my $fullUrl = $url . $config->ScriptName . '?' . $id;
    my $wiki = $wikiParser->parse(
        $oldText,
        add_node_ids => 1,
        url => $fullUrl,
        config => $config,
        freelink => $config->FreeLinks
    );
    my $newText = $wiki->view(
        'wikitext',
        config => $config
    );

    #print "#\n$newText\n#\n";
    
    if ($section->getRevision > 0) {
        $keptRevision->addSection($section, $now);
        $keptRevision->trimKepts($now);
        $keptRevision->save();
    }

    $text->setText($newText);
    $text->setMinor(1);
    $text->setSummary($CONVERT_MESSAGE);
    $section->setRevision($section->getRevision() + 1);
    $page->setTS($now);
    $page->save();


}
PurpleWiki::Database::ReleaseLock($config);



