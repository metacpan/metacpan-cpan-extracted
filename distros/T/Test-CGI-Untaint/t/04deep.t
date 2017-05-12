#!/usr/bin/perl -w

###
# testing local extraction handler
###

package CGI::Untaint::deep;
use base qw(CGI::Untaint::object);
use strict;

sub _untaint_re { qr/(.*)/i };

sub is_valid
{
  my $this = shift;
  $this->value(["fred",["burt","ernie"]]);

  return 1;
}

###########################################################

# fool perl that we've loaded properly
# will this work on windows?
$INC{"CGI/Untaint/deep.pm"} = 1;

###########################################################

####
# tests
####

package main;
use strict;

use Test::Builder::Tester tests => 2;
use Test::CGI::Untaint;

# simply get the value we asked for
test_out("ok 1 - 'fred' deeply extractable as deep");
is_extractable_deeply("fred",["fred",["burt","ernie"]],"deep");
test_test("is_extractable_deeply works");

# okay, if the data structures arn't very good
test_out("not ok 1 - 'fred' deeply extractable as deep");
test_fail(+4);
test_diag(q{    Structures begin differing at:});
test_diag(q{         $got->[1][0] = 'burt'});
test_diag(q{    $expected->[1][0] = Does not exist});
is_extractable_deeply("fred",["fred"],"deep");
test_test("badness");

