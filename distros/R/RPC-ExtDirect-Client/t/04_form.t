# Test Ext.Direct form POST request handling

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Server::Util;
use RPC::ExtDirect::Client::Test::Util;

use test::class;
use RPC::ExtDirect::Test::Pkg::Meta;

use RPC::ExtDirect::Client;

my $tests = eval do { local $/; <DATA>; }           ## no critic
    or die "Can't eval DATA: $@";

plan tests => 4 + (3 * @$tests);

# Clean up %ENV so that HTTP::Tiny does not accidentally connect to a proxy
clean_env;

# Host/port in @ARGV means there's server listening elsewhere
my ($host, $port) = maybe_start_server(static_dir => 't/htdocs');
ok $port, "Got host: $host and port: $port";

my $cclass = 'RPC::ExtDirect::Client';
my $client = eval { $cclass->new( host => $host, port => $port, timeout => 1, ) };

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
    my $want   = $test->{want};
    my $error  = $test->{error};
    
    next TEST if %run_only && !$run_only{$name};
    
    my $have = eval {
        $client->submit(
            action   => $action,
            method   => $method,
            arg      => $arg,
            metadata => $meta,
        );
    };
    
    my $have_ref = ref $have;
    
    is $@, '', "$name: didn't die";
    
    if ( $error ) {
        like $have_ref,      qr/Exception/, "$name: exception type";
        like $have->message, $error,        "$name: exception regex";
    }
    else {
        unlike  $have_ref, qr/Exception/, "$name: no exception";
        is_deep $have,     $want,         "$name: return data matches";
    }
}

__DATA__
#line 76
# This data should always be synchronized with the corresponding section
# in RPC::ExtDirect::Client::Async t/04_form.t
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
