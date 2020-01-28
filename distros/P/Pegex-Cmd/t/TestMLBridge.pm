use strict; use warnings;
package TestMLBridge;
use base 'TestML::Bridge';

use Capture::Tiny 'capture_merged';

sub run {
  my ($self, $command) = @_;

  $command =~ s{pegex\b}{perl bin/pegex} or die;

  capture_merged {
      system "$command";
  };
}

1;
