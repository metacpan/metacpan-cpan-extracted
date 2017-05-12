use strict;
use Test::More tests => 2;

use lib 't/lib';
use TestUtil;

use PHP::Session;

my $sid = "12345";

my @tests = ("a" x 32766, "a" x 32767);

for my $test (@tests) {
    { my $session = PHP::Session->new($sid, { create => 1, save_path => 't' });
      $session->set(text => $test);
      $session->save(); }

    { my $session = PHP::Session->new($sid, { save_path => 't' });
      is $session->get('text'), $test, "testdata is $test";
      $session->destroy(); }
}




