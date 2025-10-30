#!/usr/bin/env perl
# -*- mode: cperl; -*-

use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);
use Data::Dumper;

use Query::Param;

########################################################################
subtest 'get' => sub {
########################################################################
  local $ENV{CONTENT_TYPE}   = 'application/x-www-form-urlencoded';
  local $ENV{REQUEST_METHOD} = 'GET';
  local $ENV{QUERY_STRING}   = 'foo=bar&baz=buz&biz';

  my $args = Query::Param->new_from_request;

  is( $args->get('foo'), 'bar', 'foo is bar' );

  is( $args->get('baz'), 'buz', 'baz is buz' );

  is( $args->get('biz'), q{}, 'biz is q{}' );
};

########################################################################
subtest 'post multipart/form-data' => sub {
########################################################################

  local $ENV{CONTENT_TYPE}   = 'multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW';
  local $ENV{REQUEST_METHOD} = 'POST';

  my $content = <<'END_OF_CONTENT';
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="hobbies"

gardening
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="hobbies"

golfing
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="username"

johndoe
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="avatar"; filename="avatar.png"
Content-Type: image/png

...binary content of the avatar.png file goes here...
...file data...
...file data...
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="bio"

Software engineer and cat enthusiast.
------WebKitFormBoundary7MA4YWxkTrZu0gW--
END_OF_CONTENT

  local $ENV{CONTENT_LENGTH} = length $content;

  open my $fh, '<', \$content
    or die "could not open handle on string\n";

  local *STDIN = $fh;

  my $args = Query::Param->new_from_request();

  close $fh;

  is( $args->get('username'), 'johndoe', 'username is johndoe' )
    or diag( Dumper($args) );

  is( $args->get('bio'), 'Software engineer and cat enthusiast.', 'bio is Software engineer...' )
    or diag( Dumper($args) );

  is( ref $args->get('hobbies'), 'ARRAY', 'hobbies is an array' )
    or diag( Dumper($args) );
};

########################################################################
subtest 'post application/json' => sub {
########################################################################
  local $ENV{CONTENT_TYPE}   = 'application/json';
  local $ENV{REQUEST_METHOD} = 'POST';

  my $content = <<'END_OF_CONTENT';
{
 "foo" : "bar",
 "baz" : "buz"
}
END_OF_CONTENT

  open my $fh, '<', \$content
    or die "could not open handle on string\n";

  local *STDIN = $fh;

  # local $ENV{CONTENT_LENGTH} = length $content;

  my $args = Query::Param->new_from_request();

  close $fh;

  is( $args->get('foo'), 'bar', 'foo is bar' )
    or diag( Dumper($args) );

  is( $content, $args->to_string, 'to_string is json string' );
};

done_testing();

1;
