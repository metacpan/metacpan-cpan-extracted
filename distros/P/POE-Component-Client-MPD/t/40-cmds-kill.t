#!perl
#
# This file is part of POE-Component-Client-MPD
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use 5.010;
use strict;
use warnings;

# -- test session
{
    package My::Session;
    use MooseX::POE;
    use Test::More;
    sub START {
        POE::Kernel->alias_set( 'tester' );     # refcount++
        POE::Kernel->delay_set( kill => 0.5 );  # FIXME: use connected event to start tests in pococm-test
    }
    event check => sub {
        my @procs = grep { /\smpd\s/ } grep { !/grep/ } qx{ ps -ef };
        is( scalar @procs, 0, 'kill shuts down mpd' );
    };
    event kill => sub {
        POE::Kernel->delay_set( check => 1 );
        POE::Kernel->post( mpd => 'kill' );
        POE::Kernel->alias_remove( 'tester' );   # refcount--
    };
    no Moose;
    __PACKAGE__->meta->make_immutable;
    1;
}
# -- main test
package main;
use POE;
use POE::Component::Client::MPD;
use Test::More;

eval 'use Test::Corpus::Audio::MPD';
plan skip_all => $@ if $@ =~ s/\n+BEGIN failed--compilation aborted.*//s;
plan tests => 1;

POE::Component::Client::MPD->spawn;
My::Session->new;
POE::Kernel->run;
exit;
