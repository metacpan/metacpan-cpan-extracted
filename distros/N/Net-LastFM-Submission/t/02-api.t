#!/usr/bin/perl
use strict;
use utf8;

use Test::More tests => 26;

use lib qw(../lib ..);
use Net::LastFM::Submission 'encode_data';

my $conf = require '.lastfmrc';

# diag "Testing Net::LastFM::Submission $Net::LastFM::Submission::VERSION, Perl $], $^X";

my $submit = Net::LastFM::Submission->new('enc' => 'utf8', map { $_ => $conf->{$_} } 'user', 'password');

# error

for ($submit->_error('test')) {
	my $w = 'test error';
	ok ref $_ eq 'HASH', "$w";
	ok $_->{'error' } eq 'ERROR', "$w check 1";
	ok $_->{'reason'} eq 'test',  "$w check 2";
}

# request

for ($submit->_request_handshake) {
	my $w = 'request handshake';
	
	ok   $_->method eq 'GET', "$w check method";
	like $_->uri, qr/\bc=$submit->{'client'}->{'id'}\&v=$submit->{'client'}->{'ver'}\b/, "$w check client";
	like $_->uri, qr/\bu=$submit->{'user'}->{'name'}\b/, "$w check user";
	like $_->uri, qr/\ba=\w+/, "$w check auth token";
}

{
	my $w = 'request now-playing';
	
	like $submit->_request_now_playing->{'reason'}, qr/Need a now-playing URL/, "$w check empty url";
	$submit->{'hs'}->{'url'}->{'np'}++;

	like $submit->_request_now_playing->{'reason'}, qr/Need session ID/, "$w check empty sid";
	$submit->{'hs'}->{'sid'}++;
	
	like $submit->_request_now_playing->{'reason'}, qr/Need artist\/title name/, "$w check empty list of params";
	
	local $_ = $submit->_request_now_playing(artist => 'a', title => 't');
	ok    $_->method eq 'POST', "$w check method";
	like  $_->content, qr/\bs=$submit->{'hs'}->{'sid'}\&a=a\&t=t\b/, "$w check data";
}

{
	my $w = 'request submit';
	
	like $submit->_request_submit->{'reason'}, qr/Need a submit URL/, "$w check empty url";
	$submit->{'hs'}->{'url'}->{'sm'}++;

	like $submit->_request_submit->{'reason'}, qr/Need artist\/title name/, "$w check empty list of params";
	
	local $_ = $submit->_request_submit(artist => 'a', title => 't', time => time - 10*60);
	ok    $_->method eq 'POST', "$w check method";
	like  $_->content, qr/\bs=$submit->{'hs'}->{'sid'}\&a%5B0%5D=a\&t%5B0%5D=t\&i%5B0%5D=\d+\b/, "$w check data";	
}

# response

{
	my $w = 'parse response';
	
	like $submit->_response                  ->{'reason'}, qr/No response/, "$w check init 1";
	like $submit->_response('HTTP::Response')->{'reason'}, qr/No response/, "$w check init 2";
	
	use HTTP::Response;
	
	local $_ = $submit->_response(HTTP::Response->new(500, undef, undef, 'ERROR test error'));
	ok    $_->{'code'  } == 500,          "$w check error 1";
	ok    $_->{'error' } eq 'ERROR',      "$w check error 2";
	like  $_->{'reason'}, qr/test error/, "$w check error 3";
	
	local $_ = $submit->_response(HTTP::Response->new(200, undef, undef, "OK\nsid\nnp\nsm"));
	ok    $_->{'status'} eq 'OK',      "$w check ok 1";
	ok    $_->{'sid'   } eq 'sid',     "$w check ok 2";
	ok    $_->{'url'}->{'np'} eq 'np', "$w check ok 3";
	ok    $_->{'url'}->{'sm'} eq 'sm', "$w check ok 4";
}

# encode data

{
	my $w = 'encode data';
	
	use Encode ();
	
	ok encode_data('data', 'utf8'), "$w check";
}
