# Test asynchronous Ext.Direct file upload

use strict;
use warnings;

use File::Temp 'tempfile';
use Test::More tests => 5;

use AnyEvent;
use AnyEvent::HTTP;
use RPC::ExtDirect::Client::Async;

use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Server::Util;

use lib 't/lib';
use test::class;
use RPC::ExtDirect::Client::Async::Test::Util;

# Clean up %ENV so that AnyEvent::HTTP does not accidentally connect to a proxy
clean_env;

my ($host, $port) = maybe_start_server(static_dir => 't/htdocs');
ok $port, "Got host: $host and port: $port";

my $cv = AnyEvent->condvar;

my $client = RPC::ExtDirect::Client::Async->new(
    host   => $host,
    port   => $port,
    cv     => $cv,
);

# Generate some files with some random data
my @files = map { gen_file() } 0 .. int rand 9;

my $exp_upload = [
    map {
        { name => (File::Spec->splitpath($_))[2], size => (stat $_)[7] }
    }
    @files
];

$client->upload_async(
    action => 'test',
    method => 'handle_upload',
    upload => \@files,
    cv     => $cv,
    cb     => sub {
        my ($result, $success, $error) = @_;

        ok      $success,                   "Upload successful";
        is      $error,      undef,         "Upload no error";
        unlike  ref $result, qr/Exception/, "Upload result not exception";
        is_deep $result,     $exp_upload,   "Upload data match";
    },
);

# Block until all tests finish
$cv->recv;

sub gen_file {
    my ($fh, $filename) = tempfile;

    print $fh int rand 1000 for 0 .. int rand 1000;

    return $filename;
}

