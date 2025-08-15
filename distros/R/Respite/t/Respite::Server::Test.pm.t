#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;

use Respite::Server::Test qw(setup_test_server);

ok(defined &setup_test_server, "setup_test_server imported");
ok(eval { require config }, "fake config module ready");
ok(eval { require Bam }, "fake Bam module ready");

my ($client, $server) = setup_test_server({
    service  => 'bam', # necessary because we directly subclassed Respite::Server
    api_meta => 'Bam',    # ditto
    client_utf8_encoded => 1,
    flat => 1,
    no_ssl => 1,
    # no password
});

my ($client2, $server2) = setup_test_server({
    service  => 'bam', # necessary because we directly subclassed Respite::Server
    api_meta => 'Bam',    # ditto
    client_utf8_encoded => 1,
    flat => 1,
    no_ssl => 1,
    allow_auth_basic => 1,
    pass => 'fred',
});

ok($client, 'Got client');
ok($server, 'Got server');
ok($client2, 'Got client2');
ok($server2, 'Got server2');

my $resp = eval { $client->foo };
is($resp->{'BAR'}, 1, 'Call api method foo, server no pass, client no pass') or diag(explain($resp));

$client->{'pass'} = 'fred';
$resp = eval { $client->foo };
my $e = $@;
is($resp->{'BAR'}, 1, 'Call api method foo, server no pass, client uses pass') or diag(explain([$e,$resp]));

$resp = eval { $client2->foo };
$e = $@;
is($resp->{'BAR'}, 1, 'Call api method foo, server uses pass, client uses pass') or diag(explain([$e,$resp]));

delete $client2->{'pass'};
$resp = eval { $client2->foo };
$e = $@;
cmp_ok($e, '=~', 'Invalid client auth', 'Call api method foo, server uses pass, client no pass') or diag(explain([$e,$resp]));

$client2->{'pass'} = 'not correct';
$resp = eval { $client2->foo };
$e = $@;
cmp_ok($e, '=~', 'Invalid client auth', 'Call api method foo, server uses pass, client bad pass') or diag(explain([$e,$resp]));

{
    # Instantiate a fake "config" module for testing:
    package config;
    BEGIN { $INC{"config.pm"} = "config.pm"; }
    our %config = (
        server_type => 'moo',
        provider => 'me',
    );
    sub load {
        return \%config;
    }
}

{
    # Create a test server "Bam" module:
    package Bam;
    BEGIN { $INC{"Bam.pm"} = "Bam.pm"; }
    use strict;
    use base qw(Respite::Base);
    sub api_meta {
        return shift->{'api_meta'} ||= {
            methods => {
                foo => 'bar',
            },
        };
    }

    sub bar { {BAR => 1} }
    sub bar__meta {} # { {desc => 'Bar desc'} }
}

__END__

=head1 NAME

Respite::Base.pm.t

=head1 DEVEL

If anything, this is more of an example of setup_test_server that is packaged in Respite::Server::Test.
However, it is used for basic testing to see if the sub works or not.
Typically, you should not override _configs. That may likely go away in this unit tests sometime in the future.

=cut
