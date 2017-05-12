######################################################################
# Test suite for SVN::Utils::ClientIP
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;
use Test::More;
use Proc::Info::Environment;
use SVN::Utils::ClientIP;

my $nof_tests = 1;

SKIP: {

  if( !Proc::Info::Environment::os_supported() ) {
    plan tests => $nof_tests;
    skip Proc::Info::Environment::os_not_supported_error_message(), $nof_tests;
  }

  my $path = $ENV{PATH};

  my $pid = fork();

  die "fork failed" unless defined $pid;

  if($pid) {
    # parent
    waitpid($pid, 0);
  } else {
    # child

      # Test::Harness freaks out otherwise
    plan tests => $nof_tests;

    my $finder = SVN::Utils::ClientIP->new(
      ssh_client_var_name => "PATH",
    );

    my $found = $finder->ssh_client_ip_find();
    is $found, $path, "checking PATH environment variable";
    exit 0;
  }
}
