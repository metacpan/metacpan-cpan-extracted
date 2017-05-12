#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use Perl6::Say;
use Digest::SHA;
use MIME::Base64;
use OAuth::Lite::Util;

my $http_method = "GET";
my $request_url = "http://photos.example.net/photos";
my $params = {
	oauth_consumer_key     => 'dpf43f3p2l4k3l03',
	oauth_token            => 'nnch734d00sl2jdk',
	oauth_signature_method => 'HMAC-SHA1',
	oauth_timestamp        => '1191242096',
	oauth_nonce            => 'kllo9940pd9333jh',
	oauth_version          => '1.0',
	file                   => 'vacation.jpg',
	size                   => 'original',
};

my $base = OAuth::Lite::Util::create_signature_base_string($http_method, $request_url, $params);

my $answer = q{GET&http%3A%2F%2Fphotos.example.net%2Fphotos&file%3Dvacation.jpg%26oauth_consumer_key%3Ddpf43f3p2l4k3l03%26oauth_nonce%3Dkllo9940pd9333jh%26oauth_signature_method%3DHMAC-SHA1%26oauth_timestamp%3D1191242096%26oauth_token%3Dnnch734d00sl2jdk%26oauth_version%3D1.0%26size%3Doriginal};
say $base;
say $answer;
if ($base eq $answer) {
    say "OK";
} else {
    say "NG";
}

my $key = q{kd94hf93k423kf44&pfkkdhi9sl3r4s00};
#my $sign = Digest::SHA::hmac_sha1_base64($base, $key);
my $sign = encode_base64(Digest::SHA::hmac_sha1($base, $key));

chomp $sign;
say $sign;

$params->{oauth_signature} = $sign;

my $header = OAuth::Lite::Util::build_auth_header("http://photos.example.net/", $params);
say $header;

