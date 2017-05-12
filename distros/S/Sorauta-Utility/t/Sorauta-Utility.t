# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sorauta-Utility.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use lib qw/lib/;
use Test::More tests => 14;
BEGIN { use_ok('Sorauta::Utility') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# get_from_http test
{
  my $url;

  # success
  $url = "http://google.com/";
  #print get_from_http($url)->is_success ? "success" : "failed", $/;
  is(get_from_http($url)->is_success, 1, "get_from_http success test");

  # fail
  $url = "http://sorauta.net/dummy.html";
  #print get_from_http($url)->is_success ? "success" : "failed", $/;
  isnt(get_from_http($url)->is_success, 0, "get_from_http failed test");
}

# save_file test
{
  my $path = "sample.txt";
  my $content =<<"";
Hage
Ksdc
Fuga
EOM

  #print save_file($path, $content), $/;
  is(save_file($path, $content), 1, "save_file success test");

  print `rm -rf $path`;
}

# create_get_url test
{
  my $url = "http://google.com/";
  my $params = { id => 1, name => "sample" };

  #print create_get_url($url, $params), $/;
  is(create_get_url($url, $params), "http://google.com/?name=sample&id=1&", "create_get_url success test");
}

# get_timestamp test
{
  # old timestamp
  #print get_timestamp(1327471334), $/;
  is(get_timestamp(1327471334), "2012/01/25 15:02:14", "get_timestamp success test1");
  # current timestamp
  #print get_timestamp(), $/;
  isnt(get_timestamp(1327471334), "", "get_timestamp success test2");
}

# get_date test
{
  #print get_date(), $/;
  is(ref(get_date()), "HASH", "get_date success test");
}

# get_epoch_from_formated_http test
{
  #print time, $/;
  #print get_epoch_from_formated_http("Fri, 13 Jan 2012 23:49:21 GMT"), $/;
  is(get_epoch_from_formated_http("Fri, 13 Jan 2012 23:49:21 GMT"), "1326498561", "get_epoch_from_formated_http success test");
}

# cat test
{
  my @path_list = ('/Users', 'user', 'Desktop', 'Hoge.txt');
  is(cat(@path_list), "/Users/user/Desktop/Hoge.txt", "cat success test");
}

# is_hidden_file test
{
  my $file_path = ".svn";
  #print is_hidden_file($file_path), $/;
  is(is_hidden_file($file_path), 1, "is_hidden_file test1");
  $file_path = "sample.txt";
  #print is_hidden_file($file_path), $/;
  is(is_hidden_file($file_path), 0, "is_hidden_file test2");
}

# is_unnecessary_copying_file test
{
  my $file_path = ".svn";
  #print is_unnecessary_copying_file($file_path), $/;
  is(is_unnecessary_copying_file($file_path), 1, "is_unnecessary_copying_file test1");
  $file_path = "sample.txt";
  #print is_unnecessary_copying_file($file_path), $/;
  is(is_unnecessary_copying_file($file_path), 0, "is_unnecessary_copying_file test2");
}

1;
