#!/usr/bin/env perl
#
# $Id: Template-Stash-HTML-Entities.t,v 1.3 2007/05/04 07:33:34 hironori.yoshida Exp $
#
use strict;
use warnings;
use version; our $VERSION = qv('1.3.1');

use blib;
use Test::More tests => 3;

use Template::Config;
use Template::Stash::HTML::Entities;

my $stash = Template::Stash::HTML::Entities->new;

isa_ok( $stash, $Template::Config::STASH );

$stash->set( value => q{&} );
is( $stash->get('value'), '&amp;', 'encoded automatically' );

$stash->set( value => [q{&}] );
is_deeply( $stash->get('value'), [q{&}], 'reference is not encoded' );
