#!/usr/bin/perl -T
# 04_response.t

use Test::More tests => 56;

use strict;
use warnings;
use Net::ICAP::Response;
use Net::ICAP::Common qw(:std :resp);
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

sub sed_n_1p {
    my $file = shift;
    my ( $text, $fh );

    open $fh, '<', $file;
    ($text) = <$fh>;
    close $fh;

    return $text;
}

# These should all fail because of invalid headers
foreach $file (@reqfiles) {
    $msg = new Net::ICAP::Response;
    ok( !$msg->parse( IO::File->new("< $file") ), "Parse Response $file 1" );
    ok( scalar grep /invalid header/sm,
        $msg->error, "Parse Request Error $file 1" );
}

# These should all pass
foreach $file (@respfiles) {
    $msg = new Net::ICAP::Response;
    ok( $msg->parse( IO::File->new("< $file") ), "Parse Response $file 1" );
    ok( !scalar grep /invalid header/sm,
        $msg->error, "Parse Response Error $file 1" );
    $n = sed_n_1p($file);
    ($u) = ( $n =~ /^\S+\s+(\d+)/sm );
    is( $msg->status, $u, "Parse Status $file 1" );
    ($u) = ( $n =~ /^\S+\s+\d+\s+(.+)\r\n$/sm );
    is( $msg->statusText, $u,         "Parse Status Text $file 1" );
    is( $msg->version,    'ICAP/1.0', "Parse Version $file 1" );
    $text = '';
    ok( $msg->generate( \$text ), "Generate $file 1" );
    $n = wc_c($file);
    is( length $text, $n, "Match generated size $file 1" );
}

# Test creating a response from scratch
$msg = Net::ICAP::Response->new(
    status  => ICAP_OK,
    headers => {
        ISTag => 'asdkleijdas',
        Allow => '204',
        },
        );
ok( defined $msg, 'New response creation 1' );
$text = '';
ok( $msg->generate( \$text ), 'New response generation 1' );

# end 04_response.t
