#!/usr/bin/perl -T
# 03_request.t

use Test::More tests => 56;

use strict;
use warnings;
use Net::ICAP::Request;
use Net::ICAP::Common qw(:std :req);
use IO::File;
use Paranoid::Debug;

my ( $msg, $file, $fh, $text, @errors, $n, $u, %headers );

my @reqfiles = qw(t/sample-icap/options-request
    t/sample-icap/reqmod-post-request t/sample-icap/reqmod-error-request
    t/sample-icap/respmod-get-request t/sample-icap/respmod-trailer-request
    t/sample-icap/reqmod-get-request);
my @respfiles = qw(t/sample-icap/options-response
    t/sample-icap/reqmod-post-response t/sample-icap/reqmod-error-response
    t/sample-icap/respmod-get-response t/sample-icap/respmod-trailer-response
    t/sample-icap/reqmod-get-response);

sub wc_c {
    my $file = shift;
    my ( $text, $fh );

    open $fh, '<', $file;
    $text = join '', <$fh>;
    close $fh;

    return length $text;
}

# These should all fail because of invalid headers
foreach $file (@respfiles) {
    $msg = new Net::ICAP::Request;
    ok( !$msg->parse( IO::File->new("< $file") ), "Parse Response $file 1" );
    ok( scalar grep /invalid header/sm,
        $msg->error, "Parse Response Error $file 1" );
}

# These should all pass
foreach $file (@reqfiles) {
    $msg = new Net::ICAP::Request;
    ok( $msg->parse( IO::File->new("< $file") ), "Parse Response $file 1" );
    ok( !scalar grep /invalid header/sm,
        $msg->error, "Parse Response Error $file 1" );
    ($n) = ( $file =~ /^.+\/(\w+)-.+$/sm );
    $n = uc $n;
    is( $msg->method, $n, "Parse Method $file 1" );
    ($n) = ( $msg->url =~ m#^icap://([^/:]+)#smi );
    is( $msg->header('Host'), $n,         "Parse URL $file 1" );
    is( $msg->version,        'ICAP/1.0', "Parse Version $file 1" );
    $text = '';
    ok( $msg->generate( \$text ), "Generate $file 1" );
    $n = wc_c($file);
    is( length $text, $n, "Match generated size $file 1" );
}

# Test creating a request from scratch
$msg = Net::ICAP::Request->new(
    method  => ICAP_REQMOD,
    url     => 'icap://localhost/service',
    headers => {
        Host  => 'localhost',
        Allow => '204',
        },
        );
ok( defined $msg, 'New request creation 1' );
$text = '';
ok( $msg->generate( \$text ), 'New request generation 1' );

# end 03_request.t
