#!/usr/bin/perl
#
# moinConvert.pl
#
# $Id$
#
# Converts MoinMoin files over to PurpleWiki.
#
# To use, you must have all of your MoinMoin files in a directory, and
# you must setup an wikidb directory where the converted database will
# go.  That wikidb should have a config file.
#
# Usage:
#
#   moinConvert.pl /path/to/moinmoin /path/to/wikidb

use strict;
use lib '/home/eekim/devel/PurpleWiki/trunk';
use PurpleWiki::Config;
use PurpleWiki::Database;
use PurpleWiki::Database::KeptRevision;
use PurpleWiki::Database::Page;
use PurpleWiki::Parser::MoinMoin;

my $MOINDIR;
my $WIKIDB;
if (scalar @ARGV == 2) {
    $MOINDIR = shift @ARGV;
    $WIKIDB = shift @ARGV;
}
else {
    print <<EOM;
Usage:
    $0 moindir wikidb

where moindir is the directory containing the MoinMoin Wiki files and
wikidb is the directory where the PurpleWiki config file resides and
the converted files will eventually go.

EOM
    exit;
}

opendir DIR, $MOINDIR;
my @files = grep { -f "$MOINDIR/$_" } readdir(DIR);
closedir DIR;

my $config = PurpleWiki::Config->new($WIKIDB);
my $wikiParser = PurpleWiki::Parser::MoinMoin->new;

foreach my $file (@files) {
    my $now = time;
    my $wikiContent = &PurpleWiki::Database::ReadFileOrDie("$MOINDIR/$file");
    my $wiki = $wikiParser->parse($wikiContent, add_node_ids => 1);

    my $keptRevision = new PurpleWiki::Database::KeptRevision(id => $file);
    my $page = new PurpleWiki::Database::Page(id => $file, now => $now);
    $page->openPage();
    my $text = $page->getText();
    my $section = $page->getSection();

    $text->setText($wiki->view('wikitext'));
    $text->setMinor(1);
    $text->setSummary('Converted from MoinMoin.');
    $section->setRevision($section->getRevision() + 1);
    $section->setTS($now);
    $page->setTS($now);
    $page->save();
}
