package Parallel::Workers::Backend::Null;

use warnings;
use strict;
use Carp;
 
sub new {
  warn "We won't be doing any Parallel Work, please install a Parallel::Workers::Backend:: module\n";
  bless {};
}

sub pre {
}

sub do {
}

sub post {
}

1; # Magic true value required at end of module
__END__
