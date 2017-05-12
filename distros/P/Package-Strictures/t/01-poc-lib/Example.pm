package    # NO CPAN
  Example;

use strict;
use warnings;

use Package::Strictures::Register -setup => {
  -strictures => {
    'STRICT' => {
      default => '',
      type    => 'Bool',              # NOT IMPLEMENTED OR TESTED
      'ENV'   => 'EXAMPLE_STRICT',    # NOT IMPLEMENTED OR TESTED
    }
  },
  -groups => {                        # NOT IMPLEMENTED OR TESTED
    '@all' => {
      doinstead => { STRICT => 1, },
      ENV       => 'EXAMPLE_STRICT_ALL',
    }
  }
};

use namespace::clean;

sub slow {
  my $result = 5;

  if (STRICT) {

    # Simulate some slow validation.
    #
    sleep 1;

    if (@_) {
      die "slow() takes no parameters";
    }
  }
  return $result;
}

1;

