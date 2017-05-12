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

my $max_retries = 3;

# -- test session
{
    package My::Session;
    use MooseX::Has::Sugar;
    use MooseX::POE;
    use MooseX::Types::Moose qw{ Int };
    use Readonly;
    use Test::More;

    Readonly my $ALIAS => 'tester';
    Readonly my $K     => $poe_kernel;

    has count => ( rw, default=>0, isa=>Int );

    sub START { $K->alias_set( $ALIAS ); } # refcount++

    event mpd_connect_error_retriable => sub {
        my ($self, $errstr) = @_[OBJECT, ARG0];
        like($errstr, qr/^connect: \(\d+\) /, 'retriable error trapped');
        $self->count( $self->count + 1 );
    };

    event mpd_connect_error_fatal => sub {
        my ($self, $errstr) = @_[OBJECT, ARG0];

        # checks
        is($self->count, $max_retries-1, 'retriable errors are tried again $max_retries times');
        like($errstr, qr/^Too many failed attempts!/, 'too many errors lead to fatal error');

        # cleanup
        $K->post( _mpd_conn => 'disconnect' );
        $K->alias_remove( $ALIAS );   # refcount--
    };

    no Moose;
    __PACKAGE__->meta->make_immutable;
    1;
}

# -- main test
use POE;
use POE::Component::Client::MPD::Connection;
use Test::More tests => 4;

My::Session->new;
POE::Component::Client::MPD::Connection->spawn( {
    host        => 'localhost',
    port        => 16600,
    id          => 'tester',
    retry_wait  => 0,
    max_retries => $max_retries,
} );
POE::Kernel->run;
exit;
