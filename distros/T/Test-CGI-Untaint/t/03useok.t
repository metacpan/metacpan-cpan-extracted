#!/usr/bin/perl -w

###
# testing local extraction handler
###

package CGI::Untaint::blessit;
use base qw(CGI::Untaint::object);
use strict;

sub _untaint_re { qr/(.*)/i };

sub is_valid
{
  my $this = shift;
  $this->value(bless {}, $this->value);

  return 1;
}

########################################################

package CGI::Untaint::undeaf;
use base qw(CGI::Untaint::object);
use strict;

sub _untaint_re { qr/(.*)/i };

sub is_valid
{
  my $this = shift;
  $this->value(undef);

  return 1;
}

########################################################

package CGI::Untaint::nakedref;
use base qw(CGI::Untaint::object);
use strict;

sub _untaint_re { qr/(.*)/i };

sub is_valid
{
  my $this = shift;
  $this->value([]);

  return 1;
}

###########################################################

# fool perl that we've loaded properly
# will this work on windows?
$INC{"CGI/Untaint/blessit.pm"} = 1;
$INC{"CGI/Untaint/undeaf.pm"} = 1;
$INC{"CGI/Untaint/nakedref.pm"} = 1;

###########################################################

####
# tests
####

package main;
use strict;

use Test::Builder::Tester tests => 4;
use Test::CGI::Untaint;

# simply get the value we asked for
test_out("ok 1 - 'fred' extractable as a 'fred'");
is_extractable_isa("fred","fred","blessit");
test_test("is_extractable_isa works");

# okay, if we hand back undef
test_out("not ok 1 - 'fred' extractable as a 'fred'");
test_fail(+2);
test_diag("    the extracted object isn't defined");
is_extractable_isa("fred","fred","undeaf");
test_test("handing back undef");

# okay, if we hand back a plain ref
test_out("not ok 1 - 'fred' extractable as a 'fred'");
test_fail(+2);
test_diag("    the extracted object isn't a 'fred' it's a 'ARRAY'");
is_extractable_isa("fred","fred","nakedref");
test_test("handing back plain ref");

# okay, if we hand back the wrong object type
test_out("not ok 1 - 'ernie' extractable as a 'fred'");
test_fail(+2);
test_diag("    the extracted object isn't a 'fred' it's a 'ernie'");
is_extractable_isa("ernie","fred","blessit");
test_test("wrong type");


