#!/usr/bin/env perl

package Prty::MediaWiki::Client::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::MediaWiki::Client');
}

# -----------------------------------------------------------------------------

sub test_unitTest : Ignore(1) {
    my $self = shift;

    my $cli = Prty::MediaWiki::Client->new(
        url => 'http://localhost/mediawiki/api.php',
        # url => 'https://en.wikipedia.org/w/api.php',
        verbose => 1,
    );
    $self->is(ref($cli),'Prty::MediaWiki::Client');

    my $res = $cli->getPage('Hauptseite');
    # my $res = $cli->getPage('Main Page');
}

# -----------------------------------------------------------------------------

package main;
Prty::MediaWiki::Client::Test->runTests;

# eof
