package Qiniu::Util;
use strict;
use 5.010;
use Exporter 'import';
use Mojo::JSON qw(decode_json encode_json);
use Digest::SHA qw(hmac_sha1);
use MIME::Base64 qw(decode_base64 encode_base64);
our @EXPORT_OK = ( qw(decode_json encode_json safe_b64_encode encode_base64 hmac_sha1 encoded_entry_uri) );

sub safe_b64_encode {
    my $str = shift;
    $str = encode_base64($str);
    $str =~ tr/+/-/;
    $str =~ tr/\//_/;
    $str =~ s/\n//g;
    return $str;
}

sub encoded_entry_uri {
    my ($bucket, $key) = @_;
    my $entry = $key ? "$bucket:$key" : $bucket;
    return safe_b64_encode($entry);
}

