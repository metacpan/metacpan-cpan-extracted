#!/usr/bin/perl -w

###
# testing local extraction handler
###

package CGI::Untaint::metasyntatic;
use base qw(CGI::Untaint::object);
use strict;

# define the regex
sub _untaint_re { qr/(foo|null)/i };

# define a set where we can return undef
sub is_valid
{
  my $this = shift;

  if ($this->value eq "NULL")
    { $this->value(undef) }

  return 1;
}

# fool perl that we've loaded properly
# will this work on windows?
$INC{"CGI/Untaint/metasyntatic.pm"} = 1;

####
# tests
####

package main;
use strict;

use Test::Builder::Tester tests => 9;
use Test::CGI::Untaint;

# is_extractable

# simply get the value we asked for
test_out("ok 1 - 'foo' extractable as metasyntatic");
is_extractable("foo","foo","metasyntatic");
test_test("is_extractable works");

# am able to set custom font
test_out("ok 1 - custom");
is_extractable("foo","foo","metasyntatic", "custom");
test_test("is_extractable custom text");

# does extracting undef work okay?
test_out("ok 1 - 'NULL' extractable as metasyntatic");
is_extractable("NULL",undef,"metasyntatic");
test_test("is_extractable undef");

# an error extracting
# NB this might fail if CGI::Untaint ever changes its error messages
test_out("not ok 1 - 'bar' extractable as metasyntatic");
test_fail(+2);
test_diag("data (bar) does not untaint with default pattern");
is_extractable("bar","foo","metasyntatic");
test_test("is extractable fails ok");

# getting the wrong thing back
test_out("not ok 1 - 'foo' extractable as metasyntatic");
test_fail(+3);
test_diag("         got: 'foo'");
test_diag("    expected: 'bar'");
is_extractable("foo","bar","metasyntatic");
test_test("is_extractable fails ok 2");

# unextractable

# something that isn't extractable
test_out("ok 1 - 'bar' unextractable as metasyntatic");
unextractable("bar","metasyntatic");
test_test("unextractable works");

# test the custom error message
test_out("ok 1 - custom");
unextractable("bar","metasyntatic", "custom");
test_test("unextractable custom text");

# test that something was sucessfully extracted when it wasn't meant
# to be
test_out("not ok 1 - 'Foo' unextractable as metasyntatic");
test_fail(+3);
test_diag("expected data to be unextractable, but got:");
test_diag(" 'Foo'");
unextractable("Foo","metasyntatic");
test_test("unextractable fails ok");

# and again, even when the thingy hands back an undef
test_out("not ok 1 - 'NULL' unextractable as metasyntatic");
test_fail(+3);
test_diag("expected data to be unextractable, but got:");
test_diag(" undef");
unextractable("NULL","metasyntatic");
test_test("unextractable fails ok 2");
