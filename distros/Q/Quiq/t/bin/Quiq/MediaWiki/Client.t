#!/usr/bin/env perl

package Quiq::MediaWiki::Client::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::MediaWiki::Client');
}

# -----------------------------------------------------------------------------

sub test_load: Ignore(2) {
    my $self = shift;

    my $mwl = Quiq::MediaWiki::Client->new('ruv',-debug=>1);
    $self->is(ref($mwl),'Quiq::MediaWiki::Client');

    my $url = $mwl->url;
    $self->is($url,'http://lxv0103.ruv.de:8080/api.php');

    $mwl->loadPage('dss-ims-manual','~/dss-ims-manual.mw');
}

# -----------------------------------------------------------------------------

package main;
Quiq::MediaWiki::Client::Test->runTests;

# eof
