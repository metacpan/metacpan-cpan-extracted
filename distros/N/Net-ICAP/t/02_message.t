#!/usr/bin/perl -T
# 02_message.t

use Test::More tests => 26;

use strict;
use warnings;
use Net::ICAP::Common qw(:all);
use Net::ICAP::Message;
use IO::File;
use Paranoid::Debug;

my $msg = new Net::ICAP::Message;
my ( $file, $fh, $text, @errors, $n, %headers, $out, $rv );

# Test scalar parse
$file = 't/sample-icap/reqmod-post-request';
open $fh, '<', $file or die $!;
$text = join '', <$fh>;
close $fh;

ok( !$msg->parse( \$text ), 'Parse Scalar 1' );
@errors = $msg->error;
$n = scalar grep /invalid header/sm, @errors;
is( scalar @errors, 1, 'Parse Scalar Errors 1' );
is( $n,             1, 'Parse Errors 2' );
%headers = $msg->getHeaders;
is( $headers{Encapsulated},
    'req-hdr=0, req-body=147',
    'Parse Scalar Header 1'
    );

# Test filehandle parse
$msg = new Net::ICAP::Message;
open $fh, '<', $file or die $!;
ok( !$msg->parse($fh), 'Parse Scalar 1' );
@errors = $msg->error;
$n = scalar grep /invalid header/sm, @errors;
is( scalar @errors, 1, 'Parse Scalar Errors 1' );
is( $n,             1, 'Parse Errors 2' );
%headers = $msg->getHeaders;
is( $headers{Encapsulated},
    'req-hdr=0, req-body=147',
    'Parse Scalar Header 1'
    );
close $fh;

# Test IO::Handle parse
$fh = new IO::File;
$fh->open("< $file");
$msg = new Net::ICAP::Message;
open $fh, '<', $file or die $!;
ok( !$msg->parse($fh), 'Parse Scalar 1' );
@errors = $msg->error;
$n = scalar grep /invalid header/sm, @errors;
is( scalar @errors, 1, 'Parse Scalar Errors 1' );
is( $n,             1, 'Parse Errors 2' );
%headers = $msg->getHeaders;
is( $headers{Encapsulated},
    'req-hdr=0, req-body=147',
    'Parse Scalar Header 1'
    );
$fh->close;

# Test generate
$rv = $msg->reqhdr("GET / HTTP/1.1\r\nHost: localhost\r\n");
ok( $rv, 'reqhdr write 1' );
$rv = $msg->body( ICAP_REQ_BODY, 'hardy har har' );
ok( $rv, 'body write 1' );
$msg->header( 'Date', 'Date: Mon, 10 Jan 2000  09:55:21 GMT' );
$rv = $msg->generate( \$out );
ok( $rv, 'generate 1' );
is( length $out, 196, 'generate 2' );
ok( $msg->ieof(1), 'IEOF 1' );
$out = '';
$rv  = $msg->generate( \$out );
ok( $rv, 'generate 3' );
is( length $out, 202, 'generate 4' );
is( $msg->ieof,  1,   'IEOF 2' );
ok( $msg->ieof(0), 'IEOF 3' );
is( $msg->ieof, 0, 'IEOF 4' );
$out = '';
$rv  = $msg->generate( \$out );
ok( $rv, 'generate 5' );
is( length $out, 196, 'generate 6' );

# Test new message generation
$msg = Net::ICAP::Message->new(
    version => ICAP_VERSION,
    trailer => "X-Foo: bar\r\nX-User: jdoe\r\n",
    headers => {
        Date    => scalar localtime,
        Pragma  => "something intelligble",
        'X-Foo' => 'bar',
        },
    reqhdr    => "GET / HTTP/1.0\r\nHost: localhost\r\n",
    body      => "<HTML></HTML>",
    body_type => ICAP_REQ_BODY,
    );
ok( defined $msg, "Create New Message 1" );
is( $msg->header('X-Foo'), 'bar', "Create New Message 2" );

# end 02_message.t
