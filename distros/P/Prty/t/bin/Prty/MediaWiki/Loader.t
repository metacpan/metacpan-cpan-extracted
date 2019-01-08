#!/usr/bin/env perl

package Prty::MediaWiki::Loader::Test;
use base qw/Prty::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Prty::MediaWiki::Loader');
}

# -----------------------------------------------------------------------------

sub test_unitTest: Ignore(2) {
    my $self = shift;

    my $mwl = Prty::MediaWiki::Loader->new('ruv',-debug=>1);
    $self->is(ref($mwl),'Prty::MediaWiki::Loader');

    my $url = $mwl->url;
    $self->is($url,'http://lxv0103.ruv.de:8080/api.php');

    $mwl->loadPage('dss-ims-manual','~/dss-ims-manual.mw');
}

# -----------------------------------------------------------------------------

package main;
Prty::MediaWiki::Loader::Test->runTests;

# eof
