#!/usr/bin/env perl

package Quiq::MediaWiki::Api::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::MediaWiki::Api');
}

# -----------------------------------------------------------------------------

sub test_unitTest: Ignore(2) {
    my $self = shift;

    my $mwl = Quiq::MediaWiki::Api->new('ruv',-debug=>1);
    $self->is(ref($mwl),'Quiq::MediaWiki::Api');

    my $url = $mwl->url;
    $self->is($url,'http://lxv0103.ruv.de:8080/api.php');

    $mwl->loadPage('dss-ims-manual','~/dss-ims-manual.mw');
}

# -----------------------------------------------------------------------------

package main;
Quiq::MediaWiki::Api::Test->runTests;

# eof
