#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Exception::LessClever;
use Child qw/child/;

my $CLASS = 'Parallel::Runner';
use_ok( $CLASS );

my $one = $CLASS->new(2);
$one->_children([child { sleep 10 }]);

# Test::Warn does not handle multi-line warnings properly
# https://rt.cpan.org/Public/Bug/Display.html?id=25427
{
    my @warn;
    local $SIG{__WARN__} = sub { push @warn => @_ };
    $one = undef;
    ok( @warn, "Got a warning" );
    is( $warn[0], <<EOT, "Correct Warning" );
Parallel::Runner object destroyed without first calling finish(), This will
terminate all your child processes. This either means you forgot to call
finish() or your parent process has died.
EOT
}

SKIP: {
    skip ( "Kill tests are only run when \$ENV{RUN_KILL_TESTS} is set", 1 )
        unless $ENV{'RUN_KILL_TESTS'};

    lives_ok {
        my @warn;
        local $SIG{__WARN__} = sub { push @warn => @_ };
        $one = $CLASS->new(2);
        $one->run( sub { sleep 30 });
        $one = undef;
        sleep 10;
    } "Did not kill self";
}

SKIP: {
    skip ( "Kill tests are only run when \$ENV{RUN_KILL_TESTS} is set", 5 )
        unless $ENV{'RUN_KILL_TESTS'};

    $one = $CLASS->new(3);
    $one->run( sub { sleep 30 });
    $one->run( sub { sleep 30 });
    lives_ok {
        my @warn;
        local $SIG{__WARN__} = sub { push @warn => @_ };
        local $SIG{ALRM} = sub { die( 'alarm' )};
        alarm 10;
        $one->killall(15, 1);
        $one->finish;
        alarm 0;
        like( $warn[0], qr/\d+ - Killing: /, "Warn for first pid" );
        like( $warn[1], qr/\d+ - Killing: /, "Warn for second pid" );
    } "Killed, no timeout";

    {
        my @warn;
        local $SIG{__WARN__} = sub { push @warn => @_ };
        $one = $CLASS->new(2);
        $one->run( sub {
            local $SIG{TERM} = sub { sleep 30 };
            sleep 30;
        });
        $one = undef;
        sleep 8;
        my ( $siga, $sigb ) = map { s/\s+.*//s; $_ } @warn[-2,-1];
        my $diff = $sigb - $siga;
        ok( $diff > 3, "First signal sent after delay" );
        ok( $diff < 8, "Second signal sent before too long" );
    };

    {
        my @warn;
        local $SIG{__WARN__} = sub { push @warn => @_ };
        my $one = $CLASS->new(3);
        $one = undef;
        ok( !@warn, "No warnings for out of scope w/o tasks" );
    }
};

lives_ok {
    my $one = $CLASS->new();
    $one->_children(undef);
    $one = undef;
} "Handles empty pids accessor";

done_testing;
