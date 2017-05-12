#!perl
  
use strict;
use warnings FATAL => 'all';
  
use lib qw(lib);
use base q(Apache::TestRunPerl);
use Apache::TestConfig ();

main::->new->run(@ARGV);

sub pre_configure {
      my $self = shift;
      # mod_bt doesn't like to be loaded if it isn't configured.
      Apache::TestConfig::autoconfig_skip_module_add('mod_bt.c')
}
