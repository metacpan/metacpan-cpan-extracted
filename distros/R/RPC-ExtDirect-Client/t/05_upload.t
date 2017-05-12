# Test Ext.Direct form POST/upload request handling

use strict;
use warnings;

use File::Temp 'tempfile';
use File::Spec;

use Test::More tests => 7;

use lib 't/lib';
use test::class;
use RPC::ExtDirect::Test::Util;
use RPC::ExtDirect::Server::Util;
use RPC::ExtDirect::Client::Test::Util;

use RPC::ExtDirect::Client;

# Clean up %ENV so that HTTP::Tiny does not accidentally connect to a proxy
clean_env;

# CGI::Simple has uploads disabled by default; maybe this is what causes
# massive failures in CPAN testers?
eval {
    no warnings 'once';

    require CGI;
    $CGI::DISABLE_UPLOADS = 0;

    require CGI::Simple;
    $CGI::Simple::DISABLE_UPLOADS = 0;
};

# Host/port in @ARGV means there's server listening elsewhere
my ($host, $port) = maybe_start_server(static_dir => 't/htdocs');
ok $port, "Got host: $host and port: $port";

my $cclass = 'RPC::ExtDirect::Client';

my $client = eval { $cclass->new( host => $host, port => $port, timeout => 1, ) };

is     $@,      '',      "Didn't die";
ok     $client,          'Got client object';
ref_ok $client, $cclass, 'Right object, too,';

# Generate some files with some random data
my @files = map { gen_file() } 0 .. int rand 9;

my $exp = [
    map {
        { name => (File::Spec->splitpath($_))[2], size => (stat $_)[7] }
    }
    @files
];

my $data = eval {
    $client->submit(
        action => 'test',
        method => 'handle_upload',
        arg    => {},
        upload => \@files,
    )
};

is      $@,        '',            "Upload didn't die";
unlike  ref $data, qr/Exception/, "Upload result not an exception";
is_deep $data,     $exp,          "Upload data match";

sub gen_file {
    my ($fh, $filename) = tempfile;

    print $fh int rand 1000 for 0 .. int rand 1000;

    return $filename;
}

