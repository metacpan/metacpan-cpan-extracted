use strict;
use warnings;
use lib 't/lib';
use PkgConfig::Capture;
use Test::More;
use PkgConfig;

note "DEFAULT_SEARCH_PATH = $_" for @PkgConfig::DEFAULT_SEARCH_PATH;

# adjust to test with real pkg-config
my @pkg_config = ( $^X, $INC{'PkgConfig.pm'} );
#my @pkg_config = ( 'pkg-config' );

#  assuming nobody will create a library named after an extinct
#  crocodile from the Miocene Riversleigh fauna.  
my $nonexistent_lib = 'libtrilophosuchus-rackhami';

my $re_error_message = qr/^Can't find $nonexistent_lib.pc in any of /m;

my %test_data = (
  'no-arg' => {
    stdout => 'unlike',
    stderr => 'unlike',
  },
  '--print-errors' => {
    stdout => 'unlike',
    stderr => 'like',
  },
  '--silence-errors' => {
    stdout => 'unlike',
    stderr => 'unlike',
  },
  '--errors-to-stdout' => {
    stdout => 'like',
    stderr => 'unlike',
  },
  
);


foreach my $test_name (sort keys %test_data) {
  my @command
    = grep {$_ ne 'no-arg'}
      ( @pkg_config, $test_name, $nonexistent_lib );

  note "% @command";
  my($out, $err, $ret) = capture {
    system @command;
    $?;
  };

  is $ret, 256, "error code correct";
  if ($test_data{$test_name}{stdout} eq 'like') {
    like $out, $re_error_message, "stdout for $test_name contains error string";
  }
  else {
    unlike $out, $re_error_message, "stdout for $test_name does not contain error string";
  }
  if ($test_data{$test_name}{stderr} eq 'like') {
    like $err, $re_error_message, "stderr for $test_name contains error string";
  }
  else {
    unlike $err, $re_error_message, "stderr for $test_name does not contain error string";
  }
  note "out: $out" if defined $out;
  note "err: $err" if defined $err;
  
}


done_testing();
