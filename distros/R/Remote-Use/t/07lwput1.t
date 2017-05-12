#!/usr/bin/perl -w -I../lib/
use strict;
use Test::More;
BEGIN { 
  if ( $ENV{REMOTE_USE_DEVELOPER}) {
    plan tests => 3;
  }
  else {
    plan skip_all => 'This tests only run during development';
  }


  system('rm -fR /tmp/perl5lib/* /home/pp2/perl5lib/*');

  my $config = -e 't/lwpmirrorconfig' ? 't/lwpmirrorconfig' : 'lwpmirrorconfig';
  use_ok( 'Remote::Use', config => $config, package => 'lwpmirrorconfig');
  
}
use Trivial;

can_ok('Trivial', 'hello');

my $r = Trivial::hello();
ok($r, 'hello works');
