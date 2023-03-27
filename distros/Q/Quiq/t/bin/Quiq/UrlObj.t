#!/usr/bin/env perl

package Quiq::UrlObj::Test;
use base qw/Quiq::Test::Class/;

use v5.10;
use strict;
use warnings;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::UrlObj');
}

# -----------------------------------------------------------------------------

sub test_new : Test(4) {
    my $self = shift;

    my $urlObj = Quiq::UrlObj->new;
    $self->is(ref($urlObj),'Quiq::UrlObj');
    $self->is($urlObj->url,'');

    my $url = 'http://user:passw@host.domain:8080/this/is/a/path'.
        '?arg1=val1&arg1=val2&arg2=val3#search';
    $urlObj = Quiq::UrlObj->new($url);
    $self->is($urlObj->url,$url);    

    $urlObj = Quiq::UrlObj->new(a=>1,b=>2,a=>3,d=>4);
    $self->is($urlObj->url,'?a=1&a=3&b=2&d=4');    
}

# -----------------------------------------------------------------------------

package main;
Quiq::UrlObj::Test->runTests;

# eof
