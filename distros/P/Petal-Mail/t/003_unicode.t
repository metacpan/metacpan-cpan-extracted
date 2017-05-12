#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'no_plan';
use lib ('lib', '../lib');
use Petal::Mail;

my $string;
my $formatter = new Petal::Mail (
    base_dir  => [ './t/data', './data' ],
    file      => 'news.xml'
);

my $euro  = "\x{20ac}";
my $copy  = "\x{00a9}";
my $club  = "\x{2663}";
my $spade = "\x{2660}";

my $text = "Euro: $euro Copy: $copy Club: $club Spade: $spade";

my $data = {from_name => "The Queen of $spade\'s",
           from_email => "queen\@spades.example.com",
              to_name => "The king of $club\'s",
             to_email => "king\@clubs.example.com",
              subject => "Test message: $text",
               joined => "Test message: $text"};

$string = $formatter->process ( $data );

like ($string, qr /From: =\?UTF-8\?B\?VGhlIFF1ZWVuIG9mIOKZoA==\?='s <queen\@spades\.example\.com>/);
like ($string, qr /X-Copyright: =\?UTF-8\?B\?Q29weXJpZ2h0IMKpIDIwMDUgTUtEb2MgTHRk\?=\./);

like ($string, qr /To: =\?UTF-8\?B\?VGhlIGtpbmcgb2Yg4pmj\?='s <king\@clubs\.example\.com>/);
like ($string, qr /Subject: Test message: Euro:=\?UTF-8\?B\?IOKCrCBDb3B5\?=:=\?UTF-8\?B\?IMKpIENsdWI=\?=:/);

like ($string, qr /Dear The king of $club\'s/);
like ($string, qr /$euro/);
like ($string, qr /$copy/);
like ($string, qr /$club/);
like ($string, qr /$spade/);

1;


__END__
