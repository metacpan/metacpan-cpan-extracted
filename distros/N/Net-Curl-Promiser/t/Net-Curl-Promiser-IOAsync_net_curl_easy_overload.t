#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use MyServer;

my $test_count = 1;

plan tests => $test_count;

SKIP: {
    eval { require IO::Async::Loop; 1 } or skip "IO::Async isn’t available: $@", $test_count;

    # This ensures that tests aren’t subject to potential bugs
    # in non-core event loop backends.
    no warnings 'once';
    local $IO::Async::Loop::LOOP = 'Select';

    die 'N::C::E shouldn’t be here!' if $INC{'Net/Curl/Easy.pm'};

    require Net::Curl::Promiser::IOAsync;

    my $server = MyServer->new();

    my $port = $server->port();

    my $loop = IO::Async::Loop->new();

    my $promiser = Net::Curl::Promiser::IOAsync->new($loop);

    my $easy = Net::Curl::Easy->new();
    $easy->setopt( Net::Curl::Easy::CURLOPT_URL() => "http://127.0.0.1:$port/foo" );

    # $easy->setopt( CURLOPT_VERBOSE() => 1 );

    $_ = q<> for @{$easy}{ qw(_head _body) };
    $easy->setopt( Net::Curl::Easy::CURLOPT_HEADERDATA() => \$easy->{'_head'} );
    $easy->setopt( Net::Curl::Easy::CURLOPT_FILE() => \$easy->{'_body'} );

    my $caught;

    $promiser->add_handle($easy)->catch(
        sub { $caught = [shift] }
    )->finally( sub { $loop->stop(); } );

    $loop->run();

    is( $caught, undef, 'nothing caught on successful return' );
}
