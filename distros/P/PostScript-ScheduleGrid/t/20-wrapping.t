#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2011 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 6 Oct 2011
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test word wrapping in PostScript::ScheduleGrid
#---------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

use Test::More 0.88;            # want done_testing

use Encode 'find_encoding';

# SUGGEST PREREQ: Test::Differences 0 (better output for failures)
# Load Test::Differences, if available:
BEGIN {
  if (eval "use Test::Differences; 1") {
    # Not all versions of Test::Differences support changing the style:
    eval { Test::Differences::unified_diff() }
  } else {
    eval '*eq_or_diff = \&is;'; # Just use "is" instead
  }
} # end BEGIN

#=====================================================================
# Mock up a partial ScheduleGrid so we can test word wrapping:

use PostScript::ScheduleGrid ();

{
  package Mock::Grid;

  use Moose;

  use MooseX::Types::Moose qw(Int Str);
  use PostScript::ScheduleGrid::Types ':all';

  has cell_font => (
    is      => 'ro',
    isa     => Str,
    default => 'Helvetica',
  );

  has cell_font_size => (
    is      => 'ro',
    isa     => Dimension,
    coerce  => 1,
    default => 7,
  );

  has cell_bot => (
    is      => 'ro',
    isa     => Dimension,
    coerce  => 1,
    default => 2,
  );

  has cell_left => (
    is      => 'ro',
    isa     => Dimension,
    coerce  => 1,
    default => 1,
  );

  has extra_height => (
    is      => 'ro',
    isa     => Dimension,
    coerce  => 1,
    lazy    => 1,
    default => sub { shift->cell_font_size },
  );

  has _metrics => (
    is       => 'ro',
    isa      => FontMetrics,
    init_arg => undef,
    lazy     => 1,
    default  => sub {
      my $s = shift;
      $s->ps->get_metrics($s->cell_font . '-iso', $s->cell_font_size);
    },
  );

  has ps => (
    is      => 'ro',
    isa     => 'PostScript::File',
    default => sub {
      PostScript::File->new(reencode => 'cp1252');
    },
  );

  has lines => (
    is      => 'ro',
    isa     => Int,
    default => 2,
  );

  has width => (
    is      => 'ro',
    isa     => Dimension,
    coerce  => 1,
    default => 72,
  );

  __PACKAGE__->meta->add_method(_add_cell_text =>
                                \&PostScript::ScheduleGrid::_add_cell_text);
  __PACKAGE__->meta->make_immutable;
} # end Mock::Grid

#=====================================================================
sub iName     () { 0 }
sub iParam    () { 1 }
sub iText     () { 2 }
sub iExpected () { 3 }

my @tests = (
  [
    "basic",
    {},
    "Basic test",
    "(Basic test) 101 509 S\n"
  ],
  [
    "long",
    {},
    "This is a long text to be wrapped on two lines",
    "(This is a long text to) 101 509 S\n(be wrapped on two lines) 101 502 S\n"
  ],
  [
    "long at 90pt",
    {
      width => 90
    },
    "This is a long text to be wrapped on two lines",
    "(This is a long text to be) 101 509 S\n(wrapped on two lines) 101 502 S\n"
  ],
  [
    "long at 140pt",
    {
      width => 140
    },
    "This is a long text to be wrapped on two lines",
    "(This is a long text to be wrapped on two) 101 509 S\n(lines) 101 502 S\n"
  ],
  [
    "long at 150pt",
    {
      width => 150
    },
    "This is a long text to be wrapped on two lines",
    "(This is a long text to be wrapped on two lines) 101 509 S\n"
  ],
  [
    "Superman",
    {},
    "The New Adventures of Superman: The Man of Steel Arrives",
    "(Superman: The Man) 101 509 S\n(of Steel Arrives) 101 502 S\n"
  ],
  [
    "Superman short",
    {},
    "The New Adventures of Superman",
    "(The New Adventures) 101 509 S\n(of Superman) 101 502 S\n"
  ],
  [
    "hyphens only",
    {},
    "This-line-doesn't-have-any-spaces-in-it-only-hyphens.",
    "(This\x{ad}line\x{ad}doesn't\x{ad}) 101 509 S\n(have\x{ad}any\x{ad}spaces\x{ad}in\x{ad}it\x{ad}only\x{ad}hyphens.) 101 502 S\n"
  ],
  [
    "extra_height 10",
    {
      extra_height => 10
    },
    "This is a long text to be wrapped on two lines",
    "(This is a long text to) 101 512 S\n(be wrapped on two lines) 101 502 S\n"
  ],
  [
    "extra_height 12 one-line",
    {
      extra_height => 12
    },
    "Short text",
    "(Short text) 101 514 S\n"
  ],
  [
    "no spaces",
    {},
    "This.line.will.have.to.be.wrapped.at.periods.",
    "(This.line.will.have.to.) 101 509 S\n(be.wrapped.at.periods.) 101 502 S\n"
  ],
  [
    "some spaces",
    {},
    "This line will.have.to.be.wrapped at periods.",
    "(This line will.have.to.) 101 509 S\n(be.wrapped at periods.) 101 502 S\n"
  ],
  [
    "some spaces on 3 lines",
    {
      lines => 3,
      width => 100
    },
    "This line will.not.have.to.be.wrapped at periods.",
    "(This line) 101 516 S\n(will.not.have.to.be.wrapped at) 101 509 S\n(periods.) 101 502 S\n"
  ],
  [
    "one line only",
    {
      lines => 1
    },
    "This line can not be wrapped even though it's long.",
    "(This line can not be wrapped even though it's long.) 101 502 S\n"
  ],
); # end @tests

#---------------------------------------------------------------------
my $generateResults;

if (@ARGV and $ARGV[0] eq 'gen') {
  # Just output the actual results, so they can be diffed against this file
  $generateResults = 1;
} else {
  plan tests => scalar @tests;
}

my $cp1252 = find_encoding('cp1252') or die "cp1252 missing";

for my $test (@tests) {
  my $grid = Mock::Grid->new($test->[iParam]);

  $grid->_add_cell_text(100, 100 + $grid->width, 500, $grid->lines,
                        $test->[iText]);

  my $got = $cp1252->decode( $grid->ps->get_page );

  if ($generateResults) {
    $test->[iExpected] = $got;
  } else {
    eq_or_diff($got, $test->[iExpected], $test->[iName]);
  }
}

if ($generateResults) {
  require Data::Dumper;

  my $d = Data::Dumper->new([ \@tests ], ['*tests'])
            ->Indent(1)->Useqq(1)->Quotekeys(0)->Sortkeys(1)->Dump;
  $d =~ s/\]\n\);\n\z/],\n); # end \@tests\n/;

  open(my $out, '>:utf8', '/tmp/20-wrapping.t') or die $!;
  print $out "my $d";
} else {
  done_testing;
}

# Local Variables:
# compile-command: "perl 20-wrapping.t gen"
# End:
