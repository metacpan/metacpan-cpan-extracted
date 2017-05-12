#!/usr/bin/env perl
use strict;
use warnings;

# Copyright (c) 2009 George Nistorica
# All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.

# The program tests that PoCo is sending the consolidated error string

use lib q{lib/};

use Data::Dumper;
use Test::More tests => 1;
use POE;
use POE::Component::Client::SMTP;

# set this to one in case the failed event got the single string as
# ARG3
my $consolidated_string = 0;

my $DEBUG = 0;

POE::Session->create(
    q{package_states} => [
        q{main} => [
            q{_start},     q{_stop},
            q{spawn_poco}, q{success_event},
            q{failure_event},
        ],
    ],
);

POE::Kernel->run();

is( $consolidated_string, 1, q{Consolidated string message} );
exit 0;

sub _start {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    $kernel->alias_set(q{Main_Session});
    $kernel->yield(q{spawn_poco});
    return 0;
}

sub _stop {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    return 0;
}

sub spawn_poco {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    # spawn the smpt client that should not be able to connect to
    # anything
    POE::Component::Client::SMTP->send(
        q{From}   => q{charlie@root},
        q{To}     => q{charlie@root},
        q{Server} => q{localhost},
        q{Port}   => 21233,

        # set a small timeout, in case we hit a service that really exists on
        # q{Port} (not likely but who knows}
        q{Timeout} => 3,

        # in case the test succeeds (!!!) let's see what happened
        q{TransactionLog} => 1,
        q{SMTP_Success}   => q{success_event},
        q{SMTP_Failure}   => q{failure_event},
    );
}

sub success_event {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];

    # there should be no success!
    # display what we got and exit so that we determine the smoker to
    # consider the test has failed. thus I get the contents of the
    # data
    my $transaction_log = $_[ARG1];
    diag(q{WE GOT SUCCESS!!!});
    diag( q{Transaction log: } . Dumper($transaction_log) );

    exit 1;
}

sub failure_event {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    my ( $context, $full_error, $transaction_log, $consolidated_error ) =
      @_[ ARG0 .. ARG3 ];
    if ( not defined $consolidated_error or not $consolidated_error ) {
        diag(q{Consolidated error is not defined!!!});

        # this one is the 'global' var
        $consolidated_string = 0;
    }
    else {
        $consolidated_string = 1;
        if ($DEBUG) {
            diag(qq{Consolidated string: "$consolidated_error"});
        }
    }

    return 0;
}
