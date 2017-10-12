#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

# This file is part of Perl-Critic-Pulp.
#
# Perl-Critic-Pulp is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Perl-Critic-Pulp is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Perl-Critic-Pulp.  If not, see <http://www.gnu.org/licenses/>.


use 5.006;
use strict;
use warnings;
use Test::More tests => 91;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon;

#-----------------------------------------------------------------------------
my $want_version = 95;
is ($Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon::VERSION, $want_version, 'VERSION variable');
is (Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon->VERSION, $want_version, 'VERSION class method');
{
  ok (eval { Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon->VERSION($want_version); 1 }, "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon->VERSION($check_version); 1 }, "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
require Perl::Critic;
my $critic = Perl::Critic->new
  ('-profile' => '',
   '-single-policy' => '^Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon$');
{ my @p = $critic->policies;
  is (scalar @p, 1,
      'single policy RequireFinalSemicolon');

  my $policy = $p[0];
  is ($policy->VERSION, $want_version, 'VERSION object method');
  ok (eval { $policy->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $policy->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}


#-----------------------------------------------------------------------------
# _syntax_feature_list()

foreach my $data ([ 'use syntax "try"', 'try' ],
                  [ 'use syntax', '' ],
                  [ 'use syntax qw(foo bar), quux => {}, xyzzy => {}',
                    'foo,bar,quux,xyzzy' ],
                 ) {
  my ($str, $want) = @$data;
  my $document = PPI::Document->new (\$str)
    || die "oops, no parse: $str";
  my $inc = $document->find_first ('PPI::Statement::Include')
    || die "oops, no PPI::Statement::Include in: $str";
  my $got = join(',',
                 Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon::_syntax_feature_list($inc));
  is ($got, $want, '_syntax_feature_list()');
}

#-----------------------------------------------------------------------------
# _syntax_has_feature()

foreach my $data ([ 'use syntax q{try}', 'try', 1 ],
                  [ 'use syntax',       'try', 0 ],
                  [ 'use syntax qw(foo bar), \'quux\' => {}, xyzzy => {}',
                    'xyzzy', 1 ],
                  [ 'use syntax qw(foo bar), quux => {}, xyzzy => {}',
                    'bar', 1 ],
                 ) {
  my ($str, $feature, $want) = @$data;
  my $document = PPI::Document->new (\$str)
    || die "oops, no parse: $str";
  my $inc = $document->find_first ('PPI::Statement::Include')
    || die "oops, no PPI::Statement::Include in: $str";
  my $got = (Perl::Critic::Policy::CodeLayout::RequireFinalSemicolon::_syntax_has_feature($inc, $feature)
             ? 1 : 0);
  is ($got, $want, '_syntax_has_feature()');
}


#-----------------------------------------------------------------------------
foreach my $data
  (# no critic (RequireInterpolationOfMetachars)

   [ 0, "grep { defined\n } \@y" ],
   [ 1, "sub { defined\n }" ],
   [ 0, "use List::Util;  reduce { \$a+\$b\n } \@y" ],
   [ 0, "List::Util::first { \$_ > 10\n } \@y" ],
   [ 0, "any { \$_ > 10\n } \@y" ],
   [ 1, "blah { foo(); bar(); quux() \n }" ],

   [ 0, "{ a => 1 \n}" ], # hash constructor
   [ 1, "{ a,1 \n}" ],     # code block
   [ 1, "{; a => 1 \n}" ], # code block

   [ 0, "use TryCatch;  sub { try { a => 1 } \n}" ],

   # this is mis-detected as part of the "try"
   # [ 1, "use TryCatch;  sub { try { a => 1 } foo() \n}" ],

   [ 1, "use TryCatch;  try { a => 1 \n}" ], # code block
   [ 1, "use Try::Tiny; catch { a => 1 \n}" ], # code block
   [ 1, "use Try;       finally { a => 1 \n}" ], # code block

   [ 0, "use Try;          { blah(); try { foo() } catch { bar() }\n }" ],
   [ 0, "use TryCatch;     { blah(); try { foo() } catch (\$err) { bar() }\n }" ],
   [ 0, "use syntax 'try'; { blah(); try { foo() } catch { bar() finally { quux() } }\n }" ],
   [ 1, "use Try::Tiny;    { blah(); try { foo() } catch { bar() }\n }" ],
   [ 1, "use Try::Tiny::Except; { blah(); try { foo() } catch { bar() }\n }" ],

   [ 0, "use Try; { try { foo() } catch { bar() } try { foo() } catch { bar() }\n }" ],
   [ 1, "use Try::Tiny; { try { foo() } catch { bar() };\n try { foo() } catch { bar() }\n }" ],

   [ 1, "{\n  print <<HERE\nsome text\nHERE\n}" ],
   [ 0, "map { \$x\n } \@y" ],
   [ 0, "map {; q{a},1\n } \@y" ],
   [ 0, "map {; q{a},1,q{b},2\n } \@y" ],

   [ 0, "return \\ { a=>2 \n }" ], # ref to hashref

   # hashrefs
   [ 0, "\{ a => 1\n}" ],
   [ 0, "\$x = { 1 => 2\n}" ],
   [ 0, "\$x = \\{ a=>2,a=>2\n}" ], # ref to hashref

   [ 0, "Foo->new({ %args,\n})" ],
   [ 0, "foo({ %args,\n })" ],
   [ 1, "sub { %args,\n}" ],
   [ 1, "sub foo { %args,  \n }" ],
   [ 0, "\$x = { %args,  \n }" ],
   [ 0, "bless { 1 => 2\n}, \$_[0];" ],

   # the prototype on first() is not recognised, as yet
   [ 0, "List::Util::first { 123,\n } \@args" ],

   [ 0, 'sub foo' ],
   [ 0, 'sub foo { }' ],
   [ 0, "sub foo {\n}" ],
   [ 0, "do {\n}" ],
   [ 0, "do {\n} while(1)" ],
   [ 0, "sub foo {;}" ],
   [ 0, "sub foo {;\n}" ],
   [ 0, "sub foo {;\n__END__" ],
   [ 0, "BEGIN {}" ],
   [ 0, "BEGIN {\n}" ],
   [ 0, "BEGIN { MYLABEL: { print 123 }\n}" ],
   [ 0, "sub foo { if (1) { print; }\n}" ],
   [ 0, "sub foo { while (1) { print; }\n}" ],
   [ 0, "sub foo { until (1) { print; }\n}" ],
   [ 0, "sub foo { if (1) { print; } else { print; }\n}" ],
   [ 0, "sub foo { if (1) { print 1; } elsif (2) { print 2; }\n}" ],
   [ 0, "sub foo { return bless { 1 => 2\n}, \$_[0] }" ],
   [ 0, "sub foo { \$x = bless { 1 => 2\n}, \$_[0] }" ],
   [ 0, "sub foo { \$x = { 1 => 2\n} }" ],

   [ 0, "sub foo { 123 }" ],
   [ 0, "sub foo { 123; }" ],
   [ 0, "sub foo { 123;\n}" ],
   [ 1, "sub foo { 123\n}" ],
   [ 1, "sub foo { 123 # x \n }" ],
   [ 0, "sub foo { return 123;\n}" ],
   [ 1, "sub foo { return 123\n}" ],
   [ 0, "sub foo { return {};\n}" ],
   [ 1, "sub foo { return {}\n}" ],
   # unterminated
   [ 1, "sub foo { 123" ],
   [ 1, "sub foo { 123 # x" ],

   [ 0, "do { 123 }" ],
   [ 0, "do { 123\n}" ],
   [ 0, "do { 123 # x \n }" ],
   # unterminated
   [ 0, "do { 123" ],
   [ 0, "do { 123 # x" ],

   [ 0, "do { 123 } until (\$condition)" ],
   [ 1, "do { 123\n} until (\$condition)" ],
   [ 1, "do { 123 # x \n } until (\$condition)" ],

   [ 0, "do { 123 } while (\$condition)" ],
   [ 1, "do { 123\n} while (\$condition)" ],
   [ 1, "do { 123 # x \n } while (\$condition)" ],

   ## use critic
  ) {
  my ($want_count, $str) = @$data;

  my @violations = $critic->critique (\$str);

  my $got_count = scalar @violations;
  is ($got_count, $want_count, "str: $str");

  if ($got_count != $want_count) {
    foreach (@violations) {
      diag ($_->description);
    }
  }
}

exit 0;
