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
    use Readonly;
    use Test::More;

    Readonly my $ALIAS => 'tester';
    Readonly my $K     => $poe_kernel;

    sub START { $K->alias_set( $ALIAS ); }      # refcount++

    event mpd_connect_error_fatal => sub {
        my $arg = $_[ARG0];
        like($arg, qr/^Not a mpd server - welcome string was:/, 'wrong server');
        $K->alias_remove( $ALIAS ); # refcount--
        $K->post( _mpd_conn => 'disconnect' );
    };

    no Moose;
    __PACKAGE__->meta->make_immutable;
    1;
}

# -- main test
use POE;
use POE::Component::Client::MPD::Connection;
use Test::More;

my $sendmail_running = grep { /:25\s.*LISTEN/ } qx{ netstat -an };
plan skip_all => 'need some sendmail server running' unless $sendmail_running;
plan tests => 1;

My::Session->new;
POE::Component::Client::MPD::Connection->spawn( {
    host => 'localhost',
    port => 25,
    id   => 'tester',
} );
POE::Kernel->run;
exit;
