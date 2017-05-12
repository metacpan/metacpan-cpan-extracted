use strict;
use Test::More tests => 5;

use lib 't/lib';
use TestUtil;

use PHP::Session;

my $sid = "12345";

my @tests = qw(20030224000000 012345 1.4 01.4 123545);

for my $test (@tests) {
    { my $session = PHP::Session->new($sid, { create => 1, save_path => 't' });
      $session->set(text => $test);
      $session->save(); }

    { my $session = PHP::Session->new($sid, { save_path => 't' });
      is $session->get('text'), $test, "testdata is $test";
      $session->destroy(); }
}




