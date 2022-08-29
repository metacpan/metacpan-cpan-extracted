#!/usr/bin/env perl

use Test2::V0;

use Capture::Tiny qw( capture_stderr );
use IO::Socket::INET ();
use Net::EmptyPort qw( empty_port );
use Time::HiRes qw( ualarm usleep );

use subs 'timed';

require Net::Wait;

subtest 'Basic usage' => sub {
    my $port = empty_port();

    like dies { Net::Wait->import( -timeout => 0.1, "127.0.0.1:$port" ) },
        qr/^Net::Wait timed out while waiting for 127.0.0.1:$port/,
        'Dies if port does not listen';

    my $socket = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => $port,
        Listen => 1,
    ) or die "Could not create socket: $!";

    is do { Net::Wait->import( -timeout => 0.1, "127.0.0.1:$port" ); 'ok' },
        'ok', 'Does not die if port is listening';
};

subtest 'Verbose' => sub {
    my %tests = (
        'Waiting up to 0.1 seconds' => 0.1,
        'Waiting up to 10 seconds'  => undef,
        'Waiting up to 1 second'    => 1,
        'Waiting'                   => -1,
    );

    while ( my ( $label, $timeout ) = each %tests ) {
        my $port = empty_port();

        my $socket = IO::Socket::INET->new(
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Listen    => 1,
        ) or die "Could not create socket: $!";

        my $output = $label . " for 127.0.0.1:$port\n";

        is  capture_stderr {
                timed $timeout => sub {
                    Net::Wait->import(
                        -verbose,
                        defined $timeout ? ( -timeout => $timeout ) : (),
                        "127.0.0.1:$port",
                    );
                }
            },
            $output, $label;
    }
};

subtest 'Parameter validation' => sub {
    like dies { Net::Wait->import() },
        qr/^Missing list of host\/port pairs when loading Net::Wait/,
        'Must have list of host/port pairs';

    like dies { Net::Wait->import( -fake ) },
        qr/^Found unknown option when loading Net::Wait: -fake/,
        'Options must be valid';

    like dies { Net::Wait->import( -timeout ) },
        qr/^Missing value for -timeout when loading Net::Wait/,
        'Option values must exist';

    like dies { Net::Wait->import( 'foo' ) },
        qr/^Cannot parse host and port from argument to Net::Wait: 'foo'/,
        'Host/port pairs must be valid';
};

done_testing;

# Based on Sys::SigAction
my $TIMEOUT = {};
sub timed ($&) {
    my ( $timeout, $code ) = @_;

    # Not good for general usage, but for this test
    # we want to ensure that there's always _some_ timeout
    $timeout = 0.1 if !$timeout || $timeout < 0;

    my $timed_out = 0;

    eval {
        local $SIG{ALRM} = sub { $timed_out = 1; die $TIMEOUT };

        eval {
            ualarm( $timeout * 1_000_000 );
            $code->();
        };

        ualarm(0);

        die $@ if $@;
    };

    die $@ if $@ && !( ref $@ && $@ == $TIMEOUT );

    return $timed_out;
}
