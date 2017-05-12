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
    use MooseX::Has::Sugar;
    use MooseX::POE;
    use MooseX::Types::Moose qw{ ArrayRef };
    use POE::Component::Client::MPD::Message;
    use Readonly;
    use Test::More;

    Readonly my $ALIAS => 'tester';
    Readonly my $K     => $poe_kernel;

    has tests => (
        ro, auto_deref, required,
        isa     => ArrayRef,
        traits  => ['Array'],
        handles => {
            peek     => [ get => 0 ],
            pop_test => 'shift',
            nbtests  => 'count',
        },
    );


    # -- initializers

    # event: _start()
    # called when the poe session has started.
    sub START {
        $K->alias_set( $ALIAS );        # refcount++
        $K->delay( _next_test => 1 );   # launch the first test
    }

    # -- public events

    # event: _mpd_data ( $msg )
    # event: _mpd_error( $msg )
    # called when mpd talks back, with $msg as a pococm-message param.
    sub _mpd_result {
        my ($self, $state, $arg0, $arg1) = @_[OBJECT, STATE, ARG0, ARG1];

        my $test  = $self->pop_test;   # remove test being played
        my $event = $test->[2];
        is($state, $event, "got a $event event");
        $test->[3]->($arg0, $arg1);   # check if everything went fine
        $K->yield( '_next_test' );    # call next test
    }
    event mpd_data  => \&_mpd_result;
    event mpd_error => \&_mpd_result;

    # -- private events

    # event: _next_test()
    # called to schedule the next test.
    event _next_test => sub {
        my $self = shift;
        if ( $self->nbtests == 0 ) { # no more tests.
            $K->alias_remove($ALIAS);
            $K->post( _mpd_conn => 'disconnect' );
            return;
        }

        # post next event.
        my $msg = POE::Component::Client::MPD::Message->new({
            request => 'foo', params=>[],
        });
        my $test = $self->peek;
        $msg->_set_commands( [ $test->[0] ] );
        $msg->_set_cooking (   $test->[1]   );
        $K->post( _mpd_conn => 'send', $msg );
    };
    no Moose;
    __PACKAGE__->meta->make_immutable;
    1;
}

# -- main tester
package main;
use POE::Component::Client::MPD::Message;
use POE::Component::Client::MPD::Connection;
use Test::More;

# are we able to test module?
eval 'use Test::Corpus::Audio::MPD';
plan skip_all => $@ if $@ =~ s/\n+BEGIN failed--compilation aborted.*//s;
plan tests => 34;

# tests to be run
My::Session->new( { tests => [
    [ 'bad command', 'raw',         'mpd_error', \&_check_bad_command      ],
    [ 'password fail', 'raw',       'mpd_error', \&_check_bad_password     ],
    [ 'password foobar', 'raw',     'mpd_data',  \&_check_good_password    ],
    [ 'status',      'raw',         'mpd_data',  \&_check_data_raw         ],
    [ 'lsinfo',      'as_items',    'mpd_data',  \&_check_data_as_items    ],
    [ 'stats',       'strip_first', 'mpd_data',  \&_check_data_strip_first ],
    [ 'stats',       'as_kv',       'mpd_data',  \&_check_data_as_kv       ],
] } );
POE::Component::Client::MPD::Connection->spawn( {
    host => 'localhost',
    port => 6600,
    id   => 'tester',
} );
POE::Kernel->run;
exit;

#--
# private subs
sub _check_bad_command {
    like($_[1], qr/unknown command "bad"/, 'unknown command');
}
sub _check_bad_password {
    like($_[1], qr/incorrect password/, 'bad password');
}
sub _check_good_password {
    is($_[1], undef, 'no error message');
}
sub _check_data_as_items {
    is($_[1], undef, 'no error message');
    isa_ok($_, 'Audio::MPD::Common::Item',
            '$AS_ITEMS returns') for @{ $_[0]->_data };
}
sub _check_data_as_kv {
    is($_[1], undef, 'no error message');
    my %h = @{ $_[0]->_data };
    unlike( $h{$_}, qr/\D/, '$AS_KV cooks as a hash' ) for keys %h;
    # stats return numerical data as second field.
}
sub _check_data_raw {
    is($_[1], undef, 'no error message');
    isnt(scalar @{ $_[0]->_data }, 0, 'commands return stuff' );
}
sub _check_data_strip_first {
    is($_[1], undef, 'no error message');
    unlike( $_, qr/\D/, '$STRIP_FIRST return only 2nd field' ) for @{ $_[0]->_data };
    # stats return numerical data as second field.
}
