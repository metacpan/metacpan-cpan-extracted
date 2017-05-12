#!/usr/bin/perl

##
## Tests for Petal::Utils::CreateHref module
##

use blib;
use strict;

use Test::More qw(no_plan);
use Carp;

use t::LoadPetal;
use Petal::Utils qw( :uri );

my $url1 = 'http://www.foo.com';
my $url2 = 'www.foo.com';
my $url3 = 'ftp://ftp.foo.com';
my $url4 = 'ftp.foo.com';

my $template = Petal->new('23__create_href.html');
my $out      = $template->process( {
    url1 => $url1,
    url2 => $url2,
    url3 => $url3,
    url4 => $url4,
  } );

like($out, qr!create_href1: <a href="$url1"!, 'url1');
like($out, qr!create_href2: <a href="http://$url2"!, 'url2');
like($out, qr!create_href3: <a href="$url3"!, 'url3');
like($out, qr!create_href4: <a href="ftp://$url4"!, 'url4');

