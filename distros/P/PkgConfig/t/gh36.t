use strict;
use warnings;
use lib 't/lib';
use PkgConfig::Path 't/data/gh36';
use PkgConfig::Capture;
use Test::More;
use PkgConfig;

note "DEFAULT_SEARCH_PATH = $_" for @PkgConfig::DEFAULT_SEARCH_PATH;

# adjust to test with real pkg-config
my @pkg_config = ( $^X, $INC{'PkgConfig.pm'} );
#my @pkg_config = ( 'pkg-config' );

subtest 'ppkg-config --modversion with missing dependency' => sub {

  my @command = ( @pkg_config, '--modversion', 'foo' );

  note "% @command";
  my($out, $err, $ret) = capture {
    system @command;
    $?;
  };

  is $ret, 0;
  is $out, "1.0.2\n";
  note "out: $out" if defined $out;
  note "err: $err" if defined $err;

  done_testing;
};

done_testing;
