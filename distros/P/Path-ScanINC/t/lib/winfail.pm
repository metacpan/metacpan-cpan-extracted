
use strict;
use warnings;

package winfail;

use Test::More;
use Test::Fatal;

my $last;
my $will_reason;
my $expect_undef;

sub will_win($)  { $will_reason = $_[0]; $expect_undef = 1 }
sub will_fail($) { $will_reason = $_[0]; $expect_undef = undef }

sub t(&) {
  my $result = &exception( $_[0] );
  if ( $ENV{TRACE_EXCEPTIONS} ) {
    note $result if defined $result;
  }
  if ($expect_undef) {
    if ( not defined $result ) {
      return pass "[no exception] $will_reason";
    }
    else {
      return fail "$will_reason (expected nonfatal)";
    }
  }
  if ( defined $result ) {
    return pass "[expect exception] $will_reason";
  }
  else {
    return fail "$will_reason (expected exception)";
  }
}

sub import {
  my $caller = caller(0);
  no strict 'refs';
  *{"${caller}::will_win"}  = \&will_win;
  *{"${caller}::will_fail"} = \&will_fail;
  *{"${caller}::t"}         = \&t;

}

1;
