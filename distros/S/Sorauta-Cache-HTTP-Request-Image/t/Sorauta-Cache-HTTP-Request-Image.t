# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sorauta-Cache-HTTP-Request-Image.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use lib qw/lib/;
use Test::More tests => 2;
BEGIN { use_ok('Sorauta::Cache::HTTP::Request::Image') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $CACHE_PATH = '/tmp/';
my $SAMPLE_URLS = [
  'http://www.google.co.jp/images/srpr/logo3w.png',
#  'http://sorauta.net/images/common/author.jpg',
];
my $MAX_WIDTH = 900;
my $MAX_HEIGHT = 1600;
my $DEBUG = 0;
my $CHECK = 0;
my $RENDER = 0;

# get test
{
  # テスト用
  my $url = $SAMPLE_URLS->[int(rand(@$SAMPLE_URLS))];

  # キャッシュ生成
  my $result = Sorauta::Cache::HTTP::Request::Image->new({
    cache_path            => $CACHE_PATH,
    url                   => $url,
    check                 => $CHECK,
    render                => $RENDER,
    debug                 => $DEBUG,
  })->execute;

  ok($result, "get request image");
}

# get test2
=pod
{
  my $cgi = CGI->new;
  my $url = $cgi->param('url');
  my $check = $cgi->param('check');

  # キャッシュ生成
  Sorauta::Cache::HTTP::Request::Image->new({
    cache_path            => $CACHE_PATH,
    url                   => $url,
    check                 => $CHECK,
    debug                 => $DEBUG,

  })->execute;
}
=cut

1;
