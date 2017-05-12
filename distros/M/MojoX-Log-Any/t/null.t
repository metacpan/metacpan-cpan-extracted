use strict;
use warnings;

use Test::More 1.302067;
use Test::Mojo;

use FindBin;
BEGIN {
  unshift @INC, "$FindBin::Bin";
}
require "testapp.pl";

my $t = Test::Mojo->new;
$t->get_ok('/')->content_is('Log::Any::Proxy');

done_testing();
