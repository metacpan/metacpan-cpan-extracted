#!/usr/bin/env perl

#
# Test exception handler
#

use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec;

use lib join '/', File::Spec->splitdir( dirname(__FILE__) ), 'lib';
use lib join '/', File::Spec->splitdir( dirname(__FILE__) ), '..', 'lib';

use Mojolicious::Lite;

use MojoX::JSON::RPC::Service::AutoRegister;

# Documentation browser under "/perldoc" (this plugin requires Perl 5.10)
plugin 'PODRenderer';

plugin 'json_rpc_dispatcher' => {
    services => {
        '/jsonrpc' => MojoX::JSON::RPC::Service::AutoRegister->new->register(
            'sum',
            sub {
                my @params = @_;
                my $sum    = 0;
                $sum += $_ for @params;
                return $sum;
            }
            )->register(
            'die',
            sub {
                die "Test exit from die";
            }
            )
    },
    exception_handler => sub {
        my ( $dispatcher, $err, $m ) = @_;

        # Faking invalid request

        $m->invalid_request('Just testing');
        return;
        }
};

#-------------------------------------------------------------------

# Back to tests

package main;

use TestUts;

use Test::More tests => 3;
use Test::Mojo;

use_ok 'MojoX::JSON::RPC::Client';

my $t = Test::Mojo->new( app );
my $client = MojoX::JSON::RPC::Client->new( ua => $t->ua );

TestUts::test_call(
    $client,
    '/jsonrpc',
    {   id     => 1,
        method => 'sum',
        params => [ 17, 25 ]
    },
    { result => 42 },
    'sum 1'
);

TestUts::test_call(
    $client,
    '/jsonrpc',
    {   id     => 1,
        method => 'die'
    },
    {   error => {
            code    => -32600,
            message => 'Invalid Request.',
            data    => 'Just testing'
        }
    },
    'die 1'
);

1;

