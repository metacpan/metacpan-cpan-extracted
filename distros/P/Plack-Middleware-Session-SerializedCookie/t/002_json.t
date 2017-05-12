#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Plack::Middleware::Session::SerializedCookie;

for(qw(MIME::Base64 JSON)) {
    eval "require $_";
    plan skip_all => "$_ not found!" if $@;
}

require './t/Common.pm';

my $serialize = sub { MIME::Base64::encode_base64(JSON::encode_json(@_), '') };
my $deserialize = sub { JSON::decode_json(MIME::Base64::decode_base64(@_)) if defined $_[0] };

Test::Common::test_complex($serialize, $deserialize);

done_testing;
