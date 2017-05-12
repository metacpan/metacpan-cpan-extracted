use lib './lib';

use strict;
use warnings;

use Error qw(:try);
use Pipeline::Base;
use Test::More tests => 2;

package Subclass;

use base qw( Pipeline::Base );

sub init {
  return undef;
}

1;
package main;

ok( my $obj = Pipeline::Base->new(), "constructed a new pipeline base object" );
try {
  Subclass->new();
} catch Pipeline::Error::Construction with {
  ok( 1, "threw an error" );
};

1;
