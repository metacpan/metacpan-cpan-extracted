#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use Mojo::UserAgent;
use Mojo::UserAgent::CookieJar::ChromeMacOS;

my $ua = Mojo::UserAgent->new;
$ua->cookie_jar(Mojo::UserAgent::CookieJar::ChromeMacOS->new);

my $tx = $ua->get('https://www.baidu.com/');
say $tx->req->headers->to_string; use Data::Dumper;