use strict;
use Test::More;

use constant TMPFILE => "./blib/google-api.key";
use constant URL     => "http://aaronland.net";

#

my $key = $ARGV[0];

if ($key) {
  &run_test();
}

elsif (open KEY , "<".TMPFILE) {
  $key = <KEY>;
  chomp $key;
  close KEY;

  &run_test();
}

else {
  plan tests => 1;

  ok($key,"Got Google API key");
}

sub run_test {
  plan tests => 5;

  ok($key,"Got Google API key");
  use_ok("Net::Google");

  my $google = Net::Google->new(key=>$key,debug=>0);
  isa_ok($google,"Net::Google");

  my $cache = $google->cache();
  isa_ok($cache,"Net::Google::Cache");

  $cache->url(URL);
  ok(length($cache->get()),"Got cache for ".URL);

  exit;
}



