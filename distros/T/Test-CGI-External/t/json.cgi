#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::PP 'encode_json';
my $guff = encode_json ({"test" => "json"});
print <<EOF;
Content-Type: application/json

$guff
EOF
exit;
