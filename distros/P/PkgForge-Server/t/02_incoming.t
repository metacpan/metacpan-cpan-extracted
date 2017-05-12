#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use PkgForge::Handler::Incoming;

my $handler = new_ok( 'PkgForge::Handler::Incoming' );

is_deeply( $handler->configfile, [ '/etc/pkgforge/pkgforge.yml',
                                   '/etc/pkgforge/handlers.yml',
                                   '/etc/pkgforge/incoming.yml' ],
           'Configuration files' );

can_ok( $handler, qw(execute) );

done_testing();
