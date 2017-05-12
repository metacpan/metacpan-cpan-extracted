use strict;
use Test::More;

use Module::LocalLoad;


subtest 'Localload' => sub {
  plan skip_all => 'load() tested on dev box' if !exists($ENV{RELEASE_TESTING});
  $ENV{PERL_HACK_LIB} = '/tmp/';
  load('Term::ANSIColor'); # 5.6.0
  my $base = $ENV{PERL_HACK_LIB};
  ok(
    $INC{'Term/ANSIColor.pm'} eq "$base/Term/ANSIColor.pm",
    "Term::ANSIColor loaded | PERL_HACK_LIB eq $base",
  );
  #unlink("$base/Term/ANSIColor.pm");
  #delete $ENV{PERL_HACK_LIB};
  #delete $INC{'Term::ANSIColor'};


  #load('IO::File');
  #ok(
  #  $INC{'IO/File.pm'} eq '/tmp/lib/IO/File.pm',
  #  'IO::File loaded | PERL_HACK_LIB unset',
  #);
};

done_testing();

