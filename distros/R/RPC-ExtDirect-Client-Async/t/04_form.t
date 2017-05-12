# Test asynchronous Ext.Direct form submits

use strict;
use warnings;

use Test::More;

use AnyEvent;
use AnyEvent::HTTP;
use RPC::ExtDirect::Client::Async;

use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Server::Util;

use RPC::ExtDirect::Test::Pkg::Meta;

use lib 't/lib';
use test::class;
use RPC::ExtDirect::Client::Async::Test::Util;

my $tests = eval do { local $/; <DATA>; }           ## no critic
    or die "Can't eval DATA: $@";

plan tests => 4 + (4 * @$tests);

# Clean up %ENV so that AnyEvent::HTTP does not accidentally connect to a proxy
clean_env;

my ($host, $port) = maybe_start_server(static_dir => 't/htdocs');
ok $port, "Got host: $host and port: $port";

my $cv = AnyEvent->condvar;

my $cclass = 'RPC::ExtDirect::Client::Async';
my $client = eval {
    $cclass->new(
        host   => $host,
        port   => $port,
        cv     => $cv,
    )
};

is     $@,      '',      "Didn't die";
ok     $client,          'Got client object';
ref_ok $client, $cclass, 'Right object, too,';

# maybe_start_server will leave arguments it doesn't know about
my %run_only = map { $_ => 1 } @ARGV;

TEST:
for my $test ( @$tests ) {
    my $name   = $test->{name};
    my $action = $test->{action};
    my $method = $test->{method};
    my $arg    = $test->{arg};
    my $meta   = $test->{meta};
    my $upload = $test->{upload};
    my $want   = $test->{want};
    my $err_re = $test->{error};
    my $type   = $test->{type} || 'submit';
    
    next TEST if %run_only && !$run_only{$name};
    
    my $sub_name = "${type}_async";
    
    eval {
        $client->$sub_name(
            action   => $action,
            method   => $method,
            arg      => $arg,
            metadata => $meta,
            upload   => $upload,
            cv       => $cv,
            cb       => sub {
                my ($result, $success, $error) = @_;
                
                my $ref = ref $result;

                # $success is *transport* success; when we're testing
                # methods returning exceptions, the mere fact that we
                # did receive the response already means successful
                # invocation. So in fact we should have *no* unsuccessful
                # calls at all in this test suite.
                ok $success, "$name: successful";
                
                if ( $err_re ) {
                    my $msg = $result->message;
                    like $ref, qr/Exception/, "$name: exception";
                    like $msg, $err_re,       "$name: error message";
                }
                else {
                    unlike  $ref,    qr/Exception/, "$name: no exception";
                    is_deep $result, $want,         "$name: result data";
                }
            },
        );
    };
    
    is $@, '', "$name didn't die";
}

# Block until all tests finish
$cv->recv;

__DATA__
#line 106
# These tests are literally copied from the corresponding t/04_form.t
# in RPC::ExtDirect::Client. Both test sets should always be in sync!
[{
    name   => 'Basic form submit',
    action => 'test',
    method => 'handle_form',
    arg    => { frobbe => 'throbbe', vita => 'voom' },
    want   => { frobbe => 'throbbe', vita => 'voom' },
}, {
    name   => 'Ordered metadata',
    action => 'Meta',
    method => 'form_ordered',
    arg    => { fred => 'frob', },
    meta   => [42],
    want   => { fred => 'frob', metadata => [42] },
}, {
    name   => 'Named metadata',
    action => 'Meta',
    method => 'form_named',
    arg    => { boogaloo => 1916, frogg => 'splurge', },
    meta   => { foo => 1, bar => 2, baz => 3, },
    want   => {
        _m => { foo => 1, bar => 2, baz => 3, },
        boogaloo => 1916, frogg => 'splurge',
    },
}];
