#!/usr/bin/env perl

use lib './';
use lib './t';
use lib './lib';
use lib '../lib';
use lib $ENV{'HOME'} . '/perl5/lib/perl5';

use Mojo::Base -strict;

# Disable Bonjour, IPv6 and libev
BEGIN {
  $ENV{MOJO_NO_BONJOUR} = $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_IOWATCHER} = 'Mojo::IOWatcher';
}

use Test::More tests => 9;

use Mojolicious::Lite;
use Test::Mojo;

# DOC renderer plugin
plugin 'DOCRenderer';

# app->start;
my $t = Test::Mojo->new;

$t->get_ok('/doc')
    ->status_is(200)
    ->content_like(qr/It works!/);
$t->get_ok("/doc.txt")
    ->status_is(200)
    ->content_like(qr/It works!/);
$t->get_ok("/doc/Mojolicious/Plugin/DOCRenderer")
    ->status_is(200)
    ->content_like(qr/DOCRenderer/);

__END__

=head1 NAME

MyApp - My Mojolicious Application

=head1 DESCRIPTION

It works!

=cut
